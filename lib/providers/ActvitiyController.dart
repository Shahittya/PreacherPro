import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ActivityData.dart';
import '../models/ActivityAssignment.dart'; 

class ActivityController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<ActivityData>> activitiesStream() {
    return _db
        .collection('activities')
        .orderBy('activity_date')
        .snapshots()
        .asyncMap((snap) async {
          final activities = snap.docs.map((d) => ActivityData.fromDoc(d)).toList();
          
          // Fetch assignments and details for each activity
          for (var activity in activities) {
            await activity.fetchDetails();
          }
          
          return activities;
        });
  }

  // optional: one-time fetch
  Future<List<ActivityData>> fetchActivitiesOnce() async {
    final snap = await _db.collection('activities').orderBy('activity_date').get();
    return snap.docs.map((d) => ActivityData.fromDoc(d)).toList();
  }

  Future<void> addActivity(ActivityData activity) async {
    await ActivityData.addActivity(activity);
    notifyListeners();
  }

  // Mark activity and its assignment (if any) as checked_in
  Future<void> markCheckedIn(ActivityData activity) async {
    // Update activity status
    await _db.collection('activities').doc(activity.docId).update({'status': 'checked_in'});

    // Update related assignment status if exists
    ActivityAssignment? assignment = activity.assignment;
    assignment ??= await ActivityAssignment.getAssignmentByActivity(activity.activityId);
    if (assignment != null && assignment.docId.isNotEmpty) {
      await ActivityAssignment.updateStatus(assignment.docId, 'checked_in');
    }

    notifyListeners();
  }
  
}
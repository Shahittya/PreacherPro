import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ActivityData.dart';
import '../models/ActivityAssignment.dart'; 

class ActivityController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper method to get status priority for sorting
  int _getStatusPriority(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return 1;
      case 'checked_in':
        return 2;
      case 'pending':
        return 3;
      case 'rejected':
        return 4;
      case 'approved':
        return 5;
      case 'missed':
        return 6;
      default:
        return 7;
    }
  }

  Stream<List<ActivityData>> activitiesStream() {
    // Get current officer's UID
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    // Always use UID for filtering (not email) since assigned_by stores UID
    final userId = currentUser.uid;
    print('👮 Officer filtering activities for user: $userId');
    print('📧 Officer email: ${currentUser.email}');

    // Stream from activities collection to get real-time updates
    return _db
        .collection('activities')
        .snapshots()
        .asyncMap((activitiesSnap) async {
          // Get all activity IDs assigned by this officer
          final assignmentsSnap = await _db
              .collection('activity_assignments')
              .where('assigned_by', isEqualTo: userId)
              .get();
          
          print('🔍 Checking assignments - Query: assigned_by = $userId');
          print('🔍 Found ${assignmentsSnap.docs.length} assignment documents');
          
          // Debug: print all assignments to see what's there
          for (var doc in assignmentsSnap.docs) {
            final data = doc.data();
            print('  Assignment: activity_id=${data['activity_id']}, assigned_by=${data['assigned_by']}');
          }
          
          final assignedActivityIds = assignmentsSnap.docs
              .map((doc) => doc.data()['activity_id'] as int)
              .toSet();
          
          print('📋 Found ${assignedActivityIds.length} activities assigned by this officer');
          print('📋 Activity IDs assigned by officer: $assignedActivityIds');

          // Filter activities: created by this officer OR assigned by this officer
          print('🔍 Total activities in database: ${activitiesSnap.docs.length}');
          
          var activities = activitiesSnap.docs
              .map((d) => ActivityData.fromDoc(d))
              .where((activity) {
                final createdByOfficer = activity.createdBy == userId;
                final assignedByOfficer = assignedActivityIds.contains(activity.activityId);
                
                if (createdByOfficer || assignedByOfficer) {
                  print('  ✓ Including activity_id=${activity.activityId}: created_by=${activity.createdBy}, createdByOfficer=$createdByOfficer, assignedByOfficer=$assignedByOfficer');
                }
                
                return createdByOfficer || assignedByOfficer;
              })
              .toList();
          
          print('✅ Filtered to ${activities.length} activities (created by OR assigned by officer)');
          
          // Fetch assignments and details for each activity
          for (var activity in activities) {
            await activity.fetchDetails();
          }
          
          // Sort by status priority, then by activity_date descending (newest first within same status)
          activities.sort((a, b) {
            final statusCompare = _getStatusPriority(a.status).compareTo(_getStatusPriority(b.status));
            if (statusCompare != 0) return statusCompare;
            
            // Secondary sort: by activity_date descending
            try {
              final dateA = _parseDate(a.activityDate);
              final dateB = _parseDate(b.activityDate);
              return dateB.compareTo(dateA); // descending
            } catch (_) {
              return 0;
            }
          });
          
          return activities;
        });
  }

  // Stream of activities for a specific preacher (by UID)
  Stream<List<ActivityData>> preacherActivitiesStream(String preacherUid) {
    if (preacherUid.isEmpty) {
      return Stream.value([]);
    }

    return _db
        .collection('activities')
        .snapshots()
        .asyncMap((activitiesSnap) async {
          // Get all activity IDs assigned to this preacher
          final assignmentsSnap = await _db
              .collection('activity_assignments')
              .where('preacher_id', isEqualTo: preacherUid)
              .get();

          final assignedActivityIds = assignmentsSnap.docs
              .map((doc) => (doc.data()['activity_id'] as num).toInt())
              .toSet();

          var activities = activitiesSnap.docs
              .map((d) => ActivityData.fromDoc(d))
              .where((activity) =>
                  assignedActivityIds.contains(activity.activityId) ||
                  activity.createdBy == preacherUid)
              .toList();

          for (var activity in activities) {
            await activity.fetchDetails();
          }

          activities.sort((a, b) {
            final statusCompare = _getStatusPriority(a.status)
                .compareTo(_getStatusPriority(b.status));
            if (statusCompare != 0) return statusCompare;
            try {
              final dateA = _parseDate(a.activityDate);
              final dateB = _parseDate(b.activityDate);
              return dateB.compareTo(dateA);
            } catch (_) {
              return 0;
            }
          });

          return activities;
        });
  }

  // Helper to parse date string (handles both DD/MM/YYYY and YYYY-MM-DD formats)
  DateTime _parseDate(String dateStr) {
    try {
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      } else {
        final parts = dateStr.split('-');
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
    } catch (_) {
      return DateTime.now();
    }
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

  // Delete activity and its assignment (only if status is 'assigned')
  Future<bool> deleteActivity(ActivityData activity) async {
    try {
      // Check if activity can be deleted (only if assigned status)
      if (activity.status.toLowerCase() != 'assigned') {
        return false;
      }

      // Delete the assignment if it exists
      await ActivityAssignment.deleteAssignmentByActivity(activity.activityId);

      // Delete the activity
      await ActivityData.deleteActivity(activity.docId);

      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting activity: $e');
      return false;
    }
  }
  
}
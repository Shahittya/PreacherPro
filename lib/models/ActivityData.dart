import 'package:cloud_firestore/cloud_firestore.dart';
import 'ActivityAssignment.dart';

class ActivityData {
  final String docId;
  final int activityId;
  final String title;
  final String topic;
  final String description;
  final String activityDate;
  final String startTime;
  final String endTime;
  final String locationName;
  final String locationAddress;
  final double locationLat;
  final double locationLng;
  final String createdBy;
  final DateTime createdAt;
  String status;
  // Explanation & review metadata
  String? explanationReason;
  String? explanationDetails;
  String? explanationProofUrl;
  DateTime? explanationTimestamp;
  String? explanationManualLocation;
  String? officerDecision; // approved_attended | reject_absent | cancelled
  DateTime? officerDecisionTimestamp;
  
  // Additional fields for display
  String? preacherName;
  String? officerName;
  ActivityAssignment? assignment;

  ActivityData({
    required this.docId,
    required this.activityId,
    required this.title,
    required this.topic,
    required this.description,
    required this.activityDate,
    required this.startTime,
    required this.endTime,
    required this.locationName,
    required this.locationAddress,
    required this.locationLat,
    required this.locationLng,
    required this.createdBy,
    required this.createdAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'activity_id': activityId,
      'title': title,
      'topic': topic,
      'description': description,
      'activity_date': activityDate,
      'start_time': startTime,
      'end_time': endTime,
      'location_name': locationName,
      'location_address': locationAddress,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'created_by': createdBy,
      'created_at': Timestamp.fromDate(createdAt),
      'status': status,
      if (explanationReason != null) 'explanation_reason': explanationReason,
      if (explanationDetails != null) 'explanation_details': explanationDetails,
      if (explanationProofUrl != null) 'explanation_proof_url': explanationProofUrl,
      if (explanationTimestamp != null) 'explanation_timestamp': Timestamp.fromDate(explanationTimestamp!),
      if (explanationManualLocation != null) 'explanation_manual_location': explanationManualLocation,
      if (officerDecision != null) 'officer_decision': officerDecision,
      if (officerDecisionTimestamp != null) 'officer_decision_timestamp': Timestamp.fromDate(officerDecisionTimestamp!),
      if (preacherName != null) 'preacher_name': preacherName,
      if (officerName != null) 'officer_name': officerName,
    };
  }

  factory ActivityData.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final activity = ActivityData(
      docId: doc.id,
      activityId: data['activity_id'] ?? 0,
      title: data['title'] ?? '',
      topic: data['topic'] ?? '',
      description: data['description'] ?? '',
      activityDate: data['activity_date'] ?? '',
      startTime: data['start_time'] ?? '',
      endTime: data['end_time'] ?? '',
      locationName: data['location_name'] ?? '',
      locationAddress: data['location_address'] ?? '',
      locationLat: (data['location_lat'] ?? 0.0).toDouble(),
      locationLng: (data['location_lng'] ?? 0.0).toDouble(),
      createdBy: data['created_by'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? '',
    );
    activity.explanationReason = data['explanation_reason'] as String?;
    activity.explanationDetails = data['explanation_details'] as String?;
    activity.explanationProofUrl = data['explanation_proof_url'] as String?;
    activity.explanationTimestamp = (data['explanation_timestamp'] as Timestamp?)?.toDate();
    activity.explanationManualLocation = data['explanation_manual_location'] as String?;
    activity.officerDecision = data['officer_decision'] as String?;
    activity.officerDecisionTimestamp = (data['officer_decision_timestamp'] as Timestamp?)?.toDate();
    activity.preacherName = data['preacher_name'] as String?;
    activity.officerName = data['officer_name'] as String?;
    return activity;
  }

  static final CollectionReference _activitiesCollection =
      FirebaseFirestore.instance.collection('activities');

  // Create
  static Future<void> addActivity(ActivityData activity) async {
    await FirebaseFirestore.instance.collection('activities').add(activity.toMap());
  }

  // Update
  static Future<void> updateActivity(ActivityData activity) async {
    await _activitiesCollection.doc(activity.docId).update(activity.toMap());
  }

  // Update specific fields only
  static Future<void> updateActivityFields(String docId, Map<String, dynamic> fields) async {
    await _activitiesCollection.doc(docId).update(fields);
  }

  // Delete
  static Future<void> deleteActivity(String docId) async {
    await _activitiesCollection.doc(docId).delete();
  }

  // Stream
  static Stream<List<ActivityData>> getActivitiesStream() {
    return _activitiesCollection.orderBy('activity_date').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => ActivityData.fromDoc(doc)).toList(),
    );
  }

  // Fetch preacher and officer names for this activity
  Future<void> fetchDetails() async {
    try {
      // Get assignment by activity ID
      assignment = await ActivityAssignment.getAssignmentByActivity(activityId);
      
      if (assignment != null) {
        // Fetch preacher name from preachers collection
        final preacherDoc = await FirebaseFirestore.instance
            .collection('preachers')
            .doc(assignment!.preacherId)
            .get();
        
        if (preacherDoc.exists) {
          preacherName = preacherDoc.data()?['fullName'] ?? 'Unknown Preacher';
        }

        // Fetch officer name from officers collection using assigned_by as document ID
        final officerDoc = await FirebaseFirestore.instance
            .collection('officers')
            .doc(assignment!.assignedBy)
            .get();
        
        if (officerDoc.exists) {
          officerName = officerDoc.data()?['fullName'] ?? 'Unknown Officer';
        } else {
          // Fallback: try using the createdBy from activity as document ID
          final officerDoc2 = await FirebaseFirestore.instance
              .collection('officers')
              .doc(createdBy)
              .get();
          
          if (officerDoc2.exists) {
            officerName = officerDoc2.data()?['fullName'] ?? createdBy;
          } else {
            officerName = createdBy; // Use the UID if name not found
          }
        }
      } else {
        officerName = createdBy; // Use the UID if no assignment found
      }
    } catch (e) {
      print('Error fetching activity details: $e');
      preacherName = 'Error loading';
      officerName = createdBy;
    }
  }

  // Fetch details for multiple activities
  static Future<List<ActivityData>> fetchMultipleDetails(List<ActivityData> activities) async {
    final futures = activities.map((activity) => activity.fetchDetails()).toList();
    await Future.wait(futures);
    return activities;
  }
}




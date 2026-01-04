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
  final String status;
  
  // Additional fields for display
  String? preacherName;
  String? officerName;
  ActivityAssignment? assignment;

  // Optional embedded submission fields (if you choose to store submission on the activity doc)
  int? submissionId;
  int? submissionAssignmentId;
  String? submissionPreacherId;
  double? submissionGpsLat;
  double? submissionGpsLng;
  DateTime? submissionGpsTimestamp;
  String? submissionAttendance;
  String? submissionRemarks;
  String? submissionAttachmentUrl;
  DateTime? submissionSubmittedAt;

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
      if (preacherName != null) 'preacher_name': preacherName,
      if (officerName != null) 'officer_name': officerName,
      if (submissionId != null) 'submission_id': submissionId,
      if (submissionAssignmentId != null) 'submission_assignment_id': submissionAssignmentId,
      if (submissionPreacherId != null) 'submission_preacher_id': submissionPreacherId,
      if (submissionGpsLat != null) 'submission_gps_latitude': submissionGpsLat,
      if (submissionGpsLng != null) 'submission_gps_longitude': submissionGpsLng,
      if (submissionGpsTimestamp != null) 'submission_gps_timestamp': Timestamp.fromDate(submissionGpsTimestamp!),
      if (submissionAttendance != null) 'submission_attendance': submissionAttendance,
      if (submissionRemarks != null) 'submission_remarks': submissionRemarks,
      if (submissionAttachmentUrl != null) 'submission_attachment_url': submissionAttachmentUrl,
      if (submissionSubmittedAt != null) 'submission_submitted_at': Timestamp.fromDate(submissionSubmittedAt!),
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
    activity.preacherName = data['preacher_name'] as String?;
    activity.officerName = data['officer_name'] as String?;
    activity.submissionId = data['submission_id'] as int?;
    activity.submissionAssignmentId = data['submission_assignment_id'] as int?;
    activity.submissionPreacherId = data['submission_preacher_id'] as String?;
    final subLat = data['submission_gps_latitude'];
    if (subLat != null) activity.submissionGpsLat = (subLat as num).toDouble();
    final subLng = data['submission_gps_longitude'];
    if (subLng != null) activity.submissionGpsLng = (subLng as num).toDouble();
    activity.submissionGpsTimestamp = (data['submission_gps_timestamp'] as Timestamp?)?.toDate();
    activity.submissionAttendance = data['submission_attendance'] as String?;
    activity.submissionRemarks = data['submission_remarks'] as String?;
    activity.submissionAttachmentUrl = data['submission_attachment_url'] as String?;
    activity.submissionSubmittedAt = (data['submission_submitted_at'] as Timestamp?)?.toDate();
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




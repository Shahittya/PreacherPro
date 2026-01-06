import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityAssignment {
  final String docId;
  final int assignmentId;
  final int activityId;
  final String preacherId;
  final String assignedBy;
  final DateTime assignedAt;
  final String assignmentStatus;

  ActivityAssignment({
    required this.docId,
    required this.assignmentId,
    required this.activityId,
    required this.preacherId,
    required this.assignedBy,
    required this.assignedAt,
    required this.assignmentStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'assignment_id': assignmentId,
      'activity_id': activityId,
      'preacher_id': preacherId,
      'assigned_by': assignedBy,
      'assigned_at': Timestamp.fromDate(assignedAt),
      'assignment_status': assignmentStatus,
    };
  }

  factory ActivityAssignment.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ActivityAssignment(
      docId: doc.id,
      assignmentId: data['assignment_id'] ?? 0,
      activityId: data['activity_id'] ?? 0,
      preacherId: data['preacher_id'] ?? '',
      assignedBy: data['assigned_by'] ?? '',
      assignedAt: (data['assigned_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      assignmentStatus: data['assignment_status'] ?? 'assigned',
    );
  }

  static final CollectionReference _assignmentsCollection =
      FirebaseFirestore.instance.collection('activity_assignments');

  // Create
  static Future<void> createAssignment(ActivityAssignment assignment) async {
    await _assignmentsCollection.add(assignment.toMap());
  }

  // Get assignments by preacher ID
  static Future<List<ActivityAssignment>> getAssignmentsByPreacher(String preacherId) async {
    final snapshot = await _assignmentsCollection
        .where('preacher_id', isEqualTo: preacherId)
        .get();
    return snapshot.docs.map((doc) => ActivityAssignment.fromDoc(doc)).toList();
  }

  // Get assignment by activity ID
  static Future<ActivityAssignment?> getAssignmentByActivity(int activityId) async {
    final snapshot = await _assignmentsCollection
        .where('activity_id', isEqualTo: activityId)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return ActivityAssignment.fromDoc(snapshot.docs.first);
  }

  // Update assignment status
  static Future<void> updateStatus(String docId, String newStatus) async {
    await _assignmentsCollection.doc(docId).update({
      'assignment_status': newStatus,
    });
  }

  // Update preacher assignment
  static Future<void> updatePreacher(String docId, String newPreacherId) async {
    await _assignmentsCollection.doc(docId).update({
      'preacher_id': newPreacherId,
    });
  }

  // Delete assignment
  static Future<void> deleteAssignment(String docId) async {
    await _assignmentsCollection.doc(docId).delete();
  }

  // Delete assignment by activity ID
  static Future<void> deleteAssignmentByActivity(int activityId) async {
    final snapshot = await _assignmentsCollection
        .where('activity_id', isEqualTo: activityId)
        .get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // Stream assignments by preacher
  static Stream<List<ActivityAssignment>> streamAssignmentsByPreacher(String preacherId) {
    return _assignmentsCollection
        .where('preacher_id', isEqualTo: preacherId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActivityAssignment.fromDoc(doc))
            .toList());
  }
}

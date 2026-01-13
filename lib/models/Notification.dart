import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityNotification {
  final String docId;
  final String preacherId;
  final int activityId;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String type; // 'assignment', 'approval', 'rejection', etc.

  ActivityNotification({
    required this.docId,
    required this.preacherId,
    required this.activityId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.type = 'assignment',
  });

  Map<String, dynamic> toMap() {
    return {
      'preacher_id': preacherId,
      'activity_id': activityId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'is_read': isRead,
      'type': type,
    };
  }

  factory ActivityNotification.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ActivityNotification(
      docId: doc.id,
      preacherId: data['preacher_id'] ?? '',
      activityId: data['activity_id'] ?? 0,
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['is_read'] ?? false,
      type: data['type'] ?? 'assignment',
    );
  }

  // Static method to create a notification
  static Future<void> createNotification(ActivityNotification notification) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .add(notification.toMap());
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ActivityData.dart';
import '../models/ActivityAssignment.dart';
import '../models/Notification.dart';

class ActivityController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _autoCheckTimer;

  ActivityController() {
    // Start automatic check for missed check-ins every 5 minutes
    _startAutoCheckTimer();
  }

  void _startAutoCheckTimer() {
    _autoCheckTimer?.cancel();
    _autoCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _runAutoCheckForAllActivities();
    });
  }

  Future<void> _runAutoCheckForAllActivities() async {
    try {
      print('🔄 Running automatic check for missed check-ins...');
      final snap = await _db
          .collection('activities')
          .where('status', isEqualTo: 'assigned')
          .get();

      for (var doc in snap.docs) {
        final activity = ActivityData.fromDoc(doc);
        await _autoMarkCheckInMissedIfNeeded(activity);
      }
      print(
        'Auto-check completed. Checked ${snap.docs.length} assigned activities.',
      );
    } catch (e) {
      print('Auto-check failed: $e');
    }
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  // Helper method to get status priority for sorting
  int _getStatusPriority(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return 1;
      case 'checked_in':
        return 2;
      case 'pending_officer_review':
        return 3;
      case 'pending_report':
        return 4;
      case 'pending_absence_review':
        return 5;
      case 'check_in_missed':
        return 6;
      case 'rejected':
      case 'absent':
        return 7;
      case 'approved':
        return 8;
      case 'cancelled':
        return 9;
      default:
        return 10;
    }
  }

  // Stream ALL activities (for admin dashboard - no filtering by officer)
  Stream<List<ActivityData>> allActivitiesStream() {
    return _db.collection('activities').snapshots().asyncMap((
      activitiesSnap,
    ) async {
      final activities = <ActivityData>[];
      for (var activityDoc in activitiesSnap.docs) {
        final activity = ActivityData.fromDoc(activityDoc);
        await activity.fetchDetails();
        await _autoMarkCheckInMissedIfNeeded(activity);
        activities.add(activity);
      }
      
      // Sort by status priority then by date
      activities.sort((a, b) {
        final aPriority = _getStatusPriority(a.status);
        final bPriority = _getStatusPriority(b.status);
        if (aPriority != bPriority) return aPriority.compareTo(bPriority);
        
        final aDate = _parseDate(a.activityDate);
        final bDate = _parseDate(b.activityDate);
        return aDate.compareTo(bDate);
      });
      
      return activities;
    });
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
    return _db.collection('activities').snapshots().asyncMap((
      activitiesSnap,
    ) async {
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
        print(
          '  Assignment: activity_id=${data['activity_id']}, assigned_by=${data['assigned_by']}',
        );
      }

      final assignedActivityIds = assignmentsSnap.docs
          .map((doc) => doc.data()['activity_id'] as int)
          .toSet();

      print(
        '📋 Found ${assignedActivityIds.length} activities assigned by this officer',
      );
      print('📋 Activity IDs assigned by officer: $assignedActivityIds');

      // Filter activities: created by this officer OR assigned by this officer
      print('🔍 Total activities in database: ${activitiesSnap.docs.length}');

      var activities = activitiesSnap.docs
          .map((d) => ActivityData.fromDoc(d))
          .where((activity) {
            final createdByOfficer = activity.createdBy == userId;
            final assignedByOfficer = assignedActivityIds.contains(
              activity.activityId,
            );

            if (createdByOfficer || assignedByOfficer) {
              print(
                '  ✓ Including activity_id=${activity.activityId}: created_by=${activity.createdBy}, createdByOfficer=$createdByOfficer, assignedByOfficer=$assignedByOfficer',
              );
            }

            return createdByOfficer || assignedByOfficer;
          })
          .toList();

      print(
        '✅ Filtered to ${activities.length} activities (created by OR assigned by officer)',
      );

      // Fetch assignments and details for each activity and auto-mark check_in_missed when window passed
      for (var activity in activities) {
        await activity.fetchDetails();
        await _autoMarkCheckInMissedIfNeeded(activity);
      }

      // Sort by status priority, then by activity_date descending (newest first within same status)
      activities.sort((a, b) {
        final statusCompare = _getStatusPriority(
          a.status,
        ).compareTo(_getStatusPriority(b.status));
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

    return _db.collection('activities').snapshots().asyncMap((
      activitiesSnap,
    ) async {
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
          .where(
            (activity) =>
                assignedActivityIds.contains(activity.activityId) ||
                activity.createdBy == preacherUid,
          )
          .toList();

      for (var activity in activities) {
        await activity.fetchDetails();
        await _autoMarkCheckInMissedIfNeeded(activity);
      }

      activities.sort((a, b) {
        final statusCompare = _getStatusPriority(
          a.status,
        ).compareTo(_getStatusPriority(b.status));
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
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      } else {
        final parts = dateStr.split('-');
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (_) {
      return DateTime.now();
    }
  }

  // Build DateTime from date and time strings (handles AM/PM and 24h)
  DateTime? _buildDateTime(String dateStr, String timeStr) {
    try {
      final date = _parseDate(dateStr);
      var hour = 0;
      var minute = 0;
      var t = timeStr.trim();
      final hasPeriod = t.contains('AM') || t.contains('PM');
      if (hasPeriod) {
        final isAM = t.contains('AM');
        t = t.replaceAll('AM', '').replaceAll('PM', '').trim();
        final parts = t.split(':');
        if (parts.length >= 2) {
          hour = int.parse(parts[0]);
          minute = int.parse(parts[1]);
          if (!isAM && hour != 12) hour += 12;
          if (isAM && hour == 12) hour = 0;
        }
      } else {
        final parts = t.split(':');
        if (parts.length >= 2) {
          hour = int.parse(parts[0]);
          minute = int.parse(parts[1]);
        }
      }
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  // Auto-mark assigned activities as check_in_missed if past the check-in window (1h after end)
  Future<void> _autoMarkCheckInMissedIfNeeded(ActivityData activity) async {
    try {
      if (activity.status.toLowerCase() != 'assigned') return;
      final startDt = _buildDateTime(activity.activityDate, activity.startTime);
      final endDt = _buildDateTime(activity.activityDate, activity.endTime);
      if (startDt == null || endDt == null) return;
      final windowClose = endDt.add(const Duration(hours: 1));
      if (DateTime.now().isAfter(windowClose)) {
        await _db.collection('activities').doc(activity.docId).update({
          'status': 'check_in_missed',
        });
        if (activity.assignment?.docId.isNotEmpty == true) {
          await ActivityAssignment.updateStatus(
            activity.assignment!.docId,
            'check_in_missed',
          );
          // Notify preacher about missed check-in
          await ActivityNotification.createNotification(
            ActivityNotification(
              docId: '',
              preacherId: activity.assignment!.preacherId,
              activityId: activity.activityId,
              message:
                  'Check-in missed for "${activity.title}". Please submit an explanation or mark as absent.',
              timestamp: DateTime.now(),
              type: 'check_in_missed',
            ),
          );
        }
        activity.status = 'check_in_missed';
      }
    } catch (e) {
      print(
        'Auto check_in_missed failed for activity ${activity.activityId}: $e',
      );
    }
  }

  Future<void> submitExplanation({
    required ActivityData activity,
    required String reason,
    String details = '',
    String proofUrl = '',
    String? manualLocation,
  }) async {
    final now = DateTime.now();

    // Late Check-In with proof goes to "pending_officer_review"
    // Absence explanations go to "pending_absence_review"
    final isLateCheckIn = reason == 'Late Check-In' && proofUrl.isNotEmpty;
    final newStatus = isLateCheckIn
        ? 'pending_officer_review'
        : 'pending_absence_review';

    await _db.collection('activities').doc(activity.docId).update({
      'status': newStatus,
      'explanation_reason': reason,
      'explanation_details': details,
      'explanation_proof_url': proofUrl,
      'explanation_manual_location': manualLocation,
      'explanation_timestamp': Timestamp.fromDate(now),
    });

    // Update assignment status as well
    if (activity.assignment?.docId.isNotEmpty == true) {
      await ActivityAssignment.updateStatus(
        activity.assignment!.docId,
        newStatus,
      );
    }

    activity.status = newStatus;
    activity.explanationReason = reason;
    activity.explanationDetails = details;
    activity.explanationProofUrl = proofUrl;
    activity.explanationManualLocation = manualLocation;
    activity.explanationTimestamp = now;

    // Notify preacher that explanation was submitted
    if (activity.assignment?.preacherId != null) {
      final message = isLateCheckIn
          ? 'Your late check-in for "${activity.title}" with photo proof has been submitted. Awaiting officer review.'
          : 'Your explanation for "${activity.title}" has been submitted and is awaiting officer review.';

      await ActivityNotification.createNotification(
        ActivityNotification(
          docId: '',
          preacherId: activity.assignment!.preacherId,
          officerId: activity.createdBy.isNotEmpty ? activity.createdBy : null,
          activityId: activity.activityId,
          message: message,
          timestamp: now,
          type: isLateCheckIn
              ? 'late_check_in_submitted'
              : 'explanation_submitted',
        ),
      );
    }

    // Notify officer that explanation was submitted (for review)
    if (activity.assignment?.preacherId != null &&
        activity.createdBy.isNotEmpty) {
      // Fetch preacher name for better notification
      String preacherName = 'Preacher';
      try {
        final preacherDoc = await _db
            .collection('preachers')
            .doc(activity.assignment!.preacherId)
            .get();
        if (preacherDoc.exists) {
          preacherName = preacherDoc.data()?['fullName'] ?? 'Preacher';
        }
      } catch (e) {
        print('Error fetching preacher name: $e');
      }

      final explanationTypeLabel = isLateCheckIn
          ? 'Late Check-In'
          : 'Absence Explanation';

      await ActivityNotification.createNotification(
        ActivityNotification(
          docId: '',
          preacherId: activity.assignment!.preacherId,
          officerId: activity.createdBy,
          activityId: activity.activityId,
          message:
              '$preacherName submitted $explanationTypeLabel for "${activity.title}"\n\nReason: $reason\n\nAwaiting your review.',
          timestamp: now,
          type: 'explanation_pending_review',
        ),
      );
    }
    notifyListeners();
  }

  Future<void> preacherMarkAbsent(
    ActivityData activity, {
    String reason = 'Not able to attend',
  }) async {
    final now = DateTime.now();
    await _db.collection('activities').doc(activity.docId).update({
      'status': 'absent',
      'explanation_reason': reason,
      'explanation_details': reason,
      'explanation_timestamp': Timestamp.fromDate(now),
    });
    if (activity.assignment?.docId.isNotEmpty == true) {
      await ActivityAssignment.updateStatus(
        activity.assignment!.docId,
        'absent',
      );
    }
    activity.status = 'absent';
    activity.explanationReason = reason;
    activity.explanationDetails = reason;
    activity.explanationTimestamp = now;
    notifyListeners();
  }

  // Officer approves explanation - if late check-in go to pending_report, otherwise mark as checked_in
  Future<void> officerApproveExplanation(ActivityData activity) async {
    final now = DateTime.now();
    final isLateCheckIn =
        activity.explanationReason?.toLowerCase().contains('late') ?? false;
    final newStatus = isLateCheckIn ? 'pending_report' : 'checked_in';
    final currentOfficerId = _auth.currentUser?.uid;

    await _db.collection('activities').doc(activity.docId).update({
      'status': newStatus,
      'officer_decision': 'approved_attended',
      'officer_decision_timestamp': Timestamp.fromDate(now),
    });
    if (activity.assignment?.docId.isNotEmpty == true) {
      await ActivityAssignment.updateStatus(
        activity.assignment!.docId,
        newStatus,
      );
    }
    activity.status = newStatus;
    activity.officerDecision = 'approved_attended';
    activity.officerDecisionTimestamp = now;

    // Notify preacher about approval
    if (activity.assignment?.preacherId != null) {
      final message = isLateCheckIn
          ? 'Your late check-in for "${activity.title}" has been approved. Please submit your attendance report.'
          : 'Your attendance for "${activity.title}" has been approved by the officer.';

      await ActivityNotification.createNotification(
        ActivityNotification(
          docId: '',
          preacherId: activity.assignment!.preacherId,
          officerId: currentOfficerId,
          activityId: activity.activityId,
          message: message,
          timestamp: now,
          type: 'approval',
        ),
      );
    }
    notifyListeners();
  }

  // Officer marks attended directly (for forgot GPS scenarios)
  Future<void> officerMarkAttended(ActivityData activity) async {
    final now = DateTime.now();
    final currentOfficerId = _auth.currentUser?.uid;

    await _db.collection('activities').doc(activity.docId).update({
      'status': 'pending_report',
      'officer_decision': 'manually_marked_attended',
      'officer_decision_timestamp': Timestamp.fromDate(now),
    });
    if (activity.assignment?.docId.isNotEmpty == true) {
      await ActivityAssignment.updateStatus(
        activity.assignment!.docId,
        'pending_report',
      );
    }
    activity.status = 'pending_report';
    activity.officerDecision = 'manually_marked_attended';
    activity.officerDecisionTimestamp = now;

    // Notify preacher
    if (activity.assignment?.preacherId != null) {
      await ActivityNotification.createNotification(
        ActivityNotification(
          docId: '',
          preacherId: activity.assignment!.preacherId,
          officerId: currentOfficerId,
          activityId: activity.activityId,
          message:
              'Officer marked you as attended for "${activity.title}". Please submit your report.',
          timestamp: now,
          type: 'manually_attended',
        ),
      );
    }
    notifyListeners();
  }

  // Officer approves late check-in with photo proof - preacher must submit report
  Future<void> officerApproveLateCheckIn(ActivityData activity) async {
    final now = DateTime.now();
    final currentOfficerId = _auth.currentUser?.uid;

    await _db.collection('activities').doc(activity.docId).update({
      'status': 'pending_report',
      'officer_decision': 'approved_late_check_in',
      'officer_decision_timestamp': Timestamp.fromDate(now),
    });
    if (activity.assignment?.docId.isNotEmpty == true) {
      await ActivityAssignment.updateStatus(
        activity.assignment!.docId,
        'pending_report',
      );
    }
    activity.status = 'pending_report';
    activity.officerDecision = 'approved_late_check_in';
    activity.officerDecisionTimestamp = now;

    // Notify preacher to submit report
    if (activity.assignment?.preacherId != null) {
      await ActivityNotification.createNotification(
        ActivityNotification(
          docId: '',
          preacherId: activity.assignment!.preacherId,
          officerId: currentOfficerId,
          activityId: activity.activityId,
          message:
              'Your late check-in for "${activity.title}" has been verified. Please now submit your attendance report with topic confirmation, photos, and remarks.',
          timestamp: now,
          type: 'late_check_in_approved',
        ),
      );
    }
    notifyListeners();
  }

  // Officer rejects late check-in with photo proof - marks as absent
  Future<void> officerRejectLateCheckIn(ActivityData activity) async {
    final now = DateTime.now();
    final currentOfficerId = _auth.currentUser?.uid;

    await _db.collection('activities').doc(activity.docId).update({
      'status': 'absent',
      'officer_decision': 'rejected_late_check_in',
      'officer_decision_timestamp': Timestamp.fromDate(now),
    });
    if (activity.assignment?.docId.isNotEmpty == true) {
      await ActivityAssignment.updateStatus(
        activity.assignment!.docId,
        'absent',
      );
    }
    activity.status = 'absent';
    activity.officerDecision = 'rejected_late_check_in';
    activity.officerDecisionTimestamp = now;

    // Notify preacher - flow ends
    if (activity.assignment?.preacherId != null) {
      await ActivityNotification.createNotification(
        ActivityNotification(
          docId: '',
          preacherId: activity.assignment!.preacherId,
          officerId: currentOfficerId,
          activityId: activity.activityId,
          message:
              'Your late check-in for "${activity.title}" could not be verified and has been marked as absent. No report submission required.',
          timestamp: now,
          type: 'late_check_in_rejected',
        ),
      );
    }
    notifyListeners();
  }

  // Officer reschedules an activity (date/time/location) and notifies preacher
  Future<void> officerRescheduleActivity(
    ActivityData activity, {
    required String newDate,
    required String newStartTime,
    String? newEndTime,
    String? newLocationName,
    String? newLocationAddress,
    double? newLat,
    double? newLng,
    required String reason,
  }) async {
    final now = DateTime.now();

    final updates = <String, dynamic>{
      'activity_date': newDate,
      'start_time': newStartTime,
      'end_time': newEndTime ?? activity.endTime,
      'location_name': newLocationName ?? activity.locationName,
      'location_address': newLocationAddress ?? activity.locationAddress,
      'location_lat': newLat ?? activity.locationLat,
      'location_lng': newLng ?? activity.locationLng,
      'status': 'assigned',
      'officer_decision': 'rescheduled',
      'officer_decision_timestamp': Timestamp.fromDate(now),
      // Clear explanation fields from previous missed/absence flows
      'explanation_reason': null,
      'explanation_details': null,
      'explanation_proof_url': null,
      'explanation_manual_location': null,
      'explanation_timestamp': null,
    };

    await _db.collection('activities').doc(activity.docId).update(updates);

    // Keep assignment in sync
    if (activity.assignment?.docId.isNotEmpty == true) {
      await ActivityAssignment.updateStatus(
        activity.assignment!.docId,
        'assigned',
      );
    }

    // Update in-memory object so UI reflects immediately
    activity.status = 'assigned';
    activity.officerDecision = 'rescheduled';
    activity.officerDecisionTimestamp = now;
    activity.explanationReason = null;
    activity.explanationDetails = null;
    activity.explanationProofUrl = null;
    activity.explanationManualLocation = null;
    activity.explanationTimestamp = null;

    // Notify preacher of reschedule
    if (activity.assignment?.preacherId != null) {
      try {
        final message =
            'Schedule updated for "${activity.title}" to $newDate at $newStartTime. Reason: $reason';
        await ActivityNotification.createNotification(
          ActivityNotification(
            docId: '',
            preacherId: activity.assignment!.preacherId,
            officerId: _auth.currentUser?.uid,
            activityId: activity.activityId,
            message: message,
            timestamp: now,
            isRead: false,
            type: 'rescheduled',
          ),
        );
      } catch (e) {
        debugPrint('Warning: failed to send reschedule notification: $e');
      }
    }

    notifyListeners();
  }

  // Officer accepts absence explanation - marks as absent with acceptance message
  Future<void> officerAcceptAbsence(ActivityData activity) async {
    final now = DateTime.now();
    final currentOfficerId = _auth.currentUser?.uid;

    await _db.collection('activities').doc(activity.docId).update({
      'status': 'absent',
      'officer_decision': 'accept_absent',
      'officer_decision_timestamp': Timestamp.fromDate(now),
    });
    if (activity.assignment?.docId.isNotEmpty == true) {
      await ActivityAssignment.updateStatus(
        activity.assignment!.docId,
        'absent',
      );
    }
    activity.status = 'absent';
    activity.officerDecision = 'accept_absent';
    activity.officerDecisionTimestamp = now;

    // Notify preacher about acceptance
    if (activity.assignment?.preacherId != null) {
      await ActivityNotification.createNotification(
        ActivityNotification(
          docId: '',
          preacherId: activity.assignment!.preacherId,
          officerId: currentOfficerId,
          activityId: activity.activityId,
          message:
              'Your absence explanation for "${activity.title}" was accepted. Status: Absent.',
          timestamp: now,
          type: 'absence_accepted',
        ),
      );
    }
    notifyListeners();
  }

  Future<void> officerRejectExplanation(ActivityData activity) async {
    final now = DateTime.now();
    final currentOfficerId = _auth.currentUser?.uid;

    await _db.collection('activities').doc(activity.docId).update({
      'status': 'absent',
      'officer_decision': 'reject_absent',
      'officer_decision_timestamp': Timestamp.fromDate(now),
    });
    if (activity.assignment?.docId.isNotEmpty == true) {
      await ActivityAssignment.updateStatus(
        activity.assignment!.docId,
        'absent',
      );
    }
    activity.status = 'absent';
    activity.officerDecision = 'reject_absent';
    activity.officerDecisionTimestamp = now;

    // Notify preacher about rejection
    if (activity.assignment?.preacherId != null) {
      await ActivityNotification.createNotification(
        ActivityNotification(
          docId: '',
          preacherId: activity.assignment!.preacherId,
          officerId: currentOfficerId,
          activityId: activity.activityId,
          message:
              'Your explanation for "${activity.title}" was not accepted. Status: Absent.',
          timestamp: now,
          type: 'rejection',
        ),
      );
    }
    notifyListeners();
  }

  Future<void> officerCancelEvent(ActivityData activity) async {
    final now = DateTime.now();
    final currentOfficerId = _auth.currentUser?.uid;

    await _db.collection('activities').doc(activity.docId).update({
      'status': 'cancelled',
      'officer_decision': 'cancelled',
      'officer_decision_timestamp': Timestamp.fromDate(now),
    });
    if (activity.assignment?.docId.isNotEmpty == true) {
      await ActivityAssignment.updateStatus(
        activity.assignment!.docId,
        'cancelled',
      );
    }
    activity.status = 'cancelled';
    activity.officerDecision = 'cancelled';
    activity.officerDecisionTimestamp = now;

    // Notify preacher about cancellation
    if (activity.assignment?.preacherId != null) {
      await ActivityNotification.createNotification(
        ActivityNotification(
          docId: '',
          preacherId: activity.assignment!.preacherId,
          officerId: currentOfficerId,
          activityId: activity.activityId,
          message:
              'Activity "${activity.title}" has been cancelled by the officer.',
          timestamp: now,
          type: 'cancellation',
        ),
      );
    }
    notifyListeners();
  }

  // optional: one-time fetch
  Future<List<ActivityData>> fetchActivitiesOnce() async {
    final snap = await _db
        .collection('activities')
        .orderBy('activity_date')
        .get();
    return snap.docs.map((d) => ActivityData.fromDoc(d)).toList();
  }

  Future<void> addActivity(ActivityData activity) async {
    await ActivityData.addActivity(activity);
    notifyListeners();
  }

  // Submit activity report (preacher) and notify assigned officer
  Future<void> submitActivityReport({
    required ActivityData activity,
    required String sessionOutcome,
    required String attendanceRange,
    required String remarks,
    String? topicDelivered,
    String? actualStart,
    String? actualEnd,
    String? incidentNote,
    String? organizerFeedback,
    String? proofPhotoBase64,
    Map<String, dynamic>? gpsInfo,
  }) async {
    final now = DateTime.now();

    // Ensure assignment is loaded
    ActivityAssignment? assignment = activity.assignment;
    assignment ??= await ActivityAssignment.getAssignmentByActivity(activity.activityId);

    final submissionId = now.millisecondsSinceEpoch;
    final Map<String, dynamic> submission = {
      'submission_id': submissionId,
      'activity_id': activity.activityId,
      'assignment_id': assignment?.assignmentId,
      'preacher_id': assignment?.preacherId,
      'session_outcome': sessionOutcome,
      'attendance_range': attendanceRange,
      'remarks': remarks,
      'topic_delivered': topicDelivered ?? activity.topic,
      'actual_time_start': actualStart,
      'actual_time_end': actualEnd,
      'incident_note': incidentNote,
      'organizer_feedback': organizerFeedback,
      'proof_photo_base64': proofPhotoBase64,
      'submitted_at': Timestamp.fromDate(now),
      if (gpsInfo != null) 'gps_latitude': gpsInfo['lat'],
      if (gpsInfo != null) 'gps_longitude': gpsInfo['lng'],
      if (gpsInfo != null) 'gps_accuracy': gpsInfo['accuracy'],
      if (gpsInfo != null) 'gps_distance_to_target': gpsInfo['distance_to_target'],
      if (gpsInfo != null) 'gps_timestamp': gpsInfo['timestamp'],
    };

    // Remove null entries for cleanliness
    submission.removeWhere((key, value) => value == null);

    // Store submission as a separate document in activity_submissions collection ONLY
    await _db.collection('activity_submissions').add(submission);

    // Update activity status to 'pending_report_review' (awaiting officer review)
    // DO NOT store submission_* fields in activity document
    await _db.collection('activities').doc(activity.docId).update({
      'status': 'pending_report_review',
    });

    // Update activity_assignment status to 'pending_report_review' as well
    if (assignment != null) {
      await _db.collection('activity_assignments').doc(assignment.docId).update({
        'assignment_status': 'pending_report_review',
      });
    }

    // Notify assigned officer (fallback to createdBy if assignment missing)
    final officerId = assignment?.assignedBy.isNotEmpty == true
        ? assignment!.assignedBy
        : (activity.createdBy.isNotEmpty ? activity.createdBy : null);

    if (officerId != null) {
      await ActivityNotification.createNotification(
        ActivityNotification(
          docId: '',
          preacherId: assignment?.preacherId ?? '',
          officerId: officerId,
          activityId: activity.activityId,
          message:
              'Report submitted for "${activity.title}". Outcome: $sessionOutcome. Attendance: $attendanceRange.',
          timestamp: now,
          type: 'report_submitted',
        ),
      );
    }

    notifyListeners();
  }

  // Mark activity and its assignment (if any) as checked_in
  Future<void> markCheckedIn(ActivityData activity) async {
    // Update activity status
    await _db.collection('activities').doc(activity.docId).update({
      'status': 'checked_in',
    });

    // Update related assignment status if exists
    ActivityAssignment? assignment = activity.assignment;
    assignment ??= await ActivityAssignment.getAssignmentByActivity(
      activity.activityId,
    );
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


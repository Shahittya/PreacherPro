import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/ActivityData.dart';
import '../../../models/ActivityAssignment.dart';
import '../../../models/Notification.dart';

class ReviewReportScreen extends StatefulWidget {
  final ActivityData activity;
  const ReviewReportScreen({super.key, required this.activity});

  @override
  State<ReviewReportScreen> createState() => _ReviewReportScreenState();
}

class _ReviewReportScreenState extends State<ReviewReportScreen> {
  bool _loading = true;
  bool _submitting = false;
  bool _showRejectionInput = false;
  Map<String, dynamic>? _submissionData;
  String? _submissionDocId;
  final _rejectionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSubmission();
  }

  @override
  void dispose() {
    _rejectionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSubmission() async {
    setState(() => _loading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('activity_submissions')
          .where('activity_id', isEqualTo: widget.activity.activityId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        setState(() {
          _submissionDocId = doc.id;
          _submissionData = doc.data();
          _loading = false;
        });
      } else {
        setState(() {
          _submissionData = null;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load submission: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.amber.shade300,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Review Report',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
        ),
        
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _submissionData == null
              ? const Center(child: Text('No submission found'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildContent(),
                      ),
                      _buildActionButtons(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.activity.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                widget.activity.activityDate,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                '${widget.activity.startTime} - ${widget.activity.endTime}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.amber.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.activity.locationName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final data = _submissionData!;
    final actualStart = (data['actual_time_start'] ?? data['actual_start_time'] ?? '').toString();
    final actualEnd = (data['actual_time_end'] ?? data['actual_end_time'] ?? '').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Preacher Submission Details'),
        const SizedBox(height: 12),
        _infoCard('Session Outcome', data['session_outcome'] ?? 'N/A'),
        _infoCard('Attendance Range', data['attendance_range'] ?? 'N/A'),
        _infoCard('Topic Delivered', data['topic_delivered'] ?? widget.activity.topic),
        _infoCard("Preacher's Remarks", data['remarks']?.toString().isEmpty ?? true ? 'N/A' : data['remarks'].toString()),
        Row(
          children: [
            Expanded(
              child: _infoCard('Start Time', actualStart.isEmpty ? widget.activity.startTime : actualStart, compact: true),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _infoCard('End Time', actualEnd.isEmpty ? widget.activity.endTime : actualEnd, compact: true),
            ),
          ],
        ),
        if (data['incident_note']?.toString().isNotEmpty ?? false)
          _infoCard('Incident Notes', data['incident_note'].toString()),
        if (data['organizer_feedback']?.toString().isNotEmpty ?? false)
          _infoCard('Feedback & Suggestions', data['organizer_feedback'].toString()),
        if (data['proof_photo_base64']?.toString().isNotEmpty ?? false) ...[
          const SizedBox(height: 12),
          _sectionTitle('Photo Proof'),
          const SizedBox(height: 8),
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.grey.shade200,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(
                base64Decode(data['proof_photo_base64']),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey.shade400),
                ),
              ),
            ),
          ),
        ],
        if (_showRejectionInput) ...[
          const SizedBox(height: 20),
          _sectionTitle('Rejection Reason'),
          const SizedBox(height: 8),
          TextField(
            controller: _rejectionCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter reason for rejecting this report...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_showRejectionInput) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : () => _handleDecision(approve: false),
                icon: const Icon(Icons.check),
                label: _submitting
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirm Rejection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _submitting ? null : () => setState(() => _showRejectionInput = false),
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : () => setState(() => _showRejectionInput = true),
              icon: const Icon(Icons.close),
              label: const Text('Reject Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : () => _handleDecision(approve: true),
              icon: const Icon(Icons.check_circle),
              label: _submitting
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Approve Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87),
    );
  }

  Widget _infoCard(String label, String value, {bool compact = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            offset: const Offset(0, 1),
            color: Colors.black.withOpacity(0.03),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: compact ? 12 : 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
          ),
          if (!compact) const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: compact ? 13 : 14, fontWeight: FontWeight.w700, color: Colors.black87),
            maxLines: compact ? 1 : 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _handleDecision({required bool approve}) async {
    if (_submissionDocId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission not found')),
      );
      return;
    }
    if (!approve && _rejectionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a rejection reason')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      // Update submission
      final submissionRef = FirebaseFirestore.instance
          .collection('activity_submissions')
          .doc(_submissionDocId);

      final submissionUpdate = <String, dynamic>{
        'submission_status': approve ? 'approved' : 'rejected',
        'reviewed_at': FieldValue.serverTimestamp(),
        if (!approve) 'rejection_reason': _rejectionCtrl.text.trim(),
      };
      await submissionRef.update(submissionUpdate);

      // Update activity
      final activityUpdate = <String, dynamic>{
        'status': approve ? 'approved' : 'rejected',
        'officer_decision': approve ? 'approved_report' : 'rejected_report',
        'officer_decision_timestamp': FieldValue.serverTimestamp(),
        if (!approve) 'rejection_reason': _rejectionCtrl.text.trim(),
      };
      await ActivityData.updateActivityFields(widget.activity.docId, activityUpdate);

      // Update assignment if exists
      if (widget.activity.assignment != null) {
        await ActivityAssignment.updateStatus(
          widget.activity.assignment!.docId,
          approve ? 'approved' : 'rejected',
        );
      }

      // Notify preacher
      final assignment = widget.activity.assignment ?? 
          await ActivityAssignment.getAssignmentByActivity(widget.activity.activityId);
      
      if (assignment != null) {
        final notificationMsg = approve
            ? 'Your activity report for "${widget.activity.title}" has been approved!'
            : 'Your activity report for "${widget.activity.title}" was rejected.\nReason: ${_rejectionCtrl.text.trim()}';

        await ActivityNotification.createNotification(
          ActivityNotification(
            docId: '',
            preacherId: assignment.preacherId,
            activityId: widget.activity.activityId,
            message: notificationMsg,
            timestamp: DateTime.now(),
            type: approve ? 'report_approved' : 'report_rejected',
          ),
        );
      }

      if (!mounted) return;

      if (approve) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report rejected successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.green, size: 48),
              ),
              const SizedBox(height: 18),
              const Text(
                'Report Approved',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 10),
              const Text(
                'Activity has been successfully approved!\nPreacher has been notified.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
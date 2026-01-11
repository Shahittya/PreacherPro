import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../../../models/ActivityData.dart';

class ViewReportAdminScreen extends StatefulWidget {
  final ActivityData activity;
  const ViewReportAdminScreen({super.key, required this.activity});

  @override
  State<ViewReportAdminScreen> createState() => _ViewReportAdminScreenState();
}

class _ViewReportAdminScreenState extends State<ViewReportAdminScreen> {
  bool _loading = true;
  Map<String, dynamic>? _submissionData;

  @override
  void initState() {
    super.initState();
    _loadSubmission();
  }

  Future<void> _loadSubmission() async {
    setState(() {
      _loading = true;
    });
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('activity_submissions')
          .where('activity_id', isEqualTo: widget.activity.activityId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _submissionData = snapshot.docs.first.data();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
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
    final statusLower = widget.activity.status.toLowerCase();
    final isAbsent = statusLower == 'absent';
    final hasSubmission = _submissionData != null;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.amber.shade300,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isAbsent ? 'Absence Details' : 'Activity Report',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: isAbsent
                        ? _buildAbsenceContent()
                        : hasSubmission
                            ? _buildSubmissionContent()
                            : _buildNoSubmissionContent(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade400, Colors.amber.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.activity.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.amber.shade800),
                    const SizedBox(width: 6),
                    Text(
                      widget.activity.activityDate,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.amber.shade800),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.activity.startTime} - ${widget.activity.endTime}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, size: 18, color: Colors.red.shade600),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.activity.locationName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          if (widget.activity.preacherName != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, size: 18, color: Colors.blue.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.activity.preacherName!,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAbsenceContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Absence Information', icon: Icons.cancel, color: Colors.red),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.red.shade300, width: 2),
            boxShadow: [
              BoxShadow(
                blurRadius: 8,
                offset: const Offset(0, 2),
                color: Colors.red.withOpacity(0.1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Marked as Absent',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              if (widget.activity.explanationReason?.isNotEmpty ?? false) ...[
                const SizedBox(height: 16),
                Text(
                  'Reason',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.activity.explanationReason!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade900,
                    height: 1.5,
                  ),
                ),
              ],
              if (widget.activity.explanationDetails?.isNotEmpty ?? false) ...[
                const SizedBox(height: 16),
                Text(
                  'Details',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.activity.explanationDetails!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade900,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoSubmissionContent() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No submission found',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Report has not been submitted yet',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionContent() {
    final data = _submissionData!;
    final actualStart = (data['actual_time_start'] ?? data['actual_start_time'] ?? '').toString();
    final actualEnd = (data['actual_time_end'] ?? data['actual_end_time'] ?? '').toString();
    final submissionStatus = data['submission_status'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Badge
        if (submissionStatus.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: submissionStatus == 'approved'
                  ? Colors.green.shade50
                  : submissionStatus == 'rejected'
                      ? Colors.red.shade50
                      : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: submissionStatus == 'approved'
                    ? Colors.green.shade300
                    : submissionStatus == 'rejected'
                        ? Colors.red.shade300
                        : Colors.orange.shade300,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  submissionStatus == 'approved'
                      ? Icons.check_circle
                      : submissionStatus == 'rejected'
                          ? Icons.cancel
                          : Icons.pending,
                  color: submissionStatus == 'approved'
                      ? Colors.green.shade700
                      : submissionStatus == 'rejected'
                          ? Colors.red.shade700
                          : Colors.orange.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  submissionStatus == 'approved'
                      ? 'Report Approved'
                      : submissionStatus == 'rejected'
                          ? 'Report Rejected'
                          : 'Pending Review',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: submissionStatus == 'approved'
                        ? Colors.green.shade700
                        : submissionStatus == 'rejected'
                            ? Colors.red.shade700
                            : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Rejection Reason
        if (submissionStatus == 'rejected' && (data['rejection_reason']?.isNotEmpty ?? false)) ...[
          _buildRejectionCard('Rejection Reason', data['rejection_reason']),
        ],

        _sectionTitle('Submission Details', icon: Icons.description),
        const SizedBox(height: 16),
        _infoCard('Session Outcome', data['session_outcome'] ?? 'N/A', icon: Icons.how_to_vote),
        _infoCard('Attendance Range', data['attendance_range'] ?? 'N/A', icon: Icons.people),
        _infoCard('Topic Delivered', data['topic_delivered'] ?? widget.activity.topic, icon: Icons.topic),
        _infoCard("Preacher's Remarks", data['remarks']?.toString().isEmpty ?? true ? 'N/A' : data['remarks'].toString(), icon: Icons.notes),
        Row(
          children: [
            Expanded(
              child: _infoCard('Start Time', actualStart.isEmpty ? widget.activity.startTime : actualStart, compact: true, icon: Icons.play_circle_outline),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _infoCard('End Time', actualEnd.isEmpty ? widget.activity.endTime : actualEnd, compact: true, icon: Icons.stop_circle_outlined),
            ),
          ],
        ),
        if (data['incident_note']?.toString().isNotEmpty ?? false)
          _infoCard('Incident Notes', data['incident_note'].toString(), icon: Icons.warning_amber, isWarning: true),
        if (data['organizer_feedback']?.toString().isNotEmpty ?? false)
          _infoCard('Feedback & Suggestions', data['organizer_feedback'].toString(), icon: Icons.feedback),
        if (data['proof_photo_base64']?.toString().isNotEmpty ?? false) ...[
          const SizedBox(height: 20),
          _sectionTitle('Photo Proof', icon: Icons.photo_camera),
          const SizedBox(height: 12),
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.grey.shade300, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(
                base64Decode(data['proof_photo_base64']),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('Failed to load image', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionTitle(String title, {IconData? icon, Color? color}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: color ?? Colors.amber.shade700),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color ?? Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _infoCard(String label, String value, {bool compact = false, IconData? icon, bool isWarning = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: isWarning ? Colors.orange.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWarning ? Colors.orange.shade200 : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 2),
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isWarning 
                    ? Colors.orange.shade100 
                    : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: compact ? 16 : 20,
                color: isWarning 
                    ? Colors.orange.shade700 
                    : Colors.amber.shade700,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: compact ? 4 : 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: compact ? 14 : 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  maxLines: compact ? 1 : 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionCard(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 2),
            color: Colors.red.withOpacity(0.1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade900,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

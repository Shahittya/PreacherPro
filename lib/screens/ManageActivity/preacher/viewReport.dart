import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../../../models/ActivityData.dart';
import 'editSubmission.dart';

class ViewReportScreen extends StatefulWidget {
  final ActivityData activity;
  const ViewReportScreen({super.key, required this.activity});

  @override
  State<ViewReportScreen> createState() => _ViewReportScreenState();
}

class _ViewReportScreenState extends State<ViewReportScreen> {
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Expanded(
              child: Text(
                "View Activity Report",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, size: 24, color: Colors.black54),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _submissionData == null
              ? const Center(child: Text('No submission found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Builder(
                    builder: (_) {
                      final data = _submissionData!;
                      final actualStart = (data['actual_time_start'] ?? data['actual_start_time'] ?? '').toString();
                      final actualEnd = (data['actual_time_end'] ?? data['actual_end_time'] ?? '').toString();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoCard('Session Outcome', data['session_outcome'] ?? 'N/A'),
                          _buildInfoCard('Attendance Range', data['attendance_range'] ?? 'N/A'),
                          _buildInfoCard('Topic Delivered', data['topic_delivered'] ?? widget.activity.topic),
                          _buildInfoCard(
                            'Remarks',
                            data['remarks']?.isEmpty ?? true
                                ? 'No remarks provided'
                                : data['remarks'],
                          ),

                          // Time Range
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  'Start Time',
                                  actualStart.isEmpty ? widget.activity.startTime : actualStart,
                                  compact: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildInfoCard(
                                  'End Time',
                                  actualEnd.isEmpty ? widget.activity.endTime : actualEnd,
                                  compact: true,
                                ),
                              ),
                            ],
                          ),

                          // Rejection Reason (if rejected)
                          if (data['submission_status'] == 'rejected' && (data['rejection_reason']?.isNotEmpty ?? false))
                            _buildRejectionCard('Rejection Reason', data['rejection_reason']),

                          // Incident Note
                          if (data['incident_note']?.isNotEmpty ?? false)
                            _buildInfoCard('Incident Notes', data['incident_note']),

                          // Organizer Feedback
                          if (data['organizer_feedback']?.isNotEmpty ?? false)
                            _buildInfoCard('Feedback & Suggestions', data['organizer_feedback']),

                          // Photo Proof
                          if (data['proof_photo_base64']?.isNotEmpty ?? false) ...[
                            const Text(
                              "Photo Proof",
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              height: 250,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300, width: 2),
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.grey[100],
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.memory(
                                  base64Decode(data['proof_photo_base64']),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.broken_image_outlined, size: 56, color: Colors.grey.shade400),
                                          const SizedBox(height: 8),
                                          Text('Failed to load image', style: TextStyle(color: Colors.grey.shade600)),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                          ],

                          // GPS Info Badge
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.location_on, color: Colors.green, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  "GPS Location Verified",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Edit Submission Button (only for pending_report_review)
                          if (widget.activity.status.toLowerCase() == 'pending_report_review')
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EditSubmissionScreen(
                                          activity: widget.activity,
                                          submissionData: data,
                                        ),
                                      ),
                                    ).then((updated) {
                                      if (updated == true) {
                                        _loadSubmission();
                                      }
                                    }); // Reload after edit
                                },
                                icon: const Icon(Icons.edit),
                                label: const Text(
                                  "Edit Submission",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildInfoCard(String label, String value, {bool compact = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            offset: const Offset(0, 2),
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
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
          SizedBox(height: compact ? 4 : 8),
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
    );
  }

  Widget _buildRejectionCard(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
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
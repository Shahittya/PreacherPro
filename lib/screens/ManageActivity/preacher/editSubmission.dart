import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../../models/ActivityData.dart';

class EditSubmissionScreen extends StatefulWidget {
  final ActivityData activity;
  final Map<String, dynamic> submissionData;
  const EditSubmissionScreen({super.key, required this.activity, required this.submissionData});

  @override
  State<EditSubmissionScreen> createState() => _EditSubmissionScreenState();
}

class _EditSubmissionScreenState extends State<EditSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _sessionOutcome = 'completed';
  String _attendanceRange = '';
  String _remarks = '';
  String _topicDelivered = '';
  String _timeStart = '';
  String _timeEnd = '';
  String _incidentNote = '';
  String _organizerFeedback = '';
  File? _proofPhoto;
  String? _proofPhotoBase64;
  bool _encodingPhoto = false;
  bool _updating = false;

  final _topicCtrl = TextEditingController();
  final _startTimeCtrl = TextEditingController();
  final _endTimeCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  final _incidentCtrl = TextEditingController();
  final _feedbackCtrl = TextEditingController();

  final List<String> _sessionOutcomes = const [
    'completed',
    'completed_partial',
    'cancelled_onsite',
    'not_conducted',
  ];

  final List<String> _attendanceRanges = const [
    '0-10',
    '10-30',
    '30-50',
    '50-100',
    '100+',
    'Not Applicable',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing submission data
    _sessionOutcome = widget.submissionData['session_outcome'] ?? 'completed';
    _attendanceRange = widget.submissionData['attendance_range'] ?? '';
    _topicDelivered = widget.submissionData['topic_delivered'] ?? widget.activity.topic;
    _remarks = widget.submissionData['remarks'] ?? '';
    _timeStart = (widget.submissionData['actual_time_start'] ?? widget.submissionData['actual_start_time'] ?? '').toString();
    _timeEnd = (widget.submissionData['actual_time_end'] ?? widget.submissionData['actual_end_time'] ?? '').toString();
    _incidentNote = widget.submissionData['incident_note'] ?? '';
    _organizerFeedback = widget.submissionData['organizer_feedback'] ?? '';
    _proofPhotoBase64 = widget.submissionData['proof_photo_base64'];

    _topicCtrl.text = _topicDelivered;
    _startTimeCtrl.text = _timeStart;
    _endTimeCtrl.text = _timeEnd;
    _remarksCtrl.text = _remarks;
    _incidentCtrl.text = _incidentNote;
    _feedbackCtrl.text = _organizerFeedback;
  }

  @override
  void dispose() {
    _topicCtrl.dispose();
    _startTimeCtrl.dispose();
    _endTimeCtrl.dispose();
    _remarksCtrl.dispose();
    _incidentCtrl.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
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
                "Edit Report Submission",
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Outcome
              const Text(
                "Session Outcome *",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _sessionOutcome,
                items: _sessionOutcomes.map((o) => DropdownMenuItem(
                  value: o,
                  child: Text(
                    o,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                )).toList(),
                onChanged: (v) => setState(() => _sessionOutcome = v!),
                decoration: _dropdownDecoration(),
                isExpanded: true,
              ),

              const SizedBox(height: 16),

              // Attendance (range)
              const Text(
                "Attendance Range *",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _attendanceRange.isEmpty ? null : _attendanceRange,
                items: _attendanceRanges.map((r) => DropdownMenuItem(
                  value: r,
                  child: Text(
                    r,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                )).toList(),
                onChanged: (v) => setState(() => _attendanceRange = v!),
                decoration: _dropdownDecoration(hint: "Select attendance range"),
                validator: (v) => (v == null || v.isEmpty) ? 'Please select a range' : null,
                isExpanded: true,
              ),

              const SizedBox(height: 16),

              // Topic delivered
              const Text(
                "Topic Delivered *",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _topicCtrl,
                onChanged: (v) => _topicDelivered = v,
                decoration: _inputDecoration("Topic shared"),
              ),

              const SizedBox(height: 16),

              // Remarks
              const Text(
                "Remarks",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _remarksCtrl,
                onChanged: (v) => _remarks = v,
                maxLines: 3,
                decoration: _inputDecoration("Any general notes or observations..."),
              ),

              const SizedBox(height: 16),

              // Time Range
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Start Time",
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _startTimeCtrl,
                          readOnly: true,
                          onTap: () => _pickTime(isStart: true),
                          decoration: _inputDecoration(widget.activity.startTime),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "End Time",
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _endTimeCtrl,
                          readOnly: true,
                          onTap: () => _pickTime(isStart: false),
                          decoration: _inputDecoration(widget.activity.endTime),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Incident Note
              const Text(
                "Incident Notes (Optional)",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _incidentCtrl,
                onChanged: (v) => _incidentNote = v,
                maxLines: 3,
                decoration: _inputDecoration("Any issues or incidents during the session..."),
              ),

              const SizedBox(height: 16),

              // Organizer Feedback
              const Text(
                "Feedback & Suggestions (Optional)",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _feedbackCtrl,
                onChanged: (v) => _organizerFeedback = v,
                maxLines: 3,
                decoration: _inputDecoration("Feedback from organizers or suggestions..."),
              ),

              const SizedBox(height: 16),

              // Photo Proof
              const Text(
                "Photo Proof *",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 6),
              if (_proofPhoto != null || _proofPhotoBase64 != null) ...[
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _proofPhoto != null
                        ? Image.file(_proofPhoto!, fit: BoxFit.cover)
                        : Image.memory(
                            base64Decode(_proofPhotoBase64!),
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _encodingPhoto ? null : _pickPhoto,
                      icon: Icon(_encodingPhoto ? Icons.hourglass_empty : Icons.photo_library),
                      label: Text(_encodingPhoto ? 'Processing...' : 'Change Photo'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // GPS Verified Badge
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

              // Update Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updating ? null : _handleUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: _updating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "Update Report",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
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
        borderSide: BorderSide(color: Colors.lightGreen, width: 2),
      ),
    );
  }

  InputDecoration _dropdownDecoration({String? hint}) {
    return _inputDecoration(hint ?? '').copyWith(hintText: hint);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final formatted = _formatTime(picked);
      setState(() {
        if (isStart) {
          _timeStart = formatted;
          _startTimeCtrl.text = formatted;
        } else {
          _timeEnd = formatted;
          _endTimeCtrl.text = formatted;
        }
      });
    }
  }

  String _formatTime(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 75,
      );
      if (pickedFile != null) {
        setState(() {
          _proofPhoto = File(pickedFile.path);
          _proofPhotoBase64 = null; // reset cached base64 when user picks a new photo
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<String?> _encodePhotoAsBase64(File photo) async {
    try {
      setState(() => _encodingPhoto = true);
      final bytes = await photo.readAsBytes();
      
      if (bytes.isEmpty) {
        throw Exception('Image file is empty');
      }
      
      if (bytes.length > 1200000) {
        throw Exception(
          'Image too large (${(bytes.length / 1024 / 1024).toStringAsFixed(2)}MB). Keep images under 1.2MB.',
        );
      }
      
      final base64String = base64Encode(bytes);
      return base64String;
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to encode photo: $e')),
      );
      return null;
    } finally {
      if (mounted) setState(() => _encodingPhoto = false);
    }
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_attendanceRange.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select attendance range')),
      );
      return;
    }
    if (_proofPhoto == null && _proofPhotoBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo proof is required')),
      );
      return;
    }

    setState(() => _updating = true);
    try {
      // Encode new photo if selected
      if (_proofPhoto != null) {
        _proofPhotoBase64 = await _encodePhotoAsBase64(_proofPhoto!);
        if (_proofPhotoBase64 == null) {
          setState(() => _updating = false);
          return;
        }
      }

      // Update the submission document
        final snapshot = await FirebaseFirestore.instance
          .collection('activity_submissions')
          .where('activity_id', isEqualTo: widget.activity.activityId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          'session_outcome': _sessionOutcome,
          'attendance_range': _attendanceRange,
          'topic_delivered': _topicDelivered.trim().isEmpty ? widget.activity.topic : _topicDelivered.trim(),
          'remarks': _remarks.trim(),
          'actual_time_start': _timeStart.trim().isEmpty ? null : _timeStart.trim(),
          'actual_time_end': _timeEnd.trim().isEmpty ? null : _timeEnd.trim(),
          'incident_note': _incidentNote.trim().isEmpty ? null : _incidentNote.trim(),
          'organizer_feedback': _organizerFeedback.trim().isEmpty ? null : _organizerFeedback.trim(),
          'proof_photo_base64': _proofPhotoBase64,
          'updated_at': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report updated successfully')),
        );
      } else {
        throw Exception('Submission not found');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }
}
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../../models/ActivityData.dart';
import '../../../providers/ActivityController.dart';

class SubmitReportScreen extends StatefulWidget {
  final ActivityData activity;
  const SubmitReportScreen({super.key, required this.activity});

  @override
  State<SubmitReportScreen> createState() => _SubmitReportScreenState();
}

class _SubmitReportScreenState extends State<SubmitReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final ActivityController _controller = ActivityController();

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
  bool _submitting = false;

  final _topicCtrl = TextEditingController();
  final _startTimeCtrl = TextEditingController();
  final _endTimeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _topicDelivered = widget.activity.topic;
    _topicCtrl.text = widget.activity.topic;
  }

  @override
  void dispose() {
    _topicCtrl.dispose();
    _startTimeCtrl.dispose();
    _endTimeCtrl.dispose();
    super.dispose();
  }

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
                "Submit Activity Report",
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
                items: _sessionOutcomes
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.replaceAll('_', ' '))))
                    .toList(),
                onChanged: (v) => setState(() => _sessionOutcome = v ?? 'completed'),
                isExpanded: true,
                decoration: _dropdownDecoration(),
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
                items: _attendanceRanges
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _attendanceRange = v ?? ''),
                isExpanded: true,
                decoration: _dropdownDecoration(hint: "Select range"),
                validator: (v) => (v == null || v.isEmpty) ? 'Please select a range' : null,
              ),

              const SizedBox(height: 16),

              // Topic delivered
              const Text(
                "Topic Delivered",
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
                "Remarks *",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 6),
              TextFormField(
                maxLines: 3,
                onChanged: (v) => _remarks = v,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please add a short remark' : null,
                decoration: _inputDecoration("How did it go?"),
              ),

              const SizedBox(height: 16),

              // Actual times (optional)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startTimeCtrl,
                      readOnly: true,
                      onTap: () => _pickTime(isStart: true),
                      decoration: _inputDecoration("Select time").copyWith(labelText: 'Time Start'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _endTimeCtrl,
                      readOnly: true,
                      onTap: () => _pickTime(isStart: false),
                      decoration: _inputDecoration("Select time").copyWith(labelText: 'Time End'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Incident note (conditional)
              if (_sessionOutcome != 'completed') ...[
                const Text(
                  "Incident / Issue",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  maxLines: 2,
                  onChanged: (v) => _incidentNote = v,
                  decoration: _inputDecoration("What happened?"),
                ),
                const SizedBox(height: 16),
              ],

              // Organizer feedback (optional)
              const Text(
                "Organizer Feedback (optional)",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 6),
              TextFormField(
                maxLines: 2,
                onChanged: (v) => _organizerFeedback = v,
                decoration: _inputDecoration("Requests, comments, follow-ups"),
              ),

              const SizedBox(height: 16),

              // Photo Proof Upload (required)
              const Text(
                "Photo Proof * (required for payment/KPI)",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _encodingPhoto ? null : _pickPhoto,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _proofPhoto != null
                      ? Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _proofPhoto!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _encodingPhoto ? null : _pickPhoto,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Change Photo'),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, color: Colors.grey.shade600, size: 28),
                            const SizedBox(width: 10),
                            Text(
                              'Tap to upload photo proof',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                            ),
                          ],
                        ),
                ),
              ),
              if (_encodingPhoto) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
                const SizedBox(height: 4),
                Text(
                  'Encoding photo...',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],

              const SizedBox(height: 18),

              // GPS Verified Badge
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
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

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          "Submit Report",
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
      
      // Check file size (Firestore field limit is 1MB, base64 adds ~33% overhead)
      if (bytes.length > 1200000) {
        throw Exception(
          'Image too large (${(bytes.length / 1024 / 1024).toStringAsFixed(2)}MB). Keep images under 1.2MB.',
        );
      }
      
      final base64String = base64Encode(bytes);
      print('📸 Image size: ${(bytes.length / 1024).toStringAsFixed(2)}KB');
      print('📊 Base64 size: ${(base64String.length / 1024).toStringAsFixed(2)}KB');
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_attendanceRange.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select attendance range')),
      );
      return;
    }
    if (_proofPhoto == null && _proofPhotoBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo proof is required for payment/KPI.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      // Encode photo if selected
      if (_proofPhoto != null && _proofPhotoBase64 == null) {
        _proofPhotoBase64 = await _encodePhotoAsBase64(_proofPhoto!);
        if (_proofPhotoBase64 == null) {
          setState(() => _submitting = false);
          return; // Encoding failed, abort submission
        }
      }

      await _controller.submitActivityReport(
        activity: widget.activity,
        sessionOutcome: _sessionOutcome,
        attendanceRange: _attendanceRange,
        remarks: _remarks.trim(),
        topicDelivered: _topicDelivered.trim().isEmpty ? widget.activity.topic : _topicDelivered.trim(),
        actualStart: _timeStart.trim().isEmpty ? null : _timeStart.trim(),
        actualEnd: _timeEnd.trim().isEmpty ? null : _timeEnd.trim(),
        incidentNote: _incidentNote.trim().isEmpty ? null : _incidentNote.trim(),
        organizerFeedback: _organizerFeedback.trim().isEmpty ? null : _organizerFeedback.trim(),
        proofPhotoBase64: _proofPhotoBase64,
        gpsInfo: {
          'lat': widget.activity.locationLat,
          'lng': widget.activity.locationLng,
          'accuracy': null,
          'distance_to_target': null,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted and officer notified')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submit failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
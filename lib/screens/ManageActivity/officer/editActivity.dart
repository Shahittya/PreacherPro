import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/ActivityData.dart';
import '../../../models/ActivityAssignment.dart';
import '../../../models/Notification.dart' as NotificationModel;
import 'editMapScreen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class EditActivityForm extends StatefulWidget {
  final ActivityData activityToEdit;
  final String assignmentDocId;

  const EditActivityForm({
    Key? key,
    required this.activityToEdit,
    required this.assignmentDocId,
  }) : super(key: key);

  @override
  State<EditActivityForm> createState() => _EditActivityFormState();
}

class _EditActivityFormState extends State<EditActivityForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _titleController;
  late TextEditingController _topicController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _locationAddressController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _endTimeController;

  List<String> preachers = [];
  List<String> preacherIds = [];
  String? preacher;
  String? preacherId;

  double _selectedLat = 0.0;
  double _selectedLng = 0.0;
  String _selectedLocationName = '';

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data
    _titleController = TextEditingController(text: widget.activityToEdit.title);
    _topicController = TextEditingController(text: widget.activityToEdit.topic);
    _descriptionController = TextEditingController(text: widget.activityToEdit.description);
    _locationController = TextEditingController(text: widget.activityToEdit.locationName);
    _locationAddressController = TextEditingController(text: widget.activityToEdit.locationAddress);
    _dateController = TextEditingController(text: widget.activityToEdit.activityDate);
    _timeController = TextEditingController(text: widget.activityToEdit.startTime);
    _endTimeController = TextEditingController(text: widget.activityToEdit.endTime);

    _selectedLocationName = widget.activityToEdit.locationName;
    _selectedLat = widget.activityToEdit.locationLat;
    _selectedLng = widget.activityToEdit.locationLng;

    // Set preacher if assignment exists
    if (widget.activityToEdit.assignment != null) {
      preacherId = widget.activityToEdit.assignment!.preacherId;
      preacher = widget.activityToEdit.preacherName;
    }

    fetchPreachers();
  }

  Future<void> fetchPreachers() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('preachers').get();

      if (snapshot.docs.isEmpty) {
        print('No active preachers found');
        return;
      }

      print('Found ${snapshot.docs.length} active preachers');

      preacherIds.clear();
      final Map<String, String> uniquePreachers = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final name = data['fullName']?.toString() ?? '';

        if (name.isNotEmpty) {
          String displayName = name;
          if (uniquePreachers.containsKey(name)) {
            displayName = '$name (${doc.id.substring(0, 5)})';
          }

          uniquePreachers[displayName] = doc.id;
        }
      }

      final names = uniquePreachers.keys.toList();
      preacherIds = uniquePreachers.values.toList();

      if (mounted) {
        setState(() {
          preachers = names;
        });
      }
    } catch (e) {
      print('Error fetching preachers: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _topicController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _locationAddressController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLat == 0.0 && _selectedLng == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Update activity fields
      await ActivityData.updateActivityFields(widget.activityToEdit.docId, {
        'title': _titleController.text.trim(),
        'topic': _topicController.text.trim(),
        'description': _descriptionController.text.trim(),
        'activity_date': _dateController.text.trim(),
        'start_time': _timeController.text.trim(),
        'end_time': _endTimeController.text.trim(),
        'location_name': _selectedLocationName,
        'location_address': _locationAddressController.text.trim(),
        'location_lat': _selectedLat,
        'location_lng': _selectedLng,
      });

      // Update preacher assignment if changed
      if (preacherId != null && preacherId != widget.activityToEdit.assignment?.preacherId) {
        await ActivityAssignment.updatePreacher(widget.assignmentDocId, preacherId!);
        
        // Create notification for the newly assigned preacher
        try {
          final notification = NotificationModel.ActivityNotification(
            docId: '',
            preacherId: preacherId!,
            activityId: widget.activityToEdit.activityId,
            message: 'You have been reassigned to "${_titleController.text.trim()}" on ${_dateController.text.trim()} at ${_timeController.text.trim()}',
            timestamp: DateTime.now(),
            isRead: false,
            type: 'assignment',
          );
          
          await NotificationModel.ActivityNotification.createNotification(notification);
          print('Reassignment notification created for preacher: $preacherId');
        } catch (e) {
          print('Warning: could not create reassignment notification: $e');
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.amber.shade300,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Activity', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // Subtitle
                const Text(
                  "Update activity details and reassign preacher",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 12),

                // Section header - Activity Details
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "Activity Details",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Activity Title *',
                    hintText: 'e.g., Sunday Service',
                    filled: true,
                    fillColor: Colors.grey[100],
                    prefixIcon: Icon(Icons.title, color: Colors.grey[600]),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.amber.shade300, width: 2),
                    ),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Title required' : null,
                ),
                const SizedBox(height: 14),

                // Topic
                TextFormField(
                  controller: _topicController,
                  decoration: InputDecoration(
                    labelText: 'Topic *',
                    hintText: 'e.g., Bible Study',
                    filled: true,
                    fillColor: Colors.grey[100],
                    prefixIcon: Icon(Icons.topic, color: Colors.grey[600]),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.amber.shade300, width: 2),
                    ),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Topic required' : null,
                ),
                const SizedBox(height: 14),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Additional details...',
                    filled: true,
                    fillColor: Colors.grey[100],
                    prefixIcon: Icon(Icons.description, color: Colors.grey[600]),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.amber.shade300, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Section header - Date & Time
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "Date & Time",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),

                // Date
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Date *',
                    hintText: 'DD/MM/YYYY',
                    filled: true,
                    fillColor: Colors.grey[100],
                    prefixIcon: Icon(Icons.calendar_today, color: Colors.grey[600]),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.amber.shade300, width: 2),
                    ),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _dateController.text =
                            '${picked.day}/${picked.month}/${picked.year}';
                      });
                    }
                  },
                  validator: (value) => value?.isEmpty ?? true ? 'Date required' : null,
                ),
                const SizedBox(height: 14),

                // Time Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _timeController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Start Time *',
                          hintText: 'HH:MM',
                          filled: true,
                          fillColor: Colors.grey[100],
                          prefixIcon: Icon(Icons.access_time, color: Colors.grey[600]),
                          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.amber.shade300, width: 2),
                          ),
                        ),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              _timeController.text = picked.format(context);
                            });
                          }
                        },
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Start time required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _endTimeController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'End Time',
                          hintText: 'HH:MM (optional)',
                          filled: true,
                          fillColor: Colors.grey[100],
                          prefixIcon: Icon(Icons.access_time_filled, color: Colors.grey[600]),
                          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.amber.shade300, width: 2),
                          ),
                        ),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              _endTimeController.text = picked.format(context);
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Section header - Location
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "Location Details",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),

                // Location Name
                TextFormField(
                  controller: _locationController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Location Name *',
                    hintText: 'Select preaching location',
                    filled: true,
                    fillColor: Colors.grey[100],
                    prefixIcon: Icon(Icons.location_on, color: Colors.grey[600]),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.amber.shade300, width: 2),
                    ),
                  ),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditMapScreen(
                          initialLat: _selectedLat,
                          initialLng: _selectedLng,
                          initialLocationName: _selectedLocationName,
                        ),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        _selectedLat = result['lat'];
                        _selectedLng = result['lng'];
                        _selectedLocationName = result['name'];
                        _locationController.text = _selectedLocationName;
                      });
                    }
                  },
                  validator: (value) => value?.isEmpty ?? true ? 'Location required' : null,
                ),
                const SizedBox(height: 14),

                // Location Address
                TextFormField(
                  controller: _locationAddressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Location Address',
                    hintText: 'Enter full address (optional)',
                    filled: true,
                    fillColor: Colors.grey[100],
                    prefixIcon: Icon(Icons.home, color: Colors.grey[600]),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.amber.shade300, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Section header - Assignment
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "Preacher Assignment",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),

                // Preacher Selection
                DropdownButtonFormField<String>(
                  value: preacher,
                  isExpanded: false,
                  items: preachers
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      preacher = value;
                      final index = preachers.indexOf(value ?? '');
                      if (index >= 0) {
                        preacherId = preacherIds[index];
                      }
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Assign to Preacher *',
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.amber.shade300, width: 2),
                    ),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Preacher required' : null,
                ),
                const SizedBox(height: 6),
                Text(
                  "Available preachers: ${preachers.join(', ')}",
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 14),

                // Info box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade600, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Changes will be applied immediately. The assigned preacher will be notified if you reassign this activity.",
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveActivity,
                    icon: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : const Icon(Icons.check_circle),
                    label: Text(
                      _isLoading ? 'Updating Activity...' : 'Update Activity',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lime.shade600,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

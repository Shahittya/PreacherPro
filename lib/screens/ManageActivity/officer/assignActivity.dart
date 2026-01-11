import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/ActivityData.dart';
import '../../../models/ActivityAssignment.dart';
import '../../../models/Notification.dart' as NotificationModel;
import 'package:provider/provider.dart';
import '../../../providers/ActivityController.dart';
import 'MapScreen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; 

class AssignActivityForm extends StatefulWidget {
  final ActivityData? activityToEdit; // null for create, populated for edit
  final String? assignmentDocId; // Document ID of assignment for editing

  const AssignActivityForm({
    Key? key,
    this.activityToEdit,
    this.assignmentDocId,
  }) : super(key: key);

  @override
  State<AssignActivityForm> createState() => _AssignActivityFormState();
}

class _AssignActivityFormState extends State<AssignActivityForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; 
  String title = "";
  String topic = "";
  String description = "";
  String location = "";
  String date = "";
  String time = "";
  String endTime = "";
  String locationAddress = "";
  List<String> preachers = [];
  List<String> preacherIds = []; // Store preacher document IDs
  String? preacher;
  String? preacherId; // Selected preacher's document ID

  double _selectedLat = 0.0;
  double _selectedLng = 0.0;
  String _selectedLocationName = '';

  late TextEditingController _titleController;
  late TextEditingController _topicController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _locationAddressController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _endTimeController;
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _topicController = TextEditingController();
    _descriptionController = TextEditingController();
    _locationController = TextEditingController();
    _locationAddressController = TextEditingController();
    _dateController = TextEditingController();
    _timeController = TextEditingController();
    _endTimeController = TextEditingController();

    // If editing, populate fields with existing activity data
    if (widget.activityToEdit != null) {
      _titleController.text = widget.activityToEdit!.title;
      _topicController.text = widget.activityToEdit!.topic;
      _descriptionController.text = widget.activityToEdit!.description;
      _locationController.text = widget.activityToEdit!.locationName;
      _locationAddressController.text = widget.activityToEdit!.locationAddress;
      _dateController.text = widget.activityToEdit!.activityDate;
      _timeController.text = widget.activityToEdit!.startTime;
      _endTimeController.text = widget.activityToEdit!.endTime;
      _selectedLocationName = widget.activityToEdit!.locationName;
      _selectedLat = widget.activityToEdit!.locationLat;
      _selectedLng = widget.activityToEdit!.locationLng;
      
      // Set preacher if editing
      if (widget.activityToEdit!.assignment != null) {
        preacherId = widget.activityToEdit!.assignment!.preacherId;
        preacher = widget.activityToEdit!.preacherName;
      }
    }

    fetchPreachers().then((list) {
      setState(() {
        preachers = list;
      });
    });
  }

  Future<List<String>> fetchPreachers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('preachers')
          .get();
      
      if (snapshot.docs.isEmpty) {
        print('No active preachers found');
        return [];
      }
      
      print('Found ${snapshot.docs.length} active preachers');
      
      // Clear previous data
      preacherIds.clear();
      
      // Use a map to track seen names and ensure uniqueness
      final Map<String, String> uniquePreachers = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final name = data['fullName']?.toString() ?? '';
        
        if (name.isNotEmpty) {
          // If name already exists, append doc ID to make it unique
          String displayName = name;
          if (uniquePreachers.containsKey(name)) {
            displayName = '$name (${doc.id.substring(0, 6)})';
          }
          
          uniquePreachers[displayName] = doc.id;
        }
      }
      
      // Store IDs in the same order as names
      final names = uniquePreachers.keys.toList();
      preacherIds = uniquePreachers.values.toList();
      
      return names;
    } catch (e) {
      print('Error fetching preachers: $e');
      return [];
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
  
  // Validate location is selected
  if (_selectedLat == 0.0 && _selectedLng == 0.0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a location')),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    final controller = Provider.of<ActivityController>(context, listen: false);
    
    // Get current user ID from Firebase Auth
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid ?? 'unknown_user';
    
    if (widget.activityToEdit != null) {
      // EDITING existing activity
      await ActivityData.updateActivityFields(widget.activityToEdit!.docId, {
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
      if (preacherId != null && preacherId != widget.activityToEdit!.assignment?.preacherId) {
        if (widget.assignmentDocId != null) {
          await ActivityAssignment.updatePreacher(widget.assignmentDocId!, preacherId!);
          
          // Create notification for the newly assigned preacher
          try {
            final notification = NotificationModel.ActivityNotification(
              docId: '',
              preacherId: preacherId!,
              activityId: widget.activityToEdit!.activityId,
              message: 'You have been reassigned to "${_titleController.text.trim()}" on ${_dateController.text.trim()} at ${_timeController.text.trim()}',
              timestamp: DateTime.now(),
              isRead: false,
              type: 'assignment',
            );
            
            await NotificationModel.ActivityNotification.createNotification(notification);
            print('Reassignment notification created successfully for preacher: $preacherId');
          } catch (e) {
            print('Warning: could not create reassignment notification: $e');
          }
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity updated successfully!')),
        );
      }
    } else {
      // CREATING new activity
      final activity = ActivityData(
        docId: '',
        activityId: DateTime.now().millisecondsSinceEpoch,
        title: _titleController.text.trim(),
        topic: _topicController.text.trim(),
        description: _descriptionController.text.trim(),
        activityDate: _dateController.text.trim(),
        startTime: _timeController.text.trim(),
        endTime: _endTimeController.text.trim(),
        locationName: _selectedLocationName,
        locationAddress: _locationAddressController.text.trim(),
        locationLat: _selectedLat,
        locationLng: _selectedLng,
        createdBy: currentUserId, 
        createdAt: DateTime.now(),
        status: 'assigned',
      );

      await controller.addActivity(activity);
      
      // Create activity assignment using the model
      if (preacherId != null) {
        final assignment = ActivityAssignment(
          docId: '',
          assignmentId: DateTime.now().millisecondsSinceEpoch,
          activityId: activity.activityId,
          preacherId: preacherId!,
          assignedBy: currentUserId,
          assignedAt: DateTime.now(),
          assignmentStatus: 'assigned',
        );
        
        await ActivityAssignment.createAssignment(assignment);

        // Create notification for the preacher
        try {
          final notification = NotificationModel.ActivityNotification(
            docId: '',
            preacherId: preacherId!,
            activityId: activity.activityId,
            message: 'You have been assigned to "${_titleController.text.trim()}" on ${_dateController.text.trim()} at ${_timeController.text.trim()}',
            timestamp: DateTime.now(),
            isRead: false,
            type: 'assignment',
          );
          
          await NotificationModel.ActivityNotification.createNotification(notification);
          print('Notification created successfully for preacher: $preacherId');
        } catch (e) {
          print('Warning: could not create notification: $e');
        }

        // Also store display names on the activity doc for immediate rendering
        try {
          String? preacherFullName;
          final preacherDoc = await FirebaseFirestore.instance
              .collection('preachers')
              .doc(preacherId)
              .get();
          if (preacherDoc.exists) {
            preacherFullName = preacherDoc.data()?['fullName'] as String?;
          }

          String? officerFullName;
          final officerDoc = await FirebaseFirestore.instance
              .collection('officers')
              .doc(currentUserId)
              .get();
          if (officerDoc.exists) {
            officerFullName = officerDoc.data()?['fullName'] as String?;
          }

          // find the activity document by activity_id and update names
          final activitySnap = await FirebaseFirestore.instance
              .collection('activities')
              .where('activity_id', isEqualTo: activity.activityId)
              .limit(1)
              .get();
          if (activitySnap.docs.isNotEmpty) {
            await activitySnap.docs.first.reference.update({
              if (preacherFullName != null) 'preacher_name': preacherFullName,
              if (officerFullName != null) 'officer_name': officerFullName,
            });
          }
        } catch (e) {
          print('Warning: could not cache display names on activity: $e');
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity assigned successfully!')),
        );
      }
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
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.activityToEdit != null ? "Edit Activity" : "Assign Activity",
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
      ),
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
                // Add this for extra gap between AppBar and body
                const SizedBox(height: 12), // Adjust this value as needed

                // Subtitle
                const Text(
                  "Fill in the details below to create and assign a preaching activity.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                _sectionHeader("Activity Details"),
                const SizedBox(height: 5),

                // Activity Title
                Card(
                  elevation: 0,
                  color: Colors.grey.shade50,
                  shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader("Activity Title"),
                    TextFormField(
                    controller: _titleController,
                    decoration: _inputDecoration(
                    label: "Activity Title *",
                    hint: "Enter activity title",
                    icon: Icons.title,
                    ),
                    onChanged: (v) => title = v,
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ],
                  ),
                  ),
                ),
                const SizedBox(height:3),

                // Topic & Description in Card
                Card(
                  elevation: 0,
                  color: Colors.grey.shade50,
                  shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    _sectionHeader("Topic & Description"),

                    // Topic
                    TextFormField(
                      controller: _topicController,
                      decoration: _inputDecoration(
                      label: "Topic *",
                      hint: "Enter preaching topic",
                      icon: Icons.topic,
                      ),
                      onChanged: (v) => topic = v,
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: _inputDecoration(
                      label: "Description",
                      hint: "Enter activity description (optional)",
                      icon: Icons.description,
                      ),
                      onChanged: (v) => description = v,
                    ),
                    ],
                  ),
                  ),
                ),
                const SizedBox(height: 3),

                // Location Section Card
                Card(
                  elevation: 0,
                  color: Colors.grey.shade50,
                  shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    _sectionHeader("Location"),
                    // Location
                    TextFormField(
                      controller: _locationController,
                      readOnly: true, // Make it read-only
                      decoration: _inputDecoration(
                      label: "Location *",
                      hint: "Tap to select location on map",
                      icon: Icons.location_on,
                       ).copyWith(
                      suffixIcon: const Icon(Icons.map, color: Colors.green),
                      ),
                      onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                        builder: (context) => MapScreen(
                          onLocationSelected: (LatLng location, String locationName) {
                          setState(() {
                            _selectedLat = location.latitude;
                            _selectedLng = location.longitude;
                            _selectedLocationName = locationName;
                            _locationController.text = 
                            "$locationName\n(${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)})";
                          });
                          },
                        ),
                        ),
                      );
                      },
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),

                    // Location Address
                    TextFormField(
                      controller: _locationAddressController,
                      decoration: _inputDecoration(
                      label: "Location Address",
                      hint: "Enter location address (optional)",
                      icon: Icons.map,
                      ),
                      maxLines: 2,
                      onChanged: (v) => locationAddress = v,
                    ),
                    ],
                  ),
                  ),
                ),
                const SizedBox(height: 3),
                Card(
                  elevation: 0,
                  color: Colors.grey.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader("Schedule"),
                          // Date
                      TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        decoration: _inputDecoration(
                          label: "Activity Date *",
                          hint: "DD/MM/YYYY",
                          icon: Icons.calendar_today,
                        ),
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
                            date = _dateController.text;
                          }
                        },
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height:10),

                // Start & End Time in one row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _timeController,
                        readOnly: true,
                        decoration: _inputDecoration(
                          label: "Start Time *",
                          hint: "HH:MM",
                          icon: Icons.access_time,
                        ),
                        onTap: () async {
                          // Get current time for initial time, or use 9:00 AM as default
                          final now = DateTime.now();
                          final initialTime = _timeController.text.isEmpty
                              ? TimeOfDay(hour: 9, minute: 0) // Default to 9:00 AM
                              : TimeOfDay.now();
                          
                          TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: initialTime,
                            builder: (BuildContext context, Widget? child) {
                              return MediaQuery(
                                data: MediaQuery.of(context).copyWith(
                                  alwaysUse24HourFormat: false,
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            _timeController.text = picked.format(context);
                            time = _timeController.text;
                          }
                        },
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _endTimeController,
                        readOnly: true,
                        decoration: _inputDecoration(
                          label: "End Time",
                          hint: "HH:MM",
                          icon: Icons.access_time_filled,
                        ),  
                        onTap: () async {
                          // Default to 1 hour after start time or 10:00 AM
                          TimeOfDay initialTime;
                          if (_timeController.text.isNotEmpty) {
                            // Try to parse start time and add 1 hour
                            try {
                              final startTimeParts = _timeController.text.split(':');
                              int hour = int.parse(startTimeParts[0].replaceAll(RegExp(r'[^0-9]'), ''));
                              int minute = int.parse(startTimeParts[1].replaceAll(RegExp(r'[^0-9]'), ''));
                              
                              // Check if PM
                              if (_timeController.text.toLowerCase().contains('pm') && hour != 12) {
                                hour += 12;
                              } else if (_timeController.text.toLowerCase().contains('am') && hour == 12) {
                                hour = 0;
                              }
                              
                              // Add 1 hour
                              hour = (hour + 1) % 24;
                              initialTime = TimeOfDay(hour: hour, minute: minute);
                            } catch (e) {
                              initialTime = TimeOfDay(hour: 10, minute: 0);
                            }
                          } else {
                            initialTime = TimeOfDay(hour: 10, minute: 0); // Default to 10:00 AM
                          }
                          
                          TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: initialTime,
                            builder: (BuildContext context, Widget? child) {
                              return MediaQuery(
                                data: MediaQuery.of(context).copyWith(
                                  alwaysUse24HourFormat: false,
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            _endTimeController.text = picked.format(context);
                            endTime = _endTimeController.text;
                          }
                        },
                      ),
                    ),
                  ],
                ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                // Preacher Dropdown
              Card(
                elevation: 0,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader("Assign Preacher"),
                      DropdownButtonFormField<String>(
                        initialValue: preacher,
                        isExpanded: true,
                        decoration: _inputDecoration(
                          label: "Assign to Preacher *",
                          hint: "Select preacher",
                          icon: Icons.person,
                        ),
                        items: preachers
                            .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(
                                    p,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            preacher = v;
                            final index = preachers.indexOf(v!);
                            preacherId = index != -1 ? preacherIds[index] : null;
                          });
                        },
                        validator: (v) => v == null ? 'Please select a preacher' : null,
                      ),
                    ],
                  ),
                ),
              ),

                const SizedBox(height: 6),
                // Info box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info, color: Colors.amber, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "The assigned preacher must perform GPS check-in at the activity location before submitting their report.",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Assign Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveActivity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade400,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 1,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            widget.activityToEdit != null
                                ? "Update Activity"
                                : "Assign Activity",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
Widget _sectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 13,
        letterSpacing: 1.2,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    ),
  );
}


InputDecoration _inputDecoration({
  required String label,
  required String hint,
  required IconData icon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: Colors.grey.shade100,
    prefixIcon: Icon(icon, color: Colors.grey.shade600),
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
  );
}

}
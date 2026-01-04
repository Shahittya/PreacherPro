import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/ActivityData.dart';
import '../../../models/ActivityAssignment.dart';
import 'package:provider/provider.dart';
import '../../../providers/ActvitiyController.dart';
import 'MapScreen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; 

class AssignActivityForm extends StatefulWidget {
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
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error assigning activity: $e')),
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Assign New Activity",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
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
                  "Create and assign preaching activity",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 12),

                // Section header
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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

                // Activity Title
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: "Activity Title *",
                    hintText: "Enter activity title",
                    filled: true,
                    fillColor: Colors.grey[100],
                    prefixIcon: Icon(Icons.title, color: Colors.grey[600]), // Optional
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
                  onChanged: (v) => title = v,
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                // Topic
                TextFormField(
                  controller: _topicController,
                  decoration: InputDecoration(
                    labelText: "Topic *",
                    hintText: "Enter preaching topic",
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
                  onChanged: (v) => topic = v,
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                // Description
               TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Description",
                    hintText: "Describe the activity, objectives, etc.",
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
                  onChanged: (v) => description = v,
                ),
                const SizedBox(height: 14),

                // Location
                TextFormField(
                  controller: _locationController,
                  readOnly: true, // Make it read-only
                  decoration: InputDecoration(
                    labelText: "Location *",
                    hintText: "Select preaching location",
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
                const SizedBox(height: 14),

                // Location Address
                TextFormField(
                  controller: _locationAddressController,
                  decoration: InputDecoration(
                    labelText: "Location Address",
                    hintText: "Enter full address (optional)",
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
                  maxLines: 2,
                  onChanged: (v) => locationAddress = v,
                ),
                const SizedBox(height: 14),

                // Date
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "Date *",
                    hintText: "DD/MM/YYYY",
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
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
                      date = _dateController.text;
                    }
                  },
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                // Start & End Time in one row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _timeController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: "Start Time *",
                          hintText: "HH:MM",
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
                          TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
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
                        decoration: InputDecoration(
                          labelText: "End Time",
                          hintText: "HH:MM (optional)",
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
                          TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
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
                const SizedBox(height: 14),

                // Preacher Dropdown
                DropdownButtonFormField<String>(
                  value: preacher,
                  isExpanded: false,
                  decoration: InputDecoration(
                    labelText: "Assign to Preacher *",
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
                  items: preachers
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      preacher = v;
                      // Get the corresponding preacher ID
                      final index = preachers.indexOf(v!);
                      if (index != -1 && index < preacherIds.length) {
                        preacherId = preacherIds[index];
                      }
                    });
                  },
                  validator: (value) => value == null ? 'Please select a preacher' : null,
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
                          "The assigned preacher will receive a notification and must perform GPS check-in at the location before submitting their report.",
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
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () async {
                      if (_formKey.currentState!.validate()) {
                        await _saveActivity();
                        // Do NOT call Navigator.pop here, it's already called in _saveActivity after saving
                      }
                    },
                    icon: const Icon(Icons.send),
                    label: const Text(
                      "Assign Activity",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
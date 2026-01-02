import 'package:cloud_firestore/cloud_firestore.dart';

class PreacherData {
  final String id;
  final String fullName; // Changed from name
  final String email;
  final String phone; // Changed from phoneNumber
  final String icNumber; // New
  final String address; // New
  final String qualification; // New
  final String district;
  final String status;
  final String trainingStatus;
  final int activityCount;

  PreacherData({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.icNumber,
    required this.address,
    required this.qualification,
    required this.district,
    required this.status,
    required this.trainingStatus,
    this.activityCount = 0,
  });

  // Convert from Firebase (Map) to App Object
  factory PreacherData.fromMap(Map<String, dynamic> data, String id) {
    return PreacherData(
      id: id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      icNumber: data['icNumber'] ?? '',
      address: data['address'] ?? '',
      qualification: data['qualification'] ?? '',
      district: data['district'] ?? '',
      status: data['status'] ?? 'Active',
      trainingStatus: data['trainingStatus'] ?? 'pending',
      activityCount: data['activityCount'] ?? 0,
    );
  }

  // Convert from App Object to Firebase (Map)
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'icNumber': icNumber,
      'address': address,
      'qualification': qualification,
      'district': district,
      'status': status,
      'trainingStatus': trainingStatus,
      'activityCount': activityCount,
    };
  }

  // --- Firestore Operations ---
  static final CollectionReference _preachersCollection =
      FirebaseFirestore.instance.collection('preachers');

  // Create
  static Future<void> addPreacher(PreacherData preacher) async {
    if (preacher.id.isEmpty) {
      await _preachersCollection.add(preacher.toMap());
    } else {
      await _preachersCollection.doc(preacher.id).set(preacher.toMap());
    }
  }

  // Read (Stream)
  static Stream<List<PreacherData>> getPreachersStream() {
    return _preachersCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return PreacherData.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  // Read Single
  static Future<PreacherData?> getPreacherById(String id) async {
    DocumentSnapshot doc = await _preachersCollection.doc(id).get();
    if (doc.exists) {
        return PreacherData.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // Update
  static Future<void> updatePreacher(PreacherData preacher) async {
    await _preachersCollection.doc(preacher.id).update(preacher.toMap());
  }
  
  // Specific Update: Status
  static Future<void> updatePreacherStatus(String id, String status) async {
    await _preachersCollection.doc(id).update({'status': status});
  }

  // Delete
  static Future<void> deletePreacher(String id) async {
    await _preachersCollection.doc(id).delete();
  }
}

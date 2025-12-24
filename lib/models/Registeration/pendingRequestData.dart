import 'package:cloud_firestore/cloud_firestore.dart';

class PendingRequestData {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all pending preacher registration requests
  /// Returns a map with 'success' status and 'preachers' list
  Future<Map<String, dynamic>> getPendingPreachers() async {
    try {
      // Query users collection where role is PREACHER and status is PENDING
      QuerySnapshot userSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'PREACHER')
          .where('status', isEqualTo: 'PENDING')
          .get();

      List<Map<String, dynamic>> pendingPreachers = [];

      // Fetch corresponding preacher details for each pending user
      for (var userDoc in userSnapshot.docs) {
        String preacherId = userDoc.id;

        // Get preacher details from preachers collection
        DocumentSnapshot preacherDoc = await _firestore
            .collection('preachers')
            .doc(preacherId)
            .get();

        if (preacherDoc.exists) {
          Map<String, dynamic> preacherData =
              preacherDoc.data() as Map<String, dynamic>;
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          // Combine user and preacher data
          pendingPreachers.add({
            'uid': preacherId,
            'email': userData['email'] ?? '',
            'name': userData['name'] ?? '',
            'fullName': preacherData['fullName'] ?? '',
            'address': preacherData['address'] ?? '',
            'district': preacherData['district'] ?? '',
            'icNumber': preacherData['icNumber'] ?? '',
            'phone': preacherData['phone'] ?? '',
            'qualification': preacherData['qualification'] ?? '',
            'submittedAt': preacherData['submittedAt'],
            'status': userData['status'] ?? 'PENDING',
          });
        }
      }

      return {
        'success': true,
        'preachers': pendingPreachers,
        'message': 'Pending preachers fetched successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'preachers': [],
        'message': 'Error fetching pending preachers: ${e.toString()}',
      };
    }
  }

  /// Get detailed information of a specific preacher
  /// Returns a map with 'success' status and 'preacher' data
  Future<Map<String, dynamic>> getPreacherDetails(String preacherId) async {
    try {
      // Get user data
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(preacherId)
          .get();

      if (!userDoc.exists) {
        return {
          'success': false,
          'preacher': null,
          'message': 'User not found',
        };
      }

      // Get preacher data
      DocumentSnapshot preacherDoc = await _firestore
          .collection('preachers')
          .doc(preacherId)
          .get();

      if (!preacherDoc.exists) {
        return {
          'success': false,
          'preacher': null,
          'message': 'Preacher details not found',
        };
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> preacherData =
          preacherDoc.data() as Map<String, dynamic>;

      // Combine all data
      Map<String, dynamic> preacherDetails = {
        'uid': preacherId,
        'email': userData['email'] ?? '',
        'name': userData['name'] ?? '',
        'role': userData['role'] ?? '',
        'status': userData['status'] ?? '',
        'fullName': preacherData['fullName'] ?? '',
        'address': preacherData['address'] ?? '',
        'district': preacherData['district'] ?? '',
        'icNumber': preacherData['icNumber'] ?? '',
        'phone': preacherData['phone'] ?? '',
        'qualification': preacherData['qualification'] ?? '',
        'submittedAt': preacherData['submittedAt'],
        'reviewedAt': preacherData['reviewedAt'],
        'reviewedBy': preacherData['reviewedBy'],
        'rejectionReason': preacherData['rejectionReason'],
      };

      return {
        'success': true,
        'preacher': preacherDetails,
        'message': 'Preacher details fetched successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'preacher': null,
        'message': 'Error fetching preacher details: ${e.toString()}',
      };
    }
  }

  /// Approve a preacher registration request
  /// Updates status to ACTIVE and records review information
  Future<void> approvePreacherRequest(
    String preacherId,
    String adminUid,
  ) async {
    try {
      // Start a batch write for atomic operation
      WriteBatch batch = _firestore.batch();

      // Update users collection - set status to ACTIVE
      DocumentReference userRef = _firestore
          .collection('users')
          .doc(preacherId);
      batch.update(userRef, {'status': 'ACTIVE'});

      // Update preachers collection - record review information
      DocumentReference preacherRef = _firestore
          .collection('preachers')
          .doc(preacherId);
      batch.update(preacherRef, {
        'reviewedBy': adminUid,
        'reviewedAt': FieldValue.serverTimestamp(),
        'rejectionReason': null,
      });

      // Commit the batch
      await batch.commit();
    } catch (e) {
      throw Exception('Error approving preacher: ${e.toString()}');
    }
  }

  /// Reject a preacher registration request
  /// Updates status to REJECTED and records reason and review information
  Future<void> rejectPreacherRequest(
    String preacherId,
    String adminUid,
    String rejectionReason,
  ) async {
    try {
      // Start a batch write for atomic operation
      WriteBatch batch = _firestore.batch();

      // Update users collection - set status to REJECTED
      DocumentReference userRef = _firestore
          .collection('users')
          .doc(preacherId);
      batch.update(userRef, {'status': 'REJECTED'});

      // Update preachers collection - record review information and reason
      DocumentReference preacherRef = _firestore
          .collection('preachers')
          .doc(preacherId);
      batch.update(preacherRef, {
        'reviewedBy': adminUid,
        'reviewedAt': FieldValue.serverTimestamp(),
        'rejectionReason': rejectionReason,
      });

      // Commit the batch
      await batch.commit();
    } catch (e) {
      throw Exception('Error rejecting preacher: ${e.toString()}');
    }
  }
}

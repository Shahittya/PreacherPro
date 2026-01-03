/// ProfileData Model - Handles profile data structure and serialization
/// Following MVC architecture: This model only contains data structure and toMap/fromMap
class ProfileData {
  // Properties
  final String fullName;
  final String email;
  final String phoneNumber;
  final String address;
  final String role;
  final String district;
  final String qualification;

  // Constructor
  ProfileData({
    this.fullName = '',
    this.email = '',
    this.phoneNumber = '',
    this.address = '',
    this.role = '',
    this.district = '',
    this.qualification = '',
  });

  /// Convert ProfileData object to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'role': role,
      'district': district,
      'qualification': qualification,
    };
  }

  /// Create ProfileData object from Map (from database)
  factory ProfileData.fromMap(Map<String, dynamic> map) {
    return ProfileData(
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      role: map['role'] ?? '',
      district: map['district'] ?? '',
      qualification: map['qualification'] ?? '',
    );
  }
}


/// Payment Model - Handles payment data structure and serialization
/// Following MVC architecture: This model only contains data structure and toMap/fromMap
class Payment {
  final String paymentId;
  final String preacherId;
  final String preacherName;
  final String eventId;
  final String eventTitle;
  final String activityDescription;
  final DateTime eventDate;
  final double requestedAmount;
  final double approvedAmount;
  final String status;
  final String adminStatus;
  final String? address;
  final String? currency;
  final String? rejectionReason;
  final String? adminRejectionReason;
  final bool viewed;

  Payment({
    required this.paymentId,
    required this.preacherId,
    required this.preacherName,
    required this.eventId,
    required this.eventTitle,
    required this.activityDescription,
    required this.eventDate,
    required this.requestedAmount,
    this.approvedAmount = 0.0,
    this.status = 'Pending',
    this.adminStatus = 'Pending',
    this.address,
    this.currency = 'RM',
    this.rejectionReason,
    this.adminRejectionReason,
    this.viewed = false,
  });

  /// Convert Payment object to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': paymentId,
      'preacherId': preacherId,
      'preacher': preacherName,
      'eventId': eventId,
      'eventName': eventTitle,
      'description': activityDescription,
      'date': eventDate.toIso8601String(),
      'amount': approvedAmount,
      'requestedAmount': requestedAmount,
      'status': status,
      'adminStatus': adminStatus,
      'address': address,
      'currency': currency,
      'rejectionReason': rejectionReason,
      'adminRejectionReason': adminRejectionReason,
      'viewed': viewed,
    };
  }

  /// Create Payment object from Map (from database)
  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      paymentId: map['id'] ?? '',
      preacherId: map['preacherId'] ?? '',
      preacherName: map['preacher'] ?? '',
      eventId: map['eventId'] ?? '',
      eventTitle: map['eventName'] ?? '',
      activityDescription: map['description'] ?? '',
      eventDate: map['date'] != null 
          ? DateTime.parse(map['date']) 
          : DateTime.now(),
      requestedAmount: (map['requestedAmount'] ?? map['amount'] ?? 0.0).toDouble(),
      approvedAmount: (map['amount'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'Pending',
      adminStatus: map['adminStatus'] ?? 'Pending',
      address: map['address'],
      currency: map['currency'] ?? 'RM',
      rejectionReason: map['rejectionReason'],
      adminRejectionReason: map['adminRejectionReason'],
      viewed: map['viewed'] ?? false,
    );
  }
}


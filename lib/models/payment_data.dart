/// Payment Model - Handles payment data structure and serialization
/// Following MVC architecture: This model only contains data structure and toMap/fromMap
class Payment {
  final String paymentId;
  final String preacherId;
  final String preacherName;
  final String activityId;
  final String eventName;
  final String description;
  final String eventDate;
  final String? topic;
  final double amount;
  final String status;
  final String adminStatus;
  final String? address;
  final String? currency;
  final String? rejectionReason;
  final String? adminRejectionReason;
  final bool viewed;
  final dynamic requestedDate;
  final dynamic approvedDate;
  final dynamic rejectedDate;
  final String? officerId;
  final String? adminId;

  Payment({
    required this.paymentId,
    required this.preacherId,
    required this.preacherName,
    this.activityId = '',
    this.eventName = '',
    this.description = '',
    this.eventDate = '',
    this.topic,
    this.amount = 0.0,
    this.status = 'pending',
    this.adminStatus = 'pending',
    this.address,
    this.currency = 'RM',
    this.rejectionReason,
    this.adminRejectionReason,
    this.viewed = false,
    this.requestedDate,
    this.approvedDate,
    this.rejectedDate,
    this.officerId,
    this.adminId,
  });

  /// Convert Payment object to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': paymentId,
      'paymentId': paymentId,
      'docId': paymentId,
      'preacherId': preacherId,
      'preacher': preacherName,
      'preacherName': preacherName,
      'activityId': activityId,
      'eventName': eventName,
      'description': description,
      'date': eventDate,
      'eventDate': eventDate,
      'topic': topic,
      'amount': amount,
      'status': status,
      'adminStatus': adminStatus,
      'address': address,
      'currency': currency,
      'rejectionReason': rejectionReason,
      'adminRejectionReason': adminRejectionReason,
      'viewed': viewed,
      'requestedDate': requestedDate,
      'approvedDate': approvedDate,
      'rejectedDate': rejectedDate,
      'officerId': officerId,
      'adminId': adminId,
    };
  }

  /// Create Payment object from Map (from database)
  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      paymentId: map['id'] ?? map['paymentId'] ?? map['docId'] ?? '',
      preacherId: map['preacherId'] ?? '',
      preacherName: map['preacher'] ?? map['preacherName'] ?? 'Unknown',
      activityId: map['activityId'] ?? '',
      eventName: map['eventName'] ?? '',
      description: map['description'] ?? '',
      eventDate: map['date'] ?? map['eventDate'] ?? '',
      topic: map['topic'],
      amount: (map['amount'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'pending',
      adminStatus: map['adminStatus'] ?? map['status'] ?? 'pending',
      address: map['address'],
      currency: map['currency'] ?? 'RM',
      rejectionReason: map['rejectionReason'],
      adminRejectionReason: map['adminRejectionReason'],
      viewed: map['viewed'] ?? false,
      requestedDate: map['requestedDate'],
      approvedDate: map['approvedDate'],
      rejectedDate: map['rejectedDate'],
      officerId: map['officerId'],
      adminId: map['adminId'],
    );
  }
  
  /// Create a copy of Payment with updated fields
  Payment copyWith({
    String? paymentId,
    String? preacherId,
    String? preacherName,
    String? activityId,
    String? eventName,
    String? description,
    String? eventDate,
    String? topic,
    double? amount,
    String? status,
    String? adminStatus,
    String? address,
    String? currency,
    String? rejectionReason,
    String? adminRejectionReason,
    bool? viewed,
    dynamic requestedDate,
    dynamic approvedDate,
    dynamic rejectedDate,
    String? officerId,
    String? adminId,
  }) {
    return Payment(
      paymentId: paymentId ?? this.paymentId,
      preacherId: preacherId ?? this.preacherId,
      preacherName: preacherName ?? this.preacherName,
      activityId: activityId ?? this.activityId,
      eventName: eventName ?? this.eventName,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      topic: topic ?? this.topic,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      adminStatus: adminStatus ?? this.adminStatus,
      address: address ?? this.address,
      currency: currency ?? this.currency,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      adminRejectionReason: adminRejectionReason ?? this.adminRejectionReason,
      viewed: viewed ?? this.viewed,
      requestedDate: requestedDate ?? this.requestedDate,
      approvedDate: approvedDate ?? this.approvedDate,
      rejectedDate: rejectedDate ?? this.rejectedDate,
      officerId: officerId ?? this.officerId,
      adminId: adminId ?? this.adminId,
    );
  }
}


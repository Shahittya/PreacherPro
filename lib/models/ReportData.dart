import 'package:cloud_firestore/cloud_firestore.dart';

class ReportData {
  final String id;
  final String preacherId;
  final String preacherName;
  final String type; // 'activity', 'kpi', 'payment'
  final String month;
  final int year;
  final DateTime date;
  final int activityCount;
  final Map<String, dynamic> details;

  ReportData({
    required this.id,
    required this.preacherId,
    required this.preacherName,
    required this.type,
    required this.month,
    required this.year,
    required this.date,
    this.activityCount = 0,
    this.details = const {},
  });

  // Convert from Firebase (Map) to App Object
  factory ReportData.fromMap(Map<String, dynamic> data, String id) {
    return ReportData(
      id: id,
      preacherId: data['preacherId'] ?? '',
      preacherName: data['preacherName'] ?? '',
      type: data['type'] ?? 'activity',
      month: data['month'] ?? '',
      year: data['year'] ?? DateTime.now().year,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      activityCount: data['activityCount'] ?? 0,
      details: data['details'] ?? {},
    );
  }

  // Convert from App Object to Firebase (Map)
  Map<String, dynamic> toMap() {
    return {
      'preacherId': preacherId,
      'preacherName': preacherName,
      'type': type,
      'month': month,
      'year': year,
      'date': Timestamp.fromDate(date),
      'activityCount': activityCount,
      'details': details,
    };
  }

  // --- Firestore Operations ---
  static final CollectionReference _reportsCollection =
      FirebaseFirestore.instance.collection('reports');

  // Create
  static Future<void> addReport(ReportData report) async {
    if (report.id.isEmpty) {
      await _reportsCollection.add(report.toMap());
    } else {
      await _reportsCollection.doc(report.id).set(report.toMap());
    }
  }

  // Read (Stream) - All reports
  static Stream<List<ReportData>> getReportsStream() {
    return _reportsCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ReportData.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  // Read (Stream) - Filtered by type
  static Stream<List<ReportData>> getReportsByTypeStream(String type) {
    return _reportsCollection
        .where('type', isEqualTo: type)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ReportData.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  // Read Single
  static Future<ReportData?> getReportById(String id) async {
    DocumentSnapshot doc = await _reportsCollection.doc(id).get();
    if (doc.exists) {
      return ReportData.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // Get Monthly Activity Stats (for chart)
  static Future<Map<String, int>> getMonthlyActivityStats(int year) async {
    QuerySnapshot snapshot = await _reportsCollection
        .where('year', isEqualTo: year)
        .where('type', isEqualTo: 'activity')
        .get();

    Map<String, int> monthlyStats = {
      'Jan': 0, 'Feb': 0, 'Mar': 0, 'Apr': 0,
      'May': 0, 'Jun': 0, 'Jul': 0, 'Aug': 0,
      'Sep': 0, 'Oct': 0, 'Nov': 0, 'Dec': 0,
    };

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      String month = data['month'] ?? '';
      int count = data['activityCount'] ?? 0;
      if (monthlyStats.containsKey(month)) {
        monthlyStats[month] = monthlyStats[month]! + count;
      }
    }

    return monthlyStats;
  }

  // Update
  static Future<void> updateReport(ReportData report) async {
    await _reportsCollection.doc(report.id).update(report.toMap());
  }

  // Delete
  static Future<void> deleteReport(String id) async {
    await _reportsCollection.doc(id).delete();
  }

  // Seed sample data for testing
  static Future<void> seedSampleReports() async {
    final sampleData = [
      {
        'preacherId': 'preacher1',
        'preacherName': 'Ali Ahmad',
        'type': 'activity',
        'month': 'Jan',
        'year': 2026,
        'date': Timestamp.fromDate(DateTime(2026, 1, 15)),
        'activityCount': 8,
        'details': {'lectures': 5, 'workshops': 3},
      },
      {
        'preacherId': 'preacher2',
        'preacherName': 'Siti Fatimah',
        'type': 'activity',
        'month': 'Feb',
        'year': 2026,
        'date': Timestamp.fromDate(DateTime(2026, 2, 10)),
        'activityCount': 5,
        'details': {'lectures': 3, 'workshops': 2},
      },
      {
        'preacherId': 'preacher3',
        'preacherName': 'Ahmad Hassan',
        'type': 'activity',
        'month': 'Mar',
        'year': 2026,
        'date': Timestamp.fromDate(DateTime(2026, 3, 20)),
        'activityCount': 12,
        'details': {'lectures': 8, 'workshops': 4},
      },
      {
        'preacherId': 'preacher1',
        'preacherName': 'Ali Ahmad',
        'type': 'kpi',
        'month': 'Jan',
        'year': 2026,
        'date': Timestamp.fromDate(DateTime(2026, 1, 31)),
        'activityCount': 0,
        'details': {'score': 85, 'target': 100},
      },
      {
        'preacherId': 'preacher2',
        'preacherName': 'Siti Fatimah',
        'type': 'payment',
        'month': 'Feb',
        'year': 2026,
        'date': Timestamp.fromDate(DateTime(2026, 2, 28)),
        'activityCount': 0,
        'details': {'amount': 1500.00, 'status': 'paid'},
      },
    ];

    for (var data in sampleData) {
      await _reportsCollection.add(data);
    }
  }

  // Check if reports collection has data
  static Future<bool> hasData() async {
    QuerySnapshot snapshot = await _reportsCollection.limit(1).get();
    return snapshot.docs.isNotEmpty;
  }
}

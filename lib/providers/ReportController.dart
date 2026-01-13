import 'package:flutter/material.dart';
import '../models/ReportData.dart';

class ReportController extends ChangeNotifier {
  String _selectedType = 'activity';
  String _searchQuery = '';
  DateTime? _fromDate;
  DateTime? _toDate;

  // Getters
  String get selectedType => _selectedType;
  String get searchQuery => _searchQuery;
  DateTime? get fromDate => _fromDate;
  DateTime? get toDate => _toDate;

  // Stream for all reports
  Stream<List<ReportData>> get reportsStream => ReportData.getReportsStream();

  // Stream for filtered reports by type
  Stream<List<ReportData>> getReportsByType(String type) {
    return ReportData.getReportsByTypeStream(type);
  }

  // Set selected tab type
  void setSelectedType(String type) {
    _selectedType = type;
    notifyListeners();
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  // Set date filter
  void setDateFilter(DateTime? from, DateTime? to) {
    _fromDate = from;
    _toDate = to;
    notifyListeners();
  }

  // Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _fromDate = null;
    _toDate = null;
    notifyListeners();
  }

  // Filter reports locally
  List<ReportData> filterReports(List<ReportData> reports) {
    return reports.where((report) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        if (!report.preacherName.toLowerCase().contains(_searchQuery)) {
          return false;
        }
      }

      // Date range filter
      if (_fromDate != null && report.date.isBefore(_fromDate!)) {
        return false;
      }
      if (_toDate != null && report.date.isAfter(_toDate!.add(const Duration(days: 1)))) {
        return false;
      }

      return true;
    }).toList();
  }

  // Get monthly activity statistics for chart
  Future<Map<String, int>> getMonthlyStats(int year) async {
    return await ReportData.getMonthlyActivityStats(year);
  }

  // CRUD wrappers
  Future<void> addReport(ReportData report) async {
    await ReportData.addReport(report);
    notifyListeners();
  }

  Future<void> updateReport(ReportData report) async {
    await ReportData.updateReport(report);
    notifyListeners();
  }

  Future<void> deleteReport(String id) async {
    await ReportData.deleteReport(id);
    notifyListeners();
  }

  Future<ReportData?> getReportById(String id) {
    return ReportData.getReportById(id);
  }
}

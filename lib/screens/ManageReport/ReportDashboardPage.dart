import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ReportData.dart';
import '../../models/PreacherData.dart';
import '../../providers/ReportController.dart';
import '../../providers/PreacherController.dart';
import 'ReportFilterModal.dart';
import 'ReportDetailModal.dart';
import 'GenerateSummaryModal.dart';
import 'ExportSuccessDialog.dart';
import 'SummaryReportScreen.dart';

class ReportDashboardPage extends StatefulWidget {
  const ReportDashboardPage({super.key});

  @override
  State<ReportDashboardPage> createState() => _ReportDashboardPageState();
}

class _ReportDashboardPageState extends State<ReportDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedCategory = 'All';
  DateTime? _fromDate;
  DateTime? _toDate;
  Map<String, int> _monthlyStats = {};

  final List<String> _tabs = ['Activity', 'KPI', 'Payment', 'Summary'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadMonthlyStats();
  }

  Future<void> _loadMonthlyStats() async {
    final controller = Provider.of<ReportController>(context, listen: false);
    final stats = await controller.getMonthlyStats(DateTime.now().year);
    setState(() {
      _monthlyStats = stats;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterModal() {
    showDialog(
      context: context,
      builder: (context) => ReportFilterModal(
        initialFromDate: _fromDate,
        initialToDate: _toDate,
        initialCategory: _selectedCategory,
        onApply: (from, to, category) {
          setState(() {
            _fromDate = from;
            _toDate = to;
            _selectedCategory = category;
          });
          Provider.of<ReportController>(context, listen: false)
              .setDateFilter(from, to);
        },
      ),
    );
  }

  void _showReportDetail(ReportData report) {
    showDialog(
      context: context,
      builder: (context) => ReportDetailModal(report: report),
    );
  }

  void _generateSummaryReport() {
    showDialog(
      context: context,
      builder: (context) => GenerateSummaryModal(
        onExport: (month, district, reportType) async {
          // Get preachers data
          final preacherController = Provider.of<PreacherController>(context, listen: false);
          
          // Fetch preachers once
          final preachers = await PreacherData.getPreachersStream().first;
          
          if (mounted) {
            // Navigate to summary report screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SummaryReportScreen(
                  month: month,
                  district: district,
                  reportType: reportType,
                  preachers: preachers,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  void _exportReport() {
    showDialog(
      context: context,
      builder: (context) => GenerateSummaryModal(
        onExport: (month, district, reportType) {
          // Simulate export process
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              ExportSuccessDialog.show(context);
            }
          });
        },
      ),
    );
  }

  Future<void> _seedSampleData() async {
    // Check if data already exists
    bool hasData = await ReportData.hasData();
    if (hasData) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sample data already exists!'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      await ReportData.seedSampleReports();
      await _loadMonthlyStats(); // Refresh chart data
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sample data added successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportController = Provider.of<ReportController>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: const Color(0xFF3B5998),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Seed sample data button (for testing)
          IconButton(
            icon: const Icon(Icons.add_chart),
            onPressed: _seedSampleData,
            tooltip: 'Seed Sample Data',
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: _exportReport,
            tooltip: 'Export',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Report Dashboard',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[700],
              indicator: BoxDecoration(
                color: const Color(0xFF3B5998),
                borderRadius: BorderRadius.circular(20),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: _tabs.map((tab) => Tab(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(tab),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Search Bar and Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Activity reports by pr...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                reportController.setSearchQuery('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      reportController.setSearchQuery(value);
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.tune,
                      color: (_fromDate != null || _toDate != null)
                          ? const Color(0xFF3B5998)
                          : Colors.grey[600],
                    ),
                    onPressed: _showFilterModal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Monthly Activities Chart
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monthly Activities',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  child: _buildBarChart(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Activity Reports List
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Activity Reports',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Reports List - Show Preachers
          Expanded(
            child: StreamBuilder<List<PreacherData>>(
              stream: Provider.of<PreacherController>(context, listen: false).preachersStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<PreacherData> preachers = snapshot.data ?? [];
                
                // Apply search filter
                if (_searchController.text.isNotEmpty) {
                  preachers = preachers.where((p) => 
                    p.fullName.toLowerCase().contains(_searchController.text.toLowerCase())
                  ).toList();
                }

                if (preachers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, 
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No preachers found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: preachers.length,
                  itemBuilder: (context, index) {
                    final preacher = preachers[index];
                    return _buildPreacherReportCard(preacher);
                  },
                );
              },
            ),
          ),

          // Generate Summary Report Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _generateSummaryReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B5998),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Generate Summary Report',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    // Get the first 3 months for display
    final months = ['Jan', 'Feb', 'Mar'];
    final maxValue = _monthlyStats.values.isEmpty 
        ? 12 
        : (_monthlyStats.values.reduce((a, b) => a > b ? a : b)).toDouble();
    final chartMax = maxValue > 0 ? maxValue : 12;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Y-axis labels
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${chartMax.toInt()}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text('${(chartMax * 0.75).toInt()}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text('${(chartMax * 0.5).toInt()}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text('${(chartMax * 0.25).toInt()}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text('0', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        const SizedBox(width: 8),
        // Bars
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: months.map((month) {
              final value = _monthlyStats[month]?.toDouble() ?? 0;
              final barHeight = chartMax > 0 ? (value / chartMax) * 120 : 0.0;
              
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Value label on top
                  if (value > 0)
                    Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3B5998),
                      ),
                    ),
                  const SizedBox(height: 4),
                  // Bar
                  Container(
                    width: 50,
                    height: barHeight > 0 ? barHeight : 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B8DD6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Month label
                  Text(
                    month,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildReportCard(ReportData report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _showReportDetail(report),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.preacherName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.month,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreacherReportCard(PreacherData preacher) {
    // Get month based on activity - for demo, using current or random month
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final currentMonth = months[DateTime.now().month - 1];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            // Show preacher report detail
            showDialog(
              context: context,
              builder: (context) => Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Report Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        preacher.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentMonth,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Activities: ${preacher.activityCount} activities\nTraining: ${preacher.trainingStatus}\nDistrict: ${preacher.district}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B5998),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preacher.fullName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentMonth,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

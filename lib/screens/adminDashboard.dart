import 'package:flutter/material.dart';
import 'home_screen.dart';

// Models & Providers
import '../models/ActivityData.dart';
import '../providers/ActvitiyController.dart';
import '../providers/Login/LoginController.dart';

// Pages
import 'ManageActivity/admin/adminActivityList.dart';
import 'ManagePreacher/PreacherManagementPage.dart';
import 'ManageProfile/userProfilePage.dart';
import 'Registeration/officerRegisterPage.dart';
import 'Registeration/registrationRequestPage.dart';
import 'ManagePayment/muip_admin_payment_page.dart';
import 'ManageReport/ReportDashboardPage.dart'; // From Current

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  // Use IndexedStack to keep all page states alive
  final List<Widget> _pages = [
    const _DashboardPage(),           // 0: Dashboard Home
    const PreacherManagementPage(),   // 1: Preacher List
    const ReportDashboardPage(),      // 2: Reports (From Current)
    const RegistrationRequestPage(),  // 3: Requests
    const OfficerRegisterPage(),      // 4: Add MUIP/Officer
    const MuipAdminPaymentPage(),     // 5: Payments
    const UserProfilePage(),          // 6: Profile
  ];

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout(BuildContext context) async {
    final controller = LoginController();
    Map<String, dynamic> result = await controller.logout();

    if (context.mounted) {
      if (result['success']) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              title: Row(
                children: [
                  const SizedBox(width: 16),
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.admin_panel_settings, size: 22, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Welcome back', style: TextStyle(fontSize: 12)),
                      Text('MUIP Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
                IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context)),
              ],
            )
          : null, // Sub-pages typically handle their own AppBars or use a generic one
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Preachers'),
          BottomNavigationBarItem(icon: Icon(Icons.assessment), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.person_add), label: 'Add MUIP'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Payment'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard Page Content (Stateful to handle filters and real-time streams)
// ---------------------------------------------------------------------------
class _DashboardPage extends StatefulWidget {
  const _DashboardPage({Key? key}) : super(key: key);

  @override
  State<_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<_DashboardPage> {
  final _activityController = ActivityController();
  String _searchQuery = '';
  String _timeFilter = 'all';

  // Logic for filtering activities
  List<ActivityData> _applyFilters(List<ActivityData> activities) {
    final now = DateTime.now();
    return activities.where((a) {
      // Search logic
      final matchesSearch = _searchQuery.isEmpty || 
          a.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.locationName.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Time filter logic
      if (!matchesSearch) return false;
      if (_timeFilter == 'all') return true;

      final parsed = _parseDate(a.activityDate);
      if (parsed == null) return false;

      if (_timeFilter == 'today') return parsed.day == now.day && parsed.month == now.month;
      if (_timeFilter == 'week') return now.difference(parsed).inDays <= 7;
      
      return true;
    }).toList();
  }

  DateTime? _parseDate(String date) {
    try {
      if (date.contains('/')) {
        final parts = date.split('/');
        return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }
      return DateTime.parse(date);
    } catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return StreamBuilder<List<ActivityData>>(
      stream: _activityController.activitiesStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final activities = snapshot.data!;
        final filtered = _applyFilters(activities);
        final openCount = activities.where((a) => a.status.toLowerCase() != 'approved').length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _DashboardHero(
                scheme: scheme,
                openCount: openCount,
                submissionCount: activities.length,
                onOpenTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminActivityList())),
                onSubmissionTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportDashboardPage())),
              ),
              const SizedBox(height: 20),
              _SearchAndFilters(
                scheme: scheme,
                initialQuery: _searchQuery,
                initialFilter: _timeFilter,
                onQueryChanged: (v) => setState(() => _searchQuery = v),
                onFilterChanged: (v) => setState(() => _timeFilter = v),
              ),
              const SizedBox(height: 20),
              _SectionHeader(
                title: 'Upcoming Activities',
                actionLabel: 'See all',
                onActionTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminActivityList())),
              ),
              ...filtered.take(5).map((activity) => _ActivityCard(
                scheme: scheme,
                title: activity.title,
                subtitle: activity.locationName,
                dateText: activity.activityDate,
                timeText: '${activity.startTime} - ${activity.endTime}',
                status: activity.status,
                badgeText: activity.topic,
              )),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Helper Widgets (Keep from Incoming version for the Modern UI)
// ---------------------------------------------------------------------------

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({required this.scheme, required this.openCount, required this.submissionCount, required this.onOpenTap, required this.onSubmissionTap});
  final ColorScheme scheme; final int openCount; final int submissionCount; final VoidCallback onOpenTap; final VoidCallback onSubmissionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.deepPurple, Colors.deepPurple.shade300]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Admin Activity Hub', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _StatPill(label: 'Pending', value: '$openCount', icon: Icons.pending, onTap: onOpenTap)),
              const SizedBox(width: 10),
              Expanded(child: _StatPill(label: 'Total Reports', value: '$submissionCount', icon: Icons.description, onTap: onSubmissionTap)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value, required this.icon, required this.onTap});
  final String label; final String value; final IconData icon; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ]),
        ]),
      ),
    );
  }
}

// Search, Filters, ActivityCard, and SectionHeader classes should be kept 
// exactly as they were in the 'incoming' version to maintain the styled list view.

class _SearchAndFilters extends StatelessWidget {
  const _SearchAndFilters({required this.scheme, required this.initialQuery, required this.initialFilter, required this.onQueryChanged, required this.onFilterChanged});
  final ColorScheme scheme; final String initialQuery; final String initialFilter; final ValueChanged<String> onQueryChanged; final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TextField(
        onChanged: onQueryChanged,
        decoration: InputDecoration(
          hintText: 'Search activities...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 10),
      Row(children: [
        FilterChip(label: const Text('All'), selected: initialFilter == 'all', onSelected: (_) => onFilterChanged('all')),
        const SizedBox(width: 8),
        FilterChip(label: const Text('Today'), selected: initialFilter == 'today', onSelected: (_) => onFilterChanged('today')),
      ]),
    ]);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.actionLabel, required this.onActionTap});
  final String title; final String actionLabel; final VoidCallback onActionTap;
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      TextButton(onPressed: onActionTap, child: Text(actionLabel)),
    ]);
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.scheme, required this.title, required this.subtitle, required this.dateText, required this.timeText, required this.status, required this.badgeText});
  final ColorScheme scheme; final String title; final String subtitle; final String dateText; final String timeText; final String status; final String badgeText;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$subtitle\n$dateText • $timeText'),
        isThreeLine: true,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.deepPurple.shade50, borderRadius: BorderRadius.circular(8)),
          child: Text(status, style: const TextStyle(color: Colors.deepPurple, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
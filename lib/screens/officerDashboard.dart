import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

// Controllers & Providers
import '../providers/Login/LoginController.dart';
import '../providers/ActvitiyController.dart';
import '../providers/PreacherController.dart';

// Models
import '../models/ActivityData.dart';
import '../models/Notification.dart';
import '../models/PreacherData.dart';

// Pages
import 'ManageProfile/userProfilePage.dart';
import 'ManageActivity/officer/officerActivityList.dart';
import 'ManageActivity/officer/assignActivity.dart';
import 'ManagePayment/payment_page.dart';
import 'ManagePreacher/PreacherManagementPage.dart';
import 'ManageReport/ReportDashboardPage.dart';
import 'ManageKPI/ManageKPIPage.dart';

class OfficerDashboard extends StatefulWidget {
  const OfficerDashboard({super.key});

  @override
  State<OfficerDashboard> createState() => _OfficerDashboardState();
}

class _OfficerDashboardState extends State<OfficerDashboard> {
  int _selectedIndex = 0;

  // The IndexedStack keeps the state of pages alive when switching tabs
  final List<Widget> _pages = [
    const _DashboardBody(),              // Index 0
    const PreacherManagementPage(),      // Index 1 (From Current)
    const OfficerActivityList(),         // Index 2 (From Incoming)
    const ManageKPIPage(),               // Index 3 (From Current)
    const ReportDashboardPage(),         // Index 4 (From Current)
    const PaymentPage(),                 // Index 5
    const UserProfilePage(),             // Index 6
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
          SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      // Show AppBar only on the Dashboard tab
      appBar: _selectedIndex == 0
          ? AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.amber.shade600,
              foregroundColor: Colors.white,
              title: _buildAppBarTitle(currentUser),
              actions: [
                IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
                IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context)),
              ],
            )
          : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber.shade700,
        unselectedItemColor: Colors.grey[600],
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Preachers'),
          BottomNavigationBarItem(icon: Icon(Icons.event_outlined), label: 'Activities'),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'KPI'),
          BottomNavigationBarItem(icon: Icon(Icons.assessment_outlined), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildAppBarTitle(User? user) {
    return StreamBuilder<DocumentSnapshot>(
      stream: user != null 
          ? FirebaseFirestore.instance.collection('officers').doc(user.uid).snapshots() 
          : null,
      builder: (context, snapshot) {
        String name = 'Officer';
        if (snapshot.hasData && snapshot.data!.exists) {
          name = snapshot.data!.get('fullName') ?? 'Officer';
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome,', style: TextStyle(fontSize: 12)),
            Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        );
      },
    );
  }
}

class _DashboardBody extends StatefulWidget {
  const _DashboardBody();

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  final activityController = ActivityController();
  int _totalPreachers = 0;
  int _activePreachers = 0;

  @override
  void initState() {
    super.initState();
    _loadPreacherStats();
  }

  Future<void> _loadPreacherStats() async {
    final preachers = await PreacherData.getPreachersStream().first;
    if (mounted) {
      setState(() {
        _totalPreachers = preachers.length;
        _activePreachers = preachers.where((p) => p.status.toLowerCase() == 'active').length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ActivityData>>(
      stream: activityController.activitiesStream(),
      builder: (context, snapshot) {
        final activities = snapshot.data ?? [];
        final pendingCount = activities.where((a) => a.status.toLowerCase() == 'pending').length;

        return CustomScrollView(
          slivers: [
            // Header with Unified Stats
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade600, Colors.amber.shade700],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Overall Statistics', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _statCard('Preachers', _totalPreachers),
                          _statCard('Active', _activePreachers),
                          _statCard('Pending Reports', pendingCount),
                          _statCard('Total Activities', activities.length),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Quick Actions from Current version
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.5,
                      children: [
                        _actionCard(context, Icons.person_add, 'Add Preacher', Colors.blue, () {
                           // Logic to navigate or open form
                        }),
                        _actionCard(context, Icons.assignment_add, 'Assign Activity', Colors.orange, () {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignActivityForm()));
                        }),
                        _actionCard(context, Icons.trending_up, 'Set KPI', Colors.green, () {
                           // Trigger KPI logic
                        }),
                        _actionCard(context, Icons.location_on, 'GPS Track', Colors.red, () {}),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Recent Submissions List from Incoming version
            if (activities.any((a) => a.status.toLowerCase() == 'pending'))
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Recent Pending Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final pending = activities.where((a) => a.status.toLowerCase() == 'pending').toList();
                    if (index >= pending.length) return null;
                    return _buildReportItem(pending[index]);
                  },
                  childCount: activities.where((a) => a.status.toLowerCase() == 'pending').length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, int value) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('$value', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _actionCard(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem(ActivityData activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(activity.title),
        subtitle: Text(activity.preacherName ?? 'Preacher'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to review report
        },
      ),
    );
  }
}
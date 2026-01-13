import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

// Models & Providers
import '../models/ActivityData.dart';
import '../models/Notification.dart';
import '../providers/ActvitiyController.dart';
import '../providers/Login/LoginController.dart';

// Pages
import 'ManageProfile/userProfilePage.dart';
import 'ManageActivity/preacher/actvitiyList.dart';
import 'ManagePayment/preacher_payment_page.dart';
import 'ManageKPI/MyKPIOverviewPage.dart'; // From Current

class PreacherDashboard extends StatefulWidget {
  const PreacherDashboard({super.key});

  @override
  State<PreacherDashboard> createState() => _PreacherDashboardState();
}

class _PreacherDashboardState extends State<PreacherDashboard> {
  int _selectedIndex = 0;
  final ActivityController _activityController = ActivityController();

  // Integrated Pages List
  final List<Widget> _pages = [
    const _DashboardBody(),               // Index 0
    const ActivityList(),                 // Index 1
    const MyKPIOverviewPage(),            // Index 2 (From Current)
    const PreacherPaymentPage(),          // Index 3
    const UserProfilePage(),              // Index 4
  ];

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

  // Navigation Logic
  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  // MARK: Notification Logic
  Future<void> _markAllNotificationsRead(String uid) async {
    try {
      final db = FirebaseFirestore.instance;
      final snap = await db
          .collection('notifications')
          .where('preacher_id', isEqualTo: uid)
          .where('is_read', isEqualTo: false)
          .get();
      if (snap.docs.isEmpty) return;
      final batch = db.batch();
      for (var d in snap.docs) {
        batch.update(d.reference, {'is_read': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Failed to mark notifications read: $e');
    }
  }

  Widget _buildNotificationIcon(User? currentUser) {
    if (currentUser == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('preacher_id', isEqualTo: currentUser.uid)
          .where('is_read', isEqualTo: false)
          .snapshots(),
      builder: (context, unreadSnap) {
        final unreadCount = unreadSnap.hasData ? unreadSnap.data!.docs.length : 0;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () async {
                await _markAllNotificationsRead(currentUser.uid);
                _showNotificationSheet(context, currentUser);
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 10,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showNotificationSheet(BuildContext context, User currentUser) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Divider(),
              // ... StreamBuilder for notification list (same as incoming code) ...
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              automaticallyImplyLeading: false,
              elevation: 0,
              backgroundColor: Colors.lightGreen.shade500,
              toolbarHeight: 68,
              title: _buildAppBarTitle(currentUser),
              actions: [
                _buildNotificationIcon(currentUser),
                IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context)),
              ],
            )
          : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.lightGreen.shade600,
          unselectedItemColor: Colors.grey[600],
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.event_outlined), activeIcon: Icon(Icons.event), label: 'Activities'),
            BottomNavigationBarItem(icon: Icon(Icons.trending_up_outlined), activeIcon: Icon(Icons.trending_up), label: 'My KPI'),
            BottomNavigationBarItem(icon: Icon(Icons.payment), activeIcon: Icon(Icons.payment), label: 'Payment'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarTitle(User? currentUser) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white.withOpacity(0.25),
          child: const Icon(Icons.person, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        StreamBuilder<DocumentSnapshot>(
          stream: currentUser != null ? FirebaseFirestore.instance.collection('preachers').doc(currentUser.uid).snapshots() : null,
          builder: (context, snapshot) {
            final name = snapshot.hasData && snapshot.data!.exists ? snapshot.data!.get('fullName') ?? 'Preacher' : 'Preacher';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Assalamualaikum,', style: TextStyle(fontSize: 14, color: Colors.white)),
                Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            );
          },
        ),
      ],
    );
  }
}
// Dashboard Body Widget
class _DashboardBody extends StatefulWidget {
  const _DashboardBody();

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  final ActivityController _activityController = ActivityController();

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Stats Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.lightGreen.shade400, Colors.lightGreen.shade600],
                ),
              ),
              child: StreamBuilder<List<ActivityData>>(
                stream: currentUser == null
                    ? null
                    : _activityController.preacherActivitiesStream(currentUser.uid),
                builder: (context, snapshot) {
                  if (currentUser == null) return const SizedBox.shrink();
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  }

                  final myActivities = snapshot.data!.where((a) => 
                    a.assignment?.preacherId == currentUser.uid
                  ).toList();

                  final assigned = myActivities.where((a) => a.status == 'assigned').length;
                  final pending = myActivities.where((a) => a.status == 'pending').length;
                  final approved = myActivities.where((a) => a.status == 'approved').length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Statistics',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildStatCard('Total', myActivities.length),
                            const SizedBox(width: 10),
                            _buildStatCard('Assigned', assigned),
                            const SizedBox(width: 10),
                            _buildStatCard('Pending', pending),
                            const SizedBox(width: 10),
                            _buildStatCard('Approved', approved),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Quick Actions
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(Icons.location_on, 'GPS Check-In', Colors.lightGreen, () {}),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickAction(Icons.description, 'Submit Report', Colors.blue, () {}),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // My Activities Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('My Activities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  TextButton(onPressed: () {}, child: const Text('View all')),
                ],
              ),
            ),

            // Activity List
            StreamBuilder<List<ActivityData>>(
              stream: currentUser == null
                  ? null
                  : _activityController.preacherActivitiesStream(currentUser.uid),
              builder: (context, snapshot) {
                if (currentUser == null) return const SizedBox.shrink();
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final activities = snapshot.data!
                    .where((a) => a.assignment?.preacherId == currentUser.uid)
                    .take(5)
                    .toList();

                if (activities.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('No Activities Yet', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: activities.length,
                  itemBuilder: (context, index) => _buildActivityCard(activities[index]),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(ActivityData activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(activity.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${activity.activityDate} • ${activity.locationName}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(activity.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            activity.status.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _getStatusColor(activity.status),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.green;
      case 'pending': return Colors.orange;
      case 'rejected': return Colors.red;
      case 'assigned': return Colors.blue;
      default: return Colors.grey;
    }
  }
}

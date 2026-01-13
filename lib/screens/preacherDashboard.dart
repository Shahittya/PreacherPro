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

// ... Keep the rest of the _DashboardBody and helper classes from the Incoming version ...
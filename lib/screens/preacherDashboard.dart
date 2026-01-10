import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import '../models/ActivityData.dart';
import '../models/Notification.dart';
import '../providers/ActvitiyController.dart';
import '../providers/Login/LoginController.dart';
import 'ManageProfile/userProfilePage.dart';
import 'ManageActivity/preacher/actvitiyList.dart';
import 'ManagePayment/preacher_payment_page.dart';

class PreacherDashboard extends StatefulWidget {
  const PreacherDashboard({super.key});

  @override
  State<PreacherDashboard> createState() => _PreacherDashboardState();
}

class _PreacherDashboardState extends State<PreacherDashboard> {
  int _selectedIndex = 0;
  final ActivityController _activityController = ActivityController();

  final List<Widget> _pages = [
    // index 0 - dashboard
    const _DashboardBody(),
    // index 1 - activities
    const ActivityList(),
    // index 2 - preachers (placeholder)
    const Center(child: Text('Preachers')),
    // index 3 - reports (placeholder)
    const Center(child: Text('Reports')),
    // index 4 - payment
    const PreacherPaymentPage(),
    // index 5 - profile
    const UserProfilePage(),
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
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
      // Soft-fail: keep UI responsive if marking read fails
      debugPrint('Failed to mark notifications read: $e');
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
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
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (ctx) {
                    return SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  'Notifications',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                ),
                                Icon(Icons.notifications),
                              ],
                            ),
                            const SizedBox(height: 12),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('notifications')
                                  .where('preacher_id', isEqualTo: currentUser.uid)
                                  .limit(10)
                                  .snapshots(),
                              builder: (context, snap) {
                                if (snap.hasError) {
                                  return Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      'Failed to load notifications. ${snap.error}',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  );
                                }
                                if (!snap.hasData) {
                                  return const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }
                                final items = snap.data!.docs
                                    .map((d) => ActivityNotification.fromDoc(d))
                                    .toList()
                                  ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
                                if (items.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Text('No notifications yet.'),
                                  );
                                }
                                return ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: items.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (context, index) => _NotificationItem(items[index]),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 10,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
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
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    child: const Icon(Icons.person, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  StreamBuilder<DocumentSnapshot>(
                    stream: currentUser != null
                        ? FirebaseFirestore.instance
                            .collection('preachers')
                            .doc(currentUser.uid)
                            .snapshots()
                        : null,
                    builder: (context, snapshot) {
                      final name = snapshot.hasData && snapshot.data!.exists
                          ? snapshot.data!.get('fullName') ?? 'Preacher'
                          : 'Preacher';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                          'Assalamualaikum,',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              actions: [
                _buildNotificationIcon(currentUser),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _logout(context),
                ),
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
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.lightGreen.shade600,
          unselectedItemColor: Colors.grey[600],
          backgroundColor: Colors.white,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_outlined),
              activeIcon: Icon(Icons.event),
              label: 'Activities',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Preachers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assessment_outlined),
              activeIcon: Icon(Icons.assessment),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.payment),
              activeIcon: Icon(Icons.payment),
              label: 'Payment',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// small extracted dashboard body to keep _pages clean
class _DashboardBody extends StatefulWidget {
  const _DashboardBody();

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  final ActivityController _activityController = ActivityController();
  String _timeFilter = 'all';

  DateTime? _safeParseDate(String dateStr) {
    try {
      final s = dateStr.trim();
      if (s.isEmpty) return null;
      if (s.contains('/')) {
        final parts = s.split('/');
        if (parts.length == 3) {
          final d = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          final y = int.parse(parts[2]);
          return DateTime(y, m, d);
        }
      } else if (s.contains('-')) {
        // Try ISO first (YYYY-MM-DD)
        try {
          return DateTime.parse(s);
        } catch (_) {
          // Fallback for DD-MM-YYYY
          final parts = s.split('-');
          if (parts.length == 3) {
            final d = int.parse(parts[0]);
            final m = int.parse(parts[1]);
            final y = int.parse(parts[2]);
            return DateTime(y, m, d);
          }
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {

  void _goToActivitiesTab(BuildContext context) {
    final parent = context.findAncestorStateOfType<_PreacherDashboardState>();
    parent?._onItemTapped(1);
  }
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
                  if (currentUser == null) {
                    return const SizedBox.shrink();
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  }

                  final allActivities = snapshot.data!;
                  final myActivities = allActivities.where((a) => 
                    a.assignment?.preacherId == currentUser?.uid
                  ).toList();

                  final assigned = myActivities.where((a) => a.status == 'assigned').length;
                  final checkedIn = myActivities.where((a) => a.status == 'checked_in').length;
                  final pending = myActivities.where((a) => a.status == 'pending').length;
                  final approved = myActivities.where((a) => a.status == 'approved').length;
                  final rejected = myActivities.where((a) => a.status == 'rejected').length;
                  final total = myActivities.length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                      'My Statistics',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _StatCard('Total Assigned', total, Colors.white),
                            const SizedBox(width: 10),
                            _StatCard('Assigned', assigned, Colors.blue.shade300),
                            const SizedBox(width: 10),
                            _StatCard('Checked-In', checkedIn, Colors.cyan.shade300),
                            const SizedBox(width: 10),
                            _StatCard('Pending', pending, Colors.orange.shade300),
                            const SizedBox(width: 10),
                            _StatCard('Approved', approved, Colors.green.shade300),
                            const SizedBox(width: 10),
                            _StatCard('Rejected', rejected, Colors.red.shade300),
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
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.location_on,
                          label: 'GPS Check-In',
                          color: Colors.lightGreen,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.description,
                          label: 'Submit Report',
                          color: Colors.blue,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // My Activities Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Activities',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _goToActivitiesTab(context),
                        child: const Text('View all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All', style: TextStyle(fontSize: 12)),
                        selected: _timeFilter == 'all',
                        onSelected: (_) => setState(() => _timeFilter = 'all'),
                        selectedColor: Colors.lightGreen.shade100,
                        checkmarkColor: Colors.lightGreen,
                      ),
                      FilterChip(
                        label: const Text('Today', style: TextStyle(fontSize: 12)),
                        selected: _timeFilter == 'today',
                        onSelected: (_) => setState(() => _timeFilter = 'today'),
                        selectedColor: Colors.lightGreen.shade100,
                        checkmarkColor: Colors.lightGreen,
                      ),
                      FilterChip(
                        label: const Text('Week', style: TextStyle(fontSize: 12)),
                        selected: _timeFilter == 'week',
                        onSelected: (_) => setState(() => _timeFilter = 'week'),
                        selectedColor: Colors.lightGreen.shade100,
                        checkmarkColor: Colors.lightGreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),

            // Activity Cards
            StreamBuilder<List<ActivityData>>(
              stream: currentUser == null
                  ? null
                  : _activityController.preacherActivitiesStream(currentUser.uid),
              builder: (context, snapshot) {
                if (currentUser == null) {
                  return const SizedBox.shrink();
                }
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                var activities = snapshot.data!.where((a) => 
                  a.assignment?.preacherId == currentUser?.uid
                ).toList();

                // Apply time filter
                if (_timeFilter != 'all') {
                  final now = DateTime.now();
                  activities = activities.where((activity) {
                    final activityDate = _safeParseDate(activity.activityDate);
                    if (activityDate == null) return false;

                    if (_timeFilter == 'today') {
                      return activityDate.year == now.year &&
                             activityDate.month == now.month &&
                             activityDate.day == now.day;
                    } else if (_timeFilter == 'week') {
                      final weekAgo = now.subtract(const Duration(days: 7));
                      return activityDate.isAfter(weekAgo) && activityDate.isBefore(now.add(const Duration(days: 1)));
                    }
                    return true;
                  }).toList();
                }

                if (activities.isEmpty) {
                  return _EmptyStateCard(
                    title: 'No Activities',
                    message: _timeFilter == 'all'
                        ? 'You have no assigned activities yet.'
                        : 'No activities for this time period.',
                  );
                }

                // Sort
                if (_timeFilter == 'all') {
                  // Sort by date (newest first) when showing all
                  activities.sort((a, b) {
                    final da = _safeParseDate(a.activityDate);
                    final db = _safeParseDate(b.activityDate);
                    if (da == null && db == null) return 0;
                    if (da == null) return 1;
                    if (db == null) return -1;
                    return db.compareTo(da);
                  });
                } else {
                  // Sort by priority when filtered
                  activities.sort((a, b) {
                    int getPriority(String? status) {
                      switch (status?..toUpperCase()) {
                        case 'assigned':
                          return 1;
                        case 'checked_in':
                          return 2;
                        case 'pending':
                          return 3;
                        case 'approved':
                          return 4;
                        case 'rejected':
                          return 5;
                        default:
                          return 6;
                      }
                    }
                    return getPriority(a.status).compareTo(getPriority(b.status));
                  });
                }

                // Scrollable activity list within a bounded height so users can browse more
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 420),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: activities.length,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) => _ActivityCard(activities[index]),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            // Notifications & Alerts Section (for current preacher)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications & Alerts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: () {
                      // Placeholder: could navigate to a full notifications page
                    },
                    child: const Text('See all'),
                  ),
                ],
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.grey.shade50,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseAuth.instance.currentUser == null
                    ? null
                    : FirebaseFirestore.instance
                        .collection('notifications')
                        .where('preacher_id', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                        .limit(5)
                        .snapshots(),
                builder: (context, snap) {
                  if (FirebaseAuth.instance.currentUser == null) {
                    return const SizedBox.shrink();
                  }
                  if (snap.hasError) {
                    return Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Failed to load notifications. ${snap.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  }
                  if (!snap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(8),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final notifications = snap.data!.docs
                      .map((d) => ActivityNotification.fromDoc(d))
                      .toList()
                    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
                  if (notifications.isEmpty) {
                    return Row(
                      children: [
                        Icon(Icons.notifications_off, color: Colors.grey.shade500),
                        const SizedBox(width: 8),
                        Text('No notifications yet', style: TextStyle(color: Colors.grey.shade700)),
                      ],
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) => _NotificationItem(notifications[index]),
                  );
                },
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final ActivityNotification notification;

  const _NotificationItem(this.notification);

  String _timeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${diff.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    if (diff.inHours < 24) return '${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'} ago';
    if (diff.inDays < 7) return '${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'} ago';
    final weeks = (diff.inDays / 7).floor();
    return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
  }

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;
    Color iconBgColor;

    switch (notification.type) {
      case 'submission':
        icon = Icons.description;
        iconColor = Colors.blue.shade700;
        iconBgColor = Colors.blue.shade50;
        break;
      case 'approval':
        icon = Icons.check_circle;
        iconColor = Colors.green.shade700;
        iconBgColor = Colors.green.shade50;
        break;
      case 'rejection':
        icon = Icons.cancel;
        iconColor = Colors.red.shade700;
        iconBgColor = Colors.red.shade50;
        break;
      case 'edit':
        icon = Icons.edit;
        iconColor = Colors.orange.shade700;
        iconBgColor = Colors.orange.shade50;
        break;
      case 'assignment':
        icon = Icons.assignment;
        iconColor = Colors.lightGreen.shade700;
        iconBgColor = Colors.lightGreen.shade50;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey.shade700;
        iconBgColor = Colors.grey.shade50;
    }

    final timeAgo = _timeAgo(notification.timestamp);

    return InkWell(
      onTap: () {
        // Placeholder for notification tap action
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.message,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(notification.type.toUpperCase(),
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            )),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeAgo,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatCard(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
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
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final ActivityData activity;

  const _ActivityCard(this.activity);

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.amber;
      case 'rejected':
        return Colors.red;
      case 'assigned':
        return Colors.orange;
      case 'checked_in':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  bool _isCheckInTimeValid(ActivityData activity) {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      DateTime? activityDate;
      final dateStr = activity.activityDate.trim();
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          activityDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      } else if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            activityDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          } else {
            activityDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          }
        }
      }

      if (activityDate == null) return false;
      if (activityDate.year != today.year || activityDate.month != today.month || activityDate.day != today.day) {
        return false;
      }

      final startParts = activity.startTime.split(':');
      final endParts = activity.endTime.split(':');
      if (startParts.length < 2 || endParts.length < 2) return false;

      final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      final currentMinutes = now.hour * 60 + now.minute;

      return currentMinutes >= (startMinutes - 60) && currentMinutes <= (endMinutes + 60);
    } catch (e) {
      return false;
    }
  }

  void _showDetailsPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.60,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  // Title Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          activity.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      _statusChip(activity.status),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Basic Info Section
                  _sectionHeader('Basic Information'),
                  _detailRow(Icons.person, 'Preacher', activity.preacherName ?? 'Not assigned'),
                  _detailRow(Icons.admin_panel_settings, 'Assigned Officer', activity.officerName ?? activity.createdBy),

                  const SizedBox(height: 16),
                  _sectionHeader('Date & Time'),
                  _detailRow(Icons.calendar_month, 'Date & Time', '${activity.activityDate} ${activity.startTime} - ${activity.endTime}'),

                  const SizedBox(height: 16),
                  _sectionHeader('Location'),
                  _detailRow(Icons.location_on, 'Venue', activity.locationName),
                  _detailRow(Icons.location_city, 'Address', activity.locationAddress),

                  const SizedBox(height: 16),
                  _sectionHeader('Activity Details'),
                  _detailRow(Icons.topic, 'Topic', activity.topic),
                  _detailRow(Icons.description, 'Description', activity.description),

                  const SizedBox(height: 16),
                  _sectionHeader('Status & Verification'),
                  Row(
                    children: [
                      _statusChip(activity.status),
                      if (activity.status.toLowerCase() == 'checked_in')...[
                        const SizedBox(width: 10),
                        _gpsVerifiedBadge(),
                      ],
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ACTION BUTTONS
                  if (activity.status.toLowerCase() == 'assigned' && _isCheckInTimeValid(activity)) ...[
                    ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _checkInGPS(context);
                      },
                      icon: const Icon(Icons.location_on),
                      label: const Text('GPS Check-In'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ] else if (activity.status.toLowerCase() == 'assigned') ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'GPS check-in is available 1 hour before start time (${activity.startTime}) until 1 hour after end time (${activity.endTime}).',
                              style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Close button (always shown)
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text("Close"),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.red.shade700),
                    backgroundColor: Colors.red.shade700,
                  ),
                ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color bgColor;
    Color textColor;
    switch (status.toLowerCase()) {
      case 'checked_in':
      case 'assigned':
        bgColor = Colors.yellow.shade100;
        textColor = Colors.orange.shade800;
        break;
      case 'approved':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case 'pending':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        break;
      case 'rejected':
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _gpsVerifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.yellow.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: Colors.orange.shade800, size: 18),
          const SizedBox(width: 6),
          Text(
            'GPS Verified',
            style: TextStyle(
              color: Colors.orange.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.lightGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, color: Colors.black)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkInGPS(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('GPS Check-In feature coming soon'),
        backgroundColor: Colors.lightGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(activity.status);

    return GestureDetector(
      onTap: () => _showDetailsPopup(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border(
            left: BorderSide(color: Colors.lightGreen.shade400, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 14,
              offset: const Offset(0, 4),
              color: Colors.black.withOpacity(0.08),
            ),
          ],
        ),
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + compact status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    activity.title ?? 'Untitled Activity',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _compactStatusChip(activity.status),
              ],
            ),
            const SizedBox(height: 6),

            // Date & time as metadata
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.lightGreen),
                const SizedBox(width: 6),
                  Text(
                    '${activity.activityDate} | ${activity.startTime} - ${activity.endTime}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),

            // Location pill
            if (activity.locationAddress.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.lightGreen.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.lightGreen),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        activity.locationAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            // Topic Badge (dark blue-grey pill)
            if (activity.topic != null && activity.topic!.trim().isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 64, 91, 162),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.label_rounded, size: 14, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      activity.topic!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
      
            const SizedBox(height: 4),
            // Minimal dashboard action
            if (activity.status == 'assigned' && _isCheckInTimeValid(activity))
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _checkInGPS(context),
                    icon: const Icon(Icons.location_on, size: 16),
                    label: const Text('Check In'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.lightGreen,
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 3),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Tap for details',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _compactStatusChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyStateCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
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
        children: [
          Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

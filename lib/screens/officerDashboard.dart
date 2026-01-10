import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import '../providers/Login/LoginController.dart';
import '../providers/ActivityController.dart';
import '../models/ActivityData.dart';
import '../models/Notification.dart';
import 'ManageProfile/userProfilePage.dart';
import 'ManageActivity/officer/officerActivityList.dart';
import 'ManageActivity/officer/assignActivity.dart';

Future<void> _markAllOfficerNotificationsRead(String officerId) async {
  try {
    final db = FirebaseFirestore.instance;
    final relevantTypes = [
      'explanation_pending_review',
      'explanation_submitted',
    ];
    final snap = await db
        .collection('notifications')
        .where('officer_id', isEqualTo: officerId)
        .where('is_read', isEqualTo: false)
        .get();
    final docs = snap.docs
        .where((d) => relevantTypes.contains(d.data()['type']))
        .toList();
    if (docs.isEmpty) return;
    final batch = db.batch();
    for (final d in docs) {
      batch.update(d.reference, {'is_read': true});
    }
    await batch.commit();
  } catch (e) {
    debugPrint('Failed to mark officer notifications read: $e');
  }
}

Future<void> _openOfficerNotificationsSheet(BuildContext context) async {
  final officerId = FirebaseAuth.instance.currentUser?.uid;
  if (officerId == null) return;

  await _markAllOfficerNotificationsRead(officerId);

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
                    .where('officer_id', isEqualTo: officerId)
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

                  final officerTypes = [
                    'explanation_pending_review',
                    'explanation_submitted',
                  ];

                  final items =
                      snap.data!.docs
                          .map((d) => ActivityNotification.fromDoc(d))
                          .where(
                            (n) =>
                                n.officerId == officerId &&
                                officerTypes.contains(n.type),
                          )
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
                    itemBuilder: (context, index) => _OfficerNotificationTile(
                      notification: items[index],
                      currentOfficerId: officerId,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class OfficerDashboard extends StatefulWidget {
  const OfficerDashboard({super.key});

  @override
  State<OfficerDashboard> createState() => _OfficerDashboardState();
}

class _OfficerDashboardState extends State<OfficerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    // index 0 - dashboard
    const _DashboardBody(),
    // index 1 - activities
    const OfficerActivityList(),
    // index 2 - preachers (placeholder)
    const Center(child: Text('Preachers')),
    // index 3 - reports (placeholder)
    const Center(child: Text('Reports')),
    // index 4 - profile
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

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.amber.shade600,
              foregroundColor: Colors.white,
              titleSpacing: 0,
              title: Row(
                children: [
                  const SizedBox(width: 16),
                  Container(
                    width: 42,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield, size: 22),
                  ),
                  const SizedBox(width: 12),
                  StreamBuilder<DocumentSnapshot>(
                    stream: currentUser != null
                        ? FirebaseFirestore.instance
                              .collection('officers')
                              .doc(currentUser.uid)
                              .snapshots()
                        : null,
                    builder: (context, snapshot) {
                      String officerName = 'Officer';
                      if (snapshot.hasData && snapshot.data!.exists) {
                        officerName =
                            snapshot.data!.get('fullName') ?? 'Officer';
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome, ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            officerName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none),
                  onPressed: () => _openOfficerNotificationsSheet(context),
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _logout(context),
                ),
              ],
            )
          : null, // No AppBar for other tabs
      body: IndexedStack(index: _selectedIndex, children: _pages),
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
          selectedItemColor: Colors.amber.shade600,
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
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(ActivityNotification notification) {
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
        iconColor = Colors.amber.shade700;
        iconBgColor = Colors.amber.shade50;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey.shade700;
        iconBgColor = Colors.grey.shade50;
    }

    final timeAgo = _getTimeAgo(notification.timestamp);

    return InkWell(
      onTap: () {
        // Handle notification tap
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeAgo,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade600,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return '${(difference.inDays / 7).floor()} ${(difference.inDays / 7).floor() == 1 ? 'week' : 'weeks'} ago';
    }
  }
}

// Dashboard body widget with full functionality
class _DashboardBody extends StatefulWidget {
  const _DashboardBody();

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  final controller = ActivityController();
  String officerName = 'Officer';
  static final Map<String, String> _preacherNameCache = {};

  String _formatStatus(String? status) {
    if (status == null || status.isEmpty) return 'Unknown';
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  Future<String> _getPreacherName(String preacherId) async {
    if (preacherId.isEmpty) return 'Preacher';
    if (_preacherNameCache.containsKey(preacherId)) {
      return _preacherNameCache[preacherId]!;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('preachers')
          .doc(preacherId)
          .get();
      if (doc.exists) {
        final name = doc.data()?['fullName'] ?? 'Preacher';
        _preacherNameCache[preacherId] = name;
        return name;
      }
    } catch (e) {
      debugPrint('Error fetching preacher name: $e');
    }

    return 'Preacher';
  }

  @override
  void initState() {
    super.initState();
    _loadOfficerName();
  }

  Future<void> _loadOfficerName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('officers')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          officerName = doc.data()?['fullName'] ?? 'Officer';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ActivityData>>(
      stream: controller.activitiesStream(),
      builder: (context, snapshot) {
        final activities = snapshot.data ?? [];

        // Calculate statistics (updated to latest statuses)
        final assignedCount = activities
            .where((a) => a.status.toLowerCase() == 'assigned')
            .length;
        final checkedInCount = activities
            .where((a) => a.status.toLowerCase() == 'checked_in')
            .length;
        final pendingCount = activities
            .where((a) => a.status.toLowerCase() == 'pending')
            .length; // report awaiting officer review
        final pendingReportCount = activities
            .where((a) => a.status.toLowerCase() == 'pending_report')
            .length; // preacher to submit report
        final pendingOfficerReviewCount = activities
            .where((a) => a.status.toLowerCase() == 'pending_officer_review')
            .length; // late check-in explanation
        final pendingAbsenceReviewCount = activities
            .where((a) => a.status.toLowerCase() == 'pending_absence_review')
            .length; // absence explanation
        final approvedCount = activities
            .where((a) => a.status.toLowerCase() == 'approved')
            .length;
        final rejectedCount = activities
            .where((a) => a.status.toLowerCase() == 'rejected')
            .length;
        final checkInMissedCount = activities
            .where((a) => a.status.toLowerCase() == 'check_in_missed')
            .length;
        final absentCount = activities
            .where((a) => a.status.toLowerCase() == 'absent')
            .length;
        final cancelledCount = activities
            .where((a) => a.status.toLowerCase() == 'cancelled')
            .length;

        // Recent submissions (pending status)
        final recentSubmissions = activities
            .where((a) => a.status.toLowerCase() == 'pending')
            .take(5)
            .toList();

        return Container(
          color: Colors.grey.shade50,
          child: CustomScrollView(
            slivers: [
              // Header Section with Stats
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade600, Colors.amber.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Logout
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome, $officerName',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  child: const Text(
                                    'MUIP OFFICER',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Statistics Cards in Header
                      const Text(
                        'My Statistics',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildHeaderStatCard(
                              'Total',
                              activities.length,
                              Colors.white,
                            ),
                            const SizedBox(width: 10),
                            _buildHeaderStatCard(
                              'Assigned',
                              assignedCount,
                              Colors.blue.shade200,
                            ),
                            const SizedBox(width: 10),
                            _buildHeaderStatCard(
                              'Checked-In',
                              checkedInCount,
                              Colors.cyan.shade200,
                            ),
                            const SizedBox(width: 10),
                            _buildHeaderStatCard(
                              'Check-In Missed',
                              checkInMissedCount,
                              Colors.deepOrange.shade200,
                            ),
                            const SizedBox(width: 10),
                            _buildHeaderStatCard(
                              'Pending Officer Review',
                              pendingOfficerReviewCount,
                              Colors.purple.shade200,
                            ),
                            const SizedBox(width: 10),
                            _buildHeaderStatCard(
                              'Pending Absence Review',
                              pendingAbsenceReviewCount,
                              Colors.blue.shade200,
                            ),
                            const SizedBox(width: 10),
                            _buildHeaderStatCard(
                              'Pending Review',
                              pendingCount,
                              Colors.orange.shade200,
                            ),
                            const SizedBox(width: 10),
                            _buildHeaderStatCard(
                              'Pending Report',
                              pendingReportCount,
                              Colors.amber.shade200,
                            ),
                            const SizedBox(width: 10),
                            _buildHeaderStatCard(
                              'Absent',
                              absentCount,
                              Colors.redAccent.shade200,
                            ),
                            const SizedBox(width: 10),
                            _buildHeaderStatCard(
                              'Cancelled',
                              cancelledCount,
                              Colors.grey.shade300,
                            ),
                            const SizedBox(width: 10),
                            _buildHeaderStatCard(
                              'Approved',
                              approvedCount,
                              Colors.green.shade200,
                            ),
                            const SizedBox(width: 10),
                            _buildHeaderStatCard(
                              'Rejected',
                              rejectedCount,
                              Colors.red.shade200,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Quick Actions Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionButton(
                              context,
                              icon: Icons.add_circle,
                              label: 'Assign Activity',
                              color: Colors.amber.shade600,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AssignActivityForm(),
                                    fullscreenDialog: true,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickActionButton(
                              context,
                              icon: Icons.rate_review,
                              label: 'Review Reports',
                              color: Colors.orange,
                              onTap: () {
                                DefaultTabController.of(context)?.animateTo(1);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // Recent Activity Submissions Section
              if (recentSubmissions.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Submissions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            DefaultTabController.of(context)?.animateTo(1);
                          },
                          child: Text(
                            'See all',
                            style: TextStyle(
                              color: Colors.amber.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Recent Submissions List
              if (recentSubmissions.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final activity = recentSubmissions[index];
                      return _buildSubmissionCard(context, activity);
                    }, childCount: recentSubmissions.length),
                  ),
                ),

              // Empty state if no pending submissions
              if (recentSubmissions.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 56,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Pending Submissions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'All reports have been reviewed',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Notifications & Alerts Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Notifications & Alerts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _openOfficerNotificationsSheet(context);
                        },
                        child: Text(
                          'See all',
                          style: TextStyle(
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Notifications List
              SliverToBoxAdapter(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notifications')
                      .where(
                        'officer_id',
                        isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                      )
                      .snapshots(),
                  builder: (context, notificationSnapshot) {
                    if (!notificationSnapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    final currentOfficerId =
                        FirebaseAuth.instance.currentUser?.uid;

                    // Officer-relevant notification types only
                    final officerNotificationTypes = [
                      'explanation_pending_review',
                      'explanation_submitted',
                    ];

                    final notifications =
                        notificationSnapshot.data!.docs
                            .map((doc) => ActivityNotification.fromDoc(doc))
                            .where(
                              (n) =>
                                  currentOfficerId != null &&
                                  n.officerId == currentOfficerId &&
                                  officerNotificationTypes.contains(n.type),
                            )
                            .toList()
                          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

                    final limitedNotifications = notifications.take(5).toList();

                    if (limitedNotifications.isEmpty) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No Notifications',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'All caught up!',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: limitedNotifications.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (context, index) =>
                            _buildNotificationItem(limitedNotifications[index]),
                      ),
                    );
                  },
                ),
              ),

              // Bottom spacing
              SliverToBoxAdapter(child: const SizedBox(height: 24)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderStatCard(String label, int count, Color color) {
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

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 22),
      label: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        shadowColor: color.withOpacity(0.4),
      ),
    );
  }

  Widget _buildSubmissionCard(BuildContext context, ActivityData activity) {
    final isLateCheckIn =
        activity.explanationReason?.toLowerCase().contains('late') ?? false;
    final absenceReasons = [
      'emergency',
      'medical',
      'travel',
      'forgot',
      'miscommunication',
      'other',
    ];
    final isAbsenceReason = absenceReasons.contains(
      (activity.explanationReason ?? '').toLowerCase(),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Preacher Name, Activity Title, Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.preacherName ?? 'Preacher',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  _formatStatus(activity.status),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Location
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 15,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  activity.locationName,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Date and GPS verification
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                activity.activityDate,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              if (activity.status.toLowerCase() == 'pending') ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified,
                        size: 13,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'GPS Verified',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Explanation Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reason: ${activity.explanationReason ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade900,
                  ),
                ),
                if ((activity.explanationDetails ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    activity.explanationDetails ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                  ),
                ],
                // Show proof URL for late check-in
                if (isLateCheckIn &&
                    (activity.explanationProofUrl ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      // Could open proof URL here
                    },
                    child: Text(
                      '📸 Proof: View Photo',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Actions based on reason type
          if (isAbsenceReason) ...[
            // Single action for absence reasons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showConfirmDialog(
                    context,
                    title: 'Accept Absence Explanation',
                    message:
                        'Accept absence explanation and mark as absent for: ${activity.title}',
                    onConfirm: () async {
                      final controller = ActivityController();
                      await controller.officerAcceptAbsence(activity);
                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Absence accepted and marked as absent',
                          ),
                        ),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text(
                  'Accept Absence',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ] else if (isLateCheckIn) ...[
            // Two actions for late check-in
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showConfirmDialog(
                        context,
                        title: 'Mark as Attended',
                        message:
                            'Approve late check-in for: ${activity.title}?\nPreacher can now submit their report.',
                        onConfirm: () async {
                          final controller = ActivityController();
                          await controller.officerApproveExplanation(activity);
                          if (!mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Marked as attended. Preacher can now submit report.',
                              ),
                            ),
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text(
                      'Mark as Attended',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showConfirmDialog(
                        context,
                        title: 'Reject & Mark Absent',
                        message:
                            'Reject late check-in proof and mark as absent for: ${activity.title}',
                        onConfirm: () async {
                          final controller = ActivityController();
                          await controller.officerRejectExplanation(activity);
                          if (!mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Marked as absent')),
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text(
                      'Reject Proof',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Default action for other cases
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  DefaultTabController.of(context)?.animateTo(1);
                },
                icon: const Icon(Icons.rate_review, size: 18),
                label: const Text(
                  'Review Report',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(ActivityNotification notification) {
    IconData icon;
    Color iconColor;
    Color iconBgColor;

    switch (notification.type) {
      case 'explanation_pending_review':
        icon = Icons.pending_actions;
        iconColor = Colors.blue.shade700;
        iconBgColor = Colors.blue.shade50;
        break;
      case 'explanation_submitted':
        icon = Icons.pending_actions;
        iconColor = Colors.blue.shade700;
        iconBgColor = Colors.blue.shade50;
        break;
      case 'absence_accepted':
        icon = Icons.check_circle_outline;
        iconColor = Colors.orange.shade700;
        iconBgColor = Colors.orange.shade50;
        break;
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
        iconColor = Colors.amber.shade700;
        iconBgColor = Colors.amber.shade50;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey.shade700;
        iconBgColor = Colors.grey.shade50;
    }
    final timeAgo = _getTimeAgo(notification.timestamp);
    final currentOfficerId = FirebaseAuth.instance.currentUser?.uid;

    Widget buildTile(String message) {
      return InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.w600,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade600,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Hide items that should never show on the officer dashboard
    if (notification.type == 'assignment' ||
        notification.type == 'absence_accepted') {
      return const SizedBox.shrink();
    }

    if (notification.type == 'explanation_submitted') {
      if (notification.officerId != currentOfficerId) {
        return const SizedBox.shrink();
      }

      return FutureBuilder<String>(
        future: _getPreacherName(notification.preacherId),
        builder: (context, snapshot) {
          // Use cached name if available, otherwise wait for data
          final preacherName =
              _preacherNameCache[notification.preacherId] ??
              (snapshot.hasData && snapshot.data!.isNotEmpty
                  ? snapshot.data!
                  : 'Preacher');
          final titleMatch = RegExp(
            '"([^"]+)"',
          ).firstMatch(notification.message);
          final title = titleMatch != null ? titleMatch.group(1) ?? '' : '';
          final formattedMessage = title.isNotEmpty
              ? "$preacherName's explanation for \"$title\" absent has been submitted and is awaiting officer review."
              : "$preacherName's explanation has been submitted and is awaiting officer review.";

          return buildTile(formattedMessage);
        },
      );
    }

    return buildTile(notification.message);
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return '${(difference.inDays / 7).floor()} ${(difference.inDays / 7).floor() == 1 ? 'week' : 'weeks'} ago';
    }
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
      }
    }
  }
}

class _OfficerNotificationTile extends StatelessWidget {
  final ActivityNotification notification;
  final String currentOfficerId;

  const _OfficerNotificationTile({
    required this.notification,
    required this.currentOfficerId,
  });

  IconData _iconForType(String type) {
    switch (type) {
      case 'explanation_pending_review':
        return Icons.pending_actions;
      case 'explanation_submitted':
        return Icons.pending_actions;
      case 'absence_accepted':
        return Icons.check_circle_outline;
      case 'submission':
        return Icons.description;
      case 'approval':
        return Icons.check_circle;
      case 'rejection':
        return Icons.cancel;
      case 'edit':
        return Icons.edit;
      case 'assignment':
        return Icons.assignment;
      default:
        return Icons.notifications;
    }
  }

  Color _iconColor(String type) {
    switch (type) {
      case 'explanation_pending_review':
      case 'explanation_submitted':
      case 'submission':
        return Colors.blue.shade700;
      case 'approval':
        return Colors.green.shade700;
      case 'rejection':
        return Colors.red.shade700;
      case 'edit':
        return Colors.orange.shade700;
      case 'assignment':
        return Colors.amber.shade700;
      case 'absence_accepted':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Color _iconBgColor(String type) {
    switch (type) {
      case 'explanation_pending_review':
      case 'explanation_submitted':
      case 'submission':
        return Colors.blue.shade50;
      case 'approval':
        return Colors.green.shade50;
      case 'rejection':
        return Colors.red.shade50;
      case 'edit':
        return Colors.orange.shade50;
      case 'assignment':
        return Colors.amber.shade50;
      case 'absence_accepted':
        return Colors.orange.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  String _timeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    }
    final weeks = (difference.inDays / 7).floor();
    return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
  }

  Future<String> _fetchPreacherName(String preacherId) async {
    if (preacherId.isEmpty) return 'Preacher';
    // Check cache first
    if (_DashboardBodyState._preacherNameCache.containsKey(preacherId)) {
      return _DashboardBodyState._preacherNameCache[preacherId]!;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('preachers')
          .doc(preacherId)
          .get();
      if (doc.exists) {
        final name = doc.data()?['fullName'] ?? 'Preacher';
        _DashboardBodyState._preacherNameCache[preacherId] = name;
        return name;
      }
    } catch (e) {
      debugPrint('Error fetching preacher name: $e');
    }
    return 'Preacher';
  }

  Widget _tile(BuildContext context, String message) {
    final icon = _iconForType(notification.type);
    final iconColor = _iconColor(notification.type);
    final iconBg = _iconBgColor(notification.type);
    final timeAgo = _timeAgo(notification.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: notification.isRead
                        ? FontWeight.normal
                        : FontWeight.w600,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  timeAgo,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (!notification.isRead)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade600,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (notification.type == 'assignment' ||
        notification.type == 'absence_accepted') {
      return const SizedBox.shrink();
    }

    if (notification.type == 'explanation_pending_review') {
      if (notification.officerId != currentOfficerId) {
        return const SizedBox.shrink();
      }

      return FutureBuilder<String>(
        future: _fetchPreacherName(notification.preacherId),
        builder: (context, snapshot) {
          // Use cached name if available to prevent flickering
          final preacherName =
              _DashboardBodyState._preacherNameCache[notification.preacherId] ??
              (snapshot.hasData && snapshot.data!.isNotEmpty
                  ? snapshot.data!
                  : 'Preacher');
          final titleMatch = RegExp(
            '"([^"]+)"',
          ).firstMatch(notification.message);
          final title = titleMatch != null ? titleMatch.group(1) ?? '' : '';
          final formatted = title.isNotEmpty
              ? "$preacherName's explanation for \"$title\" is awaiting your review."
              : "$preacherName's explanation is awaiting your review.";
          return _tile(context, formatted);
        },
      );
    }

    return _tile(context, notification.message);
  }
}

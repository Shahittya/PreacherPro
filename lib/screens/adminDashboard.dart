import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../models/ActivityData.dart';
import '../providers/ActivityController.dart';
import '../providers/Login/LoginController.dart';
import 'ManageActivity/admin/adminActivityList.dart';
import 'ManagePreacher/PreacherManagementPage.dart';
import 'ManageProfile/userProfilePage.dart';
import 'Registeration/officerRegisterPage.dart';
import 'Registeration/registrationRequestPage.dart';
import 'ManagePayment/muip_admin_payment_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  String _timeFilter = 'all';

  final List<Widget> _pages = [
    // index 0 - dashboard
    const _DashboardPage(),
    // index 1 - preachers
    const PreacherManagementPage(),
    // index 2 - requests
    const RegistrationRequestPage(),
    // index 3 - add MUIP
    const OfficerRegisterPage(),
    // index 4 - payment
    const MuipAdminPaymentPage(),
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

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  List<ActivityData> _applyFilters(List<ActivityData> activities) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    bool matchesRange(ActivityData a) {
      final parsed = _parseDate(a.activityDate);
      if (parsed == null) return true;
      if (parsed.isBefore(todayStart)) return false; // hide past dates from upcoming lists

      switch (_timeFilter) {
        case 'today':
          return parsed.year == now.year && parsed.month == now.month && parsed.day == now.day;
        case 'week':
          final startOfWeek = todayStart.subtract(Duration(days: todayStart.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          return !parsed.isBefore(startOfWeek) && !parsed.isAfter(endOfWeek);
        case 'month':
          return parsed.year == now.year && parsed.month == now.month;
        default:
          return true;
      }
    }

    final filtered = activities.where(matchesRange).toList();
    filtered.sort((a, b) {
      final aDate = _parseDate(a.activityDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = _parseDate(b.activityDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aDate.compareTo(bDate);
    });
    return filtered;
  }

  List<ActivityData> _recentSubmissions(List<ActivityData> activities) {
    final submissions = activities.where((a) => a.submissionSubmittedAt != null || (a.status.toLowerCase() == 'pending')).toList();
    submissions.sort((a, b) {
      final aDate = (a.submissionSubmittedAt ?? _parseDate(a.activityDate)) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = (b.submissionSubmittedAt ?? _parseDate(b.activityDate)) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return submissions.take(6).toList();
  }

  DateTime? _parseDate(String value) {
    try {
      if (value.contains('/')) {
        final parts = value.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      } else if (value.contains('-')) {
        final parts = value.split('-');
        if (parts.length == 3) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              titleSpacing: 0,
              title: Row(
                children: [
                  const SizedBox(width: 16),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Welcome back',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'MUIP Admin',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none),
                  onPressed: () {},
                ),
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Preachers'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Add MUIP',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Payment'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.scheme,
    required this.pendingReviewsCount,
    required this.overdueCount,
    required this.onPendingTap,
    required this.onOverdueTap,
  });

  final ColorScheme scheme;
  final int pendingReviewsCount;
  final int overdueCount;
  final VoidCallback onPendingTap;
  final VoidCallback onOverdueTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary,
            scheme.primary.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(0.25),
            offset: const Offset(0, 12),
            blurRadius: 32,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: TextStyle(
                        color: scheme.onPrimary.withOpacity(0.9),
                        fontSize: 13,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Admin Activity Hub',
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Review submissions, monitor activities, and manage requests.',
                      style: TextStyle(
                        color: scheme.onPrimary.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
              SizedBox(
                width: 140,
                child: _StatPill(
                label: 'Pending Reviews',
                value: pendingReviewsCount.toString(),
                color: scheme.secondary,
                icon: Icons.pending_actions,
                onTap: onPendingTap,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 140,
                child: _StatPill(
                label: 'Overdue',
                value: overdueCount.toString(),
                color: Colors.redAccent,
                icon: Icons.schedule,
                onTap: onOverdueTap,
                ),
              ),
              const SizedBox(width: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
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

class _SearchAndFilters extends StatelessWidget {
  const _SearchAndFilters({
    required this.scheme,
    required this.initialFilter,
    required this.onFilterChanged,
  });

  final ColorScheme scheme;
  final String initialFilter;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _FilterChip(
              label: 'Today',
              isSelected: initialFilter == 'today',
              onTap: () => onFilterChanged('today'),
              scheme: scheme,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'This Week',
              isSelected: initialFilter == 'week',
              onTap: () => onFilterChanged('week'),
              scheme: scheme,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'This Month',
              isSelected: initialFilter == 'month',
              onTap: () => onFilterChanged('month'),
              scheme: scheme,
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.scheme,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primary.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? scheme.primary : scheme.outlineVariant),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? scheme.primary : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _OfficerFilterChip extends StatelessWidget {
  const _OfficerFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.scheme,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primary.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? scheme.primary : scheme.outlineVariant.withOpacity(0.6)),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isSelected ? scheme.primary : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onActionTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: onActionTap,
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.scheme,
    required this.title,
    required this.subtitle,
    required this.dateText,
    required this.timeText,
    required this.status,
    required this.badgeText,
  });

  final ColorScheme scheme;
  final String title;
  final String subtitle;
  final String dateText;
  final String timeText;
  final String status;
  final String badgeText;

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('approve')) return Colors.green;
    if (normalized.contains('pending')) return Colors.orange;
    if (normalized.contains('reject')) return Colors.red;
    if (normalized.contains('assign') || normalized.contains('check')) return Colors.blueGrey;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(status);
    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text(dateText),
              const SizedBox(width: 12),
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  timeText,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({
    required this.scheme,
    required this.activityTitle,
    required this.preacher,
    required this.badge,
    required this.submittedText,
    required this.location,
    required this.status,
  });

  final ColorScheme scheme;
  final String activityTitle;
  final String preacher;
  final String badge;
  final String submittedText;
  final String location;
  final String status;

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('approve')) return Colors.green;
    if (normalized.contains('pending')) return Colors.orange;
    if (normalized.contains('reject')) return Colors.red;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            offset: const Offset(0, 6),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  activityTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge.toUpperCase(),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  preacher,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                submittedText,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey.shade700),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  location,
                  style: TextStyle(color: Colors.grey.shade800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.message,
    required this.scheme,
  });

  final IconData icon;
  final String message;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

// ============== Dashboard Page ==============
class _DashboardPage extends StatefulWidget {
  const _DashboardPage({Key? key}) : super(key: key);

  @override
  State<_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<_DashboardPage> {
  final _activityController = ActivityController();
  String _timeFilter = 'all';
  String? _selectedOfficerId;

  @override
  void dispose() {
    _activityController.dispose();
    super.dispose();
  }

  List<ActivityData> _applyFilters(List<ActivityData> activities) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    bool matchesRange(ActivityData a) {
      final parsed = _parseDate(a.activityDate);
      if (parsed == null) return true;
      if (parsed.isBefore(todayStart)) return false; // upcoming only

      switch (_timeFilter) {
        case 'today':
          return parsed.year == now.year && parsed.month == now.month && parsed.day == now.day;
        case 'week':
          final startOfWeek = todayStart.subtract(Duration(days: todayStart.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          return !parsed.isBefore(startOfWeek) && !parsed.isAfter(endOfWeek);
        case 'month':
          return parsed.year == now.year && parsed.month == now.month;
        default:
          return true;
      }
    }

    final filtered = activities.where(matchesRange).toList();
    filtered.sort((a, b) {
      final aDate = _parseDate(a.activityDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = _parseDate(b.activityDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aDate.compareTo(bDate);
    });
    return filtered;
  }

  List<ActivityData> _recentSubmissions(List<ActivityData> activities) {
    final submissions = activities.where((a) => a.submissionSubmittedAt != null || (a.status.toLowerCase() == 'pending')).toList();
    submissions.sort((a, b) {
      final aDate = (a.submissionSubmittedAt ?? _parseDate(a.activityDate)) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = (b.submissionSubmittedAt ?? _parseDate(b.activityDate)) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return submissions.take(6).toList();
  }

  DateTime? _parseDate(String value) {
    try {
      if (value.contains('/')) {
        final parts = value.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      } else if (value.contains('-')) {
        final parts = value.split('-');
        if (parts.length == 3) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return StreamBuilder<List<ActivityData>>(
      stream: _activityController.allActivitiesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final activities = snapshot.data ?? [];

        final filteredActivities = _applyFilters(activities);
        final allActivities = [...activities]
          ..sort((a, b) {
            final aDate = _parseDate(a.activityDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = _parseDate(b.activityDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });
        final recentSubmissions = _recentSubmissions(activities);
        final pendingReviews = activities
            .where((a) {
              final s = a.status.toLowerCase();
              final matchesOfficer = _selectedOfficerId == null || a.createdBy == _selectedOfficerId;
              return matchesOfficer && (s == 'pending_officer_review' || 
                     s == 'pending_absence_review' || 
                     s == 'pending_report_review');
            })
            .length;

        final overdue = activities
            .where((a) {
              final parsed = _parseDate(a.activityDate);
              final matchesOfficer = _selectedOfficerId == null || a.createdBy == _selectedOfficerId;
              return matchesOfficer && parsed != null && parsed.isBefore(DateTime.now()) && 
                     !a.status.toLowerCase().contains('approve') &&
                     !a.status.toLowerCase().contains('absent');
            })
            .length;

        return RefreshIndicator(
          onRefresh: () async {},
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              color: scheme.surfaceVariant,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DashboardHero(
                    scheme: scheme,
                    pendingReviewsCount: pendingReviews,
                    overdueCount: overdue,
                    onPendingTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminActivityList()),
                      );
                    },
                    onOverdueTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminActivityList()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.list_alt),
                      label: const Text('View All Activities'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminActivityList()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SearchAndFilters(
                    scheme: scheme,
                    initialFilter: _timeFilter,
                    onFilterChanged: (value) => setState(() => _timeFilter = value),
                  ),
                  const SizedBox(height: 12),
                  _SectionHeader(
                    title: 'All Activities',
                    actionLabel: 'See all',
                    onActionTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminActivityList()),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  if (allActivities.isEmpty)
                    _EmptyStateCard(
                      icon: Icons.event_note,
                      message: 'No activities available yet.',
                      scheme: scheme,
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: scheme.outlineVariant.withOpacity(0.8)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.025),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(14),
                      height: 340,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.drag_indicator, size: 18, color: scheme.primary.withOpacity(0.8)),
                              const SizedBox(width: 6),
                              Text(
                                'Scroll to explore',
                                style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: scheme.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${allActivities.length} items',
                                  style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: ListView.separated(
                              primary: false,
                              shrinkWrap: true,
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (context, index) {
                                final activity = allActivities[index];
                                final parsedDate = _parseDate(activity.activityDate);
                                return _ActivityCard(
                                  scheme: scheme,
                                  title: activity.title,
                                  subtitle: activity.locationName,
                                  dateText: parsedDate != null ? _formatDate(parsedDate) : activity.activityDate,
                                  timeText: '${activity.startTime} - ${activity.endTime}',
                                  status: activity.status,
                                  badgeText: activity.topic.isNotEmpty ? activity.topic : 'Activity',
                                );
                              },
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemCount: allActivities.length,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Upcoming Activities',
                    actionLabel: 'See all',
                    onActionTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminActivityList()),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  if (filteredActivities.isEmpty)
                    _EmptyStateCard(
                      icon: Icons.event_busy,
                      message: 'No activities match the current filters.',
                      scheme: scheme,
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: scheme.outlineVariant.withOpacity(0.8)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.025),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(14),
                      height: 340,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.drag_indicator, size: 18, color: scheme.primary.withOpacity(0.8)),
                              const SizedBox(width: 6),
                              Text(
                                'Scroll to review',
                                style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: scheme.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${filteredActivities.length} upcoming',
                                  style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.separated(
                              primary: false,
                              shrinkWrap: true,
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (context, index) {
                                final activity = filteredActivities[index];
                                final parsedDate = _parseDate(activity.activityDate);
                                return _ActivityCard(
                                  scheme: scheme,
                                  title: activity.title,
                                  subtitle: activity.locationName,
                                  dateText: parsedDate != null ? _formatDate(parsedDate) : activity.activityDate,
                                  timeText: '${activity.startTime} - ${activity.endTime}',
                                  status: activity.status,
                                  badgeText: activity.topic.isNotEmpty ? activity.topic : 'Activity',
                                );
                              },
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemCount: filteredActivities.length,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Recent Activity Submissions',
                    actionLabel: 'See all',
                    onActionTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminActivityList()),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  if (recentSubmissions.isEmpty)
                    _EmptyStateCard(
                      icon: Icons.outbox,
                      message: 'No submissions have arrived yet.',
                      scheme: scheme,
                    )
                  else
                    Column(
                      children: recentSubmissions.map((activity) {
                        final submittedDate = activity.submissionSubmittedAt ?? _parseDate(activity.activityDate);
                        return _SubmissionCard(
                          scheme: scheme,
                          activityTitle: activity.title,
                          preacher: activity.preacherName ?? 'Preacher pending',
                          badge: activity.status,
                          submittedText: submittedDate != null ? _formatDate(submittedDate) : 'Unscheduled',
                          location: activity.locationName,
                          status: activity.status,
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/Profile&Payment/profile_controller.dart';
import 'muip_officer_payment_page.dart';
import 'officer_approve_payment_page.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileController = Provider.of<ProfileController>(context, listen: false);
      if (profileController.role.trim().isEmpty && !profileController.isLoading) {
        profileController.loadCurrentUserProfile();
      }
    });
  }

  Widget _buildOption(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
      List<Color>? gradient}) {
    final colors = gradient ?? [Theme.of(context).primaryColor.withOpacity(0.95), Theme.of(context).primaryColor.withOpacity(0.75)];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 6)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)]),
                    child: Icon(icon, color: colors.first, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileController>(
      builder: (context, profileController, child) {
        final role = profileController.role.toUpperCase();
        final bool isOfficer = role == 'OFFICER';

        if (profileController.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Payment')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Payment'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Payment', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                if (isOfficer) ...[
                  _buildOption(
                    context,
                    icon: Icons.check_circle_outline,
                    title: 'Approve Payment',
                    subtitle: 'Review and approve pending preacher payments',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OfficerApprovePaymentPage())),
                    gradient: [Colors.deepPurple.shade400, Colors.deepPurple.shade300],
                  ),

                  _buildOption(
                    context,
                    icon: Icons.history,
                    title: 'Payment History',
                    subtitle: 'View past payments and their statuses',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MuipOfficerPaymentPage())),
                    gradient: [Colors.pink.shade300, Colors.pink.shade100],
                  ),
                ] else ...[
                  const SizedBox(height: 40),
                  Center(
                    child: Column(
                      children: const [
                        Icon(Icons.lock_outline, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('Payment management is available to Officers only.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                const Text(
                  'Note: pages use FAKE DATA placeholders until the database is ready.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

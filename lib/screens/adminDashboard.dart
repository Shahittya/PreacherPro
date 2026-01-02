import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../providers/Login/LoginController.dart';
import 'Registeration/officerRegisterPage.dart';
import 'Registeration/registrationRequestPage.dart';
import 'ManageProfile/userProfilePage.dart';
import 'ManagePreacher/PreacherManagementPage.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}
//youserf

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

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
    setState(() {
      _selectedIndex = index;
    });

    // Handle navigation based on index
    switch (index) {
      case 0: // Home
        // Already on dashboard, do nothing
        break;
      case 1: // Preachers
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PreacherManagementPage()),
        ).then((_) => setState(() => _selectedIndex = 0));
        break;
      case 2: // Requests
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const RegistrationRequestPage()),
        );
        break;
      case 3: // Add MUIP
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OfficerRegisterPage()),
        );
        break;
      case 4: // Profile
              Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UserProfilePage()),
        ).then((_) => setState(() => _selectedIndex = 0));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ), //app
        ],
      ),//
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 20),
            const Text(
              'Welcome to Admin Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Your content will be here',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
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
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

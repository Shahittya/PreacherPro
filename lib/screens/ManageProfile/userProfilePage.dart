import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/Profile&Payment/profile_controller.dart';
import 'userUpdateProfilePage.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String _loadState = 'loading';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserProfile();
  }

  Future<void> _loadCurrentUserProfile() async {
    final profileController = Provider.of<ProfileController>(context, listen: false);
    await profileController.loadCurrentUserProfile();
    
    if (mounted) {
      setState(() {
        _loadState = profileController.hasError ? 'error' : 'loaded';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileController>(
      builder: (context, profileController, child) {
        final Color themeColor = profileController.getRoleColor();
        
        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: const Text('Profile'),
            backgroundColor: themeColor,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: _buildBody(profileController, themeColor),

        );
      },
    );
  }

  Widget _buildBody(ProfileController profileController, Color themeColor) {
    if (_loadState == 'loading' || profileController.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: themeColor),
      );
    }

    if (_loadState == 'error' || profileController.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Failed to load profile',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCurrentUserProfile,
              style: ElevatedButton.styleFrom(backgroundColor: themeColor),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header section with profile info
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: themeColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.only(bottom: 30),
            child: Column(
              children: [
                const SizedBox(height: 10),
                // Profile avatar
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 12),
                // Name
                Text(
                  profileController.fullName.isNotEmpty 
                      ? profileController.fullName 
                      : profileController.getRoleDisplayName(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // Email
                Text(
                  profileController.email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Account Information Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Name row
                    _buildInfoRow(
                      icon: Icons.person_outline,
                      label: 'Name',
                      value: profileController.fullName.isNotEmpty 
                          ? profileController.fullName 
                          : profileController.getRoleDisplayName(),
                      themeColor: themeColor,
                    ),
                    
                    const Divider(height: 24),
                    
                    // Email row
                    _buildInfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: profileController.email,
                      themeColor: themeColor,
                    ),
                    
                    const Divider(height: 24),
                    
                    // Phone row
                    _buildInfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: profileController.phoneNumber.isNotEmpty 
                          ? profileController.phoneNumber 
                          : 'Not set',
                      themeColor: themeColor,
                    ),
                    
                    const Divider(height: 24),
                    
                    // Address row
                    _buildInfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Address',
                      value: profileController.address.isNotEmpty 
                          ? profileController.address 
                          : 'Not set',
                      themeColor: themeColor,
                    ),
                    
                    // Show additional fields for Preacher
                    if (profileController.role.toUpperCase() == 'PREACHER') ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        icon: Icons.location_city_outlined,
                        label: 'District',
                        value: profileController.district.isNotEmpty 
                            ? profileController.district 
                            : 'Not set',
                        themeColor: themeColor,
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        icon: Icons.school_outlined,
                        label: 'Qualification',
                        value: profileController.qualification.isNotEmpty 
                            ? profileController.qualification 
                            : 'Not set',
                        themeColor: themeColor,
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Edit account button
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UserUpdateProfilePage(),
                          ),
                        ).then((_) => _loadCurrentUserProfile());
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Tap to edit account details',
                            style: TextStyle(
                              color: themeColor,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            color: themeColor,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color themeColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: themeColor, size: 22),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }


  
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/moderation_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/feedback_screen.dart';
import '../screens/your_channel_screen.dart';
import '../screens/watch_history_screen.dart';
import '../screens/profile_screen.dart';
import '../../core/utils/snackbar_helper.dart';

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.grey[900],
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 20,
              20,
              20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.red.withValues(alpha: 0.3),
                  Colors.red.withValues(alpha: 0.1),
                  Colors.black,
                ],
              ),
            ),
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.currentUser;
                final displayName = user?.name ?? 'User';
                final photoUrl = user?.photoUrl;
                
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[800],
                      backgroundImage: photoUrl != null 
                          ? NetworkImage(photoUrl) 
                          : null,
                      child: photoUrl == null
                          ? Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Settings & Preferences',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[300],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          // Settings Options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Account Section
                _buildSectionHeader('Account'),
                _buildSettingsTile(
                  icon: Icons.person_outline,
                  title: 'Your Channel',
                  subtitle: 'Manage your content and channel',
                  onTap: () => _navigateToChannel(context),
                ),
                _buildSettingsTile(
                  icon: Icons.account_circle_outlined,
                  title: 'Account Info',
                  subtitle: 'View your account details',
                  onTap: () => _showAccountInfo(context),
                ),
                
                const SizedBox(height: 16),
                
                // Content Section
                _buildSectionHeader('Content'),
                _buildSettingsTile(
                  icon: Icons.video_library_outlined,
                  title: 'Your Content',
                  subtitle: 'Manage your videos and shorts',
                  onTap: () => _navigateToYourContent(context),
                ),
                _buildSettingsTile(
                  icon: Icons.subscriptions_outlined,
                  title: 'Subscriptions',
                  subtitle: 'Manage your channel subscriptions',
                  onTap: () => _navigateToSubscriptions(context),
                ),
                _buildSettingsTile(
                  icon: Icons.history,
                  title: 'Watch History',
                  subtitle: 'View your watched videos and shorts',
                  onTap: () => _navigateToWatchHistory(context),
                ),
                
                const SizedBox(height: 16),
                
                // Moderation Section
                _buildSectionHeader('Moderation'),
                _buildSettingsTile(
                  icon: Icons.shield_outlined,
                  title: 'Moderation Panel',
                  subtitle: 'Review reported content',
                  onTap: () => _navigateToModeration(context),
                ),
                
                const SizedBox(height: 16),
                
                // App Section
                _buildSectionHeader('App'),
                _buildSettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'View our privacy policy',
                  onTap: () => _navigateToPrivacyPolicy(context),
                ),
                _buildSettingsTile(
                  icon: Icons.feedback_outlined,
                  title: 'Feedback & Support',
                  subtitle: 'Help us improve the app',
                  onTap: () => _navigateToFeedback(context),
                ),
                
                const SizedBox(height: 16),
                
                // Danger Zone
                _buildSectionHeader('Danger Zone'),
                _buildDangerTile(
                  icon: Icons.logout,
                  title: 'Logout',
                  subtitle: 'Sign out of your account',
                  onTap: () => _handleLogout(context),
                ),
                _buildDangerTile(
                  icon: Icons.delete_forever,
                  title: 'Delete Account',
                  subtitle: 'Permanently delete your account',
                  onTap: () => _handleDeleteAccount(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[400],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[400],
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildDangerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.red, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.red,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[400],
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _navigateToChannel(BuildContext context) {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const YourChannelScreen(),
      ),
    );
  }

  void _showAccountInfo(BuildContext context) {
    Navigator.pop(context); // Close drawer
    // Show account info dialog
    showDialog(
      context: context,
      builder: (context) => _buildAccountInfoDialog(context),
    );
  }

  void _navigateToModeration(BuildContext context) {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ModerationScreen(),
      ),
    );
  }

  void _navigateToPrivacyPolicy(BuildContext context) {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyScreen(),
      ),
    );
  }

  void _navigateToFeedback(BuildContext context) {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FeedbackScreen(),
      ),
    );
  }

  void _navigateToWatchHistory(BuildContext context) {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WatchHistoryScreen(),
      ),
    );
  }

  void _navigateToYourContent(BuildContext context) {
    Navigator.pop(context); // Close drawer
    // Navigate to profile and switch to "Your Account" tab (index 0)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(initialTab: 0),
      ),
    );
  }

  void _navigateToSubscriptions(BuildContext context) {
    Navigator.pop(context); // Close drawer
    // Navigate to profile and switch to "Subscriptions" tab (index 1)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(initialTab: 1),
      ),
    );
  }

  Widget _buildAccountInfoDialog(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        final firebaseUser = authProvider.firebaseUser;
        
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Account Information',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Name', user?.name ?? firebaseUser?.displayName ?? 'Not set'),
              _buildInfoRow('Email', user?.email ?? firebaseUser?.email ?? 'Not set'),
              _buildInfoRow('Member Since', user != null ? _formatDate(user.createdAt) : 'Unknown'),
              if (user?.lastLogin != null)
                _buildInfoRow('Last Login', _formatDate(user!.lastLogin!)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey[900]!.withValues(alpha: 0.95),
                Colors.grey[850]!.withValues(alpha: 0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to logout?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[700]!, width: 1),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey[300], fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldLogout == true && context.mounted) {
      await authProvider.signOut();
    }
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.firebaseUser?.uid;

    if (userId == null) return;

    // Show warning dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Delete Account', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action is permanent and cannot be undone.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'All your data will be permanently deleted:',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 8),
            Text('• Your profile', style: TextStyle(color: Colors.white70)),
            Text('• All uploaded videos', style: TextStyle(color: Colors.white70)),
            Text('• All uploaded shorts', style: TextStyle(color: Colors.white70)),
            Text('• Your comments', style: TextStyle(color: Colors.white70)),
            Text('• Your playlists', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 16),
            Text(
              'Are you absolutely sure?',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    // Show loading dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: Colors.red),
        ),
      );
    }

    try {
      // 1. Delete all user's videos
      final videosQuery = await FirebaseFirestore.instance
          .collection('videos')
          .where('uploadedBy', isEqualTo: userId)
          .get();

      for (var doc in videosQuery.docs) {
        await doc.reference.delete();
      }

      // 2. Delete all user's shorts
      final shortsQuery = await FirebaseFirestore.instance
          .collection('shorts')
          .where('uploadedBy', isEqualTo: userId)
          .get();

      for (var doc in shortsQuery.docs) {
        await doc.reference.delete();
      }

      // 3. Delete user document
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();

      // 4. Delete Firebase Auth account
      await firebase_auth.FirebaseAuth.instance.currentUser?.delete();

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // Show success and navigate to login
      if (context.mounted) {
        SnackBarHelper.showSuccess(
          context,
          'Account deleted successfully',
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // Show error
      if (context.mounted) {
        SnackBarHelper.showError(
          context,
          'Error deleting account: $e',
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

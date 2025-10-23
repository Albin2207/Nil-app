import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Privacy Policy', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: October 21, 2025',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              'Introduction',
              'Nil App ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile application.',
            ),
            
            _buildSection(
              'Information We Collect',
              '• Account Information: Email, username, profile picture\n'
              '• Content: Videos, shorts, comments you upload\n'
              '• Usage Data: Views, likes, subscriptions\n'
              '• Device Information: Device model, OS version\n'
              '• Network Status: Online/offline connectivity',
            ),
            
            _buildSection(
              'How We Use Your Information',
              '• Provide and maintain the app\n'
              '• Personalize your experience\n'
              '• Process uploads and downloads\n'
              '• Send notifications about your content\n'
              '• Improve app performance',
            ),
            
            _buildSection(
              'Data Storage',
              'Your data is securely stored using Firebase services (Google Cloud Platform). We implement industry-standard security measures to protect your information.',
            ),
            
            _buildSection(
              'Your Rights',
              '• Access your data\n'
              '• Delete your account (Settings → Delete Account)\n'
              '• Manage subscriptions\n'
              '• Download your content\n'
              '• Request data export',
            ),
            
            _buildSection(
              'Contact Us',
              'For privacy concerns or questions, contact us at:\nthomasalbin35@gmail.com',
            ),
            
            const SizedBox(height: 24),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => _openPrivacyPolicy(),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('View Full Privacy Policy'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7B61FF),
                  side: const BorderSide(color: Color(0xFF7B61FF)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7B61FF),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[300],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse('https://sites.google.com/view/nilapp-user-help/home');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}


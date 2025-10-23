import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/utils/snackbar_helper.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  String _selectedType = 'Feedback';
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    final email = context.read<AuthProvider>().firebaseUser?.email ?? 'unknown';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Feedback & Report', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF7B61FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF7B61FF).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF7B61FF), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Help us improve! Share your feedback or report issues.',
                      style: TextStyle(color: Colors.grey[300], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Type selector
            Text(
              'Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[300]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTypeChip('Feedback', Icons.feedback_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeChip('Bug Report', Icons.bug_report_outlined),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Subject
            Text(
              'Subject',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[300]),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Brief description',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Message
            Text(
              'Message',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[300]),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Describe your feedback or issue in detail...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _submitFeedback(email),
                icon: const Icon(Icons.send, size: 20),
                label: const Text('Send via Email', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B61FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Alternative contact
            Center(
              child: TextButton.icon(
                onPressed: () => _openHelpPage(),
                icon: const Icon(Icons.help_outline, size: 18),
                label: const Text('Visit Help Center'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[400],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, IconData icon) {
    final isSelected = _selectedType == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7B61FF).withValues(alpha: 0.2) : Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF7B61FF) : Colors.grey[800]!,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF7B61FF) : Colors.grey[500],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF7B61FF) : Colors.grey[400],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitFeedback(String userEmail) async {
    if (_subjectController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      SnackBarHelper.showError(context, 'Please fill in all fields');
      return;
    }

    final subject = Uri.encodeComponent('[$_selectedType] ${_subjectController.text.trim()}');
    final body = Uri.encodeComponent(
      'Type: $_selectedType\n'
      'User: $userEmail\n\n'
      'Message:\n${_messageController.text.trim()}',
    );

    final uri = Uri.parse('mailto:thomasalbin35@gmail.com?subject=$subject&body=$body');

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      if (launched) {
        if (mounted) {
          SnackBarHelper.showSuccess(context, 'Opening email app...', icon: Icons.email);
          _subjectController.clear();
          _messageController.clear();
        }
      } else {
        if (mounted) {
          _showManualEmailDialog(userEmail);
        }
      }
    } catch (e) {
      if (mounted) {
        _showManualEmailDialog(userEmail);
      }
    }
  }

  void _showManualEmailDialog(String userEmail) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Email App Not Found', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please send your feedback manually to:',
              style: TextStyle(color: Colors.grey[300]),
            ),
            const SizedBox(height: 12),
            SelectableText(
              'thomasalbin35@gmail.com',
              style: const TextStyle(
                color: Color(0xFF7B61FF),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Subject: [${_selectedType}] ${_subjectController.text}',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              'Message: ${_messageController.text}',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF7B61FF))),
          ),
        ],
      ),
    );
  }

  Future<void> _openHelpPage() async {
    final uri = Uri.parse('https://sites.google.com/view/nilapp-user-help/home');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}


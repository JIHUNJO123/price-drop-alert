import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Privacy Policy for Price Drop Alert',
              'Last updated: December 2024\n\n'
              'Your privacy is important to us. This Privacy Policy explains how we collect, '
              'use, and protect your personal information when you use Price Drop Alert.',
            ),
            _buildSection(
              '1. Information We Collect',
              'Account Information:\n'
              '• Email address (for account creation and notifications)\n'
              '• Name (optional)\n'
              '• Password (stored securely using encryption)\n\n'
              'Usage Data:\n'
              '• Products you track\n'
              '• Price alert preferences\n'
              '• App usage statistics\n'
              '• Device information',
            ),
            _buildSection(
              '2. How We Use Your Information',
              '• Provide price tracking and alert services\n'
              '• Send notifications about price changes\n'
              '• Improve our services and user experience\n'
              '• Communicate important updates\n'
              '• Prevent fraud and abuse',
            ),
            _buildSection(
              '3. Data Sharing',
              'We do NOT sell your personal information.\n\n'
              'We may share data with:\n'
              '• Service providers who assist in operating our app\n'
              '• Analytics services to improve our app\n'
              '• Law enforcement when required by law',
            ),
            _buildSection(
              '4. Amazon Associates Program',
              'Price Drop Alert is a participant in the Amazon Services LLC Associates Program. '
              'When you click affiliate links, Amazon may collect information according to their privacy policy. '
              'We receive referral fees but no personal data about your purchases.',
            ),
            _buildSection(
              '5. Data Security',
              '• Passwords are encrypted using industry-standard methods\n'
              '• All data is transmitted using HTTPS encryption\n'
              '• We regularly update our security practices\n'
              '• Access to personal data is restricted to authorized personnel',
            ),
            _buildSection(
              '6. Data Retention',
              '• Account data is kept while your account is active\n'
              '• You can request deletion of your account and data\n'
              '• Some data may be retained for legal compliance',
            ),
            _buildSection(
              '7. Your Rights',
              'You have the right to:\n'
              '• Access your personal data\n'
              '• Correct inaccurate data\n'
              '• Delete your account and data\n'
              '• Opt-out of marketing communications\n'
              '• Export your data',
            ),
            _buildSection(
              '8. Push Notifications',
              'We send push notifications for price alerts. You can disable these in:\n'
              '• App Settings > Notifications\n'
              '• Your device\'s notification settings',
            ),
            _buildSection(
              '9. Cookies and Tracking',
              'Our app may use:\n'
              '• Local storage for app preferences\n'
              '• Analytics to understand app usage\n'
              '• Crash reporting to fix bugs',
            ),
            _buildSection(
              '10. Children\'s Privacy',
              'Our service is not intended for children under 13. '
              'We do not knowingly collect information from children under 13. '
              'If you believe a child has provided us with personal information, please contact us.',
            ),
            _buildSection(
              '11. International Users',
              'Your information may be transferred and processed in the United States. '
              'By using our app, you consent to this transfer.',
            ),
            _buildSection(
              '12. Changes to This Policy',
              'We may update this Privacy Policy from time to time. '
              'We will notify you of significant changes through the app or email.',
            ),
            _buildSection(
              '13. Contact Us',
              'If you have questions about this Privacy Policy or want to exercise your rights:\n\n'
              'Email: hoonijo@gmail.com',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

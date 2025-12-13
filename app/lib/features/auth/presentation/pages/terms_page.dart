import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Welcome to Price Drop Alert',
              'Last updated: December 2024\n\n'
              'By using Price Drop Alert ("the App"), you agree to these Terms of Service. '
              'Please read them carefully before using our services.',
            ),
            _buildSection(
              '1. Acceptance of Terms',
              'By downloading, installing, or using the App, you agree to be bound by these Terms. '
              'If you do not agree to these Terms, do not use the App.',
            ),
            _buildSection(
              '2. Description of Service',
              'Price Drop Alert is a price tracking application that:\n'
              '• Monitors product prices from various online retailers\n'
              '• Sends notifications when prices drop\n'
              '• Provides price history and analytics\n'
              '• Offers affiliate links to retailers (we may earn commissions)',
            ),
            _buildSection(
              '3. User Accounts',
              '• You must provide accurate and complete information when creating an account\n'
              '• You are responsible for maintaining the security of your account\n'
              '• You must be at least 13 years old to use this service\n'
              '• One person may not maintain more than one account',
            ),
            _buildSection(
              '4. Acceptable Use',
              'You agree NOT to:\n'
              '• Use the App for any illegal purpose\n'
              '• Attempt to circumvent any security features\n'
              '• Use automated systems to access the App excessively\n'
              '• Interfere with or disrupt the service\n'
              '• Reverse engineer or decompile the App',
            ),
            _buildSection(
              '5. Pricing and Subscriptions',
              '• Free tier: Track up to 3 products\n'
              '• Pro subscription: Unlimited products and premium features\n'
              '• Prices are subject to change with notice\n'
              '• Refunds are handled according to app store policies',
            ),
            _buildSection(
              '6. Price Data Disclaimer',
              '• Price information is provided "as is" without warranty\n'
              '• We do not guarantee the accuracy of price data\n'
              '• Prices may change without notice\n'
              '• We are not responsible for pricing errors by retailers',
            ),
            _buildSection(
              '7. Affiliate Disclosure',
              'Price Drop Alert participates in affiliate programs including Amazon Associates. '
              'We may earn commissions when you make purchases through our links. '
              'This does not affect the price you pay.',
            ),
            _buildSection(
              '8. Intellectual Property',
              'The App and its original content, features, and functionality are owned by '
              'Price Drop Alert and are protected by international copyright, trademark, and other laws.',
            ),
            _buildSection(
              '9. Termination',
              'We may terminate or suspend your account at any time, without prior notice, '
              'for conduct that we believe violates these Terms or is harmful to other users, us, or third parties.',
            ),
            _buildSection(
              '10. Limitation of Liability',
              'To the maximum extent permitted by law, Price Drop Alert shall not be liable for any '
              'indirect, incidental, special, consequential, or punitive damages resulting from your use of the service.',
            ),
            _buildSection(
              '11. Changes to Terms',
              'We reserve the right to modify these Terms at any time. We will notify users of any material changes. '
              'Continued use of the App after changes constitutes acceptance of the new Terms.',
            ),
            _buildSection(
              '12. Contact Us',
              'If you have any questions about these Terms, please contact us at:\n'
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Search
          TextField(
            decoration: InputDecoration(
              hintText: 'Search for help...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
          ),
          const SizedBox(height: 24),
          
          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickAction(
                  context,
                  Icons.email_outlined,
                  'Contact Us',
                  () => _launchEmail(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAction(
                  context,
                  Icons.chat_bubble_outline,
                  'Live Chat',
                  () => _showComingSoon(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // FAQ Section
          Text(
            'Frequently Asked Questions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildFAQItem(
            context,
            'How do I add a product to track?',
            'Simply copy the product URL from any supported store, tap the "+" button in the app, paste the URL, and we\'ll automatically start tracking the price for you.',
          ),
          _buildFAQItem(
            context,
            'Which stores are supported?',
            'We support 50+ major US retailers including Amazon, Walmart, Target, Best Buy, Nike, and many more. Check the "Supported Stores" section in Settings for the full list.',
          ),
          _buildFAQItem(
            context,
            'How often are prices updated?',
            'Prices are checked every 12 hours automatically. You can also manually refresh any product by pulling down on the product detail page.',
          ),
          _buildFAQItem(
            context,
            'How do price alerts work?',
            'When you add a product, you can set a target price. We\'ll notify you immediately when the price drops to or below your target. You can also enable alerts for any price drop.',
          ),
          _buildFAQItem(
            context,
            'What\'s the difference between Free and Pro?',
            'Free users can track up to 10 products. Pro users can track up to 100 products, get priority price checks, and access exclusive features like price history charts and export options.',
          ),
          _buildFAQItem(
            context,
            'Why can\'t I track a specific product?',
            'Some products may not be trackable due to store restrictions or dynamic pricing. If you\'re having trouble, try copying the direct product URL (not a search results page).',
          ),
          _buildFAQItem(
            context,
            'How do I delete my account?',
            'Go to Settings > Account > Delete Account. This will permanently remove your account and all tracked products. This action cannot be undone.',
          ),
          _buildFAQItem(
            context,
            'Is my data secure?',
            'Yes! We use industry-standard encryption to protect your data. We never sell your personal information and only collect data necessary to provide our service.',
          ),
          
          const SizedBox(height: 24),
          
          // Still need help?
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.support_agent,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Still need help?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Our support team is here to help you.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _launchEmail(),
                  icon: const Icon(Icons.email),
                  label: const Text('Email Support'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'jihun.jo@yahoo.com',
      queryParameters: {
        'subject': 'MyPriceDrop - Support Request',
      },
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Live chat coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

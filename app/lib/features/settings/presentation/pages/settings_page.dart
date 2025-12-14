import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

import 'package:in_app_review/in_app_review.dart';

// 설정 상태 관리
final pushNotificationsProvider = StateProvider<bool>((ref) => true);
final selectedPlanProvider = StateProvider<String?>((ref) => null);

// Support email
const String supportEmail = 'jihun.jo@yahoo.com';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pushNotifications = ref.watch(pushNotificationsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          // Profile Section
          _buildSection(
            context,
            title: l10n.account,
            children: [
              _SettingsTile(
                icon: Icons.person_outline,
                title: l10n.profile,
                subtitle: l10n.account,
                onTap: () => _showProfileDialog(context, ref, l10n),
              ),
              _SettingsTile(
                icon: Icons.workspace_premium,
                title: l10n.subscription,
                subtitle: '${l10n.freePlan} · 3 ${l10n.products.toLowerCase()}',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.upgrade,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                onTap: () {
                  _showUpgradeSheet(context);
                },
              ),
            ],
          ),
          
          // Notifications Section
          _buildSection(
            context,
            title: l10n.notifications,
            children: [
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: l10n.pushNotifications,
                subtitle: l10n.notifyWhenPriceDrops.split(' to')[0],
                trailing: Switch(
                  value: pushNotifications,
                  onChanged: (value) {
                    ref.read(pushNotificationsProvider.notifier).state = value;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(value 
                            ? 'Push notifications enabled' 
                            : 'Push notifications disabled'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          
          // App Section
          _buildSection(
            context,
            title: l10n.appearance,
            children: [
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: l10n.darkMode,
                subtitle: _getThemeModeText(themeMode, l10n),
                onTap: () => _showDarkModeDialog(context, ref, l10n),
              ),
              _SettingsTile(
                icon: Icons.language,
                title: l10n.language,
                subtitle: _getCurrentLanguageName(locale),
                onTap: () => _showLanguageDialog(context, ref),
              ),
            ],
          ),
          
          // Support Section
          _buildSection(
            context,
            title: l10n.support,
            children: [
              _SettingsTile(
                icon: Icons.store_outlined,
                title: l10n.supportedStores,
                subtitle: '100+ global retailers',
                onTap: () => context.push('/supported-stores'),
              ),
              _SettingsTile(
                icon: Icons.help_outline,
                title: l10n.helpCenter,
                onTap: () => context.push('/help-center'),
              ),
              _SettingsTile(
                icon: Icons.feedback_outlined,
                title: l10n.sendFeedback,
                onTap: () => _sendFeedbackEmail(),
              ),
              _SettingsTile(
                icon: Icons.star_outline,
                title: l10n.rateApp,
                onTap: () => _rateApp(context),
              ),
            ],
          ),
          
          // Legal Section
          _buildSection(
            context,
            title: 'Legal',
            children: [
              _SettingsTile(
                icon: Icons.description_outlined,
                title: l10n.termsOfService,
                onTap: () => _openUrl('https://mypricedrop.vercel.app/terms.html'),
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: l10n.privacyPolicy,
                onTap: () => _openUrl('https://mypricedrop.vercel.app/privacy.html'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: () {
                _confirmLogout(context, ref);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              child: Text(l10n.logout),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Version
          Center(
            child: Text(
              'Version 1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case ThemeMode.light: return l10n.lightMode;
      case ThemeMode.dark: return l10n.darkMode;
      default: return l10n.lightMode;
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showProfileDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profile),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: const Icon(Icons.person, size: 40, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            const Text('test@example.com'),
            const SizedBox(height: 8),
            Text(
              l10n.freePlan,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.done),
          ),
        ],
      ),
    );
  }

  void _showDarkModeDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final currentMode = ref.read(themeModeProvider);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.theme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: Text(l10n.lightMode),
              value: ThemeMode.light,
              groupValue: currentMode,
              onChanged: (value) {
                ref.read(themeModeProvider.notifier).setThemeMode(value!);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text(l10n.darkMode),
              value: ThemeMode.dark,
              groupValue: currentMode,
              onChanged: (value) {
                ref.read(themeModeProvider.notifier).setThemeMode(value!);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.read(localeProvider);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Language'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // System default option
              ListTile(
                leading: const Text('🌐'),
                title: const Text('System Default'),
                trailing: currentLocale == null
                    ? const Icon(Icons.check, color: AppTheme.primaryColor)
                    : null,
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale(null);
                  Navigator.pop(ctx);
                },
              ),
              const Divider(),
              // English
              _buildLanguageTile(ctx, ref, currentLocale, const Locale('en'), '🇺🇸', 'English'),
              // Spanish
              _buildLanguageTile(ctx, ref, currentLocale, const Locale('es'), '🇪🇸', 'Español'),
              // Portuguese
              _buildLanguageTile(ctx, ref, currentLocale, const Locale('pt'), '🇧🇷', 'Português'),
              // German
              _buildLanguageTile(ctx, ref, currentLocale, const Locale('de'), '🇩🇪', 'Deutsch'),
              // French
              _buildLanguageTile(ctx, ref, currentLocale, const Locale('fr'), '🇫🇷', 'Français'),
              // Japanese
              _buildLanguageTile(ctx, ref, currentLocale, const Locale('ja'), '🇯🇵', '日本語'),
              // Korean
              _buildLanguageTile(ctx, ref, currentLocale, const Locale('ko'), '🇰🇷', '한국어'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageTile(
    BuildContext dialogContext,
    WidgetRef ref,
    Locale? currentLocale,
    Locale locale,
    String flag,
    String name,
  ) {
    final isSelected = currentLocale?.languageCode == locale.languageCode;
    return ListTile(
      leading: Text(flag),
      title: Text(name),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppTheme.primaryColor)
          : null,
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(locale);
        Navigator.pop(dialogContext);
      },
    );
  }

  String _getCurrentLanguageName(Locale? locale) {
    if (locale == null) return 'System Default';
    return LocaleNotifier.getLanguageName(locale.languageCode);
  }

  Future<void> _sendFeedbackEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {
        'subject': 'MyPriceDrop - Feedback',
        'body': 'Hi,\n\nI would like to share my feedback:\n\n',
      },
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _rateApp(BuildContext context) async {
    final InAppReview inAppReview = InAppReview.instance;
    
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    } else {
      // Fallback: open App Store/Play Store directly
      await inAppReview.openStoreListing(
        appStoreId: '6756520351', // Your App Store ID
      );
    }
  }

  void _showRatingDialogLegacy(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rate the App'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enjoying MyPriceDrop?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < 4 ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thank you for rating!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Maybe Later'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: children),
        ),
      ],
    );
  }

  void _showUpgradeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Icon(
                Icons.workspace_premium,
                size: 60,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Upgrade to Pro',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Unlock unlimited price tracking',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              
              // Features
              _FeatureRow(icon: Icons.all_inclusive, text: 'Track unlimited products'),
              _FeatureRow(icon: Icons.speed, text: 'Priority price updates'),
              _FeatureRow(icon: Icons.history, text: '1 year price history'),
              _FeatureRow(icon: Icons.support_agent, text: 'Priority support'),
              
              const SizedBox(height: 32),
              
              // Pricing
              Consumer(
                builder: (context, ref, child) {
                  final selectedPlan = ref.watch(selectedPlanProvider);
                  return Column(
                    children: [
                      _PricingCard(
                        title: 'Monthly',
                        price: '\$4.99',
                        period: '/month',
                        isPopular: false,
                        isSelected: selectedPlan == 'monthly',
                        onTap: () {
                          ref.read(selectedPlanProvider.notifier).state = 'monthly';
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Monthly plan selected'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _PricingCard(
                        title: 'Annual',
                        price: '\$39.99',
                        period: '/year',
                        isPopular: true,
                        isSelected: selectedPlan == 'annual',
                        savings: 'Save 33%',
                        onTap: () {
                          ref.read(selectedPlanProvider.notifier).state = 'annual';
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Annual plan selected'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'Cancel anytime. No questions asked.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authStateProvider.notifier).logout();
              context.go('/login');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accentColor, size: 20),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final bool isPopular;
  final bool isSelected;
  final String? savings;
  final VoidCallback onTap;

  const _PricingCard({
    required this.title,
    required this.price,
    required this.period,
    required this.isPopular,
    this.isSelected = false,
    this.savings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected 
        ? AppTheme.accentColor 
        : (isPopular ? AppTheme.primaryColor : Colors.grey[300]!);
    final borderWidth = isSelected ? 3.0 : (isPopular ? 2.0 : 1.0);
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentColor.withOpacity(0.1) : null,
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (isSelected) ...[
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'BEST VALUE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (savings != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      savings!,
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  period,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

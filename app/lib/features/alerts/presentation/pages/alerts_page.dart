import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/alert_provider.dart';
import '../../../../core/utils/currency_formatter.dart';

class AlertsPage extends ConsumerStatefulWidget {
  const AlertsPage({super.key});

  @override
  ConsumerState<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends ConsumerState<AlertsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(alertProvider.notifier).loadAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final alertState = ref.watch(alertProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.priceAlerts),
        actions: [
          if (alertState.alerts.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(alertProvider.notifier).markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.done)),
                );
              },
              child: Text(l10n.done),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(alertProvider.notifier).loadAlerts(),
        child: alertState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : alertState.alerts.isEmpty
                ? _buildEmptyState(context, l10n)
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: alertState.alerts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _AlertCard(
                        alert: alertState.alerts[index],
                        onTap: () {
                          // 읽음 처리
                          ref.read(alertProvider.notifier).markAsRead(
                            alertState.alerts[index].id,
                          );
                          // 상품 상세로 이동
                          context.push('/product/${alertState.alerts[index].productId}');
                        },
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.notifications_none,
                size: 50,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.priceAlerts,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.notifyWhenPriceDrops,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertItem alert;
  final VoidCallback onTap;

  const _AlertCard({required this.alert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final currency = alert.currency;
    final savings = (alert.oldPrice ?? 0) - (alert.newPrice ?? 0);
    final isTargetReached = alert.alertType == 'target_reached';
    
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: !alert.isRead
                ? Border(
                    left: BorderSide(
                      color: isTargetReached
                          ? AppTheme.accentColor
                          : AppTheme.primaryColor,
                      width: 4,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: alert.productImage != null && alert.productImage!.isNotEmpty
                    ? Image.network(
                        alert.productImage!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
              
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Alert type badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isTargetReached
                                ? AppTheme.accentColor.withValues(alpha: 0.1)
                                : AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isTargetReached
                                    ? Icons.flag
                                    : Icons.trending_down,
                                size: 12,
                                color: isTargetReached
                                    ? AppTheme.accentColor
                                    : AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isTargetReached
                                    ? 'Target Reached!'
                                    : 'Price Drop',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isTargetReached
                                      ? AppTheme.accentColor
                                      : AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatTime(alert.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Product name
                    Text(
                      alert.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Price change
                    if (alert.oldPrice != null && alert.newPrice != null)
                      Row(
                        children: [
                          Text(
                            CurrencyFormatter.format(alert.oldPrice!, currency: currency),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 12),
                          const SizedBox(width: 8),
                          Text(
                            CurrencyFormatter.format(alert.newPrice!, currency: currency),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.priceDropColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (savings > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.priceDropColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '-${CurrencyFormatter.format(savings, currency: currency)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.priceDropColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              
              // Arrow
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey[200],
      child: const Icon(Icons.image),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat.MMMd().format(date);
    }
  }
}

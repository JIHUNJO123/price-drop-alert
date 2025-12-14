import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/product_provider.dart';
import '../../../../core/providers/alert_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/stats_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    // 페이지 로드시 상품 목록 및 알림 불러오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productProvider.notifier).loadProducts();
      ref.read(alertProvider.notifier).loadAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productProvider);
    final alertState = ref.watch(alertProvider);
    final l10n = AppLocalizations.of(context)!;
    
    // 총 절약액 계산 (originalPrice - currentPrice의 합계)
    double totalSavings = 0;
    for (final product in productState.products) {
      if (product.originalPrice != null && product.originalPrice! > product.currentPrice) {
        totalSavings += (product.originalPrice! - product.currentPrice);
      }
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(productProvider.notifier).loadProducts(),
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${l10n.appTitle} 👋',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.trackProduct,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => context.push('/settings'),
                            child: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                              child: const Icon(
                                Icons.person,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Stats Cards
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      StatsCard(
                        title: l10n.products,
                        value: '${productState.products.length}',
                        subtitle: l10n.products.toLowerCase(),
                        icon: Icons.track_changes,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      StatsCard(
                        title: l10n.totalSavings,
                        value: '\$${totalSavings.toStringAsFixed(0)}',
                        subtitle: l10n.priceHistory,
                        icon: Icons.savings,
                        color: AppTheme.accentColor,
                      ),
                      const SizedBox(width: 12),
                      StatsCard(
                        title: l10n.priceAlerts,
                        value: '${alertState.unreadCount}',
                        subtitle: l10n.notifications,
                        icon: Icons.notifications_active,
                        color: AppTheme.secondaryColor,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              
              // Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.products,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (productState.products.isNotEmpty)
                        TextButton(
                          onPressed: () => context.push('/add-product'),
                          child: Text(l10n.addProduct),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Loading state
              if (productState.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              
              // Error state
              if (productState.error != null && !productState.isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                        const SizedBox(height: 8),
                        Text(
                          l10n.failedToLoadProducts,
                          style: TextStyle(color: Colors.red[400]),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => ref.read(productProvider.notifier).loadProducts(),
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Empty state
              if (productState.products.isEmpty && !productState.isLoading && productState.error == null)
                SliverToBoxAdapter(
                  child: _buildEmptyState(context, l10n),
                ),
              
              // Products List
              if (productState.products.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = productState.products[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ProductCard(
                            product: ProductData(
                              id: product.id.toString(),
                              name: product.name,
                              imageUrl: product.imageUrl ?? '',
                              currentPrice: product.currentPrice,
                              originalPrice: product.originalPrice ?? product.currentPrice,
                              domain: product.domain,
                              priceChange: product.priceChangePercent ?? 0,
                              currency: product.currency,
                            ),
                            onTap: () => context.push('/product/${product.id}'),
                          ),
                        );
                      },
                      childCount: productState.products.length,
                    ),
                  ),
                ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-product'),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: Text(l10n.trackProduct),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 50,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.noProducts,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addFirstProduct,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/add-product'),
            icon: const Icon(Icons.add),
            label: Text(l10n.addProduct),
          ),
        ],
      ),
    );
  }
}

// Data class for products
class ProductData {
  final String id;
  final String name;
  final String imageUrl;
  final double currentPrice;
  final double originalPrice;
  final String domain;
  final double priceChange;
  final String currency;

  ProductData({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.currentPrice,
    required this.originalPrice,
    required this.domain,
    required this.priceChange,
    this.currency = 'USD',
  });
}

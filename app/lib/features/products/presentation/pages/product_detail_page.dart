import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/product_provider.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/utils/currency_formatter.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // 상품 목록이 비어있으면 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(productProvider);
      if (state.products.isEmpty) {
        ref.read(productProvider.notifier).loadProducts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productProvider);
    final productId = widget.productId;  // UUID string, not int
    final product = productState.products.where((p) => p.id == productId).firstOrNull;
    final l10n = AppLocalizations.of(context)!;

    if (productState.isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.products)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                l10n.productNotFound,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: Text(l10n.back),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.grey[100],
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                      )
                    : _buildPlaceholderImage(),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showOptionsMenu(context, product),
              ),
            ],
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Domain badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      product.domain,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Product name
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Price section
                  _buildPriceSection(context, product),
                  
                  const SizedBox(height: 24),
                  
                  // Price Statistics
                  _buildPriceStats(context, product),
                  
                  const SizedBox(height: 24),
                  
                  // Price History Chart
                  Text(
                    l10n.priceHistory,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _buildPriceChart(product),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Target Price Setting
                  _buildTargetPriceSection(context, product),
                  
                  const SizedBox(height: 24),
                  
                  // Last updated
                  Center(
                    child: Text(
                      'Last updated: ${_formatLastUpdated(product.lastUpdated ?? product.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Primary action: Buy Now button (with affiliate link)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _buyNow(product.url),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.shopping_cart, size: 22),
                  label: Text(
                    l10n.buyNow,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Secondary actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isRefreshing ? null : () => _refreshPrice(product),
                      icon: _isRefreshing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(_isRefreshing ? l10n.loading : l10n.refreshPrice),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openProductPage(product.url),
                      icon: const Icon(Icons.open_in_new),
                      label: Text(l10n.viewDetails),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'No image available',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(BuildContext context, Product product) {
    final currency = product.currency;
    final hasOriginalPrice = product.originalPrice != null && 
                             product.originalPrice! > product.currentPrice;
    final savings = hasOriginalPrice 
        ? product.originalPrice! - product.currentPrice 
        : 0.0;
    final savingsPercent = hasOriginalPrice 
        ? (savings / product.originalPrice!) * 100 
        : 0.0;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          CurrencyFormatter.format(product.currentPrice, currency: currency),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.priceDropColor,
          ),
        ),
        const SizedBox(width: 12),
        if (hasOriginalPrice) ...[
          Text(
            CurrencyFormatter.format(product.originalPrice!, currency: currency),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              decoration: TextDecoration.lineThrough,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.priceDropColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '-${savingsPercent.toStringAsFixed(0)}%',
              style: const TextStyle(
                color: AppTheme.priceDropColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriceStats(BuildContext context, Product product) {
    final currency = product.currency;
    final l10n = AppLocalizations.of(context)!;
    
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            label: l10n.lowestPrice,
            value: product.lowestPrice != null 
                ? CurrencyFormatter.format(product.lowestPrice!, currency: currency)
                : CurrencyFormatter.format(product.currentPrice, currency: currency),
            color: AppTheme.priceDropColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatBox(
            label: l10n.highestPrice,
            value: product.highestPrice != null 
                ? CurrencyFormatter.format(product.highestPrice!, currency: currency)
                : CurrencyFormatter.format(product.currentPrice, currency: currency),
            color: AppTheme.priceUpColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatBox(
            label: l10n.targetPrice,
            value: product.targetPrice != null 
                ? CurrencyFormatter.format(product.targetPrice!, currency: currency)
                : '-',
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceChart(Product product) {
    // 간단한 차트 데이터 (실제로는 가격 히스토리 API 필요)
    final currentPrice = product.currentPrice;
    final variation = currentPrice * 0.1;
    
    final spots = [
      FlSpot(0, currentPrice + variation),
      FlSpot(5, currentPrice + variation * 0.8),
      FlSpot(10, currentPrice + variation * 0.5),
      FlSpot(15, currentPrice + variation * 0.3),
      FlSpot(20, currentPrice - variation * 0.2),
      FlSpot(25, currentPrice),
      FlSpot(30, currentPrice),
    ];
    
    final minY = (currentPrice - variation * 1.5).floorToDouble();
    final maxY = (currentPrice + variation * 1.5).ceilToDouble();
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey[200],
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) => Text(
                '\$${value.toInt()}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.primaryColor,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primaryColor.withOpacity(0.1),
            ),
          ),
        ],
        minY: minY,
        maxY: maxY,
      ),
    );
  }

  Widget _buildTargetPriceSection(BuildContext context, Product product) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Target Price',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              product.targetPrice != null
                  ? 'We\'ll notify you when the price drops to \$${product.targetPrice!.toStringAsFixed(2)} or below.'
                  : 'Set a target price to get notified when it\'s reached.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showTargetPriceDialog(context, product),
                child: Text(
                  product.targetPrice != null 
                      ? 'Update Target Price' 
                      : 'Set Target Price',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh Price'),
              onTap: () {
                Navigator.pop(ctx);
                _refreshPrice(product);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Target Price'),
              onTap: () {
                Navigator.pop(ctx);
                _showTargetPriceDialog(context, product);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Link'),
              onTap: () {
                Navigator.pop(ctx);
                _copyProductLink(product);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Stop Tracking', 
                style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, product);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTargetPriceDialog(BuildContext context, Product product) {
    final controller = TextEditingController(
      text: product.targetPrice?.toStringAsFixed(2) ?? '',
    );
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Target Price'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current price: \$${product.currentPrice.toStringAsFixed(2)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                prefixText: '\$ ',
                hintText: 'Enter target price',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(controller.text);
              if (price != null && price > 0) {
                Navigator.pop(ctx);
                await _updateTargetPrice(product, price);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid price')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateTargetPrice(Product product, double targetPrice) async {
    final success = await ref.read(productProvider.notifier).updateTargetPrice(
      product.id,
      targetPrice,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? 'Target price set to \$${targetPrice.toStringAsFixed(2)}'
                : 'Failed to update target price',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _refreshPrice(Product product) async {
    setState(() => _isRefreshing = true);
    
    final updated = await ref.read(productProvider.notifier).refreshProduct(product.id);
    
    if (mounted) {
      setState(() => _isRefreshing = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated != null 
                ? 'Price updated: \$${updated.currentPrice.toStringAsFixed(2)}'
                : 'Failed to refresh price',
          ),
          backgroundColor: updated != null ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop Tracking'),
        content: const Text(
          'Are you sure you want to stop tracking this product? '
          'Your price history will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteProduct(product);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    final success = await ref.read(productProvider.notifier).deleteProduct(product.id);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product removed from tracking'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove product'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyProductLink(Product product) {
    Clipboard.setData(ClipboardData(text: product.url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard')),
    );
  }

  /// Open product page with affiliate link (for monetization)
  Future<void> _buyNow(String url) async {
    // Convert to affiliate URL (e.g., Amazon Associates)
    final affiliateUrl = AffiliateConfig.getAffiliateUrl(url);
    final uri = Uri.tryParse(affiliateUrl);
    
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open store page')),
        );
      }
    }
  }

  Future<void> _openProductPage(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open product page')),
        );
      }
    }
  }

  String _formatLastUpdated(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minutes ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else {
      return DateFormat.MMMd().format(date);
    }
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

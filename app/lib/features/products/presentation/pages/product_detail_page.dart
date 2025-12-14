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
import '../../../../core/services/api_service.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  bool _isRefreshing = false;
  List<Map<String, dynamic>>? _priceHistory;
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    // 상품 목록이 비어있으면 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(productProvider);
      if (state.products.isEmpty) {
        ref.read(productProvider.notifier).loadProducts();
      }
      _loadPriceHistory();
    });
  }

  Future<void> _loadPriceHistory() async {
    try {
      final response = await ApiService().getPriceHistory(widget.productId, days: 30);
      if (mounted) {
        setState(() {
          _priceHistory = (response['history'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _priceHistory = [];
          _isLoadingHistory = false;
        });
      }
    }
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
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
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
                      l10n.lastUpdated(_formatLastUpdated(product.lastUpdated ?? product.createdAt)),
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
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            l10n.noImageAvailable,
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
              color: AppTheme.priceDropColor.withValues(alpha: 0.1),
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
    // 로딩 중
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    // 히스토리 데이터 파싱
    final spots = <FlSpot>[];
    final currentPrice = product.currentPrice;
    
    if (_priceHistory != null && _priceHistory!.isNotEmpty) {
      // 실제 가격 히스토리 데이터 사용
      for (var i = 0; i < _priceHistory!.length; i++) {
        final item = _priceHistory![i];
        final price = (item['price'] is num) 
            ? (item['price'] as num).toDouble()
            : double.tryParse(item['price'].toString()) ?? currentPrice;
        spots.add(FlSpot(i.toDouble(), price));
      }
    } else {
      // 히스토리 데이터가 없으면 현재 가격만 표시
      spots.add(FlSpot(0, currentPrice));
      spots.add(FlSpot(1, currentPrice));
    }
    
    // min/max 계산
    final prices = spots.map((s) => s.y).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;
    final padding = priceRange > 0 ? priceRange * 0.2 : currentPrice * 0.1;
    final minY = (minPrice - padding).floorToDouble();
    final maxY = (maxPrice + padding).ceilToDouble();
    
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
              reservedSize: 55,
              getTitlesWidget: (value, meta) => Text(
                CurrencyFormatter.formatCompact(value, currency: product.currency),
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
            dotData: FlDotData(
              show: spots.length < 15,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: AppTheme.primaryColor,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  CurrencyFormatter.format(spot.y, currency: product.currency),
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        minY: minY > 0 ? minY : 0,
        maxY: maxY,
      ),
    );
  }

  Widget _buildTargetPriceSection(BuildContext context, Product product) {
    final l10n = AppLocalizations.of(context)!;
    final currency = product.currency;
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
                  l10n.targetPrice,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              product.targetPrice != null
                  ? l10n.targetPriceNotifyDesc(CurrencyFormatter.format(product.targetPrice!, currency: currency))
                  : l10n.setTargetPriceHint,
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
                      ? l10n.updateTargetPrice 
                      : l10n.setTargetPrice,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context, Product product) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh),
              title: Text(l10n.refreshPrice),
              onTap: () {
                Navigator.pop(ctx);
                _refreshPrice(product);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l10n.updateTargetPrice),
              onTap: () {
                Navigator.pop(ctx);
                _showTargetPriceDialog(context, product);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(l10n.copyLink),
              onTap: () {
                Navigator.pop(ctx);
                _copyProductLink(product);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(l10n.stopTracking, 
                style: const TextStyle(color: Colors.red)),
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
    final l10n = AppLocalizations.of(context)!;
    final currency = product.currency;
    final controller = TextEditingController(
      text: product.targetPrice?.toStringAsFixed(2) ?? '',
    );
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.setTargetPrice),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.currentPriceLabel(CurrencyFormatter.format(product.currentPrice, currency: currency)),
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: '${CurrencyFormatter.getSymbol(currency)} ',
                hintText: l10n.enterTargetPrice,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
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
    final l10n = AppLocalizations.of(context)!;
    final currency = product.currency;
    final success = await ref.read(productProvider.notifier).updateTargetPrice(
      product.id,
      targetPrice,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? l10n.targetPriceNotifyDesc(CurrencyFormatter.format(targetPrice, currency: currency))
                : l10n.somethingWentWrong,
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _refreshPrice(Product product) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isRefreshing = true);
    
    final updated = await ref.read(productProvider.notifier).refreshProduct(product.id);
    
    if (mounted) {
      setState(() => _isRefreshing = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated != null 
                ? l10n.priceUpdated
                : l10n.somethingWentWrong,
          ),
          backgroundColor: updated != null ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context, Product product) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmStopTracking),
        content: Text(l10n.confirmStopTrackingDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteProduct(product);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
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
    final l10n = AppLocalizations.of(context)!;
    Clipboard.setData(ClipboardData(text: product.url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.linkCopied)),
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
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) {
      return l10n.justNow;
    } else if (diff.inMinutes < 60) {
      return l10n.minutesAgo(diff.inMinutes);
    } else if (diff.inHours < 24) {
      return l10n.hoursAgo(diff.inHours);
    } else if (diff.inDays < 7) {
      return l10n.daysAgo(diff.inDays);
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
        color: color.withValues(alpha: 0.1),
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

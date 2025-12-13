import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/product_provider.dart';

class AddProductPage extends ConsumerStatefulWidget {
  const AddProductPage({super.key});

  @override
  ConsumerState<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends ConsumerState<AddProductPage> {
  final _urlController = TextEditingController();
  final _targetPriceController = TextEditingController();
  bool _isLoading = false;
  bool _notifyAnyDrop = false;
  Product? _addedProduct;
  String? _error;

  @override
  void dispose() {
    _urlController.dispose();
    _targetPriceController.dispose();
    super.dispose();
  }

  Future<void> _fetchAndAddProduct() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    
    // Validate URL
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      setState(() {
        _error = 'Please enter a valid URL starting with http:// or https://';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
      _addedProduct = null;
    });
    
    try {
      // Parse target price if provided
      double? targetPrice;
      if (_targetPriceController.text.isNotEmpty) {
        targetPrice = double.tryParse(_targetPriceController.text);
      }
      
      print('Calling addProduct with URL: $url');
      
      // Call API to add and track product
      final product = await ref.read(productProvider.notifier).addProduct(
        url,
        targetPrice: targetPrice,
      );
      
      print('Product result: $product');
      
      if (product != null) {
        setState(() {
          _addedProduct = product;
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Now tracking: ${product.name}'),
              backgroundColor: AppTheme.accentColor,
            ),
          );
          // Navigate back after short delay
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) context.pop();
        }
      } else {
        // Check the provider state for error
        final errorMsg = ref.read(productProvider).error;
        setState(() {
          _error = _getFriendlyErrorMessage(errorMsg);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _fetchAndAddProduct: $e');
      setState(() {
        _error = _getFriendlyErrorMessage(e.toString());
        _isLoading = false;
      });
    }
  }
  
  String _getFriendlyErrorMessage(String? error) {
    if (error == null) return 'Failed to add product. Please try again.';
    
    final lowerError = error.toLowerCase();
    
    if (lowerError.contains('already tracking')) {
      return '🔔 You\'re already tracking this product! Check your tracked items.';
    }
    if (lowerError.contains('could not fetch') || lowerError.contains('could not extract price')) {
      return '😕 Couldn\'t get the price from this page. Try copying the direct product URL (not a search page).';
    }
    if (lowerError.contains('product limit')) {
      return '📦 You\'ve reached your product limit. Upgrade to Pro to track more products!';
    }
    if (lowerError.contains('timeout')) {
      return '⏱️ The page took too long to load. Please try again.';
    }
    if (lowerError.contains('invalid url') || lowerError.contains('invalid value')) {
      return '🔗 Please enter a valid product URL starting with https://';
    }
    if (lowerError.contains('network') || lowerError.contains('connection')) {
      return '📶 Network error. Please check your internet connection.';
    }
    
    return '❌ $error';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Product'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Text(
              'Paste the product URL',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We\'ll automatically track the price and notify you when it drops.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // URL Input
            TextFormField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'https://www.store.com/product...',
                prefixIcon: const Icon(Icons.link),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_urlController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _urlController.clear();
                          setState(() {});
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.content_paste),
                      onPressed: () async {
                        final data = await Clipboard.getData('text/plain');
                        if (data?.text != null) {
                          _urlController.text = data!.text!;
                          setState(() {});
                        }
                      },
                    ),
                  ],
                ),
              ),
              onChanged: (_) => setState(() {}),
              onFieldSubmitted: (_) => _fetchAndAddProduct(),
            ),
            
            const SizedBox(height: 16),
            
            // Fetch button
            if (!_isLoading)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _urlController.text.isNotEmpty ? _fetchAndAddProduct : null,
                  child: const Text('Track This Product'),
                ),
              ),
            
            // Loading
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Adding product...'),
                    ],
                  ),
                ),
              ),
            
            // Error
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, 
                      color: AppTheme.errorColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppTheme.errorColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Preview Card
            if (_addedProduct != null) ...[
              const SizedBox(height: 24),
              _buildSuccessCard(),
            ],
            
            // Target Price Input (shown before adding)
            if (_addedProduct == null && !_isLoading) ...[
              const SizedBox(height: 24),
              
              // Target Price
              Text(
                'Set target price (optional)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _targetPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'e.g., 149.99',
                  prefixIcon: const Icon(Icons.attach_money),
                  helperText: 'We\'ll notify you when the price drops to this amount',
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Supported stores
            Text(
              'Supported Stores',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Target',
                'Best Buy',
                'Walmart',
                'Nike',
                'Shopify stores',
              ].map((store) => Chip(
                label: Text(store),
                backgroundColor: Colors.grey[100],
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, 
                  color: AppTheme.accentColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Product Added!',
                  style: TextStyle(
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _addedProduct!.imageUrl != null 
                    ? Image.network(
                        _addedProduct!.imageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                      )
                    : _buildPlaceholderImage(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _addedProduct!.domain,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _addedProduct!.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${_addedProduct!.currentPrice.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlaceholderImage() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[200],
      child: const Icon(Icons.shopping_bag),
    );
  }
}

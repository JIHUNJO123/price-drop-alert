import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SupportedStoresPage extends StatelessWidget {
  const SupportedStoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    final stores = _getSupportedStores();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supported Stores'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.store,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  '${stores.length}+ Stores Supported',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Track prices from all major US retailers',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search stores...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) {
                // TODO: Implement search filter
              },
            ),
          ),
          
          // Categories
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategory(context, 'General Retail', stores.where((s) => s.category == 'General').toList()),
                _buildCategory(context, 'Electronics', stores.where((s) => s.category == 'Electronics').toList()),
                _buildCategory(context, 'Fashion & Apparel', stores.where((s) => s.category == 'Fashion').toList()),
                _buildCategory(context, 'Sports & Outdoors', stores.where((s) => s.category == 'Sports').toList()),
                _buildCategory(context, 'Home & Garden', stores.where((s) => s.category == 'Home').toList()),
                _buildCategory(context, 'Beauty & Health', stores.where((s) => s.category == 'Beauty').toList()),
                _buildCategory(context, 'Pets', stores.where((s) => s.category == 'Pets').toList()),
                _buildCategory(context, 'Other', stores.where((s) => s.category == 'Other').toList()),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategory(BuildContext context, String title, List<StoreInfo> stores) {
    if (stores.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: stores.map((store) => _buildStoreChip(context, store)).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStoreChip(BuildContext context, StoreInfo store) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: store.color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                store.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            store.name,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  List<StoreInfo> _getSupportedStores() {
    return [
      // General Retail
      StoreInfo('Amazon', 'General', Colors.orange),
      StoreInfo('Walmart', 'General', Colors.blue),
      StoreInfo('Target', 'General', Colors.red),
      StoreInfo('Costco', 'General', Colors.red.shade700),
      StoreInfo('eBay', 'General', Colors.blue.shade700),
      StoreInfo('Etsy', 'General', Colors.orange.shade700),
      StoreInfo('Overstock', 'General', Colors.red.shade600),
      
      // Electronics
      StoreInfo('Best Buy', 'Electronics', Colors.blue.shade800),
      StoreInfo('Newegg', 'Electronics', Colors.orange.shade800),
      StoreInfo('B&H Photo', 'Electronics', Colors.black87),
      StoreInfo('Apple Store', 'Electronics', Colors.grey.shade800),
      StoreInfo('Samsung', 'Electronics', Colors.blue.shade900),
      StoreInfo('GameStop', 'Electronics', Colors.red.shade800),
      StoreInfo('Office Depot', 'Electronics', Colors.red.shade700),
      StoreInfo('Staples', 'Electronics', Colors.red),
      
      // Fashion & Apparel
      StoreInfo('Nike', 'Fashion', Colors.black),
      StoreInfo('Adidas', 'Fashion', Colors.black87),
      StoreInfo("Macy's", 'Fashion', Colors.red),
      StoreInfo('Nordstrom', 'Fashion', Colors.black),
      StoreInfo("Kohl's", 'Fashion', Colors.red.shade700),
      StoreInfo('JCPenney', 'Fashion', Colors.red.shade600),
      StoreInfo('Gap', 'Fashion', Colors.blue.shade900),
      StoreInfo('Old Navy', 'Fashion', Colors.blue),
      StoreInfo('Banana Republic', 'Fashion', Colors.black87),
      StoreInfo('H&M', 'Fashion', Colors.red.shade700),
      StoreInfo('Zara', 'Fashion', Colors.black),
      StoreInfo('Uniqlo', 'Fashion', Colors.red),
      StoreInfo('Lululemon', 'Fashion', Colors.red.shade800),
      StoreInfo('Under Armour', 'Fashion', Colors.black),
      StoreInfo('New Balance', 'Fashion', Colors.red.shade700),
      StoreInfo('Puma', 'Fashion', Colors.black),
      StoreInfo('Reebok', 'Fashion', Colors.red),
      StoreInfo('Foot Locker', 'Fashion', Colors.red.shade900),
      StoreInfo('Finish Line', 'Fashion', Colors.blue.shade800),
      StoreInfo('Zappos', 'Fashion', Colors.blue),
      StoreInfo('ASOS', 'Fashion', Colors.black),
      StoreInfo('Anthropologie', 'Fashion', Colors.pink.shade200),
      StoreInfo('Urban Outfitters', 'Fashion', Colors.black87),
      StoreInfo('Free People', 'Fashion', Colors.brown.shade300),
      StoreInfo('Express', 'Fashion', Colors.black),
      StoreInfo('Abercrombie', 'Fashion', Colors.blue.shade900),
      StoreInfo('Hollister', 'Fashion', Colors.blue.shade700),
      StoreInfo('American Eagle', 'Fashion', Colors.blue.shade800),
      StoreInfo("Victoria's Secret", 'Fashion', Colors.pink),
      StoreInfo('Converse', 'Fashion', Colors.black),
      StoreInfo('Vans', 'Fashion', Colors.black87),
      
      // Sports & Outdoors
      StoreInfo('REI', 'Sports', Colors.green.shade800),
      StoreInfo("Dick's Sporting Goods", 'Sports', Colors.green),
      StoreInfo('Academy Sports', 'Sports', Colors.blue.shade700),
      StoreInfo('Bass Pro Shops', 'Sports', Colors.green.shade900),
      StoreInfo("Cabela's", 'Sports', Colors.brown),
      StoreInfo('Patagonia', 'Sports', Colors.purple.shade800),
      StoreInfo('The North Face', 'Sports', Colors.black),
      StoreInfo('Columbia', 'Sports', Colors.blue.shade800),
      
      // Home & Garden
      StoreInfo('Home Depot', 'Home', Colors.orange.shade800),
      StoreInfo("Lowe's", 'Home', Colors.blue.shade800),
      StoreInfo('Wayfair', 'Home', Colors.purple),
      StoreInfo('Williams Sonoma', 'Home', Colors.black87),
      StoreInfo('Pottery Barn', 'Home', Colors.brown.shade600),
      StoreInfo('Crate & Barrel', 'Home', Colors.black),
      StoreInfo('IKEA', 'Home', Colors.blue.shade800),
      StoreInfo('Michaels', 'Home', Colors.red.shade700),
      StoreInfo('JoAnn', 'Home', Colors.green.shade700),
      StoreInfo('Hobby Lobby', 'Home', Colors.orange.shade700),
      
      // Beauty & Health
      StoreInfo('Sephora', 'Beauty', Colors.black),
      StoreInfo('Ulta', 'Beauty', Colors.orange),
      StoreInfo('CVS', 'Beauty', Colors.red),
      StoreInfo('Walgreens', 'Beauty', Colors.red.shade700),
      StoreInfo('Bath & Body Works', 'Beauty', Colors.blue.shade600),
      
      // Pets
      StoreInfo('Petco', 'Pets', Colors.blue.shade700),
      StoreInfo('PetSmart', 'Pets', Colors.red.shade700),
      StoreInfo('Chewy', 'Pets', Colors.blue),
    ];
  }
}

class StoreInfo {
  final String name;
  final String category;
  final Color color;

  StoreInfo(this.name, this.category, this.color);
}

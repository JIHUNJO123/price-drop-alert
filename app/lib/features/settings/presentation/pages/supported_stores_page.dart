import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SupportedStoresPage extends StatefulWidget {
  const SupportedStoresPage({super.key});

  @override
  State<SupportedStoresPage> createState() => _SupportedStoresPageState();
}

class _SupportedStoresPageState extends State<SupportedStoresPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<CountryStores> _countries = [
    CountryStores(
      flag: '🌍',
      name: 'Global',
      code: 'global',
      stores: [
        StoreInfo('Amazon', 'General', Colors.orange, ['🇺🇸', '🇬🇧', '🇩🇪', '🇫🇷', '🇪🇸', '🇮🇹', '🇯🇵', '🇨🇦', '🇦🇺', '🇧🇷', '🇲🇽', '🇮🇳']),
        StoreInfo('eBay', 'General', Colors.blue.shade700, ['🇺🇸', '🇬🇧', '🇩🇪']),
      ],
    ),
    CountryStores(
      flag: '🇺🇸',
      name: 'United States',
      code: 'us',
      stores: [
        // General Retail
        StoreInfo('Amazon.com', 'General', Colors.orange, []),
        StoreInfo('Walmart', 'General', Colors.blue, []),
        StoreInfo('Target', 'General', Colors.red, []),
        StoreInfo('Costco', 'General', Colors.red.shade700, []),
        StoreInfo('eBay', 'General', Colors.blue.shade700, []),
        StoreInfo('Etsy', 'General', Colors.orange.shade700, []),
        // Electronics
        StoreInfo('Best Buy', 'Electronics', Colors.blue.shade800, []),
        StoreInfo('Newegg', 'Electronics', Colors.orange.shade800, []),
        StoreInfo('B&H Photo', 'Electronics', Colors.black87, []),
        StoreInfo('Apple Store', 'Electronics', Colors.grey.shade800, []),
        StoreInfo('Samsung', 'Electronics', Colors.blue.shade900, []),
        // Fashion
        StoreInfo('Nike', 'Fashion', Colors.black, []),
        StoreInfo('Adidas', 'Fashion', Colors.black87, []),
        StoreInfo("Macy's", 'Fashion', Colors.red, []),
        StoreInfo('Nordstrom', 'Fashion', Colors.black, []),
        StoreInfo('Gap', 'Fashion', Colors.blue.shade900, []),
        StoreInfo('Old Navy', 'Fashion', Colors.blue, []),
        StoreInfo('H&M', 'Fashion', Colors.red.shade700, []),
        StoreInfo('Zara', 'Fashion', Colors.black, []),
        StoreInfo('Uniqlo', 'Fashion', Colors.red, []),
        StoreInfo('Zappos', 'Fashion', Colors.blue, []),
        // Home
        StoreInfo('Home Depot', 'Home', Colors.orange.shade800, []),
        StoreInfo("Lowe's", 'Home', Colors.blue.shade800, []),
        StoreInfo('Wayfair', 'Home', Colors.purple, []),
        StoreInfo('IKEA', 'Home', Colors.blue.shade800, []),
        // Beauty
        StoreInfo('Sephora', 'Beauty', Colors.black, []),
        StoreInfo('Ulta', 'Beauty', Colors.orange, []),
        // Sports
        StoreInfo('REI', 'Sports', Colors.green.shade800, []),
        StoreInfo("Dick's", 'Sports', Colors.green, []),
        // Pets
        StoreInfo('Petco', 'Pets', Colors.blue.shade700, []),
        StoreInfo('Chewy', 'Pets', Colors.blue, []),
      ],
    ),
    CountryStores(
      flag: '🇬🇧',
      name: 'United Kingdom',
      code: 'uk',
      stores: [
        StoreInfo('Amazon.co.uk', 'General', Colors.orange, []),
        StoreInfo('eBay UK', 'General', Colors.blue.shade700, [], comingSoon: true),
        StoreInfo('Argos', 'General', Colors.red, [], comingSoon: true),
        StoreInfo('John Lewis', 'General', Colors.green.shade800, [], comingSoon: true),
        StoreInfo('Currys', 'Electronics', Colors.purple, [], comingSoon: true),
      ],
    ),
    CountryStores(
      flag: '🇩🇪',
      name: 'Germany',
      code: 'de',
      stores: [
        StoreInfo('Amazon.de', 'General', Colors.orange, []),
        StoreInfo('eBay.de', 'General', Colors.blue.shade700, [], comingSoon: true),
        StoreInfo('Otto', 'General', Colors.red, [], comingSoon: true),
        StoreInfo('MediaMarkt', 'Electronics', Colors.red.shade800, [], comingSoon: true),
        StoreInfo('Saturn', 'Electronics', Colors.orange.shade800, [], comingSoon: true),
      ],
    ),
    CountryStores(
      flag: '🇫🇷',
      name: 'France',
      code: 'fr',
      stores: [
        StoreInfo('Amazon.fr', 'General', Colors.orange, []),
        StoreInfo('Fnac', 'Electronics', Colors.orange.shade700, [], comingSoon: true),
        StoreInfo('Cdiscount', 'General', Colors.red, [], comingSoon: true),
        StoreInfo('Darty', 'Electronics', Colors.red.shade700, [], comingSoon: true),
      ],
    ),
    CountryStores(
      flag: '🇪🇸',
      name: 'Spain',
      code: 'es',
      stores: [
        StoreInfo('Amazon.es', 'General', Colors.orange, []),
        StoreInfo('El Corte Inglés', 'General', Colors.green.shade800, [], comingSoon: true),
        StoreInfo('PCComponentes', 'Electronics', Colors.orange.shade800, [], comingSoon: true),
      ],
    ),
    CountryStores(
      flag: '🇮🇹',
      name: 'Italy',
      code: 'it',
      stores: [
        StoreInfo('Amazon.it', 'General', Colors.orange, []),
        StoreInfo('Unieuro', 'Electronics', Colors.blue.shade800, [], comingSoon: true),
        StoreInfo('MediaWorld', 'Electronics', Colors.red, [], comingSoon: true),
      ],
    ),
    CountryStores(
      flag: '🇯🇵',
      name: 'Japan',
      code: 'jp',
      stores: [
        StoreInfo('Amazon.co.jp', 'General', Colors.orange, []),
        StoreInfo('Rakuten', 'General', Colors.red, [], comingSoon: true),
        StoreInfo('Yodobashi', 'Electronics', Colors.red.shade800, [], comingSoon: true),
        StoreInfo('Bic Camera', 'Electronics', Colors.blue, [], comingSoon: true),
      ],
    ),
    CountryStores(
      flag: '🇨🇦',
      name: 'Canada',
      code: 'ca',
      stores: [
        StoreInfo('Amazon.ca', 'General', Colors.orange, []),
        StoreInfo('Best Buy Canada', 'Electronics', Colors.blue.shade800, [], comingSoon: true),
        StoreInfo('Canadian Tire', 'General', Colors.red, [], comingSoon: true),
      ],
    ),
    CountryStores(
      flag: '🇦🇺',
      name: 'Australia',
      code: 'au',
      stores: [
        StoreInfo('Amazon.com.au', 'General', Colors.orange, []),
        StoreInfo('JB Hi-Fi', 'Electronics', Colors.black, [], comingSoon: true),
        StoreInfo('Kogan', 'General', Colors.blue, [], comingSoon: true),
      ],
    ),
    CountryStores(
      flag: '🇧🇷',
      name: 'Brazil',
      code: 'br',
      stores: [
        StoreInfo('Amazon.com.br', 'General', Colors.orange, []),
        StoreInfo('Magazine Luiza', 'General', Colors.blue, [], comingSoon: true),
        StoreInfo('Americanas', 'General', Colors.red, [], comingSoon: true),
      ],
    ),
    CountryStores(
      flag: '🇲🇽',
      name: 'Mexico',
      code: 'mx',
      stores: [
        StoreInfo('Amazon.com.mx', 'General', Colors.orange, []),
        StoreInfo('Mercado Libre', 'General', Colors.yellow.shade700, [], comingSoon: true),
        StoreInfo('Liverpool', 'General', Colors.pink, [], comingSoon: true),
      ],
    ),
    CountryStores(
      flag: '🇮🇳',
      name: 'India',
      code: 'in',
      stores: [
        StoreInfo('Amazon.in', 'General', Colors.orange, []),
        StoreInfo('Flipkart', 'General', Colors.blue, [], comingSoon: true),
        StoreInfo('Myntra', 'Fashion', Colors.pink, [], comingSoon: true),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _countries.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supported Stores'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _countries.map((country) => Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(country.flag, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(country.code.toUpperCase()),
              ],
            ),
          )).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _countries.map((country) => _buildCountryTab(context, country)).toList(),
      ),
    );
  }

  Widget _buildCountryTab(BuildContext context, CountryStores country) {
    final activeStores = country.stores.where((s) => !s.comingSoon).length;
    final comingSoonStores = country.stores.where((s) => s.comingSoon).length;
    
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Column(
            children: [
              Text(
                country.flag,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 8),
              Text(
                country.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatChip(context, '$activeStores Active', Colors.green),
                  if (comingSoonStores > 0) ...[
                    const SizedBox(width: 8),
                    _buildStatChip(context, '$comingSoonStores Coming Soon', Colors.orange),
                  ],
                ],
              ),
            ],
          ),
        ),
        
        // Stores list
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (activeStores > 0) ...[
                _buildSectionHeader(context, '✅ Active Stores'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: country.stores
                      .where((s) => !s.comingSoon)
                      .map((store) => _buildStoreChip(context, store))
                      .toList(),
                ),
                const SizedBox(height: 24),
              ],
              if (comingSoonStores > 0) ...[
                _buildSectionHeader(context, '🚀 Coming Soon'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: country.stores
                      .where((s) => s.comingSoon)
                      .map((store) => _buildStoreChip(context, store))
                      .toList(),
                ),
              ],
              const SizedBox(height: 24),
              
              // Currency info
              if (country.code != 'global') ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.monetization_on_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Prices are displayed in local currency (${_getCurrency(country.code)})',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStoreChip(BuildContext context, StoreInfo store) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: store.comingSoon
            ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: store.comingSoon
              ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            store.name,
            style: TextStyle(
              fontSize: 13,
              color: store.comingSoon
                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                  : null,
            ),
          ),
          if (store.countries.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              store.countries.join(' '),
              style: const TextStyle(fontSize: 10),
            ),
          ],
          if (store.comingSoon) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Soon',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getCurrency(String countryCode) {
    switch (countryCode) {
      case 'us':
        return 'USD \$';
      case 'uk':
        return 'GBP £';
      case 'de':
      case 'fr':
      case 'es':
      case 'it':
        return 'EUR €';
      case 'jp':
        return 'JPY ¥';
      case 'ca':
        return 'CAD \$';
      case 'au':
        return 'AUD \$';
      case 'br':
        return 'BRL R\$';
      case 'mx':
        return 'MXN \$';
      case 'in':
        return 'INR ₹';
      default:
        return 'USD \$';
    }
  }
}

class CountryStores {
  final String flag;
  final String name;
  final String code;
  final List<StoreInfo> stores;

  CountryStores({
    required this.flag,
    required this.name,
    required this.code,
    required this.stores,
  });
}

class StoreInfo {
  final String name;
  final String category;
  final Color color;
  final List<String> countries;
  final bool comingSoon;

  StoreInfo(
    this.name,
    this.category,
    this.color,
    this.countries, {
    this.comingSoon = false,
  });
}

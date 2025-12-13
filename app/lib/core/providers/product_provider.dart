import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

/// 상품 모델
class Product {
  final String id;
  final String name;
  final String url;
  final String domain;
  final double currentPrice;
  final double? originalPrice;
  final double? lowestPrice;
  final double? highestPrice;
  final double? targetPrice;
  final String? imageUrl;
  final DateTime? lastUpdated;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.url,
    required this.domain,
    required this.currentPrice,
    this.originalPrice,
    this.lowestPrice,
    this.highestPrice,
    this.targetPrice,
    this.imageUrl,
    this.lastUpdated,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      url: json['url']?.toString() ?? '',
      domain: json['domain']?.toString() ?? '',
      currentPrice: _parseDouble(json['current_price']),
      originalPrice: _parseDoubleNullable(json['original_price']),
      lowestPrice: _parseDoubleNullable(json['lowest_price']),
      highestPrice: _parseDoubleNullable(json['highest_price']),
      targetPrice: _parseDoubleNullable(json['target_price']),
      imageUrl: json['image_url']?.toString(),
      lastUpdated: json['last_crawled_at'] != null 
          ? DateTime.tryParse(json['last_crawled_at'].toString())
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }
  
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
  
  static double? _parseDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // 가격 변동 퍼센트 계산
  double? get priceChangePercent {
    if (originalPrice == null || originalPrice == 0) return null;
    return ((currentPrice - originalPrice!) / originalPrice!) * 100;
  }
}

/// 상품 목록 상태
class ProductState {
  final List<Product> products;
  final bool isLoading;
  final String? error;

  ProductState({
    this.products = const [],
    this.isLoading = false,
    this.error,
  });

  ProductState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? error,
  }) {
    return ProductState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 상품 Provider
class ProductNotifier extends StateNotifier<ProductState> {
  final ApiService _apiService;

  ProductNotifier(this._apiService) : super(ProductState());

  /// 상품 목록 불러오기
  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final data = await _apiService.getProducts();
      final products = data.map((json) => Product.fromJson(json)).toList();
      state = state.copyWith(products: products, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 상품 추가
  Future<Product?> addProduct(String url, {double? targetPrice}) async {
    try {
      final data = await _apiService.addProduct(url, targetPrice: targetPrice);
      final product = Product.fromJson(data);
      state = state.copyWith(products: [...state.products, product]);
      return product;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// 상품 삭제
  Future<bool> deleteProduct(String productId) async {
    try {
      await _apiService.deleteProduct(productId);
      state = state.copyWith(
        products: state.products.where((p) => p.id != productId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// 가격 새로고침
  Future<Product?> refreshProduct(String productId) async {
    try {
      final data = await _apiService.refreshProduct(productId);
      final updatedProduct = Product.fromJson(data);
      
      state = state.copyWith(
        products: state.products.map((p) {
          if (p.id == productId) return updatedProduct;
          return p;
        }).toList(),
      );
      return updatedProduct;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// 목표 가격 설정
  Future<bool> updateTargetPrice(String productId, double targetPrice) async {
    try {
      await _apiService.updateTargetPrice(productId, targetPrice);
      
      state = state.copyWith(
        products: state.products.map((p) {
          if (p.id == productId) {
            return Product(
              id: p.id,
              name: p.name,
              url: p.url,
              domain: p.domain,
              currentPrice: p.currentPrice,
              originalPrice: p.originalPrice,
              lowestPrice: p.lowestPrice,
              highestPrice: p.highestPrice,
              targetPrice: targetPrice,
              imageUrl: p.imageUrl,
              lastUpdated: p.lastUpdated,
              createdAt: p.createdAt,
            );
          }
          return p;
        }).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// ID로 상품 찾기
  Product? getProductById(String id) {
    try {
      return state.products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}

/// Provider 정의
final productProvider = StateNotifierProvider<ProductNotifier, ProductState>((ref) {
  return ProductNotifier(ApiService());
});

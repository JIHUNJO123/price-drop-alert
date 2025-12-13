import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

// Auth State
class AuthState {
  final bool isLoggedIn;
  final String? token;
  final User? user;
  final bool isLoading;
  final String? error;
  
  AuthState({
    this.isLoggedIn = false,
    this.token,
    this.user,
    this.isLoading = false,
    this.error,
  });
  
  AuthState copyWith({
    bool? isLoggedIn,
    String? token,
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      token: token ?? this.token,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// User Model
class User {
  final String id;
  final String email;
  final String? name;
  final String subscriptionTier;
  final String subscriptionStatus;
  final int productCount;
  final int maxProducts;
  
  User({
    required this.id,
    required this.email,
    this.name,
    required this.subscriptionTier,
    required this.subscriptionStatus,
    required this.productCount,
    required this.maxProducts,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString(),
      subscriptionTier: json['subscription_tier']?.toString() ?? 'free',
      subscriptionStatus: json['subscription_status']?.toString() ?? 'trial',
      productCount: json['product_count'] ?? 0,
      maxProducts: json['max_products'] ?? 3,
    );
  }
  
  bool get canAddProduct => productCount < maxProducts;
  bool get isPro => subscriptionTier != 'free';
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage;
  final ApiService _api = ApiService();
  
  AuthNotifier(this._storage) : super(AuthState()) {
    _loadToken();
  }
  
  Future<void> _loadToken() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      state = state.copyWith(isLoggedIn: true, token: token);
      // Fetch user profile
      try {
        final userData = await _api.getMe();
        state = state.copyWith(
          user: User.fromJson(userData),
        );
      } catch (e) {
        // Token expired, logout
        await logout();
      }
    }
  }
  
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _api.login(email, password);
      final token = response['access_token'];
      
      await _storage.write(key: 'access_token', value: token);
      
      // Fetch user profile
      final userData = await _api.getMe();
      
      state = state.copyWith(
        isLoggedIn: true,
        token: token,
        user: User.fromJson(userData),
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Connection failed. Check your network.',
      );
    }
  }
  
  Future<void> register(String email, String password, String? name) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _api.register(email, password, name);
      final token = response['access_token'];
      
      await _storage.write(key: 'access_token', value: token);
      
      // Fetch user profile
      final userData = await _api.getMe();
      
      state = state.copyWith(
        isLoggedIn: true,
        token: token,
        user: User.fromJson(userData),
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Connection failed. Check your network.',
      );
    }
  }
  
  Future<void> logout() async {
    await _api.logout();
    state = AuthState();
  }
}

// Providers
final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(storage);
});

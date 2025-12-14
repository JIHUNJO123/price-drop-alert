import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

/// API Service - 백엔드 API 통신
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _storage = const FlutterSecureStorage();
  
  // 저장된 토큰 가져오기
  Future<String?> get _token async => await _storage.read(key: 'access_token');
  
  // 공통 헤더
  Future<Map<String, String>> get _headers async {
    final token = await _token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ============== Auth ==============
  
  /// 로그인
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(ApiConfig.authLogin),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await _storage.write(key: 'access_token', value: data['access_token']);
      return data;
    } else {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }
  
  /// 회원가입
  Future<Map<String, dynamic>> register(String email, String password, String? name) async {
    final response = await http.post(
      Uri.parse(ApiConfig.authRegister),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        if (name != null) 'name': name,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await _storage.write(key: 'access_token', value: data['access_token']);
      return data;
    } else {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }
  
  /// 현재 사용자 정보
  Future<Map<String, dynamic>> getMe() async {
    final response = await http.get(
      Uri.parse(ApiConfig.authMe),
      headers: await _headers,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }
  
  /// 로그아웃
  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
  }

  // ============== Products ==============
  
  /// 상품 목록 가져오기
  Future<List<dynamic>> getProducts() async {
    final response = await http.get(
      Uri.parse(ApiConfig.products),
      headers: await _headers,
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // API returns { "products": [...], "total": N, "has_more": bool }
      if (data is Map && data.containsKey('products')) {
        return data['products'] as List<dynamic>;
      }
      return data is List ? data : [];
    } else {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }
  
  /// 상품 추가 (URL로 트래킹)
  Future<Map<String, dynamic>> addProduct(String url, {double? targetPrice}) async {
    try {
      final headers = await _headers;
      
      final body = json.encode({
        'url': url,
        if (targetPrice != null) 'target_price': targetPrice,
      });
      
      final response = await http.post(
        Uri.parse(ApiConfig.products),
        headers: headers,
        body: body,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw ApiException(response.statusCode, _parseError(response.body));
      }
    } catch (e) {
      rethrow;
    }
  }
  
  /// 상품 삭제
  Future<void> deleteProduct(String productId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.products}/$productId'),
      headers: await _headers,
    );
    
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }
  
  /// 상품 가격 새로고침
  Future<Map<String, dynamic>> refreshProduct(String productId) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.products}/$productId/refresh'),
      headers: await _headers,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }
  
  /// 목표 가격 업데이트
  Future<Map<String, dynamic>> updateTargetPrice(String productId, double targetPrice) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.products}/$productId'),
      headers: await _headers,
      body: json.encode({
        'target_price': targetPrice,
      }),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  // ============== Alerts ==============
  
  /// 알림 목록
  Future<Map<String, dynamic>> getAlerts() async {
    final response = await http.get(
      Uri.parse(ApiConfig.alerts),
      headers: await _headers,
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // API returns { "alerts": [...], "total": N, "unread_count": N }
      return data is Map<String, dynamic> ? data : {'alerts': [], 'total': 0, 'unread_count': 0};
    } else {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }
  
  /// 알림 생성
  Future<Map<String, dynamic>> createAlert(int productId, double targetPrice) async {
    final response = await http.post(
      Uri.parse(ApiConfig.alerts),
      headers: await _headers,
      body: json.encode({
        'product_id': productId,
        'target_price': targetPrice,
      }),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }
  
  /// 알림 읽음 처리
  Future<void> markAlertRead(int alertId) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.alerts}/$alertId/read'),
      headers: await _headers,
    );
    
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }
  
  /// 모든 알림 읽음 처리
  Future<void> markAllAlertsRead() async {
    final response = await http.post(
      Uri.parse('${ApiConfig.alerts}/read-all'),
      headers: await _headers,
    );
    
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  // ============== Stats ==============
  
  /// 대시보드 통계
  Future<Map<String, dynamic>> getDashboard() async {
    final response = await http.get(
      Uri.parse(ApiConfig.stats),
      headers: await _headers,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  // ============== Helpers ==============
  
  String _parseError(String body) {
    try {
      final data = json.decode(body);
      return data['detail'] ?? 'Unknown error';
    } catch (e) {
      return 'Server error';
    }
  }
}

/// API 예외
class ApiException implements Exception {
  final int statusCode;
  final String message;
  
  ApiException(this.statusCode, this.message);
  
  @override
  String toString() => 'ApiException: $statusCode - $message';
}

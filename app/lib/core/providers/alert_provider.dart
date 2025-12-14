import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

/// 알림 모델
class AlertItem {
  final int id;
  final int productId;
  final String productName;
  final String? productImage;
  final String alertType;
  final double? oldPrice;
  final double? newPrice;
  final double? targetPrice;
  final String currency;
  final bool isRead;
  final DateTime createdAt;

  AlertItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.alertType,
    this.oldPrice,
    this.newPrice,
    this.targetPrice,
    this.currency = 'USD',
    required this.isRead,
    required this.createdAt,
  });

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    return AlertItem(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      productName: json['product_name']?.toString() ?? 'Unknown',
      productImage: json['product_image']?.toString(),
      alertType: json['alert_type']?.toString() ?? 'price_drop',
      oldPrice: json['old_price']?.toDouble(),
      newPrice: json['new_price']?.toDouble(),
      targetPrice: json['target_price']?.toDouble(),
      currency: json['currency']?.toString() ?? 'USD',
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  AlertItem copyWith({bool? isRead}) {
    return AlertItem(
      id: id,
      productId: productId,
      productName: productName,
      productImage: productImage,
      alertType: alertType,
      oldPrice: oldPrice,
      newPrice: newPrice,
      targetPrice: targetPrice,
      currency: currency,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

/// 알림 상태
class AlertState {
  final List<AlertItem> alerts;
  final bool isLoading;
  final String? error;

  AlertState({
    this.alerts = const [],
    this.isLoading = false,
    this.error,
  });

  AlertState copyWith({
    List<AlertItem>? alerts,
    bool? isLoading,
    String? error,
  }) {
    return AlertState(
      alerts: alerts ?? this.alerts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get unreadCount => alerts.where((a) => !a.isRead).length;
}

/// 알림 Provider
class AlertNotifier extends StateNotifier<AlertState> {
  final ApiService _apiService;

  AlertNotifier(this._apiService) : super(AlertState());

  /// 알림 목록 불러오기
  Future<void> loadAlerts() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final data = await _apiService.getAlerts();
      final alerts = data.map((json) => AlertItem.fromJson(json)).toList();
      state = state.copyWith(alerts: alerts, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 알림 읽음 처리
  Future<void> markAsRead(int alertId) async {
    try {
      await _apiService.markAlertRead(alertId);
      state = state.copyWith(
        alerts: state.alerts.map((a) {
          if (a.id == alertId) return a.copyWith(isRead: true);
          return a;
        }).toList(),
      );
    } catch (e) {
      // 실패해도 UI에서는 읽음 처리
      state = state.copyWith(
        alerts: state.alerts.map((a) {
          if (a.id == alertId) return a.copyWith(isRead: true);
          return a;
        }).toList(),
      );
    }
  }

  /// 모든 알림 읽음 처리
  Future<void> markAllAsRead() async {
    try {
      await _apiService.markAllAlertsRead();
      state = state.copyWith(
        alerts: state.alerts.map((a) => a.copyWith(isRead: true)).toList(),
      );
    } catch (e) {
      // 실패해도 UI에서는 읽음 처리
      state = state.copyWith(
        alerts: state.alerts.map((a) => a.copyWith(isRead: true)).toList(),
      );
    }
  }
}

/// Provider 정의
final alertProvider = StateNotifierProvider<AlertNotifier, AlertState>((ref) {
  return AlertNotifier(ApiService());
});

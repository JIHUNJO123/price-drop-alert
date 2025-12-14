/// API Configuration
/// 
/// 배포 전에 이 값을 서버 URL로 변경하세요.

class ApiConfig {
  // 개발 환경: 로컬 컴퓨터 IP (폰 테스트용)
  // 폰과 컴퓨터가 같은 WiFi에 연결되어 있어야 합니다.
  static const String devBaseUrl = 'http://192.168.0.92:8000';
  
  // 프로덕션 환경: 배포된 서버 URL
  static const String prodBaseUrl = 'https://api.yourdomain.com';
  
  // 현재 사용할 URL (개발 중에는 devBaseUrl 사용)
  static const String baseUrl = devBaseUrl;
  
  // API 버전
  static const String apiVersion = 'v1';
  
  // 전체 API URL
  static String get apiUrl => '$baseUrl/api/$apiVersion';
  
  // 엔드포인트들
  static String get authLogin => '$apiUrl/auth/login';
  static String get authRegister => '$apiUrl/auth/register';
  static String get authMe => '$apiUrl/auth/me';
  static String get products => '$apiUrl/products';
  static String get alerts => '$apiUrl/alerts';
  static String get stats => '$apiUrl/stats';
  
  // 타임아웃 설정
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

/// Affiliate Configuration
/// Amazon Associates Store ID: pricedrop2009-20
/// ✅ 활성화됨!
class AffiliateConfig {
  // Amazon Associates 태그 - 활성!
  static const String amazonTag = 'pricedrop2009-20';
  
  // 다른 Affiliate 프로그램 태그들
  static const String bestBuyTag = ''; // Best Buy Affiliate
  static const String walmartTag = ''; // Walmart Affiliate
  static const String targetTag = ''; // Target Affiliate
  
  /// Amazon URL을 Affiliate 링크로 변환
  static String getAmazonAffiliateUrl(String originalUrl) {
    if (!originalUrl.contains('amazon.com')) return originalUrl;
    if (amazonTag.isEmpty) return originalUrl;
    
    // URL에 이미 태그가 있으면 제거
    final uri = Uri.parse(originalUrl);
    final params = Map<String, String>.from(uri.queryParameters);
    params['tag'] = amazonTag;
    
    return uri.replace(queryParameters: params).toString();
  }
  
  /// 모든 스토어 URL을 Affiliate 링크로 변환
  static String getAffiliateUrl(String originalUrl) {
    final url = originalUrl.toLowerCase();
    
    if (url.contains('amazon.com')) {
      return getAmazonAffiliateUrl(originalUrl);
    }
    // TODO: 다른 스토어 Affiliate 추가
    // if (url.contains('bestbuy.com')) { ... }
    
    return originalUrl;
  }
}

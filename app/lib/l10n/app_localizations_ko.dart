// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'MyPriceDrop';

  @override
  String get home => '홈';

  @override
  String get settings => '설정';

  @override
  String get profile => '프로필';

  @override
  String get login => '로그인';

  @override
  String get logout => '로그아웃';

  @override
  String get email => '이메일';

  @override
  String get password => '비밀번호';

  @override
  String get signup => '회원가입';

  @override
  String get forgotPassword => '비밀번호를 잊으셨나요?';

  @override
  String get createAccount => '계정 만들기';

  @override
  String get alreadyHaveAccount => '이미 계정이 있으신가요?';

  @override
  String get dontHaveAccount => '계정이 없으신가요?';

  @override
  String get trackProduct => '상품 추적';

  @override
  String get addProduct => '상품 추가';

  @override
  String get pasteUrl => '상품 URL 붙여넣기';

  @override
  String get enterUrl => '지원되는 쇼핑몰의 상품 URL을 입력하세요';

  @override
  String get supportedStores => '지원 쇼핑몰';

  @override
  String get preview => '미리보기';

  @override
  String get startTracking => '추적 시작';

  @override
  String get currentPrice => '현재 가격';

  @override
  String get targetPrice => '목표 가격';

  @override
  String get setTargetPrice => '목표 가격 설정';

  @override
  String get priceHistory => '가격 히스토리';

  @override
  String get lowestPrice => '최저가';

  @override
  String get highestPrice => '최고가';

  @override
  String get averagePrice => '평균 가격';

  @override
  String get priceDropAlert => '가격 하락 알림';

  @override
  String get notifyWhenPriceDrops => '가격이 떨어지면 알림';

  @override
  String get products => '상품';

  @override
  String get noProducts => '추적 중인 상품이 없습니다';

  @override
  String get addFirstProduct => '첫 번째 상품을 추가하여 가격 추적을 시작하세요';

  @override
  String get refreshPrice => '가격 새로고침';

  @override
  String get stopTracking => '추적 중지';

  @override
  String get buyNow => '지금 구매';

  @override
  String get viewDetails => '상세 보기';

  @override
  String get copyLink => '링크 복사';

  @override
  String get linkCopied => '링크가 클립보드에 복사되었습니다';

  @override
  String get notifications => '알림';

  @override
  String get pushNotifications => '푸시 알림';

  @override
  String get priceAlerts => '가격 알림';

  @override
  String get dailyDeals => '오늘의 특가';

  @override
  String get subscription => '구독';

  @override
  String get freePlan => '무료 플랜';

  @override
  String get proPlan => 'Pro 플랜';

  @override
  String get upgrade => '업그레이드';

  @override
  String productsTracked(int count) {
    return '$count개 상품 추적 중';
  }

  @override
  String get appearance => '외관';

  @override
  String get theme => '테마';

  @override
  String get lightMode => '라이트 모드';

  @override
  String get darkMode => '다크 모드';

  @override
  String get language => '언어';

  @override
  String get support => '지원';

  @override
  String get helpCenter => '고객센터';

  @override
  String get sendFeedback => '피드백 보내기';

  @override
  String get rateApp => '앱 평가';

  @override
  String get termsOfService => '서비스 이용약관';

  @override
  String get privacyPolicy => '개인정보 처리방침';

  @override
  String get account => '계정';

  @override
  String get deleteAccount => '계정 삭제';

  @override
  String get deleteAccountWarning => '계정과 모든 데이터가 영구적으로 삭제됩니다.';

  @override
  String get error => '오류';

  @override
  String get success => '성공';

  @override
  String get loading => '로딩 중...';

  @override
  String get retry => '다시 시도';

  @override
  String get cancel => '취소';

  @override
  String get confirm => '확인';

  @override
  String get save => '저장';

  @override
  String get delete => '삭제';

  @override
  String get edit => '수정';

  @override
  String get done => '완료';

  @override
  String get next => '다음';

  @override
  String get back => '뒤로';

  @override
  String get skip => '건너뛰기';

  @override
  String get getStarted => '시작하기';

  @override
  String get connectionError => '연결 오류. 인터넷 연결을 확인해주세요.';

  @override
  String get somethingWentWrong => '문제가 발생했습니다. 다시 시도해주세요.';

  @override
  String get productNotFound => '상품을 찾을 수 없습니다';

  @override
  String get invalidUrl => '잘못된 URL입니다. 올바른 상품 URL을 입력해주세요.';

  @override
  String get failedToLoadProducts => '상품 로드 실패';

  @override
  String get failedToAddProduct => '상품 추가 실패';

  @override
  String get failedToRemoveProduct => '상품 삭제 실패';

  @override
  String get productAdded => '상품이 추가되었습니다';

  @override
  String get productRemoved => '상품이 삭제되었습니다';

  @override
  String get priceUpdated => '가격이 업데이트되었습니다';

  @override
  String get onboardingTitle1 => '가격 추적';

  @override
  String get onboardingDesc1 => '좋아하는 쇼핑몰에서 상품을 추가하고 자동으로 가격을 추적하세요.';

  @override
  String get onboardingTitle2 => '알림 받기';

  @override
  String get onboardingDesc2 => '목표 가격을 설정하고 가격이 떨어지면 알림을 받으세요.';

  @override
  String get onboardingTitle3 => '돈 절약';

  @override
  String get onboardingDesc3 => '더 이상 비싸게 사지 마세요. 최적의 타이밍에 구매하고 돈을 절약하세요.';
}

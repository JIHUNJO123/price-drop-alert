// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'MyPriceDrop';

  @override
  String get home => 'ホーム';

  @override
  String get settings => '設定';

  @override
  String get profile => 'プロフィール';

  @override
  String get login => 'ログイン';

  @override
  String get logout => 'ログアウト';

  @override
  String get email => 'メールアドレス';

  @override
  String get password => 'パスワード';

  @override
  String get signup => '新規登録';

  @override
  String get forgotPassword => 'パスワードをお忘れですか？';

  @override
  String get createAccount => 'アカウント作成';

  @override
  String get alreadyHaveAccount => '既にアカウントをお持ちですか？';

  @override
  String get dontHaveAccount => 'アカウントをお持ちでないですか？';

  @override
  String get trackProduct => '商品を追跡';

  @override
  String get addProduct => '商品を追加';

  @override
  String get pasteUrl => '商品URLを貼り付け';

  @override
  String get enterUrl => '対応ストアの商品URLを入力してください';

  @override
  String get supportedStores => '対応ストア';

  @override
  String get preview => 'プレビュー';

  @override
  String get startTracking => '追跡を開始';

  @override
  String get currentPrice => '現在価格';

  @override
  String get targetPrice => '目標価格';

  @override
  String get setTargetPrice => '目標価格を設定';

  @override
  String get priceHistory => '価格履歴';

  @override
  String get lowestPrice => '最安値';

  @override
  String get highestPrice => '最高値';

  @override
  String get averagePrice => '平均価格';

  @override
  String get priceDropAlert => '値下げアラート';

  @override
  String get notifyWhenPriceDrops => '価格が下がったら通知';

  @override
  String get products => '商品';

  @override
  String get noProducts => '追跡中の商品はありません';

  @override
  String get addFirstProduct => '最初の商品を追加して価格追跡を開始しましょう';

  @override
  String get refreshPrice => '価格を更新';

  @override
  String get stopTracking => '追跡を停止';

  @override
  String get buyNow => '今すぐ購入';

  @override
  String get viewDetails => '詳細を見る';

  @override
  String get copyLink => 'リンクをコピー';

  @override
  String get linkCopied => 'リンクをクリップボードにコピーしました';

  @override
  String get notifications => '通知';

  @override
  String get pushNotifications => 'プッシュ通知';

  @override
  String get priceAlerts => '価格アラート';

  @override
  String get dailyDeals => '本日のお得情報';

  @override
  String get subscription => 'サブスクリプション';

  @override
  String get freePlan => '無料プラン';

  @override
  String get proPlan => 'Proプラン';

  @override
  String get upgrade => 'アップグレード';

  @override
  String productsTracked(int count) {
    return '$count件の商品を追跡中';
  }

  @override
  String get appearance => '外観';

  @override
  String get theme => 'テーマ';

  @override
  String get lightMode => 'ライトモード';

  @override
  String get darkMode => 'ダークモード';

  @override
  String get language => '言語';

  @override
  String get support => 'サポート';

  @override
  String get helpCenter => 'ヘルプセンター';

  @override
  String get sendFeedback => 'フィードバックを送信';

  @override
  String get rateApp => 'アプリを評価';

  @override
  String get termsOfService => '利用規約';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get account => 'アカウント';

  @override
  String get deleteAccount => 'アカウントを削除';

  @override
  String get deleteAccountWarning => 'アカウントとすべてのデータが完全に削除されます。';

  @override
  String get error => 'エラー';

  @override
  String get success => '成功';

  @override
  String get loading => '読み込み中...';

  @override
  String get retry => '再試行';

  @override
  String get cancel => 'キャンセル';

  @override
  String get confirm => '確認';

  @override
  String get save => '保存';

  @override
  String get delete => '削除';

  @override
  String get edit => '編集';

  @override
  String get done => '完了';

  @override
  String get next => '次へ';

  @override
  String get back => '戻る';

  @override
  String get skip => 'スキップ';

  @override
  String get getStarted => '始める';

  @override
  String get connectionError => '接続エラー。インターネット接続を確認してください。';

  @override
  String get somethingWentWrong => '問題が発生しました。もう一度お試しください。';

  @override
  String get productNotFound => '商品が見つかりません';

  @override
  String get invalidUrl => '無効なURL。有効な商品URLを入力してください。';

  @override
  String get failedToLoadProducts => '商品の読み込みに失敗しました';

  @override
  String get failedToAddProduct => '商品の追加に失敗しました';

  @override
  String get failedToRemoveProduct => '商品の削除に失敗しました';

  @override
  String get productAdded => '商品を追加しました';

  @override
  String get productRemoved => '商品を削除しました';

  @override
  String get priceUpdated => '価格を更新しました';

  @override
  String get onboardingTitle1 => '価格を追跡';

  @override
  String get onboardingDesc1 => 'お気に入りのストアから商品を追加して、自動的に価格を追跡します。';

  @override
  String get onboardingTitle2 => 'アラートを受け取る';

  @override
  String get onboardingDesc2 => '目標価格を設定して、価格が下がったら通知を受け取ります。';

  @override
  String get onboardingTitle3 => 'お金を節約';

  @override
  String get onboardingDesc3 => 'もう高い買い物はしない。最適なタイミングで購入してお金を節約しましょう。';

  @override
  String get signIn => 'サインイン';

  @override
  String get welcomeBack => 'おかえりなさい！';

  @override
  String get signInToContinue => '価格追跡を続けるにはサインインしてください';

  @override
  String get startSavingMoney => '価格追跡を始めてお金を節約しましょう';

  @override
  String get orContinueWith => 'または次の方法で続ける';

  @override
  String get nameOptional => '名前（任意）';

  @override
  String get pleaseEnterEmail => 'メールアドレスを入力してください';

  @override
  String get pleaseEnterValidEmail => '有効なメールアドレスを入力してください';

  @override
  String get pleaseEnterPassword => 'パスワードを入力してください';

  @override
  String get agreeToTerms => '以下に同意します：';

  @override
  String get and => 'と';

  @override
  String get pleaseAgreeToTerms => '利用規約に同意してください';

  @override
  String get freeTrial => '3日間無料トライアル';

  @override
  String get tryProFeatures => 'すべてのPro機能を無料でお試しください';

  @override
  String get onboardingTitle4 => 'お金を節約';

  @override
  String get onboardingDesc4 => '高い買い物はしない。最適なタイミングで購入して節約しましょう。';
}

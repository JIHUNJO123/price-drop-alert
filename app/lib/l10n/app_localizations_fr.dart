// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'MyPriceDrop';

  @override
  String get home => 'Accueil';

  @override
  String get alerts => 'Alertes';

  @override
  String get settings => 'Paramètres';

  @override
  String get totalSavings => 'Économies Totales';

  @override
  String get profile => 'Profil';

  @override
  String get login => 'Connexion';

  @override
  String get logout => 'Déconnexion';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get signup => 'S\'inscrire';

  @override
  String get forgotPassword => 'Mot de passe oublié?';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get alreadyHaveAccount => 'Déjà un compte?';

  @override
  String get dontHaveAccount => 'Pas encore de compte?';

  @override
  String get trackProduct => 'Suivre le produit';

  @override
  String get addProduct => 'Ajouter un produit';

  @override
  String get pasteUrl => 'Collez l\'URL du produit';

  @override
  String get enterUrl =>
      'Entrez l\'URL du produit de n\'importe quelle boutique supportée';

  @override
  String get supportedStores => 'Boutiques Supportées';

  @override
  String get preview => 'Aperçu';

  @override
  String get startTracking => 'Commencer le suivi';

  @override
  String get currentPrice => 'Prix Actuel';

  @override
  String get targetPrice => 'Prix Cible';

  @override
  String get setTargetPrice => 'Définir le Prix Cible';

  @override
  String get priceHistory => 'Historique des Prix';

  @override
  String get lowestPrice => 'Prix le Plus Bas';

  @override
  String get highestPrice => 'Prix le Plus Haut';

  @override
  String get averagePrice => 'Prix Moyen';

  @override
  String get priceDropAlert => 'Alerte Baisse de Prix';

  @override
  String get notifyWhenPriceDrops => 'Me notifier quand le prix baisse à';

  @override
  String get products => 'Produits';

  @override
  String get noProducts => 'Aucun produit suivi pour le moment';

  @override
  String get addFirstProduct =>
      'Ajoutez votre premier produit pour commencer à suivre les prix';

  @override
  String get refreshPrice => 'Actualiser le Prix';

  @override
  String get stopTracking => 'Arrêter le Suivi';

  @override
  String get buyNow => 'Acheter Maintenant';

  @override
  String get viewDetails => 'Voir les Détails';

  @override
  String get copyLink => 'Copier le Lien';

  @override
  String get linkCopied => 'Lien copié dans le presse-papiers';

  @override
  String get notifications => 'Notifications';

  @override
  String get pushNotifications => 'Notifications Push';

  @override
  String get priceAlerts => 'Alertes de Prix';

  @override
  String get dailyDeals => 'Offres du Jour';

  @override
  String get subscription => 'Abonnement';

  @override
  String get freePlan => 'Plan Gratuit';

  @override
  String get proPlan => 'Plan Pro';

  @override
  String get upgrade => 'Améliorer';

  @override
  String productsTracked(int count) {
    return '$count produits suivis';
  }

  @override
  String get appearance => 'Apparence';

  @override
  String get theme => 'Thème';

  @override
  String get lightMode => 'Mode Clair';

  @override
  String get darkMode => 'Mode Sombre';

  @override
  String get language => 'Langue';

  @override
  String get support => 'Support';

  @override
  String get helpCenter => 'Centre d\'Aide';

  @override
  String get sendFeedback => 'Envoyer un Feedback';

  @override
  String get rateApp => 'Noter l\'App';

  @override
  String get termsOfService => 'Conditions d\'Utilisation';

  @override
  String get privacyPolicy => 'Politique de Confidentialité';

  @override
  String get account => 'Compte';

  @override
  String get deleteAccount => 'Supprimer le Compte';

  @override
  String get deleteAccountWarning =>
      'Cela supprimera définitivement votre compte et toutes les données.';

  @override
  String get error => 'Erreur';

  @override
  String get success => 'Succès';

  @override
  String get loading => 'Chargement...';

  @override
  String get retry => 'Réessayer';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get done => 'Terminé';

  @override
  String get next => 'Suivant';

  @override
  String get back => 'Retour';

  @override
  String get skip => 'Passer';

  @override
  String get getStarted => 'Commencer';

  @override
  String get connectionError =>
      'Erreur de connexion. Veuillez vérifier votre internet.';

  @override
  String get somethingWentWrong =>
      'Une erreur s\'est produite. Veuillez réessayer.';

  @override
  String get productNotFound => 'Produit non trouvé';

  @override
  String get invalidUrl =>
      'URL invalide. Veuillez entrer une URL de produit valide.';

  @override
  String get failedToLoadProducts => 'Échec du chargement des produits';

  @override
  String get failedToAddProduct => 'Échec de l\'ajout du produit';

  @override
  String get failedToRemoveProduct => 'Échec de la suppression du produit';

  @override
  String get productAdded => 'Produit ajouté avec succès';

  @override
  String get productRemoved => 'Produit supprimé';

  @override
  String get priceUpdated => 'Prix mis à jour';

  @override
  String get onboardingTitle1 => 'Suivez les Prix';

  @override
  String get onboardingDesc1 =>
      'Ajoutez des produits de vos boutiques préférées et suivez leurs prix automatiquement.';

  @override
  String get onboardingTitle2 => 'Recevez des Alertes';

  @override
  String get onboardingDesc2 =>
      'Définissez votre prix cible et soyez notifié quand le prix baisse.';

  @override
  String get onboardingTitle3 => 'Économisez de l\'Argent';

  @override
  String get onboardingDesc3 =>
      'Ne payez plus jamais trop cher. Achetez au meilleur moment et économisez.';

  @override
  String get signIn => 'Se connecter';

  @override
  String get welcomeBack => 'Bon retour!';

  @override
  String get signInToContinue => 'Connectez-vous pour continuer à suivre les prix';

  @override
  String get startSavingMoney => 'Commencez à suivre les prix et économiser';

  @override
  String get orContinueWith => 'Ou continuer avec';

  @override
  String get nameOptional => 'Nom (optionnel)';

  @override
  String get pleaseEnterEmail => 'Veuillez entrer votre e-mail';

  @override
  String get pleaseEnterValidEmail => 'Veuillez entrer un e-mail valide';

  @override
  String get pleaseEnterPassword => 'Veuillez entrer votre mot de passe';

  @override
  String get agreeToTerms => 'J\'accepte les';

  @override
  String get and => 'et';

  @override
  String get pleaseAgreeToTerms => 'Veuillez accepter les Conditions d\'Utilisation';

  @override
  String get freeTrial => 'Essai Gratuit de 3 Jours';

  @override
  String get tryProFeatures => 'Essayez toutes les fonctionnalités Pro gratuitement';

  @override
  String get onboardingTitle4 => 'Économisez de l\'Argent';

  @override
  String get onboardingDesc4 => 'Ne payez plus jamais trop. Achetez au moment parfait et économisez.';

  @override
  String get resetPassword => 'Réinitialiser le mot de passe';

  @override
  String get resetPasswordDesc => 'Entrez votre e-mail et nous vous enverrons des instructions pour réinitialiser votre mot de passe.';

  @override
  String get sendResetLink => 'Envoyer le lien';

  @override
  String get resetEmailSent => 'Si un compte existe avec cet e-mail, nous avons envoyé des instructions de réinitialisation.';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get socialLoginComingSoon => 'La connexion sociale sera disponible dans une future mise à jour.';

  @override
  String lastUpdated(String time) => 'Dernière mise à jour: $time';

  @override
  String get noImageAvailable => 'Image non disponible';

  @override
  String get updateTargetPrice => 'Modifier le Prix Cible';

  @override
  String targetPriceNotifyDesc(String price) => 'Nous vous notifierons quand le prix descendra à $price ou moins.';

  @override
  String get setTargetPriceHint => 'Définissez un prix cible pour être notifié.';

  @override
  String currentPriceLabel(String price) => 'Prix actuel: $price';

  @override
  String get enterTargetPrice => 'Entrez le prix cible';

  @override
  String get confirmStopTracking => 'Arrêter le suivi de ce produit?';

  @override
  String get confirmStopTrackingDesc => 'Vous ne recevrez plus d\'alertes de prix pour ce produit.';

  @override
  String minutesAgo(int count) => 'il y a $count minutes';

  @override
  String hoursAgo(int count) => 'il y a $count heures';

  @override
  String daysAgo(int count) => 'il y a $count jours';

  @override
  String get justNow => 'À l\'instant';
}

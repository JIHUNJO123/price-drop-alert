// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'MyPriceDrop';

  @override
  String get home => 'Inicio';

  @override
  String get settings => 'Ajustes';

  @override
  String get profile => 'Perfil';

  @override
  String get login => 'Iniciar Sesión';

  @override
  String get logout => 'Cerrar Sesión';

  @override
  String get email => 'Correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get signup => 'Registrarse';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get createAccount => 'Crear Cuenta';

  @override
  String get alreadyHaveAccount => '¿Ya tienes una cuenta?';

  @override
  String get dontHaveAccount => '¿No tienes una cuenta?';

  @override
  String get trackProduct => 'Rastrear Producto';

  @override
  String get addProduct => 'Añadir Producto';

  @override
  String get pasteUrl => 'Pega la URL del producto';

  @override
  String get enterUrl =>
      'Ingresa la URL del producto de cualquier tienda compatible';

  @override
  String get supportedStores => 'Tiendas Compatibles';

  @override
  String get preview => 'Vista Previa';

  @override
  String get startTracking => 'Comenzar a Rastrear';

  @override
  String get currentPrice => 'Precio Actual';

  @override
  String get targetPrice => 'Precio Objetivo';

  @override
  String get setTargetPrice => 'Establecer Precio Objetivo';

  @override
  String get priceHistory => 'Historial de Precios';

  @override
  String get lowestPrice => 'Precio Más Bajo';

  @override
  String get highestPrice => 'Precio Más Alto';

  @override
  String get averagePrice => 'Precio Promedio';

  @override
  String get priceDropAlert => 'Alerta de Bajada de Precio';

  @override
  String get notifyWhenPriceDrops => 'Notificarme cuando el precio baje a';

  @override
  String get products => 'Productos';

  @override
  String get noProducts => 'Aún no hay productos rastreados';

  @override
  String get addFirstProduct =>
      'Añade tu primer producto para comenzar a rastrear precios';

  @override
  String get refreshPrice => 'Actualizar Precio';

  @override
  String get stopTracking => 'Dejar de Rastrear';

  @override
  String get buyNow => 'Comprar Ahora';

  @override
  String get viewDetails => 'Ver Detalles';

  @override
  String get copyLink => 'Copiar Enlace';

  @override
  String get linkCopied => 'Enlace copiado al portapapeles';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get pushNotifications => 'Notificaciones Push';

  @override
  String get priceAlerts => 'Alertas de Precio';

  @override
  String get dailyDeals => 'Ofertas Diarias';

  @override
  String get subscription => 'Suscripción';

  @override
  String get freePlan => 'Plan Gratuito';

  @override
  String get proPlan => 'Plan Pro';

  @override
  String get upgrade => 'Mejorar';

  @override
  String productsTracked(int count) {
    return '$count productos rastreados';
  }

  @override
  String get appearance => 'Apariencia';

  @override
  String get theme => 'Tema';

  @override
  String get lightMode => 'Modo Claro';

  @override
  String get darkMode => 'Modo Oscuro';

  @override
  String get language => 'Idioma';

  @override
  String get support => 'Soporte';

  @override
  String get helpCenter => 'Centro de Ayuda';

  @override
  String get sendFeedback => 'Enviar Comentarios';

  @override
  String get rateApp => 'Calificar App';

  @override
  String get termsOfService => 'Términos de Servicio';

  @override
  String get privacyPolicy => 'Política de Privacidad';

  @override
  String get account => 'Cuenta';

  @override
  String get deleteAccount => 'Eliminar Cuenta';

  @override
  String get deleteAccountWarning =>
      'Esto eliminará permanentemente tu cuenta y todos los datos.';

  @override
  String get error => 'Error';

  @override
  String get success => 'Éxito';

  @override
  String get loading => 'Cargando...';

  @override
  String get retry => 'Reintentar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get edit => 'Editar';

  @override
  String get done => 'Hecho';

  @override
  String get next => 'Siguiente';

  @override
  String get back => 'Atrás';

  @override
  String get skip => 'Omitir';

  @override
  String get getStarted => 'Comenzar';

  @override
  String get connectionError =>
      'Error de conexión. Por favor verifica tu internet.';

  @override
  String get somethingWentWrong =>
      'Algo salió mal. Por favor intenta de nuevo.';

  @override
  String get productNotFound => 'Producto no encontrado';

  @override
  String get invalidUrl =>
      'URL inválida. Por favor ingresa una URL de producto válida.';

  @override
  String get failedToLoadProducts => 'Error al cargar productos';

  @override
  String get failedToAddProduct => 'Error al añadir producto';

  @override
  String get failedToRemoveProduct => 'Error al eliminar producto';

  @override
  String get productAdded => 'Producto añadido exitosamente';

  @override
  String get productRemoved => 'Producto eliminado';

  @override
  String get priceUpdated => 'Precio actualizado';

  @override
  String get onboardingTitle1 => 'Rastrea Precios';

  @override
  String get onboardingDesc1 =>
      'Añade productos de tus tiendas favoritas y rastrea sus precios automáticamente.';

  @override
  String get onboardingTitle2 => 'Recibe Alertas';

  @override
  String get onboardingDesc2 =>
      'Establece tu precio objetivo y recibe notificaciones cuando baje.';

  @override
  String get onboardingTitle3 => 'Ahorra Dinero';

  @override
  String get onboardingDesc3 =>
      'Nunca pagues de más. Compra en el mejor momento y ahorra dinero.';

  @override
  String get signIn => 'Iniciar Sesión';

  @override
  String get welcomeBack => '¡Bienvenido de nuevo!';

  @override
  String get signInToContinue => 'Inicia sesión para continuar rastreando precios';

  @override
  String get startSavingMoney => 'Comienza a rastrear precios y ahorrar dinero';

  @override
  String get orContinueWith => 'O continuar con';

  @override
  String get nameOptional => 'Nombre (opcional)';

  @override
  String get pleaseEnterEmail => 'Por favor ingresa tu correo electrónico';

  @override
  String get pleaseEnterValidEmail => 'Por favor ingresa un correo válido';

  @override
  String get pleaseEnterPassword => 'Por favor ingresa tu contraseña';

  @override
  String get agreeToTerms => 'Acepto los';

  @override
  String get and => 'y';

  @override
  String get pleaseAgreeToTerms => 'Por favor acepta los Términos de Servicio';

  @override
  String get freeTrial => 'Prueba Gratis de 3 Días';

  @override
  String get tryProFeatures => 'Prueba todas las funciones Pro gratis';

  @override
  String get onboardingTitle4 => 'Ahorra Dinero';

  @override
  String get onboardingDesc4 => 'Nunca pagues de más. Compra en el momento perfecto y ahorra.';
}

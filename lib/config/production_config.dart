// 🔥 CONFIGURACIÓN DE PRODUCCIÓN - TAXIPRO USUARIOX
// Activar TODAS las funcionalidades en modo real para beta

class ProductionConfig {
  // 🛡️ MODO DE DESARROLLO
  static const bool isDevelopment = false; // ❌ DESACTIVADO PARA PRODUCCIÓN
  
  // 💳 STRIPE - MODO PRODUCCIÓN
  static const bool useRealStripe = true; // ✅ STRIPE REAL
  static const bool useTestPayments = false; // ❌ NO MÁS PAGOS DE PRUEBA
  
  // 🎤 AUDIO - GRABACIÓN REAL
  static const bool useRealAudioRecording = true; // ✅ GRABACIÓN REAL
  static const bool simulateAudio = false; // ❌ NO MÁS SIMULACIÓN
  
  // 📞 EMERGENCIAS - SISTEMA REAL
  static const bool useRealEmergencySystem = true; // ✅ 911 REAL
  static const bool useTestEmergencyNumbers = false; // ❌ NO MÁS PRUEBAS
  
  // 🗺️ MAPAS Y UBICACIÓN - PRECISIÓN MÁXIMA
  static const bool useHighAccuracyLocation = true; // ✅ PRECISIÓN ALTA
  static const bool useMockLocation = false; // ❌ NO MÁS UBICACIONES FALSAS
  
  // 📊 CÁLCULOS - BACKEND REAL
  static const bool useRealFareCalculations = true; // ✅ CÁLCULOS REALES
  static const bool useMockFares = false; // ❌ NO MÁS TARIFAS SIMULADAS
  
  // 🛡️ TAXIPRO SHIELD - GRABACIÓN EN SEGUNDO PLANO
  static const bool enableBackgroundRecording = true; // ✅ GRABACIÓN CONTINUA
  static const bool useRealPanicButton = true; // ✅ BOTÓN DE PÁNICO REAL
  
  // 📱 SOPORTE - BACKEND REAL
  static const bool useRealSupportSystem = true; // ✅ TICKETS REALES
  static const bool logSupportToConsole = false; // ❌ NO MÁS LOGS DE DESARROLLO
  
  // ⚡ CLOUD FUNCTIONS - PRODUCCIÓN
  static const bool useProductionFunctions = true; // ✅ FUNCTIONS REALES
  static const String functionsRegion = 'us-central1'; // 🌎 REGIÓN PRODUCCIÓN
  
  // 🔐 SEGURIDAD - MÁXIMO NIVEL
  static const bool enableSecurityLogging = true; // ✅ LOGS DE SEGURIDAD
  static const bool enableCrashReporting = true; // ✅ REPORTES DE CRASHES
  
  // 📈 ANALYTICS - PRODUCCIÓN
  static const bool enableProductionAnalytics = true; // ✅ ANALYTICS REALES
  static const bool enableTestingAnalytics = false; // ❌ NO MÁS ANALYTICS DE PRUEBA
  
  // 🎯 CONFIGURACIÓN ESPECÍFICA PARA BETA
  static const bool betaMode = true; // ✅ MODO BETA CON USUARIOS REALES
  static const bool enableBetaFeatures = true; // ✅ CARACTERÍSTICAS BETA
  static const bool enableBetaLogging = true; // ✅ LOGS PARA BETA TESTING
}

/// Configuración dinámica basada en el modo de producción
class AppConfig {
  static bool get isProduction => ProductionConfig.isDevelopment == false;
  static bool get useRealServices => ProductionConfig.useRealStripe;
  static String get environment => isProduction ? 'PRODUCCIÓN' : 'DESARROLLO';
  
  /// Mensaje de configuración para mostrar en la app
  static String get configMessage {
    if (isProduction && ProductionConfig.betaMode) {
      return '🔥 MODO BETA - PRODUCCIÓN ACTIVA';
    } else if (isProduction) {
      return '✅ MODO PRODUCCIÓN';
    } else {
      return '🧪 MODO DESARROLLO';
    }
  }
}

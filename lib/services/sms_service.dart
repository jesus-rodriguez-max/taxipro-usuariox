import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:taxipro_usuariox/services/app_config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telephony/telephony.dart' as t;

class SmsService {
  static const _kRememberNumberKey = 'offlineRememberNumber';
  static const _kNumberOverrideKey = 'offlineSmsNumberOverride';

  static Future<String?> resolveDestinationNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final override = prefs.getString(_kNumberOverrideKey);
    if (override != null && override.isNotEmpty) return override;
    final backend = AppConfigService.instance.offlineSmsNumber;
    if (backend != null && backend.isNotEmpty) return backend;
    // Fallback por defecto solicitado: siempre disponible
    return '+15555555555';
  }

  static Future<void> setRememberNumber(bool remember) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRememberNumberKey, remember);
  }

  static Future<bool> getRememberNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kRememberNumberKey) ?? false;
  }

  static Future<void> setNumberOverride(String? number) async {
    final prefs = await SharedPreferences.getInstance();
    if (number == null || number.isEmpty) {
      await prefs.remove(_kNumberOverrideKey);
    } else {
      await prefs.setString(_kNumberOverrideKey, number);
    }
  }

  static String _shorten(String s, int maxLen) {
    s = s.trim();
    if (s.length <= maxLen) return s;
    return s.substring(0, max(0, maxLen - 1)) + '…';
  }

  static String buildOfflineSmsBody({
    required String originAddress,
    required double originLat,
    required double originLng,
    required String destAddress,
    required double destLat,
    required double destLng,
    required String uid,
  }) {
    // Prefer alias corto si se excede longitud
    String line1 = 'TAXIPRO_OFFLINE';
    String oAddr = originAddress.isEmpty ? 'Origen' : originAddress;
    String dAddr = destAddress.isEmpty ? 'Destino' : destAddress;
    String line2 = 'ORIGEN: $oAddr | ${originLat.toStringAsFixed(5)},${originLng.toStringAsFixed(5)}';
    String line3 = 'DESTINO: $dAddr | ${destLat.toStringAsFixed(5)},${destLng.toStringAsFixed(5)}';
    String line4 = 'PASAJERO_UID: $uid';
    String line5 = 'NOTA: EFECTIVO. SIN SEGURIDAD ACTIVA.';

    String msg = [line1, line2, line3, line4, line5].join('\n');
    if (msg.length <= 300) return msg; // ok

    // Si excede, acortar direcciones
    oAddr = _shorten(oAddr, 24);
    dAddr = _shorten(dAddr, 24);
    line2 = 'ORIGEN: $oAddr | ${originLat.toStringAsFixed(5)},${originLng.toStringAsFixed(5)}';
    line3 = 'DESTINO: $dAddr | ${destLat.toStringAsFixed(5)},${destLng.toStringAsFixed(5)}';
    msg = [line1, line2, line3, line4, line5].join('\n');
    if (msg.length <= 300) return msg;

    // Priorizar coordenadas solo
    line2 = 'ORIGEN: ${originLat.toStringAsFixed(5)},${originLng.toStringAsFixed(5)}';
    line3 = 'DESTINO: ${destLat.toStringAsFixed(5)},${destLng.toStringAsFixed(5)}';
    msg = [line1, line2, line3, line4, line5].join('\n');
    return msg;
  }

  static Future<bool> sendSms(String to, String body) async {
    try {
      final uri = Uri(scheme: 'sms', path: to, queryParameters: {'body': body});
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    if (Platform.isAndroid) {
      try {
        final telephony = t.Telephony.instance;
        await telephony.sendSms(to: to, message: body);
        return true;
      } catch (_) {}
    }
    return false;
  }

  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}

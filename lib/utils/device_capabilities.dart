import 'dart:io' show Platform;
import 'package:url_launcher/url_launcher.dart';

class DeviceCapabilities {
  static Future<bool> canSendSms() async {
    if (!Platform.isAndroid) return false;
    try {
      final uri = Uri(scheme: 'sms', path: '12345');
      return await canLaunchUrl(uri);
    } catch (_) {
      return false;
    }
  }
}

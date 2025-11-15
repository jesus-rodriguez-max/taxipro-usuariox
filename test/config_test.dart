import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxipro_usuariox/firebase_options.dart';

void main() {
  test('Firebase project is configured to taxipro-chofer', () {
    expect(DefaultFirebaseOptions.android.projectId, 'taxipro-chofer');
  });

  test('.env.example contains required keys', () {
    final content = File('.env.example').readAsStringSync();
    expect(content.contains('GOOGLE_API_KEY'), true);
    expect(content.contains('STRIPE_PUBLISHABLE_KEY'), true);
  });

  test('AndroidManifest uses MAPS_API_KEY placeholder', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest.contains('com.google.android.geo.API_KEY'), true);
    expect(manifest.contains('\${MAPS_API_KEY}'), true);
  });
}

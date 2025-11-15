import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:taxipro_usuariox/services/emergency_service.dart';
// import 'package:taxipro_usuariox/widgets/app_drawer.dart'; // Drawer desactivado temporalmente
import 'package:taxipro_usuariox/ui/ui_constants.dart';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _recordAudio = true;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recordAudio = prefs.getBool('safety_record_audio') ?? true;
    });
  }

  Future<void> _toggleRecord(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('safety_record_audio', v);
    setState(() => _recordAudio = v);
  }

  Future<void> _shareTrip() async {
    setState(() => _sharing = true);
    try {
      final text = Uri.encodeComponent('Compartiendo mi viaje en TaxiPro. Me encuentro bien, pero deseo que sigas mi trayecto.');
      final wa = Uri.parse('https://wa.me/?text=$text');
      if (!await launchUrl(wa, mode: LaunchMode.externalApplication)) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir WhatsApp')));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onBg = Theme.of(context).colorScheme.onBackground;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          color: onBg,
          onPressed: () => Navigator.of(context).pushNamed('/map'),
        ),
        title: Text('Escudo Taxi Pro', style: TextStyle(color: onBg)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: Image.asset('assets/icon/taxipro_icons_pack_v1/dark/security/escudo_tp.png', height: 86, filterQuality: FilterQuality.high)),
          const SizedBox(height: 12),
          Text('Seguridad TaxiPro', textAlign: TextAlign.center, style: TextStyle(color: onBg, fontWeight: FontWeight.w800, fontSize: 20)),
          const SizedBox(height: 8),
          Text('Activa grabación en segundo plano y comparte tu viaje con alguien de confianza.', textAlign: TextAlign.center, style: TextStyle(color: onBg.withOpacity(0.85))),
          const SizedBox(height: 16),
          // Grabar audio del viaje
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Icon(Icons.mic, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Text('Grabar audio del viaje (seguridad en segundo plano)', style: TextStyle(color: onBg))),
                Switch(value: _recordAudio, onChanged: _toggleRecord, activeColor: const Color(0xFF22C55E))
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Compartir mi viaje
          SizedBox(
            height: kButtonHeight,
            child: ElevatedButton(
              onPressed: _sharing ? null : _shareTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCornerRadius)),
              ),
              child: _sharing
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Compartir mi viaje con'),
            ),
          ),
          const SizedBox(height: 12),
          // Activar Escudo Taxi Pro (Emergencia)
          SizedBox(
            height: kButtonHeight,
            child: ElevatedButton.icon(
              onPressed: () => EmergencyService.activatePanic(context),
              icon: const Icon(Icons.shield, color: Colors.white),
              label: const Text('Activar Escudo Taxi Pro'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCornerRadius)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Información:', style: TextStyle(color: onBg, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('La grabación se mantiene en segundo plano solo para fines de seguridad.\nPuedes detenerla en cualquier momento.\nAl activar el Escudo TaxiPro, aceptas el uso responsable de esta función.', style: TextStyle(color: onBg.withOpacity(0.85))),
        ],
      ),
    );
  }
}

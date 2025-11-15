import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxipro_usuariox/services/app_config_service.dart';
import 'package:taxipro_usuariox/utils/device_capabilities.dart';
import 'carousel_item.dart';
import 'sphere_button.dart';
import 'sphere_colors.dart';

class BottomCarouselMenu extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final void Function(String keyId) onSelectKey;

  const BottomCarouselMenu({super.key, required this.isOpen, required this.onClose, required this.onSelectKey});

  @override
  State<BottomCarouselMenu> createState() => _BottomCarouselMenuState();
}

class _BottomCarouselMenuState extends State<BottomCarouselMenu> {
  static const String _prefsKey = 'lastMenuKey';
  final double _height = 96; // altura total del carrusel
  final double _viewportFraction = 0.14; // ~7 ítems visibles (3 por lado + 1 central)

  late PageController _pageController;
  double _currentPage = 0.0;
  List<CarouselItemData> _items = [];
  int _virtualBase = 10000;
  int _initialPage = 0;
  bool _loaded = false;
  final ValueNotifier<int> _activeIndex = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: _viewportFraction);
    _pageController.addListener(() {
      setState(() => _currentPage = _pageController.page ?? _pageController.initialPage.toDouble());
    });
    _prepare();
  }

  Future<void> _prepare() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_prefsKey) ?? 'map';

    // Build items with gating
    final cfg = AppConfigService.instance;
    final canSms = await DeviceCapabilities.canSendSms();
    final showOffline = cfg.offlineRequestsEnabled && canSms;

    final list = <CarouselItemData>[
      CarouselItemData(keyId: 'map', icon: Icons.map, semanticsLabel: 'Mapa'),
      CarouselItemData(keyId: 'illustr', icon: Icons.image, semanticsLabel: 'Ilustraciones'),
      CarouselItemData(keyId: 'wallet', icon: Icons.account_balance_wallet, semanticsLabel: 'Wallet'),
      CarouselItemData(keyId: 'faq', icon: Icons.help_outline, semanticsLabel: 'Preguntas'),
      CarouselItemData(keyId: 'support', icon: Icons.support_agent, semanticsLabel: 'Soporte'),
      if (cfg.shieldEnabled) CarouselItemData(keyId: 'shield', icon: Icons.shield, semanticsLabel: 'Escudo TaxiPro'),
      if (showOffline) CarouselItemData(keyId: 'offline', icon: Icons.sms, semanticsLabel: 'Solicitud sin Internet (SMS)'),
      CarouselItemData(keyId: 'legal', icon: Icons.privacy_tip, semanticsLabel: 'Privacidad y Términos'),
      CarouselItemData(keyId: 'settings', icon: Icons.settings, semanticsLabel: 'Configuración'),
      if (cfg.profileEnabled) CarouselItemData(keyId: 'profile', icon: Icons.person, semanticsLabel: 'Mi perfil'),
      CarouselItemData(keyId: 'logout', icon: Icons.logout, semanticsLabel: 'Cerrar sesión'),
    ];
    _items = list;

    final idx = _items.indexWhere((e) => e.keyId == last);
    final base = _virtualBase * (_items.isNotEmpty ? _items.length : 1);
    _initialPage = base + (idx >= 0 ? idx : 0);
    _pageController.dispose();
    _pageController = PageController(viewportFraction: _viewportFraction, initialPage: _initialPage);
    _pageController.addListener(() {
      final page = _pageController.page ?? _initialPage.toDouble();
      _currentPage = page;
      if (_items.isNotEmpty) {
        final nearest = page.round();
        final real = nearest % _items.length;
        if (_activeIndex.value != real) _activeIndex.value = real;
      }
    });

    setState(() => _loaded = true);
  }

  Future<void> _navigateCenter() async {
    if (_items.isEmpty) return;
    final centerIndex = (_pageController.page ?? _initialPage).round();
    final key = _items[centerIndex % _items.length].keyId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, key);
    widget.onSelectKey(key);
    widget.onClose();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = widget.isOpen;

    return IgnorePointer(
      ignoring: !isOpen,
      child: AnimatedOpacity(
        opacity: isOpen ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Stack(
          children: [
            // Backdrop blur + dim con gradiente
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onClose,
                onVerticalDragUpdate: (d) {
                  if (d.delta.dy > 8) widget.onClose();
                },
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.25),
                            Colors.black.withOpacity(0.05),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Bottom carousel panel
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                offset: isOpen ? Offset.zero : const Offset(0, 0.1),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: isOpen ? 1 : 0,
                  child: _loaded
                      ? _buildCarousel(context)
                      : SizedBox(height: _height, child: const Center(child: CircularProgressIndicator())),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarousel(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _activeIndex,
      builder: (context, active, _) {
        final spec = _items.isNotEmpty ? kSphereSpecs[_items[active % _items.length].keyId] : null;
        Color tintC1 = spec?.c1 ?? Colors.black;
        if (_pageController.hasClients && _items.isNotEmpty) {
          final pv = _pageController.page ?? _initialPage.toDouble();
          final base = pv.floor();
          final frac = (pv - base).clamp(0.0, 1.0);
          final cCenter = kSphereSpecs[_items[base % _items.length].keyId]!.c1;
          final cNext = kSphereSpecs[_items[(base + 1) % _items.length].keyId]!.c1;
          tintC1 = Color.lerp(cCenter, cNext, frac) ?? tintC1;
        }
        return Container(
          height: _height,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.25),
                Colors.black.withOpacity(0.05),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Overlay de tinte dinámico con el color del ítem activo
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          tintC1.withOpacity(0.16),
                          tintC1.withOpacity(0.06),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Divider superior sutil
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Container(height: 1, color: Colors.white.withOpacity(0.1)),
              ),
              AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  return PageView.builder(
                    physics: const PageScrollPhysics(),
                    controller: _pageController,
                    onPageChanged: (_) => HapticFeedback.selectionClick(),
                    itemBuilder: (context, index) {
                      if (_items.isEmpty) return const SizedBox();
                      final real = index % _items.length;
                      final pageVal = _pageController.hasClients ? (_pageController.page ?? _initialPage.toDouble()) : _initialPage.toDouble();
                      final delta = index - pageVal;
                      final d = delta.abs();
                      final clamped = d.clamp(0.0, 1.0);
                      // Base escala: extremos 0.7 -> centro 1.0 (SphereButton añade 1.2 en activo)
                      final scale = 1.0 - clamped * 0.3;
                      // Profundidad: desplazar en Y (px) hacia abajo en los extremos
                      final translateY = 16.0 * clamped;
                      // Opacidad: extremos 0.5 -> centro 1.0
                      final opacity = 1.0 - (clamped * 0.5);
                      final isCenter = clamped < 0.15;
                      // Perspectiva y curvatura cilíndrica: rotación en Y hacia afuera
                      final maxAngle = 0.35; // ~20°
                      final angleY = (delta.isNaN ? 0.0 : (delta.sign * maxAngle * clamped));
                      final keyId = _items[real].keyId;
                      final s = kSphereSpecs[keyId]!;
                      return Center(
                        child: Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, -0.003)
                            ..rotateY(angleY)
                            ..translate(0.0, translateY)
                            ..scale(scale),
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: SphereButton(
                              icon: s.icon,
                              c1: s.c1,
                              c2: s.c2,
                              active: isCenter,
                              opacity: opacity,
                              semantics: s.semantics,
                              onTap: () {
                                if (isCenter) {
                                  _navigateCenter();
                                } else {
                                  _pageController.animateToPage(
                                    index,
                                    duration: const Duration(milliseconds: 340),
                                    curve: Curves.elasticOut,
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

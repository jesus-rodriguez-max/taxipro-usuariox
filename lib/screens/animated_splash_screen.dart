import 'dart:async';
import 'package:flutter/material.dart';
import 'package:taxipro_usuariox/theme.dart';
import 'package:flutter/services.dart' show rootBundle;

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  bool _showGif = true;
  String _gifPath = 'assets/splash/animated_splash_screen.gif';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _controller.forward();

    // Usar el GIF oficial exactamente como está declarado
    
    // Mostrar el GIF por 1.6 segundos
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() => _showGif = false);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _showGif
              ? FadeTransition(
                  opacity: _fadeAnimation,
                  child: Image.asset(
                    _gifPath,
                    key: const ValueKey('gif'),
                    width: 300,
                    height: 300,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: Image.asset(
                    'assets/branding/isotipo_tp.png',
                    key: const ValueKey('static'),
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
        ),
      ),
    );
  }
}

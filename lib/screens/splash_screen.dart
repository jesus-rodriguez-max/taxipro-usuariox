import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:taxipro_usuariox/widgets/terms_and_conditions_modal.dart';
import 'package:taxipro_usuariox/auth/auth_wrapper.dart';
import 'package:taxipro_usuariox/screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  Timer? _timer;
  Timer? _fallbackTimer;
  bool _navigated = false;
  Route _fadeTo(Widget child) => PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, __, ___) => child,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    // 0.0 -> 1.0 (fade in 60%), luego 1.0 -> 0.0 (fade out 40%)
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 40),
    ]).animate(_controller);
    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/branding/splash_screen.png'), context);
      precacheImage(const AssetImage('assets/branding/logo_complete.png'), context);
    });
    _timer = Timer(const Duration(milliseconds: 600), _afterSplash);
    // Fallback duro: si algo se atasca, navegar a /login para no bloquear
    _fallbackTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_navigated) {
        final user = FirebaseAuth.instance.currentUser;
        final target = (user != null) ? '/home' : '/login';
        if (target == '/home') {
          Navigator.of(context).pushReplacement(_fadeTo(const AuthWrapper()));
        } else {
          Navigator.of(context).pushReplacement(_fadeTo(const LoginScreen()));
        }
        _navigated = true;
      }
    });
  }

  Future<void> _afterSplash() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('legalAccepted') ?? false;
    if (!accepted) {
      final ok = await TermsAndConditionsModal.show(context);
      if (!ok) return _afterSplash();
    }
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.of(context).pushReplacement(_fadeTo(const AuthWrapper()));
    } else {
      Navigator.of(context).pushReplacement(_fadeTo(const LoginScreen()));
    }
    _navigated = true;
    _fallbackTimer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fallbackTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _opacity,
                child: Image.asset(
                  'assets/branding/splash_screen.png',
                  width: 270,
                  height: 270,
                  fit: BoxFit.contain,
                ),
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}

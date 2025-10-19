import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simplemente esperamos 1 segundo y navegamos a login
    Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      // Asegúrate de que tienes una ruta llamada '/login' en tu MaterialApp
      Navigator.of(context).pushReplacementNamed('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo estático simple
              Container(
                width: 280,
                height: 280, 
                padding: const EdgeInsets.all(20),
                child: Image.asset(
                  'assets/splash/splash_logo.png',
                ), // Paréntesis de Image.asset que faltaba
              ), // Paréntesis de Container que faltaba
            ], // Corchete de la lista de children que faltaba
          ), // Paréntesis de Column que faltaba
        ), // Paréntesis de Center que faltaba
      ),
    );
  }
}

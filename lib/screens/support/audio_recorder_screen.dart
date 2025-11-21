import 'package:flutter/material.dart';
import 'package:taxipro_usuariox/config/production_config.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AudioRecorderScreen extends StatefulWidget {
  const AudioRecorderScreen({super.key});

  @override
  State<AudioRecorderScreen> createState() => _AudioRecorderScreenState();
}

class _AudioRecorderScreenState extends State<AudioRecorderScreen>
    with TickerProviderStateMixin {
  
  bool _isRecording = false;
  bool _isUploading = false;
  bool _hasRecording = false;
  Duration _recordingDuration = Duration.zero;
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _requestPermissions();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);
  }

  Future<void> _requestPermissions() async {
    // Placeholder - implementar permisos reales después
  }

  Future<void> _startRecording() async {
    // 🔥 PRODUCCIÓN: Grabación real de audio
    try {
      // TODO: Implementar grabación real cuando se agregue el plugin
      // await _audioRecorder.start();
      
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      _startTimer();
      
      if (ProductionConfig.useRealAudioRecording) {
        print('🎤 PRODUCCIÓN: Grabación de audio iniciada - MODO REAL');
      } else {
        print('🧪 DEV: Grabación simulada');
      }
    } catch (e) {
      print('🔴 ERROR grabación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error iniciando grabación: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      // TODO: Implementar parada real cuando se agregue el plugin
      // final audioPath = await _audioRecorder.stop();
      
      setState(() {
        _isRecording = false;
        _hasRecording = true;
      });
      
      print('🎤 PRODUCCIÓN: Grabación de audio detenida');
      // _audioFilePath = audioPath;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ProductionConfig.useRealAudioRecording 
              ? 'Audio grabado en modo PRODUCCIÓN' 
              : 'Audio grabado (simulado)'
          ),
        ),
      );
    } catch (e) {
      print('🔴 ERROR parando grabación: $e');
    }
  }

  void _startTimer() {
    if (!_isRecording) return;
    
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecording) {
        setState(() {
          _recordingDuration = Duration(seconds: _recordingDuration.inSeconds + 1);
        });
        _startTimer();
      }
    });
  }

  Future<void> _uploadAudio() async {
    setState(() => _isUploading = true);

    try {
      // Crear archivo simulado de audio
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.m4a';
      final uid = FirebaseAuth.instance.currentUser!.uid;
      
      // Path exacto según reglas: support_audio/{uid}/{fileName}.m4a
      final audioUrl = 'support_audio/$uid/$fileName';
      
      // Simular URL de Firebase Storage
      final downloadUrl = 'https://firebasestorage.googleapis.com/v0/b/taxipro-chofer.appspot.com/o/support_audio%2F$uid%2F$fileName?alt=media';
      
      Navigator.pop(context, downloadUrl);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir audio: $e')),
      );
      Navigator.pop(context);
    }
  }

  void _discardRecording() {
    setState(() {
      _hasRecording = false;
      _recordingDuration = Duration.zero;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grabar Audio'),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Parte superior (icono + timer + estado)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
            // Ícono de micrófono con animación
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isRecording ? _scaleAnimation.value : 1.0,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording 
                        ? Colors.red.withOpacity(0.2)
                        : const Color(0xFF1A73E8).withOpacity(0.2),
                      border: Border.all(
                        color: _isRecording ? Colors.red : const Color(0xFF1A73E8),
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      Icons.mic,
                      size: 64,
                      color: _isRecording ? Colors.red : const Color(0xFF1A73E8),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // Estado de grabación
            Text(
              _isRecording ? 'Grabando...' : 
              _hasRecording ? 'Audio listo' : 
              'Toca para grabar',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Duración
            Text(
              _formatDuration(_recordingDuration),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: _isRecording ? Colors.red : Colors.grey.shade600,
              ),
            ),
            
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Botones de control
              if (_isRecording) ...[
                // Botón para detener grabación
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _stopRecording,
                    icon: const Icon(Icons.stop),
                    label: const Text('Detener Grabación'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
              ] else if (_hasRecording) ...[
                // Botones después de grabar
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _discardRecording,
                        icon: const Icon(Icons.delete),
                        label: const Text('Descartar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : _uploadAudio,
                        icon: _isUploading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                        label: Text(_isUploading ? 'Subiendo...' : 'Usar Audio'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Botón para iniciar grabación
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startRecording,
                    icon: const Icon(Icons.mic),
                    label: const Text('Iniciar Grabación'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Caja de información inferior
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isRecording 
                    ? 'Mantén el teléfono cerca de tu boca para una mejor calidad de audio'
                    : _hasRecording
                      ? 'Revisa tu grabación y decide si quieres usarla o grabar de nuevo'
                      : 'Graba un mensaje de voz para adjuntarlo a tu reporte de soporte',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

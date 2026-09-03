import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _iniciarCamera();
  }

  Future<void> _iniciarCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      // Seleciona preferencialmente a câmera frontal (selfie)
      final frontal = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontal,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _initializeControllerFuture = _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Erro ao inicializar câmera: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capturarEConfirmar() async {
    try {
      await _initializeControllerFuture;
      final xFile = await _controller!.takePicture();
      if (mounted) {
        Navigator.pop(context, xFile.path); // Retorna o caminho local da imagem
      }
    } catch (e) {
      debugPrint('Erro ao tirar foto: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Identificação Facial'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              _controller != null) {
            return Stack(
              children: [
                Positioned.fill(child: CameraPreview(_controller!)),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 36.0),
                    child: FloatingActionButton.large(
                      onPressed: _capturarEConfirmar,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.camera,
                          size: 40, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          }
          return const Center(
              child: CircularProgressIndicator(color: Colors.white));
        },
      ),
    );
  }
}

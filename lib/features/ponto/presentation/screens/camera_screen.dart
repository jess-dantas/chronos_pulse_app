import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, this.caminhoSemFoto});

  /// URL/valor retornado quando o usuário opta por continuar sem foto
  /// (câmera indisponível ou permissão negada).
  final String? caminhoSemFoto;

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

  void _continuarSemFoto() {
    Navigator.pop(context, widget.caminhoSemFoto);
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final future = _initializeControllerFuture;
    if (future == null) {
      return _cameraIndisponivel();
    }

    return FutureBuilder<void>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _cameraIndisponivel();
        }
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
    );
  }

  Widget _cameraIndisponivel() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_photography, size: 48, color: Colors.white70),
          const SizedBox(height: 16),
          const Text(
            'Câmera indisponível ou sem permissão.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Você pode continuar a batida sem a foto.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _continuarSemFoto,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70),
            ),
            icon: const Icon(Icons.skip_next),
            label: const Text('Continuar sem foto'),
          ),
        ],
      ),
    );
  }
}
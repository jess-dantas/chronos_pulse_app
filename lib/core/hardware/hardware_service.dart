import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';

class HardwareService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Captura as coordenadas de GPS do dispositivo
  Future<Position?> obterLocalizacaoAtual() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica se o serviço de localização está ativo
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('O serviço de localização (GPS) está desativado.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('A permissão de acesso ao GPS foi negada.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('As permissões de GPS foram negadas permanentemente.');
    }

    // Retorna a posição atual do dispositivo
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  /// Dispara a verificação biométrica (FaceID, Impressão Digital ou PIN)
  /// Lança [Exception] com mensagem legível em caso de erro.
  Future<bool> autenticarBiometria() async {
    if (kIsWeb) return true;

    final bool deviceSupported = await _auth.isDeviceSupported();
    if (!deviceSupported) {
      throw Exception('Este dispositivo não suporta autenticação biométrica.');
    }

    final List<BiometricType> biometrics = await _auth.getAvailableBiometrics();
    if (biometrics.isEmpty) {
      throw Exception(
          'Nenhuma biometria cadastrada. Cadastre uma digital ou face nas configurações do dispositivo.');
    }

    return await _auth.authenticate(
      localizedReason: 'Confirme sua identidade para registrar o ponto',
      options: const AuthenticationOptions(
        stickyAuth: true,
        biometricOnly: false,
      ),
    );
  }
}

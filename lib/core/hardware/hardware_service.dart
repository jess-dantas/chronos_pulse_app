import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';

/// Estado da localização antes da batida — alimenta o aviso pré-registro.
/// [pronta] inclui "não sei": qualquer erro de leitura libera a batida
/// (fail-open) para nunca travar o registro.
enum LocalizacaoStatus { pronta, servicoDesligado, permissaoNegada, permissaoBloqueada }

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

  /// Status usado pelo aviso de localização ANTES da batida.
  /// Fail-open: leitura indisponível (web, plugin ausente) = [pronta].
  Future<LocalizacaoStatus> statusLocalizacao() async {
    if (kIsWeb) return LocalizacaoStatus.pronta;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocalizacaoStatus.servicoDesligado;
      }
      final permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        return LocalizacaoStatus.permissaoNegada;
      }
      if (permissao == LocationPermission.deniedForever) {
        return LocalizacaoStatus.permissaoBloqueada;
      }
      return LocalizacaoStatus.pronta;
    } catch (_) {
      return LocalizacaoStatus.pronta;
    }
  }

  /// Leva o usuário à tela corrigir o [status] (para o aviso pré-batida):
  /// serviço desligado → configurações de localização; permissão negada →
  /// prompt do sistema; permissão bloqueada → configurações do app.
  Future<void> abrirConfigLocalizacao(LocalizacaoStatus status) async {
    try {
      switch (status) {
        case LocalizacaoStatus.servicoDesligado:
          await Geolocator.openLocationSettings();
        case LocalizacaoStatus.permissaoNegada:
          await Geolocator.requestPermission();
        case LocalizacaoStatus.permissaoBloqueada:
        case LocalizacaoStatus.pronta:
          await Geolocator.openAppSettings();
      }
    } catch (e) {
      debugPrint('Aviso ao abrir configurações de localização: $e');
    }
  }

  /// true quando o aparelho suporta biometria E já tem cadastro
  /// (digital/rosto) — usado pelo gate de contingência do 1º acesso.
  Future<bool> biometriaDisponivel() async {
    if (kIsWeb) return false;
    try {
      if (!await _auth.isDeviceSupported()) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Dispara a verificação biométrica (FaceID, Impressão Digital ou PIN)
  /// Lança [Exception] com mensagem legível em caso de erro.
  Future<bool> autenticarBiometria({
    String motivo = 'Confirme sua identidade para registrar o ponto',
  }) async {
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
      localizedReason: motivo,
      options: const AuthenticationOptions(
        stickyAuth: true,
        biometricOnly: false,
      ),
    );
  }
}

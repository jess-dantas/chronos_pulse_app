import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiConstants {
  static String get baseUrl {
    // 0. Variável de ambiente informada em tempo de compilação (--dart-define=API_URL=...)
    const String envUrl = String.fromEnvironment('API_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    // 1. Se estiver rodando na WEB
    if (kIsWeb) {
      return kReleaseMode
          ? 'https://chronos-pulse.onrender.com/api/v1'
          : 'http://localhost:8080/api/v1';
    }

    // 2. Se estiver rodando no Android (Emulador usa 10.0.2.2, dispositivo físico usa IP da máquina)
    try {
      if (Platform.isAndroid) {
        const bool isEmulator = bool.fromEnvironment('EMULATOR', defaultValue: false);
        return isEmulator
            ? 'http://10.0.2.2:8080/api/v1'
            : 'http://192.168.1.14:8080/api/v1';
      }

      // 3. iOS — dispositivo físico precisa do IP da máquina (simulador usa localhost)
      if (Platform.isIOS) {
        const bool isSimulator = bool.fromEnvironment('SIMULATOR', defaultValue: false);
        return isSimulator
            ? 'http://localhost:8080/api/v1'
            : 'http://192.168.1.14:8080/api/v1';
      }
    } catch (_) {
      // Fallback para ambientes sem suporte a Platform
      return 'http://localhost:8080/api/v1';
    }

    // 4. Desktop / Fallback
    return 'http://localhost:8080/api/v1';
  }

  static const String pingEndpoint = '/auth/ping';
  static const String loginEndpoint = '/auth/login';
  static const String cadastrarEmpresaEndpoint = '/auth/cadastrar-empresa';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String meEndpoint = '/auth/me';
  static const String pontosEndpoint = '/pontos/sincronizar';
  static const String pontosEspelhoEndpoint = '/pontos/espelho';
  static const String pontosAjustarEndpoint = '/pontos/ajustar';

  // Módulo de Estoque & Almoxarifado
  static const String estoqueMateriaisEndpoint = '/estoque/materiais';
  static const String estoqueAlmoxarifadosEndpoint = '/estoque/almoxarifados';
  static const String estoqueSaldosEndpoint = '/estoque/saldos';
  static const String estoqueEntradaEndpoint = '/estoque/movimentacoes/entrada';
  static const String estoqueSaidaEndpoint = '/estoque/movimentacoes/saida';
  static const String estoqueRequisicoesEndpoint = '/estoque/requisicoes';

  // Módulo Admin (Gestão de Contratos e Métricas)
  static const String adminDashboardEndpoint = '/admin/dashboard';
  static const String adminContratosEndpoint = '/admin/contratos';
  static String adminContratoEventosEndpoint(String contratoId) => '/admin/contratos/$contratoId/eventos';
  static const String adminContratoEventoEndpoint = '/admin/contratos/eventos';
  static const String adminEmpresasEndpoint = '/empresas';
  static const String adminColaboradoresEndpoint = '/admin/colaboradores';
}

import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiConstants {
  // Deve ser informada no build/produção: --dart-define=API_URL=https://seu-host/api/v1
  static const String _envUrl = String.fromEnvironment('API_URL', defaultValue: '');

  /// Indica se a URL da API foi fornecida via --dart-define (build reproduzível).
  static bool get apiUrlInformada => _envUrl.isNotEmpty;

  static String get baseUrl {
    // 0. Variável de ambiente informada em tempo de compilação (--dart-define=API_URL=...)
    if (_envUrl.isNotEmpty) {
      return _envUrl;
    }

    if (kReleaseMode) {
      return 'https://chronos-pulse.onrender.com/api/v1';
    }

    // 1. Se estiver rodando na WEB (debug)
    if (kIsWeb) {
      return 'http://localhost:8080/api/v1';
    }

    // 2. Emulador Android usa 10.0.2.2; simulador iOS usa localhost
    try {
      if (Platform.isAndroid) {
        const bool isEmulator = bool.fromEnvironment('EMULATOR', defaultValue: false);
        return isEmulator
            ? 'http://10.0.2.2:8080/api/v1'
            : 'http://localhost:8080/api/v1';
      }

      if (Platform.isIOS) {
        const bool isSimulator = bool.fromEnvironment('SIMULATOR', defaultValue: false);
        return isSimulator ? 'http://localhost:8080/api/v1' : 'http://localhost:8080/api/v1';
      }
    } catch (_) {
      // Fallback para ambientes sem suporte a Platform
      return 'http://localhost:8080/api/v1';
    }

    // 3. Desktop / Fallback (não é destino de produção)
    return 'http://localhost:8080/api/v1';
  }

  static const String pingEndpoint = '/auth/ping';
  static const String loginEndpoint = '/auth/login';
  static const String cadastrarEmpresaEndpoint = '/auth/cadastrar-empresa';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String meEndpoint = '/auth/me';
  static const String meFotoEndpoint = '/auth/me/foto';
  static const String alterarSenhaEndpoint = '/auth/alterar-senha';
  static const String esqueciSenhaEndpoint = '/auth/esqueci-senha';
  static const String redefinirSenhaEndpoint = '/auth/redefinir-senha';
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
  static String adminContratoSaldoEndpoint(String contratoId) => '/admin/contratos/$contratoId/saldo';
  static const String adminEmpresasEndpoint = '/empresas';
  static const String adminColaboradoresEndpoint = '/admin/colaboradores';

  // Módulo Plataforma (Catálogo de Módulos e Ativação por Empresa)
  static const String adminModulosCatalogoEndpoint = '/admin/modulos';
  static String adminModulosEmpresaEndpoint(String tenantId) => '/admin/empresas/$tenantId/modulos';

  // Módulo Patrimônio
  static const String patrimonioEndpoint = '/patrimonio';
  static const String patrimonioDesfazimentosEndpoint = '/patrimonio/desfazimentos';
  static String patrimonioAprovarDesfazimentoEndpoint(String id) =>
      '/patrimonio/desfazimentos/$id/aprovar';
  static String patrimonioCancelarDesfazimentoEndpoint(String id) =>
      '/patrimonio/desfazimentos/$id';

  // Módulo Frota
  static const String frotaVeiculosEndpoint = '/frota/veiculos';
  static const String frotaAbastecimentosEndpoint = '/frota/abastecimentos';

  // Módulo Protocolo
  static const String protocoloEndpoint = '/protocolo';

  // LGPD / Privacidade
  static const String privacidadePoliticaEndpoint = '/privacidade/politica';
  static const String privacidadeMeusDadosEndpoint = '/privacidade/meus-dados';
  static const String privacidadeConsentimentoEndpoint = '/privacidade/consentimento';
}

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

  // Módulo Compras & Fornecedores
  static const String comprasFornecedoresEndpoint = '/compras/fornecedores';
  static const String comprasPedidosEndpoint = '/compras/pedidos';
  static const String comprasNfeEndpoint = '/compras/nfe';
  static const String comprasNfeReceberEndpoint = '/compras/nfe/receber';
  static const String comprasNfeImportarXmlEndpoint = '/compras/nfe/importar-xml';
  static const String comprasNfeConsultarSefazEndpoint = '/compras/nfe/consultar-sefaz';
  static const String comprasPrecosEndpoint = '/compras/precos';
  static const String comprasRequisicoesEndpoint = '/compras/requisicoes';
  static String comprasRequisicaoCancelarEndpoint(String id) => '/compras/requisicoes/$id/cancelar';
  static const String comprasCotacoesEndpoint = '/compras/cotacoes';
  static String comprasCotacaoPropostasEndpoint(String id) => '/compras/cotacoes/$id/propostas';
  static String comprasCotacaoConcluirEndpoint(String id) => '/compras/cotacoes/$id/concluir';
  static String comprasCotacaoCancelarEndpoint(String id) => '/compras/cotacoes/$id/cancelar';
  static String comprasCotacaoGerarPedidosEndpoint(String id) => '/compras/cotacoes/$id/gerar-pedidos';

  // Módulo Licitações & Contratações (Lei 14.133/2021)
  static const String licitacoesEndpoint = '/licitacoes';
  static String licitacaoDetalheEndpoint(String id) => '/licitacoes/$id';
  static String licitacaoPublicarEndpoint(String id) => '/licitacoes/$id/publicar';
  static String licitacaoPropostasEndpoint(String id) => '/licitacoes/$id/propostas';
  static String licitacaoAdjudicarEndpoint(String id) => '/licitacoes/$id/adjudicar';
  static String licitacaoHomologarEndpoint(String id) => '/licitacoes/$id/homologar';
  static String licitacaoCancelarEndpoint(String id) => '/licitacoes/$id/cancelar';
  static String licitacaoPublicarPncpEndpoint(String id) => '/licitacoes/$id/publicar-pncp';
  static String licitacaoGerarPedidosEndpoint(String id) => '/licitacoes/$id/gerar-pedidos';
  static String licitacaoAbrirDisputaEndpoint(String id) => '/licitacoes/$id/abrir-disputa';
  static String licitacaoLancesEndpoint(String id) => '/licitacoes/$id/lances';
  static String licitacaoFormalizarContratoEndpoint(String id) => '/licitacoes/$id/contrato';
  static String licitacaoPlanejamentoEndpoint(String id) => '/licitacoes/$id/planejamento';
  static String licitacaoEtpEndpoint(String id) => '/licitacoes/$id/planejamento/etp';
  static String licitacaoEtpAprovarEndpoint(String id) => '/licitacoes/$id/planejamento/etp/aprovar';
  static String licitacaoTrEndpoint(String id) => '/licitacoes/$id/planejamento/tr';
  static String licitacaoTrAprovarEndpoint(String id) => '/licitacoes/$id/planejamento/tr/aprovar';
  static String licitacaoEditalEndpoint(String id) => '/licitacoes/$id/planejamento/edital';
  static String licitacaoEditalPublicarEndpoint(String id) => '/licitacoes/$id/planejamento/edital/publicar';

  // Gestão da Execução Contratual (R30)
  static const String contratosEndpoint = '/contratos';
  static String contratoDetalheEndpoint(String id) => '/contratos/$id';
  static String contratoAditivosEndpoint(String id) => '/contratos/$id/aditivos';
  static String contratoApontamentosEndpoint(String id) => '/contratos/$id/apontamentos';
  static String contratoApontamentoResolverEndpoint(String id, String apontamentoId) =>
      '/contratos/$id/apontamentos/$apontamentoId/resolver';
  static String contratoMedicoesEndpoint(String id) => '/contratos/$id/medicoes';
  static String contratoSancoesEndpoint(String id) => '/contratos/$id/sancoes';
  static String contratoRescindirEndpoint(String id) => '/contratos/$id/rescindir';

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
  static String patrimonioAtualizarEndpoint(String id) => '/patrimonio/$id';
  static String patrimonioDesativarEndpoint(String id) => '/patrimonio/$id';
  static String patrimonioBuscarEndpoint(String termo) => '/patrimonio/buscar?q=$termo';
  static String patrimonioQrcodeEndpoint(String codigo) => '/patrimonio/qrcode/$codigo';
  static const String patrimonioDesfazimentosEndpoint = '/patrimonio/desfazimentos';
  static String patrimonioAprovarDesfazimentoEndpoint(String id) =>
      '/patrimonio/desfazimentos/$id/aprovar';
  static String patrimonioCancelarDesfazimentoEndpoint(String id) =>
      '/patrimonio/desfazimentos/$id';
  static const String patrimonioInventariosEndpoint = '/patrimonio/inventarios';
  static String patrimonioInventarioConferirEndpoint(String id) =>
      '/patrimonio/inventarios/$id/conferir';
  static String patrimonioInventarioFinalizarEndpoint(String id) =>
      '/patrimonio/inventarios/$id/finalizar';
  static String patrimonioInventarioCancelarEndpoint(String id) =>
      '/patrimonio/inventarios/$id';
  static String patrimonioInventarioDetalheEndpoint(String id) => '/patrimonio/inventarios/$id';
  static const String patrimonioTransferenciasEndpoint = '/patrimonio/transferencias';
  static String patrimonioTransferenciaConfirmarEndpoint(String id) =>
      '/patrimonio/transferencias/$id/confirmar';
  static String patrimonioTransferenciaCancelarEndpoint(String id) =>
      '/patrimonio/transferencias/$id';

  // Módulo Frota
  static const String frotaVeiculosEndpoint = '/frota/veiculos';
  static const String frotaAbastecimentosEndpoint = '/frota/abastecimentos';

  // Módulo Protocolo
  static const String protocoloEndpoint = '/protocolo';

  // Módulo Portal da Transparência (LC 131/2009) + BI
  static const String transparenciaResumoEndpoint = '/transparencia/resumo';
  static String transparenciaDespesasMensaisEndpoint(int ano) => '/transparencia/despesas-mensais?ano=$ano';
  static const String transparenciaPublicacoesEndpoint = '/transparencia/publicacoes';
  static String transparenciaPublicacaoPublicarEndpoint(String id) => '/transparencia/publicacoes/$id/publicar';
  static String transparenciaPublicacaoDeleteEndpoint(String id) => '/transparencia/publicacoes/$id';

  // Portal Público da Transparência (R31) — sem autenticação
  static String portalTransparenciaEndpoint(String slug) => '/publico/transparencia/$slug';
  static String portalLicitacoesEndpoint(String slug) => '/publico/transparencia/$slug/licitacoes';
  static String portalLicitacaoDetalheEndpoint(String slug, String id) =>
      '/publico/transparencia/$slug/licitacoes/$id';
  static String portalContratosEndpoint(String slug) => '/publico/transparencia/$slug/contratos';
  static String portalContratoDetalheEndpoint(String slug, String id) =>
      '/publico/transparencia/$slug/contratos/$id';
  static String portalDespesasMensaisEndpoint(String slug, int ano) =>
      '/publico/transparencia/$slug/despesas-mensais?ano=$ano';
  static String portalPublicacoesEndpoint(String slug) => '/publico/transparencia/$slug/publicacoes';

  // Módulo Telemetria & Observabilidade (R27)
  static const String telemetriaEventosEndpoint = '/telemetria/eventos';

  // LGPD / Privacidade
  static const String privacidadePoliticaEndpoint = '/privacidade/politica';
  static const String privacidadeMeusDadosEndpoint = '/privacidade/meus-dados';
  static const String privacidadeConsentimentoEndpoint = '/privacidade/consentimento';
}

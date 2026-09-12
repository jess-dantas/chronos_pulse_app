import 'package:flutter_test/flutter_test.dart';

import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/features/auth/data/models/usuario_model.dart';
import 'package:chronos_pulse_app/features/transparencia/data/datasources/portal_publico_remote_datasource.dart';
import 'package:chronos_pulse_app/features/transparencia/data/models/portal_publico_models.dart';
import 'package:chronos_pulse_app/features/transparencia/data/models/transparencia_models.dart';
import 'package:chronos_pulse_app/features/transparencia/data/repositories/portal_publico_repository.dart';
import 'package:chronos_pulse_app/features/transparencia/presentation/providers/portal_publico_provider.dart';

class FakePortalDataSource extends PortalPublicoRemoteDataSource {
  PortalResumoModel? resumo;
  List<PortalLicitacaoModel> licitacoes = [];
  List<PortalContratoModel> contratos = [];
  List<PortalPublicacaoModel> publicacoes = [];
  PortalLicitacaoDetalheModel? licitacaoDetalhe;
  PortalContratoDetalheModel? contratoDetalhe;
  bool falhar = false;

  FakePortalDataSource() : super(DioClient());

  @override
  Future<PortalResumoModel> getResumo(String slug) async {
    if (falhar) throw Exception('Erro de rede');
    return resumo ?? const PortalResumoModel(
      orgao: PortalOrgaoModel(slug: 'chronos-pulse-demo', nome: 'Chronos Pulse Tech', cnpj: '49262262000113'),
      licitacoesPublicadas: 2,
      licitacoesEmAndamento: 1,
      licitacoesHomologadas: 0,
      contratosAtivos: 3,
      valorEmpenhado: 30000,
      valorLiquidado: 21000,
      valorDespesasAno: 9600,
      publicacoesDivulgadas: 3,
      ultimaCompetencia: '2026-08',
    );
  }

  @override
  Future<List<PortalLicitacaoModel>> getLicitacoes(String slug) async {
    if (falhar) throw Exception('Erro de rede');
    return List.of(licitacoes);
  }

  @override
  Future<List<PortalContratoModel>> getContratos(String slug) async {
    if (falhar) throw Exception('Erro de rede');
    return List.of(contratos);
  }

  @override
  Future<List<PortalPublicacaoModel>> getPublicacoes(String slug) async {
    if (falhar) throw Exception('Erro de rede');
    return List.of(publicacoes);
  }

  @override
  Future<DespesasMensaisModel> getDespesasMensais(String slug, int ano) async {
    if (falhar) throw Exception('Erro de rede');
    return const DespesasMensaisModel(ano: 2026, meses: [
      DespesaMensalModel(
        mes: 8,
        despesasNfe: 4800,
        notasFiscais: 2,
        combustivel: 300,
        abastecimentos: 1,
        pedidosEmitidos: 4500,
        quantidadePedidos: 1,
      ),
    ]);
  }

  @override
  Future<PortalLicitacaoDetalheModel> getLicitacao(String slug, String id) async {
    if (falhar) throw Exception('Erro de rede');
    return licitacaoDetalhe ?? licitacaoDetalheParaTeste();
  }

  @override
  Future<PortalContratoDetalheModel> getContrato(String slug, String id) async {
    if (falhar) throw Exception('Erro de rede');
    return contratoDetalhe ?? contratoDetalheParaTeste();
  }
}

PortalLicitacaoModel licitacaoParaTeste() => const PortalLicitacaoModel(
      id: 'lic-1',
      numero: '001',
      modalidade: 'PREGAO',
      status: 'PUBLICADA',
      objeto: 'Aquisição de material de expediente',
      valorEstimado: 15000,
    );

PortalContratoModel contratoParaTeste() => const PortalContratoModel(
      id: 'ct-1',
      numero: 'CT-2026-001',
      objeto: 'Manutenção predial',
      status: 'ATIVO',
      valorTotal: 120000,
      valorEmpenhado: 60000,
      valorLiquidado: 40000,
    );

PortalPublicacaoModel publicacaoPortalParaTeste() => const PortalPublicacaoModel(
      id: 'p-1',
      competencia: '2026-08',
      tipoPublicacao: 'DESPESAS',
      valorTotal: 50000,
      itensCount: 12,
      dataPublicacao: '2026-09-05',
    );

PortalLicitacaoDetalheModel licitacaoDetalheParaTeste() => const PortalLicitacaoDetalheModel(
      id: 'lic-1',
      numero: '001',
      modalidade: 'PREGAO',
      tipoJulgamento: 'MENOR_PRECO',
      status: 'ABERTA',
      objeto: 'Aquisição de material de expediente',
      valorEstimado: 15000,
      itens: [
        PortalLicitacaoItemModel(
          descricao: 'Papel A4',
          quantidade: 100,
          valorEstimadoUnitario: 15,
          valorEstimadoTotal: 1500,
        ),
      ],
    );

PortalContratoDetalheModel contratoDetalheParaTeste() => const PortalContratoDetalheModel(
      id: 'ct-1',
      numero: 'CT-2026-001',
      objeto: 'Manutenção predial',
      status: 'ATIVO',
      valorTotal: 120000,
      valorEmpenhado: 60000,
      valorLiquidado: 40000,
      aditivos: [PortalAditivoModel(tipo: 'PRORROGACAO', descricao: 'Aditivo de prazo', prazoAdicionadoDias: 90, novoValorTotal: 0, aprovado: true)],
      sancoes: [PortalSancaoModel(tipo: 'MULTA', descricao: 'Atraso na entrega', percentualMulta: 2, valorMulta: 2000)],
    );

void main() {
  group('PortalPublicoModel Tests', () {
    test('resumo parseia orgao e indicadores', () {
      final model = PortalResumoModel.fromJson({
        'orgao': {'slug': 'chronos-pulse-demo', 'nome': 'Chronos Pulse Tech', 'cnpj': '49262262000113'},
        'licitacoesPublicadas': 2,
        'licitacoesEmAndamento': 1,
        'licitacoesHomologadas': 0,
        'contratosAtivos': 3,
        'valorEmpenhado': 30000,
        'valorLiquidado': 21000,
        'valorDespesasAno': 9600,
        'publicacoesDivulgadas': 3,
        'ultimaCompetencia': '2026-08',
      });

      expect(model.orgao.slug, 'chronos-pulse-demo');
      expect(model.orgao.nome, 'Chronos Pulse Tech');
      expect(model.licitacoesPublicadas, 2);
      expect(model.licitacoesEmAndamento, 1);
      expect(model.contratosAtivos, 3);
      expect(model.valorEmpenhado, 30000);
      expect(model.valorDespesasAno, 9600);
      expect(model.ultimaCompetencia, '2026-08');
    });

    test('licitacao detalhe parseia itens', () {
      final model = PortalLicitacaoDetalheModel.fromJson({
        'id': 'lic-1',
        'numero': '001',
        'modalidade': 'PREGAO',
        'tipoJulgamento': 'MENOR_PRECO',
        'status': 'ABERTA',
        'objeto': 'Objeto',
        'valorEstimado': 15000,
        'itens': [
          {
            'descricao': 'Papel A4',
            'quantidade': 100,
            'valorEstimadoUnitario': 15,
            'valorEstimadoTotal': 1500,
          },
        ],
      });

      expect(model.itens.single.descricao, 'Papel A4');
      expect(model.itens.single.valorEstimadoTotal, 1500);
      expect(model.status, 'ABERTA');
    });

    test('contrato detalhe parseia aditivos e sanções', () {
      final model = PortalContratoDetalheModel.fromJson({
        'id': 'ct-1',
        'numero': 'CT-2026-001',
        'objeto': 'Manutenção predial',
        'status': 'ATIVO',
        'valorTotal': 120000,
        'valorEmpenhado': 60000,
        'valorLiquidado': 40000,
        'aditivos': [
          {
            'tipo': 'PRORROGACAO',
            'descricao': 'Aditivo de prazo',
            'prazoAdicionadoDias': 90,
            'novoValorTotal': 0,
            'aprovado': true,
          },
        ],
        'sancoes': [
          {
            'tipo': 'MULTA',
            'descricao': 'Atraso na entrega',
            'percentualMulta': 2,
            'valorMulta': 2000,
          },
        ],
      });

      expect(model.aditivos.single.tipo, 'PRORROGACAO');
      expect(model.aditivos.single.prazoAdicionadoDias, 90);
      expect(model.sancoes.single.tipo, 'MULTA');
      expect(model.sancoes.single.valorMulta, 2000);
    });
  });

  group('PortalPublicoProvider Tests', () {
    test('carregarTudo popula resumo, licitações, contratos, publicações e despesas', () async {
      final fake = FakePortalDataSource()
        ..licitacoes = [licitacaoParaTeste()]
        ..contratos = [contratoParaTeste()]
        ..publicacoes = [publicacaoPortalParaTeste()];
      final provider = PortalPublicoProvider(PortalPublicoRepository(remoteDataSource: fake));

      await provider.carregarTudo('chronos-pulse-demo');

      expect(provider.hasData, isTrue);
      expect(provider.resumo!.orgao.slug, 'chronos-pulse-demo');
      expect(provider.licitacoes.single.id, 'lic-1');
      expect(provider.contratos.single.id, 'ct-1');
      expect(provider.publicacoes.single.valorTotal, 50000);
      expect(provider.despesasMensais!.ano, DateTime.now().year);
      expect(provider.despesasMensais!.meses.single.total, 5100);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('carregarDetalheLicitacao preenche o detalhe', () async {
      final fake = FakePortalDataSource();
      final provider = PortalPublicoProvider(PortalPublicoRepository(remoteDataSource: fake));

      await provider.carregarDetalheLicitacao('chronos-pulse-demo', 'lic-1');

      expect(provider.licitacaoDetalhe!.numero, '001');
      expect(provider.licitacaoDetalhe!.itens.single.descricao, 'Papel A4');
    });

    test('carregarDetalheContrato preenche aditivos e sanções', () async {
      final fake = FakePortalDataSource();
      final provider = PortalPublicoProvider(PortalPublicoRepository(remoteDataSource: fake));

      await provider.carregarDetalheContrato('chronos-pulse-demo', 'ct-1');

      expect(provider.contratoDetalhe!.numero, 'CT-2026-001');
      expect(provider.contratoDetalhe!.aditivos.single.tipo, 'PRORROGACAO');
      expect(provider.contratoDetalhe!.sancoes.single.valorMulta, 2000);
    });

    test('falha ao carregar expõe mensagem de erro', () async {
      final fake = FakePortalDataSource()..falhar = true;
      final provider = PortalPublicoProvider(PortalPublicoRepository(remoteDataSource: fake));

      await provider.carregarTudo('chronos-pulse-demo');

      expect(provider.errorMessage, 'Erro de rede');
      expect(provider.hasData, isFalse);
    });

    test('limparDetalhes zera os detalhes', () async {
      final fake = FakePortalDataSource();
      final provider = PortalPublicoProvider(PortalPublicoRepository(remoteDataSource: fake));
      await provider.carregarDetalheContrato('chronos-pulse-demo', 'ct-1');
      expect(provider.contratoDetalhe, isNotNull);

      provider.limparDetalhes();

      expect(provider.licitacaoDetalhe, isNull);
      expect(provider.contratoDetalhe, isNull);
    });
  });

  group('UsuarioModel tenantSlug Tests', () {
    test('fromJson parseia tenantSlug do login', () {
      final usuario = UsuarioModel.fromJson({
        'accessToken': 'token-1',
        'nome': 'Admin',
        'email': 'admin@chronos.com',
        'role': 'ADMIN_EMPRESA',
        'tenantId': 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        'tenantSlug': 'chronos-pulse-demo',
        'modulos': ['TRANSPARENCIA'],
      });

      expect(usuario.tenantSlug, 'chronos-pulse-demo');
      expect(usuario.tenantId, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11');
      expect(usuario.temModuloTransparencia, isTrue);
    });

    test('toJson preserva tenantSlug', () {
      final usuario = UsuarioModel(
        token: 't',
        tipo: 'Bearer',
        nome: 'Admin',
        email: 'a@b.com',
        role: 'ADMIN_EMPRESA',
        tenantSlug: 'red-cape',
      );

      expect(usuario.toJson()['tenantSlug'], 'red-cape');
    });
  });
}
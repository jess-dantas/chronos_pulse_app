import 'package:flutter_test/flutter_test.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/features/transparencia/data/datasources/transparencia_remote_datasource.dart';
import 'package:chronos_pulse_app/features/transparencia/data/models/transparencia_models.dart';
import 'package:chronos_pulse_app/features/transparencia/data/repositories/transparencia_repository.dart';
import 'package:chronos_pulse_app/features/transparencia/presentation/providers/transparencia_provider.dart';

class FakeTransparenciaDataSource extends TransparenciaRemoteDataSource {
  TransparenciaResumoModel? resumo;
  DespesasMensaisModel? despesas;
  List<TransparenciaPublicacaoModel> publicacoes = [];
  bool falhar = false;
  Map<String, dynamic>? ultimoPayload;

  FakeTransparenciaDataSource() : super(DioClient());

  @override
  Future<TransparenciaResumoModel> getResumo() async {
    if (falhar) throw Exception('Erro de rede');
    return resumo ?? resumoVazio();
  }

  @override
  Future<DespesasMensaisModel> getDespesasMensais(int ano) async {
    if (falhar) throw Exception('Erro de rede');
    return despesas ?? DespesasMensaisModel(ano: ano, meses: const []);
  }

  @override
  Future<List<TransparenciaPublicacaoModel>> getPublicacoes() async {
    if (falhar) throw Exception('Erro de rede');
    return List.of(publicacoes);
  }

  @override
  Future<TransparenciaPublicacaoModel> criarPublicacao(Map<String, dynamic> payload) async {
    if (falhar) throw Exception('Erro de rede');
    ultimoPayload = payload;
    final nova = TransparenciaPublicacaoModel(
      id: 'p-${publicacoes.length + 1}',
      competencia: payload['competencia'].toString(),
      tipoPublicacao: payload['tipoPublicacao'].toString(),
      valorTotal: (payload['valorTotal'] as num?)?.toDouble() ?? 0,
      itensCount: int.tryParse('${payload['itensCount']}') ?? 0,
      status: 'EM_ELABORACAO',
      observacoes: payload['observacoes']?.toString(),
    );
    publicacoes.add(nova);
    return nova;
  }

  @override
  Future<TransparenciaPublicacaoModel> publicarPublicacao(String id) async {
    final index = publicacoes.indexWhere((p) => p.id == id);
    final p = publicacoes[index];
    final atualizada = TransparenciaPublicacaoModel(
      id: p.id,
      competencia: p.competencia,
      tipoPublicacao: p.tipoPublicacao,
      valorTotal: p.valorTotal,
      itensCount: p.itensCount,
      status: 'PUBLICADO',
      dataPublicacao: '2026-09-09',
      observacoes: p.observacoes,
    );
    publicacoes[index] = atualizada;
    return atualizada;
  }

  @override
  Future<void> removerPublicacao(String id) async {
    publicacoes = publicacoes.where((p) => p.id != id).toList();
  }
}

TransparenciaResumoModel resumoVazio() {
  return TransparenciaResumoModel(
    contratos: const ContratosResumoModel(
      ativos: 2,
      valorEmpenhado: 30000,
      valorLiquidado: 21000,
      saldoTotal: 9000,
      vencendo30Dias: 1,
      vencendo60Dias: 0,
      vencendo90Dias: 0,
      vencidos: 1,
    ),
    compras: const ComprasResumoModel(
      fornecedoresAtivos: 1,
      pedidosEmitidos: 2,
      valorPedidos: 4200,
      notasFiscaisRecebidas: 3,
      valorNotasFiscais: 5000,
    ),
    licitacoes: const LicitacoesResumoModel(
      total: 2,
      emElaboracao: 0,
      publicadas: 1,
      abertas: 0,
      adjudicadas: 1,
      homologadas: 0,
      canceladas: 0,
      valorEstimadoTotal: 53850,
    ),
    estoque: const EstoqueResumoModel(
      itensEstoque: 10,
      valorTotalEstoque: 433,
      acimaDoMinimo: 8,
      abaixoDoMinimo: 2,
    ),
    patrimonio: const PatrimonioResumoModel(
      totalBens: 3,
      bensAtivos: 3,
      valorAquisicao: 15000,
      valorAtual: 13000,
    ),
    frota: const FrotaResumoModel(
      veiculos: 2,
      veiculosAtivos: 1,
      abastecimentosMes: 1,
      valorAbastecimentosMes: 300,
    ),
    colaboradores: const ColaboradoresResumoModel(total: 3, ativos: 2),
    ponto: const PontoResumoModel(registrosMes: 2),
    publicacoes: const PublicacoesResumoModel(publicadas: 3, ultimaCompetencia: '2026-08'),
  );
}

TransparenciaPublicacaoModel publicacaoParaTeste({String status = 'EM_ELABORACAO', String id = 'p-1'}) {
  return TransparenciaPublicacaoModel(
    id: id,
    competencia: '2026-08',
    tipoPublicacao: 'DESPESAS',
    valorTotal: 50000,
    itensCount: 12,
    status: status,
    dataPublicacao: status == 'PUBLICADO' ? '2026-09-05' : null,
    observacoes: 'Fechamento fiscal',
  );
}

void main() {
  group('TransparenciaProvider Tests', () {
    test('carregarTudo popula resumo, despesas e publicações', () async {
      final fake = FakeTransparenciaDataSource()
        ..resumo = resumoVazio()
        ..despesas = const DespesasMensaisModel(ano: 2026, meses: [
          DespesaMensalModel(
            mes: 3,
            despesasNfe: 3000,
            notasFiscais: 2,
            combustivel: 150,
            abastecimentos: 1,
            pedidosEmitidos: 3000,
            quantidadePedidos: 1,
          ),
        ])
        ..publicacoes = [publicacaoParaTeste()];
      final provider = TransparenciaProvider(TransparenciaRepository(remoteDataSource: fake));

      await provider.carregarTudo();

      expect(provider.hasData, isTrue);
      expect(provider.resumo!.contratos.ativos, 2);
      expect(provider.despesasMensais!.meses.single.total, 3150);
      expect(provider.publicacoes.length, 1);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('criarPublicacao envia payload normalizado e recarrega a lista', () async {
      final fake = FakeTransparenciaDataSource()
        ..resumo = resumoVazio()
        ..despesas = const DespesasMensaisModel(ano: 2026, meses: []);
      final provider = TransparenciaProvider(TransparenciaRepository(remoteDataSource: fake));

      final ok = await provider.criarPublicacao({
        'competencia': '2026-09',
        'tipoPublicacao': 'DESPESAS',
        'valorTotal': '42000,00',
        'itensCount': '14',
      });

      expect(ok, isTrue);
      expect(fake.ultimoPayload!['competencia'], '2026-09');
      expect(fake.ultimoPayload!['tipoPublicacao'], 'DESPESAS');
      expect(fake.ultimoPayload!['valorTotal'], 42000.0);
      expect(provider.publicacoes.length, 1);
      expect(provider.publicacoes.first.status, 'EM_ELABORACAO');
    });

    test('publicar transita para PUBLICADO', () async {
      final fake = FakeTransparenciaDataSource()..publicacoes = [publicacaoParaTeste()];
      final provider = TransparenciaProvider(TransparenciaRepository(remoteDataSource: fake));

      final ok = await provider.publicar('p-1');

      expect(ok, isTrue);
      expect(provider.publicacoes.first.isPublicado, isTrue);
      expect(provider.publicacoes.first.dataPublicacao, '2026-09-09');
    });

    test('remover remove publicação da lista', () async {
      final fake = FakeTransparenciaDataSource()
        ..publicacoes = [publicacaoParaTeste(), publicacaoParaTeste(status: 'PUBLICADO', id: 'p-2')];
      final provider = TransparenciaProvider(TransparenciaRepository(remoteDataSource: fake));
      await provider.carregarPublicacoes();

      final ok = await provider.remover('p-1');

      expect(ok, isTrue);
      expect(provider.publicacoes.single.id, 'p-2');
    });

    test('falha ao carregar expõe mensagem de erro', () async {
      final fake = FakeTransparenciaDataSource()..falhar = true;
      final provider = TransparenciaProvider(TransparenciaRepository(remoteDataSource: fake));

      await provider.carregarTudo();

      expect(provider.errorMessage, 'Erro de rede');
      expect(provider.hasData, isFalse);
    });

    test('criarPublicacao retorna false em falha', () async {
      final fake = FakeTransparenciaDataSource()..falhar = true;
      final provider = TransparenciaProvider(TransparenciaRepository(remoteDataSource: fake));

      final ok = await provider.criarPublicacao({
        'competencia': '2026-09',
        'tipoPublicacao': 'COMPRAS',
      });

      expect(ok, isFalse);
      expect(provider.errorMessage, 'Erro de rede');
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/core/network/paginated_response.dart';
import 'package:chronos_pulse_app/features/patrimonio/data/datasources/patrimonio_remote_datasource.dart';
import 'package:chronos_pulse_app/features/patrimonio/data/models/patrimonio_models.dart';
import 'package:chronos_pulse_app/features/patrimonio/data/repositories/patrimonio_repository.dart';
import 'package:chronos_pulse_app/features/patrimonio/presentation/providers/patrimonio_provider.dart';

class FakePatrimonioDataSource extends PatrimonioRemoteDataSource {
  List<PatrimonioModel> bensPagina0 = [];
  List<PatrimonioModel> bensPagina1 = [];
  int totalPaginas = 1;
  bool falhar = false;
  Map<String, dynamic>? ultimoPayload;

  FakePatrimonioDataSource() : super(DioClient());

  @override
  Future<PaginatedResponse<PatrimonioModel>> getBens({int page = 0, int size = 50}) async {
    if (falhar) throw Exception('Erro de rede');
    final itens = page == 0 ? bensPagina0 : bensPagina1;
    return PaginatedResponse<PatrimonioModel>(
      items: itens,
      totalElements: bensPagina0.length + bensPagina1.length,
      totalPages: totalPaginas,
      currentPage: page,
      pageSize: size,
    );
  }

  @override
  Future<PatrimonioModel> criarBem(Map<String, dynamic> payload) async {
    ultimoPayload = Map<String, dynamic>.from(payload);
    final bem = PatrimonioModel.fromJson({'id': 'b-${bensPagina0.length + 1}', 'descricao': payload['descricao']});
    bensPagina0.add(bem);
    return bem;
  }

  @override
  Future<List<PatrimonioModel>> buscarBens(String termo) async {
    if (falhar) throw Exception('Erro de rede');
    final t = termo.toLowerCase();
    return [...bensPagina0, ...bensPagina1]
        .where((b) =>
            b.descricao.toLowerCase().contains(t) ||
            (b.tombamento?.toLowerCase().contains(t) ?? false))
        .toList();
  }

  @override
  Future<PatrimonioModel> atualizarBem(String id, Map<String, dynamic> payload) async {
    ultimoPayload = Map<String, dynamic>.from(payload);
    final index = [...bensPagina0, ...bensPagina1].indexWhere((b) => b.id == id);
    if (index < 0) throw Exception('Bem não encontrado');
    final novo = PatrimonioModel.fromJson({
      'id': id,
      'descricao': payload['descricao'],
      'tombamento': payload['tombamento'],
      'estado': payload['estado'],
    });
    if (index < bensPagina0.length) {
      bensPagina0[index] = novo;
    }
    return novo;
  }

  @override
  Future<void> desativarBem(String id) async {
    bensPagina0.removeWhere((b) => b.id == id);
    bensPagina1.removeWhere((b) => b.id == id);
  }

  @override
  Future<PatrimonioModel> buscarPorQrCode(String codigo) async {
    final end = [...bensPagina0, ...bensPagina1].where((b) => b.id == codigo || b.tombamento == codigo).firstOrNull;
    if (end == null) throw Exception('Bem não encontrado no código informado');
    return end;
  }
}

void main() {
  group('Patrimonio Models Tests', () {
    test('PatrimonioModel aplica defaults e preserva campos opcionais', () {
      final bem = PatrimonioModel.fromJson({
        'id': 'b-1',
        'descricao': 'Notebook',
        'valorAquisicao': '4.500,00',
        'numeroNotaFiscal': 'NF-2026-001',
      });
      expect(bem.descricao, 'Notebook');
      expect(bem.estado, 'BOM');
      expect(bem.valorAquisicao, '4.500,00');
      expect(bem.numeroNotaFiscal, 'NF-2026-001');
      expect(bem.tombamento, isNull);
    });
  });

  group('PatrimonioProvider Tests', () {
    test('carregarBens popula a lista de bens', () async {
      final fake = FakePatrimonioDataSource()
        ..bensPagina0 = [PatrimonioModel(id: 'b-1', descricao: 'Notebook')];
      final provider = PatrimonioProvider(PatrimonioRepository(remoteDataSource: fake));

      await provider.carregarBens();

      expect(provider.bens.length, 1);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('criarBem converte valor monetário pt-BR e recarrega', () async {
      final fake = FakePatrimonioDataSource();
      final provider = PatrimonioProvider(PatrimonioRepository(remoteDataSource: fake));

      final ok = await provider.criarBem(
        tombamento: 'TOM-001',
        descricao: 'Cadeira',
        valorAquisicao: '1234,56',
      );

      expect(ok, isTrue);
      expect(fake.ultimoPayload!['valorAquisicao'], 1234.56);
      expect(provider.bens.length, 1);
    });

    test('criarBem omite campos vazios do payload', () async {
      final fake = FakePatrimonioDataSource();
      final provider = PatrimonioProvider(PatrimonioRepository(remoteDataSource: fake));

      final ok = await provider.criarBem(descricao: 'Mesa', observacoes: '');

      expect(ok, isTrue);
      expect(fake.ultimoPayload!.containsKey('valorAquisicao'), isFalse);
      expect(fake.ultimoPayload!.containsKey('observacoes'), isFalse);
    });

    test('carregarMaisBens anexa página seguinte', () async {
      final fake = FakePatrimonioDataSource()
        ..bensPagina0 = [PatrimonioModel(id: 'b-1', descricao: 'A')]
        ..bensPagina1 = [PatrimonioModel(id: 'b-2', descricao: 'B')]
        ..totalPaginas = 3;
      final provider = PatrimonioProvider(PatrimonioRepository(remoteDataSource: fake));

      await provider.carregarBens();
      expect(provider.hasMore, isTrue);

      await provider.carregarMaisBens();
      expect(provider.bens.length, 2);
      expect(provider.hasMore, isTrue);
    });

    test('falha ao carregar expõe mensagem de erro', () async {
      final fake = FakePatrimonioDataSource()..falhar = true;
      final provider = PatrimonioProvider(PatrimonioRepository(remoteDataSource: fake));

      await provider.carregarBens();

      expect(provider.errorMessage, 'Erro de rede');
      expect(provider.bens, isEmpty);
    });

    test('buscarBens filtra por tombamento e descrição', () async {
      final fake = FakePatrimonioDataSource()
        ..bensPagina0 = [
          PatrimonioModel(id: 'b-1', tombamento: 'TOM-0001', descricao: 'Notebook Dell'),
          PatrimonioModel(id: 'b-2', tombamento: 'TOM-0002', descricao: 'Impressora'),
        ];
      final provider = PatrimonioProvider(PatrimonioRepository(remoteDataSource: fake));

      await provider.buscarBens('TOM-0001');
      expect(provider.bens.length, 1);
      expect(provider.bens.first.descricao, 'Notebook Dell');

      await provider.buscarBens('impress');
      expect(provider.bens.length, 1);
      expect(provider.bens.first.descricao, 'Impressora');
    });

    test('atualizarBem envia payload com depreciação e recarrega', () async {
      final fake = FakePatrimonioDataSource()
        ..bensPagina0 = [PatrimonioModel(id: 'b-1', descricao: 'Motor', tombamento: 'TOM-0001')];
      final provider = PatrimonioProvider(PatrimonioRepository(remoteDataSource: fake));

      final ok = await provider.atualizarBem(
        id: 'b-1',
        descricao: 'Motor 3F',
        vidaUtilMeses: '120',
        dataInicioDepreciacao: '2024-01-01',
      );

      expect(ok, isTrue);
      expect(fake.ultimoPayload!['vidaUtilMeses'], 120);
      expect(fake.ultimoPayload!['dataInicioDepreciacao'], '2024-01-01');
      expect(provider.bens.first.descricao, 'Motor 3F');
    });

    test('desativarBem remove o bem da lista', () async {
      final fake = FakePatrimonioDataSource()
        ..bensPagina0 = [PatrimonioModel(id: 'b-1', descricao: 'Ar-condicionado')];
      final provider = PatrimonioProvider(PatrimonioRepository(remoteDataSource: fake));
      await provider.carregarBens();

      final ok = await provider.desativarBem('b-1');

      expect(ok, isTrue);
      expect(provider.bens, isEmpty);
    });

    test('buscarPorQrCode resolve pelo tombamento e retorna null se não achar', () async {
      final fake = FakePatrimonioDataSource()
        ..bensPagina0 = [PatrimonioModel(id: 'b-1', tombamento: 'TOM-0009', descricao: 'Bancada')];
      final provider = PatrimonioProvider(PatrimonioRepository(remoteDataSource: fake));

      final achado = await provider.buscarPorQrCode('TOM-0009');
      expect(achado?.id, 'b-1');

      final nada = await provider.buscarPorQrCode('TOM-XXXX');
      expect(nada, isNull);
    });

    test('criarBem envia vida util como inteiro no payload', () async {
      final fake = FakePatrimonioDataSource();
      final provider = PatrimonioProvider(PatrimonioRepository(remoteDataSource: fake));

      final ok = await provider.criarBem(
        descricao: 'Projetor',
        valorAquisicao: '2500,00',
        vidaUtilMeses: '60',
      );

      expect(ok, isTrue);
      expect(fake.ultimoPayload!['vidaUtilMeses'], 60);
      expect(fake.ultimoPayload!['valorAquisicao'], 2500.0);
    });
  });
}
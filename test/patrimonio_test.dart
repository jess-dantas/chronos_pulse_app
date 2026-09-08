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
  });
}
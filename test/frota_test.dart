import 'package:flutter_test/flutter_test.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/core/network/paginated_response.dart';
import 'package:chronos_pulse_app/features/frota/data/datasources/frota_remote_datasource.dart';
import 'package:chronos_pulse_app/features/frota/data/models/frota_models.dart';
import 'package:chronos_pulse_app/features/frota/data/repositories/frota_repository.dart';
import 'package:chronos_pulse_app/features/frota/presentation/providers/frota_provider.dart';

class FakeFrotaDataSource extends FrotaRemoteDataSource {
  List<FrotaVeiculoModel> veiculosPagina0 = [];
  List<FrotaVeiculoModel> veiculosPagina1 = [];
  List<AbastecimentoModel> abastecimentos = [];
  int totalPaginasVeiculos = 1;
  bool falhar = false;
  Map<String, dynamic>? ultimoPayloadVeiculo;
  Map<String, dynamic>? ultimoPayloadAbastecimento;

  FakeFrotaDataSource() : super(DioClient());

  @override
  Future<PaginatedResponse<FrotaVeiculoModel>> getVeiculos({int page = 0, int size = 50}) async {
    if (falhar) throw Exception('Servidor indisponível');
    final itens = page == 0 ? veiculosPagina0 : veiculosPagina1;
    return PaginatedResponse<FrotaVeiculoModel>(
      items: itens,
      totalElements: veiculosPagina0.length + veiculosPagina1.length,
      totalPages: totalPaginasVeiculos,
      currentPage: page,
      pageSize: size,
    );
  }

  @override
  Future<FrotaVeiculoModel> criarVeiculo(Map<String, dynamic> payload) async {
    ultimoPayloadVeiculo = Map<String, dynamic>.from(payload);
    final veiculo = FrotaVeiculoModel.fromJson({
      'id': 'v-${veiculosPagina0.length + 1}',
      'placa': payload['placa'],
      'odometroAtual': payload['odometroAtual'],
    });
    veiculosPagina0.add(veiculo);
    return veiculo;
  }

  @override
  Future<PaginatedResponse<AbastecimentoModel>> getAbastecimentos({int page = 0, int size = 50}) async {
    if (falhar) throw Exception('Servidor indisponível');
    return PaginatedResponse<AbastecimentoModel>(
      items: abastecimentos,
      totalElements: abastecimentos.length,
      totalPages: 1,
      currentPage: page,
      pageSize: size,
    );
  }

  @override
  Future<AbastecimentoModel> registrarAbastecimento(Map<String, dynamic> payload) async {
    ultimoPayloadAbastecimento = Map<String, dynamic>.from(payload);
    final abas = AbastecimentoModel.fromJson({
      'id': 'a-${abastecimentos.length + 1}',
      'veiculoId': payload['veiculoId'],
      'dataHora': payload['dataHora'],
      'litros': payload['litros'],
      'valorLitro': payload['valorLitro'],
      'valorTotal': (payload['litros'] as num) * (payload['valorLitro'] as num),
    });
    abastecimentos.add(abas);
    return abas;
  }
}

void main() {
  group('Frota Models Tests', () {
    test('FrotaVeiculoModel normaliza odômetro pt-BR e aplica defaults', () {
      final veiculo = FrotaVeiculoModel.fromJson({
        'id': 'v-1',
        'placa': 'ABC-1234',
        'odometroAtual': '21350,7',
        'anoFabricacao': 2020,
      });
      expect(veiculo.odometroAtual, 21350.7);
      expect(veiculo.status, 'ATIVO');
      expect(veiculo.anoFabricacao, 2020);
    });

    test('AbastecimentoModel aceita números e strings decimais', () {
      final abas = AbastecimentoModel.fromJson({
        'id': 'a-1',
        'veiculoId': 'v-1',
        'veiculoPlaca': 'ABC-1234',
        'dataHora': '2026-09-08T10:00:00',
        'litros': 50,
        'valorLitro': '6,99',
        'valorTotal': 349.5,
      });
      expect(abas.litros, 50.0);
      expect(abas.valorLitro, 6.99);
      expect(abas.valorTotal, 349.5);
    });
  });

  group('FrotaProvider Tests', () {
    test('carregarTudo popula veículos e abastecimentos', () async {
      final fake = FakeFrotaDataSource()
        ..veiculosPagina0 = [
          FrotaVeiculoModel(id: 'v-1', placa: 'ABC-1234'),
        ]
        ..abastecimentos = [
          AbastecimentoModel(id: 'a-1', veiculoId: 'v-1', dataHora: '2026-09-08', litros: 50, valorLitro: 6.99, valorTotal: 349.5),
        ];
      final provider = FrotaProvider(FrotaRepository(remoteDataSource: fake));

      await provider.carregarTudo();

      expect(provider.veiculos.length, 1);
      expect(provider.abastecimentos.length, 1);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('criarVeiculo normaliza odômetro vírgula para ponto', () async {
      final fake = FakeFrotaDataSource();
      final provider = FrotaProvider(FrotaRepository(remoteDataSource: fake));

      final ok = await provider.criarVeiculo({
        'placa': 'XYZ-9999',
        'odometroAtual': '12345,6',
      });

      expect(ok, isTrue);
      expect(fake.ultimoPayloadVeiculo!['odometroAtual'], 12345.6);
      expect(provider.veiculos.length, 1);
    });

    test('registrarAbastecimento normaliza litros e valorLitro', () async {
      final fake = FakeFrotaDataSource();
      final provider = FrotaProvider(FrotaRepository(remoteDataSource: fake));

      final ok = await provider.registrarAbastecimento({
        'veiculoId': 'v-1',
        'dataHora': '2026-09-08T10:00:00',
        'litros': '45,5',
        'valorLitro': '5,89',
        'odometroKm': '50000,0',
      });

      expect(ok, isTrue);
      expect(fake.ultimoPayloadAbastecimento!['litros'], 45.5);
      expect(fake.ultimoPayloadAbastecimento!['valorLitro'], 5.89);
      expect(fake.ultimoPayloadAbastecimento!['odometroKm'], 50000.0);
    });

    test('carregarMaisVeiculos anexa a próxima página quando hasMore', () async {
      final fake = FakeFrotaDataSource()
        ..veiculosPagina0 = [FrotaVeiculoModel(id: 'v-1', placa: 'ABC-1')]
        ..veiculosPagina1 = [FrotaVeiculoModel(id: 'v-2', placa: 'DEF-2')]
        ..totalPaginasVeiculos = 3;
      final provider = FrotaProvider(FrotaRepository(remoteDataSource: fake));

      await provider.carregarTudo();
      expect(provider.hasMoreVeiculos, isTrue);
      expect(provider.veiculos.length, 1);

      await provider.carregarMaisVeiculos();
      expect(provider.veiculos.length, 2);
      expect(provider.hasMoreVeiculos, isTrue);
    });

    test('erro de conexão é exposto como mensagem amigável', () async {
      final fake = FakeFrotaDataSource()..falhar = true;
      final provider = FrotaProvider(FrotaRepository(remoteDataSource: fake));

      await provider.carregarTudo();

      expect(provider.errorMessage, 'Servidor indisponível');
      expect(provider.isLoading, isFalse);
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/features/patrimonio/data/datasources/inventario_remote_datasource.dart';
import 'package:chronos_pulse_app/features/patrimonio/data/models/patrimonio_models.dart';
import 'package:chronos_pulse_app/features/patrimonio/data/repositories/inventario_repository.dart';
import 'package:chronos_pulse_app/features/patrimonio/presentation/providers/inventario_provider.dart';

InventarioItemModel item(InventarioItemModel it, bool conferido, String? resultado, String? observacao) {
  return InventarioItemModel(
    id: it.id,
    patrimonioId: it.patrimonioId,
    patrimonioTombamento: it.patrimonioTombamento,
    patrimonioDescricao: it.patrimonioDescricao,
    conferido: conferido,
    conferidoPor: conferido ? 'Teste' : null,
    dataConferencia: conferido ? '2026-09-09T10:00:00' : null,
    resultado: resultado,
    observacao: observacao,
  );
}

class FakeInventarioDataSource extends InventarioRemoteDataSource {
  List<InventarioModel> inventarios = [];
  bool falhar = false;
  Map<String, dynamic>? ultimoPayload;

  FakeInventarioDataSource() : super(DioClient());

  @override
  Future<List<InventarioModel>> listarInventarios() async {
    if (falhar) throw Exception('Erro de rede');
    return List.of(inventarios);
  }

  @override
  Future<InventarioModel> criarInventario({
    required String descricao,
    String? dataInicio,
    String? dataFim,
  }) async {
    ultimoPayload = {'descricao': descricao, 'dataInicio': dataInicio, 'dataFim': dataFim};
    final novo = InventarioModel(
      id: 'inv-${inventarios.length + 1}',
      descricao: descricao,
      dataInicio: dataInicio,
      dataFim: dataFim,
    );
    inventarios.add(novo);
    return novo;
  }

  @override
  Future<InventarioModel> conferirItem(
    String inventarioId, {
    required String patrimonioId,
    required String resultado,
    String? observacao,
  }) async {
    final index = inventarios.indexWhere((i) => i.id == inventarioId);
    final i = inventarios[index];
    final itens = i.itens
        .map((it) => it.patrimonioId == patrimonioId
            ? item(it, true, resultado, observacao)
            : it)
        .toList();
    final atualizado = InventarioModel.fromJson({
      'id': i.id,
      'descricao': i.descricao,
      'dataInicio': i.dataInicio,
      'dataFim': i.dataFim,
      'status': i.status,
      'criadoEm': i.criadoEm,
      'criadoPor': i.criadoPor,
      'itens': itens.map((it) => _itensJson(it)).toList(),
    });
    inventarios[index] = atualizado;
    return atualizado;
  }

  @override
  Future<InventarioModel> finalizar(String inventarioId) async {
    final index = inventarios.indexWhere((i) => i.id == inventarioId);
    final i = inventarios[index];
    final itens = i.itens
        .map((it) => it.conferido ? it : item(it, true, 'DIVERGENCIA', 'Não localizado'))
        .toList();
    final atualizado = InventarioModel.fromJson({
      'id': i.id,
      'descricao': i.descricao,
      'dataInicio': i.dataInicio,
      'dataFim': i.dataFim,
      'status': 'CONCLUIDO',
      'criadoEm': i.criadoEm,
      'criadoPor': i.criadoPor,
      'itens': itens.map((it) => _itensJson(it)).toList(),
    });
    inventarios[index] = atualizado;
    return atualizado;
  }

  @override
  Future<void> cancelar(String inventarioId) async {
    inventarios = inventarios.where((i) => i.id != inventarioId).toList();
  }

  Map<String, dynamic> _itensJson(InventarioItemModel it) {
    return {
      'id': it.id,
      'patrimonioId': it.patrimonioId,
      'patrimonioTombamento': it.patrimonioTombamento,
      'patrimonioDescricao': it.patrimonioDescricao,
      'conferido': it.conferido,
      'conferidoPor': it.conferidoPor,
      'dataConferencia': it.dataConferencia,
      'resultado': it.resultado,
      'observacao': it.observacao,
    };
  }
}

void main() {
  InventarioModel inventarioComItens({int total = 3}) {
    return InventarioModel(
      id: 'inv-1',
      descricao: 'Inventário Anual',
      totalItens: total,
    );
  }

  group('InventarioModel Tests', () {
    test('progresso calcula percentual de itens conferidos', () {
      final i = InventarioModel(
        id: 'inv-1',
        descricao: 'Inventário',
        totalItens: 10,
        totalConferidos: 5,
      );
      expect(i.progresso, 0.5);
      expect(inventarioComItens().progresso, 0.0);
    });

    test('fromJson calcula totais a partir dos itens quando ausentes', () {
      final i = InventarioModel.fromJson({
        'id': 'inv-1',
        'descricao': 'Inv',
        'itens': [
          {
            'patrimonioId': 'b-1',
            'conferido': true,
            'resultado': 'CONFORME',
          },
          {
            'patrimonioId': 'b-2',
            'conferido': true,
            'resultado': 'DIVERGENCIA',
          },
          {'patrimonioId': 'b-3', 'conferido': false},
        ],
      });
      expect(i.totalItens, 3);
      expect(i.totalConferidos, 2);
      expect(i.totalConformes, 1);
      expect(i.totalDivergencias, 1);
    });
  });

  group('InventarioProvider Tests', () {
    test('carregarInventarios popula a lista', () async {
      final fake = FakeInventarioDataSource()
        ..inventarios = [inventarioComItens()];
      final provider = InventarioProvider(InventarioRepository(remoteDataSource: fake));

      await provider.carregarInventarios();

      expect(provider.inventarios.length, 1);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('emAndamento filtra apenas inventários em andamento', () async {
      final fake = FakeInventarioDataSource()
        ..inventarios = [
          InventarioModel(id: 'inv-1', descricao: 'Aberto', status: 'EM_ANDAMENTO'),
          InventarioModel(id: 'inv-2', descricao: 'Fechado', status: 'CONCLUIDO'),
        ];
      final provider = InventarioProvider(InventarioRepository(remoteDataSource: fake));

      await provider.carregarInventarios();

      expect(provider.emAndamento.length, 1);
      expect(provider.emAndamento.first.descricao, 'Aberto');
    });

    test('criar abre inventário e recarrega a lista', () async {
      final fake = FakeInventarioDataSource();
      final provider = InventarioProvider(InventarioRepository(remoteDataSource: fake));

      final ok = await provider.criar(
        descricao: 'Inventário de setembro',
        dataInicio: '2026-09-01',
      );

      expect(ok, isTrue);
      expect(fake.ultimoPayload!['descricao'], 'Inventário de setembro');
      expect(provider.inventarios.length, 1);
    });

    test('conferirItem substitui inventário com item conferido', () async {
      final fake = FakeInventarioDataSource()
        ..inventarios = [
          InventarioModel.fromJson({
            'id': 'inv-1',
            'descricao': 'Inv',
            'itens': [
              {'patrimonioId': 'b-1', 'patrimonioDescricao': 'Notebook', 'patrimonioTombamento': 'TOM-0001'},
              {'patrimonioId': 'b-2', 'patrimonioDescricao': 'Impressora', 'patrimonioTombamento': 'TOM-0002'},
            ],
          }),
        ];
      final provider = InventarioProvider(InventarioRepository(remoteDataSource: fake));
      await provider.carregarInventarios();

      final atualizado = await provider.conferirItem(
        'inv-1',
        patrimonioId: 'b-1',
        resultado: 'CONFORME',
      );

      expect(atualizado, isNotNull);
      expect(atualizado!.totalConferidos, 1);
      expect(provider.inventarios.first.totalConferidos, 1);
      expect(provider.inventarios.first.itens.first.resultado, 'CONFORME');
    });

    test('finalizar marca não conferidos como divergência e conclui', () async {
      final fake = FakeInventarioDataSource()
        ..inventarios = [
          InventarioModel.fromJson({
            'id': 'inv-1',
            'descricao': 'Inv',
            'itens': [
              {'patrimonioId': 'b-1', 'conferido': true, 'resultado': 'CONFORME'},
              {'patrimonioId': 'b-2', 'conferido': false},
            ],
          }),
        ];
      final provider = InventarioProvider(InventarioRepository(remoteDataSource: fake));
      await provider.carregarInventarios();

      final ok = await provider.finalizar('inv-1');

      expect(ok, isTrue);
      final fechado = provider.inventarios.first;
      expect(fechado.status, 'CONCLUIDO');
      expect(fechado.totalDivergencias, 1);
    });

    test('cancelar remove inventário da lista', () async {
      final fake = FakeInventarioDataSource()
        ..inventarios = [inventarioComItens()];
      final provider = InventarioProvider(InventarioRepository(remoteDataSource: fake));
      await provider.carregarInventarios();

      final ok = await provider.cancelar('inv-1');

      expect(ok, isTrue);
      expect(provider.inventarios, isEmpty);
    });

    test('falha ao carregar expõe mensagem de erro', () async {
      final fake = FakeInventarioDataSource()..falhar = true;
      final provider = InventarioProvider(InventarioRepository(remoteDataSource: fake));

      await provider.carregarInventarios();

      expect(provider.errorMessage, 'Erro de rede');
      expect(provider.inventarios, isEmpty);
    });

    test('conferirItem retorna null e expõe erro em falha', () async {
      final fake = FakeInventarioDataSource();
      final provider = InventarioProvider(InventarioRepository(remoteDataSource: fake));

      final atualizado = await provider.conferirItem(
        'inv-1',
        patrimonioId: 'b-1',
        resultado: 'CONFORME',
      );

      expect(atualizado, isNull);
      expect(provider.errorMessage, isNotNull);
    });
  });
}
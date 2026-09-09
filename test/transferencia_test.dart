import 'package:flutter_test/flutter_test.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/features/patrimonio/data/datasources/transferencia_remote_datasource.dart';
import 'package:chronos_pulse_app/features/patrimonio/data/models/patrimonio_models.dart';
import 'package:chronos_pulse_app/features/patrimonio/data/repositories/transferencia_repository.dart';
import 'package:chronos_pulse_app/features/patrimonio/presentation/providers/transferencia_provider.dart';

class FakeTransferenciaDataSource extends TransferenciaRemoteDataSource {
  List<TransferenciaModel> transferencias = [];
  bool falhar = false;
  Map<String, dynamic>? ultimoPayload;

  FakeTransferenciaDataSource() : super(DioClient());

  @override
  Future<List<TransferenciaModel>> listarTransferencias() async {
    if (falhar) throw Exception('Erro de rede');
    return List.of(transferencias);
  }

  @override
  Future<TransferenciaModel> solicitar({
    required String patrimonioId,
    required String localizacaoDestino,
    String? localizacaoOrigem,
    String? responsavelOrigem,
    String? responsavelDestino,
    String? dataPrevista,
    String? justificativa,
  }) async {
    if (falhar) throw Exception('Erro de rede');
    ultimoPayload = {
      'patrimonioId': patrimonioId,
      'localizacaoDestino': localizacaoDestino,
      'localizacaoOrigem': localizacaoOrigem,
      'responsavelOrigem': responsavelOrigem,
      'responsavelDestino': responsavelDestino,
      'dataPrevista': dataPrevista,
      'justificativa': justificativa,
    };
    final nova = TransferenciaModel(
      id: 't-${transferencias.length + 1}',
      patrimonioId: patrimonioId,
      localizacaoOrigem: localizacaoOrigem,
      localizacaoDestino: localizacaoDestino,
      responsavelOrigem: responsavelOrigem,
      responsavelDestino: responsavelDestino,
      dataPrevista: dataPrevista,
      justificativa: justificativa,
    );
    transferencias.add(nova);
    return nova;
  }

  @override
  Future<TransferenciaModel> confirmar(String id) async {
    final index = transferencias.indexWhere((t) => t.id == id);
    final t = transferencias[index];
    final atualizada = TransferenciaModel(
      id: t.id,
      patrimonioId: t.patrimonioId,
      localizacaoOrigem: t.localizacaoOrigem,
      localizacaoDestino: t.localizacaoDestino,
      responsavelOrigem: t.responsavelOrigem,
      responsavelDestino: t.responsavelDestino,
      dataSolicitacao: t.dataSolicitacao,
      dataPrevista: t.dataPrevista,
      dataEfetivacao: '2026-09-09T12:00:00',
      status: 'CONFIRMADA',
      justificativa: t.justificativa,
      solicitadoPor: t.solicitadoPor,
      aprovadoPor: 'Teste',
    );
    transferencias[index] = atualizada;
    return atualizada;
  }

  @override
  Future<void> cancelar(String id) async {
    transferencias = transferencias.where((t) => t.id != id).toList();
  }
}

void main() {
  TransferenciaModel solicitada({String status = 'SOLICITADA'}) {
    return TransferenciaModel(
      id: 't-1',
      patrimonioId: 'b-1',
      localizacaoOrigem: 'Secretaria de Obras',
      localizacaoDestino: 'Almoxarifado Central',
      status: status,
    );
  }

  group('TransferenciaProvider Tests', () {
    test('carregarTransferencias popula a lista', () async {
      final fake = FakeTransferenciaDataSource()..transferencias = [solicitada()];
      final provider = TransferenciaProvider(TransferenciaRepository(remoteDataSource: fake));

      await provider.carregarTransferencias();

      expect(provider.transferencias.length, 1);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('solicitar envia payload e recarrega a lista', () async {
      final fake = FakeTransferenciaDataSource();
      final provider = TransferenciaProvider(TransferenciaRepository(remoteDataSource: fake));

      final ok = await provider.solicitar(
        patrimonioId: 'b-1',
        localizacaoDestino: 'Almoxarifado Central',
        localizacaoOrigem: 'Secretaria de Obras',
        justificativa: 'Reorganização do setor',
      );

      expect(ok, isTrue);
      expect(fake.ultimoPayload!['patrimonioId'], 'b-1');
      expect(fake.ultimoPayload!['localizacaoDestino'], 'Almoxarifado Central');
      expect(provider.transferencias.length, 1);
      expect(provider.transferencias.first.status, 'SOLICITADA');
    });

    test('confirmar substitui pela transferência confirmada', () async {
      final fake = FakeTransferenciaDataSource()..transferencias = [solicitada()];
      final provider = TransferenciaProvider(TransferenciaRepository(remoteDataSource: fake));
      await provider.carregarTransferencias();

      final ok = await provider.confirmar('t-1');

      expect(ok, isTrue);
      final t = provider.transferencias.first;
      expect(t.status, 'CONFIRMADA');
      expect(t.dataEfetivacao, isNotNull);
      expect(t.localizacaoDestino, 'Almoxarifado Central');
    });

    test('cancelar remove a transferência da lista', () async {
      final fake = FakeTransferenciaDataSource()..transferencias = [solicitada()];
      final provider = TransferenciaProvider(TransferenciaRepository(remoteDataSource: fake));
      await provider.carregarTransferencias();

      final ok = await provider.cancelar('t-1');

      expect(ok, isTrue);
      expect(provider.transferencias, isEmpty);
    });

    test('falha ao carregar expõe mensagem de erro', () async {
      final fake = FakeTransferenciaDataSource()..falhar = true;
      final provider = TransferenciaProvider(TransferenciaRepository(remoteDataSource: fake));

      await provider.carregarTransferencias();

      expect(provider.errorMessage, 'Erro de rede');
      expect(provider.transferencias, isEmpty);
    });

    test('solicitar retorna false e expõe erro em falha', () async {
      final fake = FakeTransferenciaDataSource()..falhar = true;
      final provider = TransferenciaProvider(TransferenciaRepository(remoteDataSource: fake));

      final ok = await provider.solicitar(
        patrimonioId: 'b-1',
        localizacaoDestino: 'Almoxarifado',
      );

      expect(ok, isFalse);
      expect(provider.errorMessage, 'Erro de rede');
    });
  });
}
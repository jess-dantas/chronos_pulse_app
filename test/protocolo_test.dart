import 'package:flutter_test/flutter_test.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/core/network/paginated_response.dart';
import 'package:chronos_pulse_app/features/protocolo/data/datasources/protocolo_remote_datasource.dart';
import 'package:chronos_pulse_app/features/protocolo/data/models/protocolo_models.dart';
import 'package:chronos_pulse_app/features/protocolo/data/repositories/protocolo_repository.dart';
import 'package:chronos_pulse_app/features/protocolo/presentation/providers/protocolo_provider.dart';

class FakeProtocoloDataSource extends ProtocoloRemoteDataSource {
  List<ProtocoloModel> protocolos = [];
  int totalPaginas = 1;
  bool falhar = false;
  Map<String, dynamic>? ultimoPayloadCriar;
  String? ultimoStatusId;
  String? ultimoStatus;

  FakeProtocoloDataSource() : super(DioClient());

  @override
  Future<PaginatedResponse<ProtocoloModel>> getProtocolos({int page = 0, int size = 50}) async {
    if (falhar) throw Exception('Falha de rede');
    return PaginatedResponse<ProtocoloModel>(
      items: protocolos,
      totalElements: protocolos.length,
      totalPages: totalPaginas,
      currentPage: page,
      pageSize: size,
    );
  }

  @override
  Future<ProtocoloModel> criarProtocolo(Map<String, dynamic> payload) async {
    ultimoPayloadCriar = Map<String, dynamic>.from(payload);
    final protocolo = ProtocoloModel.fromJson({
      'id': 'p-${protocolos.length + 1}',
      'numeroProtocolo': payload['numeroProtocolo'],
      'tipo': payload['tipo'],
      'assunto': payload['assunto'],
    });
    protocolos.add(protocolo);
    return protocolo;
  }

  @override
  Future<ProtocoloModel> atualizarStatus(
    String id,
    String status, {
    String? responsavel,
    String? observacoes,
  }) async {
    ultimoStatusId = id;
    ultimoStatus = status;
    final idx = protocolos.indexWhere((p) => p.id == id);
    if (idx >= 0) {
      final atual = protocolos[idx];
      protocolos[idx] = ProtocoloModel(
        id: atual.id,
        numeroProtocolo: atual.numeroProtocolo,
        tipo: atual.tipo,
        assunto: atual.assunto,
        descricao: atual.descricao,
        remetente: atual.remetente,
        destinatario: atual.destinatario,
        dataProtocolo: atual.dataProtocolo,
        status: status,
        responsavel: responsavel ?? atual.responsavel,
        observacoes: observacoes ?? atual.observacoes,
      );
    }
    return protocolos[idx];
  }
}

void main() {
  group('Protocolo Models Tests', () {
    test('ProtocoloModel aplica defaults ao desserializar', () {
      final protocolo = ProtocoloModel.fromJson({
        'id': 'p-1',
        'numeroProtocolo': '2026/0001',
        'assunto': 'Oficio de licença',
      });
      expect(protocolo.numeroProtocolo, '2026/0001');
      expect(protocolo.tipo, 'GERAL');
      expect(protocolo.status, 'RECEBIDO');
    });

    test('protocolosRecebido filtra apenas status RECEBIDO', () async {
      final fake = FakeProtocoloDataSource()
        ..protocolos = [
          ProtocoloModel(id: 'p-1', numeroProtocolo: '1', tipo: 'GERAL', assunto: 'A', status: 'RECEBIDO'),
          ProtocoloModel(id: 'p-2', numeroProtocolo: '2', tipo: 'GERAL', assunto: 'B', status: 'ENCAMINHADO'),
        ];
      final provider = ProtocoloProvider(ProtocoloRepository(remoteDataSource: fake));

      await provider.carregarProtocolos();

      expect(provider.protocolos.length, 2);
      expect(provider.protocolosRecebido.length, 1);
    });
  });

  group('ProtocoloProvider Tests', () {
    test('carregarProtocolos popula a lista', () async {
      final fake = FakeProtocoloDataSource()
        ..protocolos = [ProtocoloModel(id: 'p-1', numeroProtocolo: '1', tipo: 'GERAL', assunto: 'Oficio')];
      final provider = ProtocoloProvider(ProtocoloRepository(remoteDataSource: fake));

      await provider.carregarProtocolos();

      expect(provider.protocolos.length, 1);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('criarProtocolo monta payload com campos obrigatórios', () async {
      final fake = FakeProtocoloDataSource();
      final provider = ProtocoloProvider(ProtocoloRepository(remoteDataSource: fake));

      final ok = await provider.criarProtocolo(
        numeroProtocolo: '2026/0002',
        tipo: 'OFICIO',
        assunto: 'Resposta a requisicao',
        descricao: '',
      );

      expect(ok, isTrue);
      expect(fake.ultimoPayloadCriar!['numeroProtocolo'], '2026/0002');
      expect(fake.ultimoPayloadCriar!['tipo'], 'OFICIO');
      expect(fake.ultimoPayloadCriar!.containsKey('descricao'), isFalse);
      expect(provider.protocolos.length, 1);
    });

    test('atualizarStatus repassa id/status e recarrega', () async {
      final fake = FakeProtocoloDataSource()
        ..protocolos = [
          ProtocoloModel(id: 'p-1', numeroProtocolo: '1', tipo: 'GERAL', assunto: 'Oficio', status: 'RECEBIDO'),
        ];
      final provider = ProtocoloProvider(ProtocoloRepository(remoteDataSource: fake));

      final ok = await provider.atualizarStatus('p-1', 'ARQUIVADO');

      expect(ok, isTrue);
      expect(fake.ultimoStatusId, 'p-1');
      expect(fake.ultimoStatus, 'ARQUIVADO');
      expect(provider.protocolos.first.status, 'ARQUIVADO');
    });

    test('falha ao carregar expõe mensagem de erro', () async {
      final fake = FakeProtocoloDataSource()..falhar = true;
      final provider = ProtocoloProvider(ProtocoloRepository(remoteDataSource: fake));

      await provider.carregarProtocolos();

      expect(provider.errorMessage, 'Falha de rede');
      expect(provider.protocolos, isEmpty);
    });
  });
}
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:chronos_pulse_app/core/hardware/hardware_service.dart';
import 'package:chronos_pulse_app/core/network/conexao_service.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/core/security/device_token_store.dart';
import 'package:chronos_pulse_app/core/theme/theme_provider.dart';
import 'package:chronos_pulse_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:chronos_pulse_app/features/auth/data/repositories/auth_repository.dart';
import 'package:chronos_pulse_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:chronos_pulse_app/features/auth/presentation/screens/login_screen.dart';
import 'package:chronos_pulse_app/features/home_deslogada/presentation/screens/home_deslogada_screen.dart';
import 'package:chronos_pulse_app/features/ponto/data/datasources/ponto_remote_datasource.dart';
import 'package:chronos_pulse_app/features/ponto/data/models/registro_ponto_model.dart';
import 'package:chronos_pulse_app/features/ponto/data/repositories/ponto_repository.dart';
import 'package:chronos_pulse_app/features/ponto/presentation/providers/ponto_provider.dart';
import 'package:chronos_pulse_app/features/ponto/presentation/screens/home_ponto_screen.dart';
import 'package:chronos_pulse_app/features/ponto/presentation/screens/modo_ponto_screen.dart';

import 'ponto_test.dart' show MockPontoLocalDataSource, MockPontoRemoteDataSource;

/// Adapter que captura a requisição e responde 200 de sincronização.
class _CapturaAdapter implements HttpClientAdapter {
  RequestOptions? ultima;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();
    ultima = options;
    return ResponseBody.fromString(
      '{"idsSucesso":["ok"],"idsFalha":[]}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Adapter comutável: derruba e restabelece a rede, ecoando os ids recebidos.
class _AdapterComRede implements HttpClientAdapter {
  bool online = true;
  RequestOptions? ultima;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();
    if (!online) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message: 'sem rede',
        error: Exception('sem rede'),
      );
    }
    ultima = options;
    final registros = ((options.data as Map)['registros'] as List)
        .map((r) => r['idLocal'] as String)
        .toList();
    return ResponseBody.fromString(
      '{"idsSucesso":${jsonEncode(registros)},"idsFalha":[]}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

DeviceTokenStore _storeComVinculo() {
  final store = DeviceTokenStore(
    ler: (k) async => _memoria[k],
    gravar: (k, v) async {
      _memoria[k] = v;
    },
    remover: (k) async {
      _memoria.remove(k);
    },
  );
  return store;
}

final Map<String, String> _memoria = {};

RegistroPontoModel _registro() => RegistroPontoModel(
      idLocal: 'id-local-1',
      dataHoraDispositivo: DateTime.now().toUtc(),
      tipoRegistro: 'ENTRADA',
      latitude: -23.5,
      longitude: -46.6,
      precisaoGps: 5.0,
      fotoUrl: 'https://example.com/f.jpg',
      hashLocal: 'hash1',
      sincronizadoOffline: false,
    );

void main() {
  setUp(() => _memoria.clear());

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  group('PontoRemoteDataSource — modo dispositivo (X-Device-Token)', () {
    test('sem sessão e com vínculo: envia header + dono no payload', () async {
      await _storeComVinculo().salvar(
        token: 'dt-abc',
        cpcId: 'cpc-dono',
        nome: 'Aparelho',
        expiraEm: DateTime.now().toUtc().add(const Duration(days: 7)),
      );

      final dioClient = DioClient();
      final adapter = _CapturaAdapter();
      dioClient.dio.httpClientAdapter = adapter;
      final datasource = PontoRemoteDataSource(dioClient,
          deviceStore: _storeComVinculo());

      final sucesso =
          await datasource.sincronizarPontos([_registro()]);

      expect(sucesso, isNotEmpty);
      // Header do vínculo presente (é a única credencial da requisição).
      expect(adapter.ultima!.headers['X-Device-Token'], 'dt-abc');
      // Nunca manda Bearer vazio/antigo nesse fluxo.
      expect(adapter.ultima!.headers.containsKey('Authorization'), isFalse);
      // Defesa de posse: dono declarado no lote.
      final payload = adapter.ultima!.data as Map<String, dynamic>;
      expect(payload['colaboradorId'], 'cpc-dono');
      expect(payload['registros'], hasLength(1));
    });

    test('com sessão ativa: NÃO envia device token nem colaboradorId',
        () async {
      await _storeComVinculo().salvar(
        token: 'dt-abc',
        cpcId: 'cpc-dono',
        nome: 'Aparelho',
        expiraEm: DateTime.now().toUtc().add(const Duration(days: 7)),
      );

      final dioClient = DioClient();
      dioClient.updateToken('jwt-da-sessao');
      final adapter = _CapturaAdapter();
      dioClient.dio.httpClientAdapter = adapter;
      final datasource = PontoRemoteDataSource(dioClient,
          deviceStore: _storeComVinculo());

      await datasource.sincronizarPontos([_registro()]);

      expect(adapter.ultima!.headers.containsKey('X-Device-Token'), isFalse);
      expect(adapter.ultima!.headers['Authorization'], 'Bearer jwt-da-sessao');
      final payload = adapter.ultima!.data as Map<String, dynamic>;
      expect(payload.containsKey('colaboradorId'), isFalse);
    });

    test('sem sessão e sem vínculo: segue sem header e sem dono', () async {
      final dioClient = DioClient();
      final adapter = _CapturaAdapter();
      dioClient.dio.httpClientAdapter = adapter;
      final datasource = PontoRemoteDataSource(dioClient,
          deviceStore: _storeComVinculo());

      await datasource.sincronizarPontos([_registro()]);

      expect(adapter.ultima!.headers.containsKey('X-Device-Token'), isFalse);
      final payload = adapter.ultima!.data as Map<String, dynamic>;
      expect(payload.containsKey('colaboradorId'), isFalse);
    });
  });

  group('ModoPontoScreen — guard da rota pública', () {
    testWidgets('sem vínculo ativo mostra o aviso e volta para o login',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ModoPontoScreen(store: _storeComVinculo()),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('expirou'), findsOneWidget);
      expect(find.text('Ir para o login'), findsOneWidget);
      // Nem chega na biometria sem vínculo.
    });

    testWidgets('biometria cancelada impede o embarque', (tester) async {
      await _storeComVinculo().salvar(
        token: 'dt-abc',
        cpcId: 'cpc-dono',
        nome: 'Aparelho',
        expiraEm: DateTime.now().toUtc().add(const Duration(days: 7)),
      );

      await tester.pumpWidget(MaterialApp(
        home: ModoPontoScreen(
          store: _storeComVinculo(),
          hardwareService: _HardwareFake(resultado: false),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('cancelada'), findsOneWidget);
      expect(find.text('Ir para o login'), findsOneWidget);
    });
  });

  group('Contingência offline — fila local → sync com X-Device-Token', () {
    test('batida sem sessão e sem rede enfileira; ao voltar envia com o vínculo',
        () async {
      await _storeComVinculo().salvar(
        token: 'dt-abc',
        cpcId: 'cpc-dono',
        nome: 'Aparelho',
        expiraEm: DateTime.now().toUtc().add(const Duration(days: 7)),
      );

      final adapter = _AdapterComRede()..online = false;
      final dioClient = DioClient();
      dioClient.dio.httpClientAdapter = adapter;
      final repo = PontoRepository(
        localDataSource: MockPontoLocalDataSource(),
        remoteDataSource: PontoRemoteDataSource(dioClient,
            deviceStore: _storeComVinculo()),
      );

      final registro = RegistroPontoModel(
        idLocal: 'id-offline-1',
        colaboradorId: 'cpc-dono',
        dataHoraDispositivo: DateTime.now().toUtc(),
        tipoRegistro: 'ENTRADA',
        latitude: -23.5,
        longitude: -46.6,
        precisaoGps: 5.0,
        hashLocal: 'hash1',
        sincronizadoOffline: false,
      );

      // 1) Rede caída: a batida NÃO falha — fica na fila local.
      final primeiraTentativa = await repo.registrarPonto(registro: registro);
      expect(primeiraTentativa, isFalse);
      expect(repo.ultimaFalhaServidor, isNull); // offline ≠ rejeição do servidor
      expect(await repo.obterQuantidadePendentes(colaboradorId: 'cpc-dono'), 1);

      // 2) Rede volta: sincroniza a fila com o vínculo do dispositivo.
      adapter.online = true;
      final enviados = await repo.sincronizarPendentes(colaboradorId: 'cpc-dono');
      expect(enviados, 1);
      expect(adapter.ultima!.headers['X-Device-Token'], 'dt-abc');
      expect(adapter.ultima!.headers.containsKey('Authorization'), isFalse);
      final payload = adapter.ultima!.data as Map<String, dynamic>;
      expect(payload['colaboradorId'], 'cpc-dono');
      expect(payload['registros'], hasLength(1));
      expect(await repo.obterQuantidadePendentes(colaboradorId: 'cpc-dono'), 0);
    });
  });

  group('HomePontoScreen (modo dispositivo) — saída pela seta ←', () {
    late AuthProvider auth;
    late PontoProvider ponto;

    setUp(() {
      auth = AuthProvider(AuthRepository(
        remoteDataSource: AuthRemoteDataSource(DioClient()),
        dioClient: DioClient(),
      ));
      ponto = PontoProvider(PontoRepository(
        localDataSource: MockPontoLocalDataSource(),
        remoteDataSource: MockPontoRemoteDataSource(),
      ));
    });

    tearDown(() {
      ponto.dispose();
      auth.dispose();
    });

    testWidgets('volta para a home de ponto, não para o login',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/ponto/dispositivo',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => HomeDeslogadaScreen(
              conexao: ConexaoService(ping: () async => true),
            ),
          ),
          GoRoute(
            path: '/ponto/dispositivo',
            builder: (context, state) => HomePontoScreen(
              modoDispositivo: VinculoDispositivo(
                token: 'dt-abc',
                cpcId: 'cpc-dono',
                nome: 'Aparelho',
                expiraEm:
                    DateTime.now().toUtc().add(const Duration(days: 7)),
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider<PontoProvider>.value(value: ponto),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      expect(find.byType(HomePontoScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Sair do modo dispositivo'));
      // HomePontoScreen tem relógio com timer de 1s: evita pumpAndSettle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(HomeDeslogadaScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });
  });
}

/// Biometria falsa para não depender do plugin local_auth no teste.
class _HardwareFake extends HardwareService {
  final bool resultado;
  _HardwareFake({this.resultado = true});

  @override
  Future<bool> autenticarBiometria() async => resultado;
}

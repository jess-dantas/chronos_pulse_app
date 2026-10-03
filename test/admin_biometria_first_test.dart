import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chronos_pulse_app/core/hardware/hardware_service.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/core/security/admin_device_token_store.dart';
import 'package:chronos_pulse_app/core/theme/theme_provider.dart';
import 'package:chronos_pulse_app/features/admin/data/datasources/admin_auth_remote_datasource.dart';
import 'package:chronos_pulse_app/features/admin/data/repositories/admin_auth_repository.dart';
import 'package:chronos_pulse_app/features/admin/presentation/providers/admin_auth_provider.dart';
import 'package:chronos_pulse_app/features/admin/presentation/screens/admin_auth_screen.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';

Map<String, dynamic> _sessao(String username) => {
      'id': '1',
      'username': username,
      'nomeCompleto': 'Root',
      'email': 'root@chronos.app',
      'criadoEm': '2026-01-01T00:00:00Z',
      'accessToken': 'access-1',
      'refreshToken': 'refresh-1',
    };

/// Repositório falso: reproduz a hierarquia do backend — deviceToken válido
/// autentica direto; sem ele (ou inválido) cai no fluxo normal (2FA/senha).
class _RepoFake implements AdminAuthRepository {
  String? loginUsername;
  String? loginSenha;
  String? loginDeviceToken;
  int logins = 0;

  bool deviceValido = true;
  bool twoFactorEnabled = true;
  int vincularChamadas = 0;
  int revogarChamadas = 0;

  @override
  Future<Map<String, dynamic>> login(
    String username, {
    String? senha,
    String? deviceToken,
  }) async {
    logins++;
    loginUsername = username;
    loginSenha = senha;
    loginDeviceToken = deviceToken;

    // Biometria-first: dispositivo confiável pula senha e 2FA.
    if (deviceToken != null && deviceToken.isNotEmpty && deviceValido) {
      return _sessao(username);
    }
    if (senha != null && senha.isNotEmpty) {
      if (senha == 'senha1234') return _sessao(username);
      throw Exception('Revise suas credenciais');
    }
    // Sem senha (e sem deviceToken válido): espelho do fluxo 2FA-first.
    if (twoFactorEnabled) {
      return {
        'requiresTwoFactor': true,
        'setupRequired': false,
        'tempToken': 'temp-1',
      };
    }
    throw Exception('Senha é obrigatória');
  }

  @override
  Future<Map<String, dynamic>> bootstrapStatus() async =>
      {'bootstrapAvailable': false};

  @override
  Future<Map<String, dynamic>> dispositivoVincular({String? deviceName}) async {
    vincularChamadas++;
    return {
      'deviceToken': 'dt-novo-cru',
      'expiraEm': DateTime.now()
          .toUtc()
          .add(const Duration(days: 30))
          .toIso8601String(),
    };
  }

  @override
  Future<void> dispositivoRevogar() async {
    revogarChamadas++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// Hardware controlável (mesmo padrão dos demais testes biométricos).
class _HardwareFake extends HardwareService {
  _HardwareFake({this.disponivel = true, this.autentica = true});

  bool disponivel;
  bool autentica;
  int chamadas = 0;

  @override
  Future<bool> biometriaDisponivel() async => disponivel;

  @override
  Future<bool> autenticarBiometria({String motivo = ''}) async {
    chamadas++;
    return autentica;
  }
}

/// Credencial em memória (sem Keystore/plugin).
AdminDeviceTokenStore _store([Map<String, String>? base]) {
  final mapa = <String, String>{...?base};
  return AdminDeviceTokenStore(
    ler: (k) async => mapa[k],
    gravar: (k, v) async {
      mapa[k] = v;
    },
    remover: (k) async {
      mapa.remove(k);
    },
  );
}

/// Store pré-populado com credencial vigente.
AdminDeviceTokenStore _storeComCredencial({String token = 'dt-token-cru'}) {
  return _store({
    AdminDeviceTokenStore.chaveToken: token,
    AdminDeviceTokenStore.chaveUsername: 'Administrator',
    AdminDeviceTokenStore.chaveExpiraEm: DateTime.now()
        .toUtc()
        .add(const Duration(days: 30))
        .millisecondsSinceEpoch
        .toString(),
  });
}

/// Adapter que registra as requisições e responde com um JSON fixo.
class _RegistraAdapter implements HttpClientAdapter {
  _RegistraAdapter({this.corpo = '{"ok": true}'});

  final String corpo;
  final List<String> caminhos = [];
  final List<dynamic> corpos = [];
  final List<String> metodos = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    caminhos.add(options.path);
    metodos.add(options.method);
    final bytes = await requestStream?.fold<List<int>>(
          List<int>.empty(growable: true),
          (acumulado, parte) => acumulado..addAll(parte),
        ) ??
        <int>[];
    final texto = utf8.decode(bytes, allowMalformed: true);
    corpos.add(texto.isEmpty ? null : jsonDecode(texto));
    return ResponseBody.fromString(
      corpo,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStoragePlatform.instance =
        TestFlutterSecureStoragePlatform(<String, String>{});
  });

  group('AdminAuthProvider — dispositivo confiável (biometria-first)', () {
    late _RepoFake repo;
    late AdminAuthProvider provider;

    setUp(() {
      repo = _RepoFake();
      provider = AdminAuthProvider(repo, DioClient());
      addTearDown(provider.dispose);
    });

    test('login com deviceToken repassa o token e pula a senha', () async {
      final ok =
          await provider.login('Administrator', deviceToken: 'dt-x');

      expect(ok, isTrue);
      expect(provider.isAuthenticated, isTrue);
      expect(repo.loginDeviceToken, 'dt-x');
      expect(repo.loginSenha, isNull,
          reason: 'o tier da biometria não envia senha');
    });

    test('login manual (senha) NÃO envia deviceToken', () async {
      final ok = await provider.login('Administrator', senha: 'senha1234');

      expect(ok, isTrue);
      expect(repo.loginSenha, 'senha1234');
      expect(repo.loginDeviceToken, isNull);
    });

    test('vincularDispositivo devolve o token cru uma única vez', () async {
      final resultado = await provider.vincularDispositivo();

      expect(resultado, isNotNull);
      expect(resultado!['deviceToken'], 'dt-novo-cru');
      expect(DateTime.parse(resultado['expiraEm'] as String).isAfter(
          DateTime.now().toUtc()),
          isTrue);
      expect(repo.vincularChamadas, 1);
      expect(provider.errorMessage, isNull);
    });

    test('revogarDispositivo confirma a revogação total', () async {
      final ok = await provider.revogarDispositivo();

      expect(ok, isTrue);
      expect(repo.revogarChamadas, 1);
      expect(provider.errorMessage, isNull);
    });
  });

  group('AdminAuthRemoteDataSource — dispositivo confiável', () {
    late DioClient dioClient;
    late _RegistraAdapter adapter;
    late AdminAuthRemoteDataSource datasource;

    setUp(() {
      dioClient = DioClient();
      adapter = _RegistraAdapter(
        corpo: jsonEncode({
          'deviceToken': 'dt-cru',
          'expiraEm': '2026-11-01T00:00:00Z',
        }),
      );
      dioClient.dio.httpClientAdapter = adapter;
      datasource = AdminAuthRemoteDataSource(dioClient);
    });

    test('login biométrico inclui o deviceToken no corpo', () async {
      await datasource.login('root', deviceToken: 'dt-cru');

      final corpo = adapter.corpos.single as Map<String, dynamic>;
      expect(corpo['deviceToken'], 'dt-cru');
      expect(corpo.keys, isNot(contains('senha')));
    });

    test('login manual omite o deviceToken do corpo', () async {
      await datasource.login('root', senha: 'senha-forte-1');

      final corpo = adapter.corpos.single as Map<String, dynamic>;
      expect(corpo.keys, isNot(contains('deviceToken')));
      expect(corpo['senha'], 'senha-forte-1');
    });

    test('vincular chama POST /admin/auth/dispositivo', () async {
      final resultado = await datasource.dispositivoVincular();

      expect(resultado['deviceToken'], 'dt-cru');
      expect(adapter.caminhos.single, endsWith('/admin/auth/dispositivo'));
      expect(adapter.metodos.single, 'POST');
    });

    test('revogar chama DELETE /admin/auth/dispositivo', () async {
      await datasource.dispositivoRevogar();

      expect(adapter.caminhos.single, endsWith('/admin/auth/dispositivo'));
      expect(adapter.metodos.single, 'DELETE');
    });
  });

  group('AdminLoginScreen — biometria-first', () {
    late _RepoFake repo;
    late AdminAuthProvider provider;

    setUp(() {
      repo = _RepoFake();
      provider = AdminAuthProvider(repo, DioClient());
      addTearDown(provider.dispose);
    });

    Future<void> pumpLogin(
      WidgetTester tester, {
      AdminDeviceTokenStore? store,
      HardwareService? hw,
    }) async {
      final router = GoRouter(
        initialLocation: '/admin/auth/login',
        routes: [
          GoRoute(
            path: '/admin/auth/login',
            builder: (context, state) => AdminLoginScreen(
              hardware: hw,
              deviceStore: store,
            ),
          ),
          GoRoute(
            path: '/admin/dashboard',
            builder: (context, state) =>
                const Scaffold(body: Text('dashboard-ok')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AdminAuthProvider>.value(value: provider),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();
    }

    testWidgets('credencial + biometria: auto-prompt loga com o deviceToken',
        (tester) async {
      final hw = _HardwareFake();

      await pumpLogin(tester,
          store: _storeComCredencial(), hw: hw);

      expect(hw.chamadas, equals(1), reason: 'auto-prompt na entrada');
      expect(repo.logins, equals(1));
      expect(repo.loginDeviceToken, 'dt-token-cru');
      expect(repo.loginSenha, isNull);
      expect(find.text('dashboard-ok'), findsOneWidget);
    });

    testWidgets('sem credencial guardada o formulário segue normal',
        (tester) async {
      final hw = _HardwareFake();

      await pumpLogin(tester, store: _store(), hw: hw);

      expect(hw.chamadas, equals(0));
      expect(find.byKey(const Key('admin_biometrico_button')), findsNothing);
      expect(repo.logins, equals(0));
      expect(find.widgetWithText(ElevatedButton, 'Entrar'), findsOneWidget);
    });

    testWidgets('biometria indisponível esconde o botão', (tester) async {
      final hw = _HardwareFake(disponivel: false);

      await pumpLogin(tester,
          store: _storeComCredencial(), hw: hw);

      expect(hw.chamadas, equals(0));
      expect(find.byKey(const Key('admin_biometrico_button')), findsNothing);
      expect(repo.logins, equals(0));
    });

    testWidgets('cancelou o prompt: formulário + botão, credencial preservada',
        (tester) async {
      final hw = _HardwareFake(autentica: false);
      final store = _storeComCredencial();

      await pumpLogin(tester, store: store, hw: hw);

      expect(hw.chamadas, equals(1));
      expect(repo.logins, equals(0), reason: 'sem biometria não loga');
      expect(find.byKey(const Key('admin_biometrico_button')), findsOneWidget);
      expect(find.text('Administrator'), findsOneWidget,
          reason: 'username da credencial pré-preenchido no formulário');
      expect(await store.possuiCredencial(), isTrue,
          reason: 'cancelar não apaga a credencial');
      expect(find.text('dashboard-ok'), findsNothing);
    });

    testWidgets('repetir pelo botão após cancelamento loga', (tester) async {
      final hw = _HardwareFake(autentica: false);

      await pumpLogin(tester,
          store: _storeComCredencial(), hw: hw);
      expect(repo.logins, equals(0));

      hw.autentica = true;
      await tester.tap(find.byKey(const Key('admin_biometrico_button')));
      await tester.pumpAndSettle();

      expect(hw.chamadas, equals(2));
      expect(repo.loginDeviceToken, 'dt-token-cru');
      expect(find.text('dashboard-ok'), findsOneWidget);
    });

    testWidgets('deviceToken recusado: limpa a credencial e pede o código',
        (tester) async {
      repo.deviceValido = false;
      final store = _storeComCredencial();

      await pumpLogin(tester, store: store, hw: _HardwareFake());

      expect(find.text('Verificação em duas etapas'), findsOneWidget,
          reason: 'cai no fluxo 2FA do servidor');
      expect(find.textContaining('Dispositivo não reconhecido'), findsOneWidget);
      expect(await store.possuiCredencial(), isFalse,
          reason: 'token vencido/revogado não fica no aparelho');
      expect(find.byKey(const Key('admin_biometrico_button')), findsNothing);
      expect(find.text('dashboard-ok'), findsNothing);

      // Drena o timer do snackbar antes de encerrar o teste.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('deviceToken recusado em conta sem 2FA: limpa e revela a '
        'senha', (tester) async {
      repo.deviceValido = false;
      repo.twoFactorEnabled = false;
      final store = _storeComCredencial();

      await pumpLogin(tester, store: store, hw: _HardwareFake());

      expect(await store.possuiCredencial(), isFalse);
      expect(find.byType(TextFormField), findsNWidgets(2),
          reason: 'campo de senha revelado para o login manual');
      expect(find.textContaining('Senha é obrigatória'), findsOneWidget);
      expect(find.byKey(const Key('admin_biometrico_button')), findsNothing);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });
}

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chronos_pulse_app/core/config/app_modo.dart';
import 'package:chronos_pulse_app/core/hardware/hardware_service.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/core/router/app_router.dart';
import 'package:chronos_pulse_app/core/security/session_storage.dart';
import 'package:chronos_pulse_app/core/theme/theme_provider.dart';
import 'package:chronos_pulse_app/features/admin/data/datasources/admin_auth_remote_datasource.dart';
import 'package:chronos_pulse_app/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:chronos_pulse_app/features/admin/data/repositories/admin_auth_repository.dart';
import 'package:chronos_pulse_app/features/admin/data/repositories/admin_repository.dart';
import 'package:chronos_pulse_app/features/admin/presentation/providers/admin_auth_provider.dart';
import 'package:chronos_pulse_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:chronos_pulse_app/features/admin/presentation/screens/admin_auth_screen.dart';
import 'package:chronos_pulse_app/features/admin/presentation/screens/admin_biometric_gate_screen.dart';
import 'package:chronos_pulse_app/features/admin/presentation/screens/admin_recover_screen.dart';
import 'package:chronos_pulse_app/features/admin/presentation/screens/admin_seguranca_screen.dart';
import 'package:chronos_pulse_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:chronos_pulse_app/features/auth/data/repositories/auth_repository.dart';
import 'package:chronos_pulse_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';

Map<String, dynamic> _sessao() => {
      'id': '1',
      'username': 'root',
      'nomeCompleto': 'Root',
      'email': 'root@chronos.app',
      'criadoEm': '2026-01-01T00:00:00Z',
      'accessToken': 'access-1',
      'refreshToken': 'refresh-1',
    };

/// Repositório falso do admin: implementa os fluxos usados nos testes e
/// delega o resto para `noSuchMethod` (padrão dos fakes do projeto).
class _RepoFake implements AdminAuthRepository {
  String? loginUsername;
  String? loginSenha;
  bool sessaoNoLogin = false;
  bool twoFactorNoLogin = true;

  String? recoverSenha;
  String? recoverNovaSenha;
  String? recoverCode;
  bool sessaoNoRecover = true;

  String? enviarTemp;
  bool enviarFalha = false;

  String? emailTemp;
  String? emailCodigo;
  bool sessaoNoEmail = true;

  String? refreshChamado;
  Map<String, dynamic>? refreshResposta;

  @override
  Future<Map<String, dynamic>> login(String username, {String? senha}) async {
    loginUsername = username;
    loginSenha = senha;
    if (sessaoNoLogin) return _sessao();
    if (senha == null || senha.isEmpty) {
      if (twoFactorNoLogin) {
        return {
          'requiresTwoFactor': true,
          'setupRequired': false,
          'tempToken': 'temp-1',
        };
      }
      throw Exception('Senha é obrigatória');
    }
    throw Exception('Revise suas credenciais');
  }

  @override
  Future<Map<String, dynamic>> verifyTwoFactor(
    String tempToken,
    String codigo,
  ) async =>
      _sessao();

  @override
  Future<void> sendEmailCode(String tempToken) async {
    enviarTemp = tempToken;
    if (enviarFalha) throw Exception('Erro ao enviar o código por e-mail');
  }

  @override
  Future<Map<String, dynamic>> verifyEmailCode(
    String tempToken,
    String codigo,
  ) async {
    emailTemp = tempToken;
    emailCodigo = codigo;
    if (!sessaoNoEmail) throw Exception('Código inválido');
    return _sessao();
  }

  @override
  Future<Map<String, dynamic>> refresh(String refreshToken) async {
    refreshChamado = refreshToken;
    final resposta = refreshResposta;
    if (resposta == null) throw Exception('Sessão expirada');
    return resposta;
  }

  @override
  Future<Map<String, dynamic>> recover({
    required String username,
    String? senha,
    required String recoveryCode,
    String? novaSenha,
  }) async {
    recoverSenha = senha;
    recoverCode = recoveryCode;
    recoverNovaSenha = novaSenha;
    if (!sessaoNoRecover) throw Exception('Código de recuperação inválido');
    return {
      ..._sessao(),
      'recoveryCodes': ['AAAAA-BBBBB', 'CCCCC-DDDDD'],
    };
  }

  @override
  Future<Map<String, dynamic>> bootstrapStatus() async =>
      {'bootstrapAvailable': false};

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// AdminAuthProvider com estado de sessão/gate controlável pelo teste.
class _AdminFake extends AdminAuthProvider {
  _AdminFake() : super(_RepoFake(), DioClient());

  bool autenticado = true;
  bool bloqueada = true;
  bool saiu = false;

  @override
  bool get isAuthenticated => autenticado;

  @override
  bool get sessaoDesbloqueada => !bloqueada;

  @override
  void confirmarBiometria() {
    bloqueada = false;
    notifyListeners();
  }

  @override
  Future<void> logout() async {
    saiu = true;
    autenticado = false;
    notifyListeners();
  }
}

/// Hardware controlável para o gate biométrico admin.
class _HardwareFake extends HardwareService {
  _HardwareFake({this.disponivel = true, this.autentica = true});

  bool disponivel;
  bool autentica;
  bool lancarErro = false;
  int chamadas = 0;

  @override
  Future<bool> biometriaDisponivel() async => disponivel;

  @override
  Future<bool> autenticarBiometria({String motivo = ''}) async {
    chamadas++;
    if (lancarErro) throw Exception('sensor indisponível');
    return autentica;
  }
}

/// Adapter que registra as requisições e responde com um JSON fixo.
class _RegistraAdapter implements HttpClientAdapter {
  _RegistraAdapter({this.corpo = '{"ok": true}'});

  final String corpo;
  final List<String> caminhos = [];
  final List<dynamic> corpos = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    caminhos.add(options.path);
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

/// 401 na primeira chamada, 200 na retentativa — registra os headers.
class _Admin401Depois200Adapter implements HttpClientAdapter {
  int chamadas = 0;
  final List<dynamic> headers = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    chamadas++;
    headers.add(options.headers['Authorization']);
    if (chamadas == 1) {
      return ResponseBody.fromString(
        '{"mensagem": "Sessão expirada"}',
        401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      '{"ok": true}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

/// Router mínimo com as rotas de auth admin e destinos simulados.
GoRouter _routerAuth(AdminAuthProvider provider) => GoRouter(
      initialLocation: '/admin/auth/login',
      routes: [
        GoRoute(
          path: '/admin/auth/login',
          builder: (context, state) => const AdminLoginScreen(),
        ),
        GoRoute(
          path: '/admin/auth/recover',
          builder: (context, state) => const AdminRecoverScreen(),
        ),
        GoRoute(
          path: '/admin/dashboard',
          builder: (context, state) =>
              const Scaffold(body: Text('dashboard-ok')),
        ),
        GoRoute(
          path: '/admin/auth/setup-2fa',
          builder: (context, state) =>
              const Scaffold(body: Text('setup-ok')),
        ),
      ],
    );

Future<void> _pumpAuth(
  WidgetTester tester,
  AdminAuthProvider provider,
) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AdminAuthProvider>.value(value: provider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MaterialApp.router(routerConfig: _routerAuth(provider)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AdminAuthProvider — login 2FA-first', () {
    late _RepoFake repo;
    late AdminAuthProvider provider;

    setUp(() {
      repo = _RepoFake();
      provider = AdminAuthProvider(repo, DioClient());
    });

    test('login sem senha vai direto para o passo 2FA', () async {
      final ok = await provider.login('root');

      expect(ok, isTrue);
      expect(repo.loginUsername, 'root');
      expect(repo.loginSenha, isNull, reason: 'senha omitida (2FA-first)');
      expect(provider.requiresTwoFactor, isTrue);
      expect(provider.tempToken, 'temp-1');
      expect(provider.isAuthenticated, isFalse);
    });

    test('login com senha emite a sessão e captura a senha', () async {
      repo.sessaoNoLogin = true;

      final ok = await provider.login('root', senha: 'senha-forte-1');

      expect(ok, isTrue);
      expect(repo.loginSenha, 'senha-forte-1');
      expect(provider.isAuthenticated, isTrue);
      expect(provider.sessaoDesbloqueada, isTrue,
          reason: 'login explícito nasce desbloqueado');
      expect(provider.currentAdmin?.username, 'root');
    });

    test('sem senha em conta sem 2FA expõe "Senha é obrigatória"', () async {
      repo.twoFactorNoLogin = false;

      final ok = await provider.login('root');

      expect(ok, isFalse);
      expect(provider.errorMessage, contains('Senha é obrigatória'));
      expect(provider.isAuthenticated, isFalse);
    });

    test('verifyTwoFactor troca o tempToken pela sessão', () async {
      await provider.login('root');

      final ok = await provider.verifyTwoFactor('123456');

      expect(ok, isTrue);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.requiresTwoFactor, isFalse);
      expect(provider.tempToken, isNull);
    });
  });

  group('AdminAuthProvider — OTP por e-mail (R3)', () {
    late _RepoFake repo;
    late AdminAuthProvider provider;

    setUp(() async {
      repo = _RepoFake();
      provider = AdminAuthProvider(repo, DioClient());
      await provider.login('root');
    });

    test('enviarCodigoEmail usa o tempToken do passo 2FA', () async {
      final ok = await provider.enviarCodigoEmail();

      expect(ok, isTrue);
      expect(repo.enviarTemp, 'temp-1');
      expect(provider.errorMessage, isNull);
    });

    test('enviarCodigoEmail sem tempToken falha com mensagem', () async {
      final fresco = AdminAuthProvider(_RepoFake(), DioClient());

      final ok = await fresco.enviarCodigoEmail();

      expect(ok, isFalse);
      expect(fresco.errorMessage, contains('Sessão 2FA expirada'));
    });

    test('verifyEmailCode emite a sessão com o código de 8 dígitos', () async {
      final ok = await provider.verifyEmailCode('12345678');

      expect(ok, isTrue);
      expect(repo.emailTemp, 'temp-1');
      expect(repo.emailCodigo, '12345678');
      expect(provider.isAuthenticated, isTrue);
      expect(provider.sessaoDesbloqueada, isTrue);
    });

    test('verifyEmailCode com código errado expõe o erro', () async {
      repo.sessaoNoEmail = false;

      final ok = await provider.verifyEmailCode('00000000');

      expect(ok, isFalse);
      expect(provider.errorMessage, contains('Código inválido'));
      expect(provider.isAuthenticated, isFalse);
    });
  });

  group('AdminAuthProvider — recuperação sem senha (R1)', () {
    late _RepoFake repo;
    late AdminAuthProvider provider;

    setUp(() {
      repo = _RepoFake();
      provider = AdminAuthProvider(repo, DioClient());
    });

    test('recuperar envia senha null e novaSenha opcional', () async {
      final ok = await provider.recuperar(
        username: 'root',
        senha: null,
        recoveryCode: 'ABCDE-FGHIJ',
        novaSenha: 'senha-nova-123',
      );

      expect(ok, isTrue);
      expect(repo.recoverSenha, isNull, reason: 'recovery code já autentica');
      expect(repo.recoverCode, 'ABCDE-FGHIJ');
      expect(repo.recoverNovaSenha, 'senha-nova-123');
      expect(provider.isAuthenticated, isTrue);
      expect(provider.recoveryCodes, hasLength(2));
    });

    test('recuperar sem novaSenha mantém a senha atual', () async {
      final ok = await provider.recuperar(
        username: 'root',
        recoveryCode: 'ABCDE-FGHIJ',
      );

      expect(ok, isTrue);
      expect(repo.recoverNovaSenha, isNull);
      expect(provider.isAuthenticated, isTrue);
    });
  });

  group('AdminAuthProvider — refresh da sessão admin', () {
    late _RepoFake repo;
    late AdminAuthProvider provider;

    setUp(() async {
      repo = _RepoFake()..sessaoNoLogin = true;
      provider = AdminAuthProvider(repo, DioClient());
      await provider.login('root', senha: 'senha-forte-1');
    });

    test('renovarSessao rota os tokens pelo /admin/auth/refresh', () async {
      repo.refreshResposta = {
        'accessToken': 'access-2',
        'refreshToken': 'refresh-2',
      };

      final ok = await provider.renovarSessao();

      expect(ok, isTrue);
      expect(repo.refreshChamado, 'refresh-1');
      expect(provider.accessToken, 'access-2');
      expect(provider.refreshToken, 'refresh-2');
    });

    test('renovarSessao devolve false quando o refresh é rejeitado', () async {
      repo.refreshResposta = null;

      final ok = await provider.renovarSessao();

      expect(ok, isFalse);
      expect(provider.accessToken, 'access-1',
          reason: 'sessão em memória segue até o próximo 401 decidir');
    });
  });

  group('AdminAuthProvider — sessão persistida e gate biométrico', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStoragePlatform.instance =
          TestFlutterSecureStoragePlatform(<String, String>{
        AdminAuthProvider.keyAdminAccessToken: 'tok-restaurado',
        AdminAuthProvider.keyAdminRefreshToken: 'ref-restaurado',
        AdminAuthProvider.keyAdminSessao: jsonEncode({
          'id': '1',
          'username': 'root',
          'nomeCompleto': 'Root',
          'email': 'root@chronos.app',
          'criadoEm': '2026-01-01T00:00:00Z',
        }),
      });
    });

    test('restaurarSessao devolve a sessão TRANCADA até a biometria', () async {
      final provider = AdminAuthProvider(_RepoFake(), DioClient());

      expect(provider.isAuthenticated, isFalse);
      expect(provider.sessaoDesbloqueada, isTrue,
          reason: 'provedor novo nasce liberado');

      await provider.restaurarSessao();

      expect(provider.isAuthenticated, isTrue);
      expect(provider.accessToken, 'tok-restaurado');
      expect(provider.currentAdmin?.username, 'root');
      expect(provider.sessaoDesbloqueada, isFalse,
          reason: 'sessão restaurada exige o gate biométrico');

      provider.confirmarBiometria();
      expect(provider.sessaoDesbloqueada, isTrue);

      await provider.logout();
      expect(provider.isAuthenticated, isFalse);
      expect(
        await SessionStorage.readToken(AdminAuthProvider.keyAdminAccessToken),
        isNull,
        reason: 'logout apaga a sessão local',
      );
      expect(
        await SessionStorage.readToken(AdminAuthProvider.keyAdminSessao),
        isNull,
      );

      provider.dispose();
    });

    test('restaurarSessao sem chaves locais mantém deslogado', () async {
      FlutterSecureStoragePlatform.instance =
          TestFlutterSecureStoragePlatform(const <String, String>{});
      final provider = AdminAuthProvider(_RepoFake(), DioClient());

      await provider.restaurarSessao();

      expect(provider.isAuthenticated, isFalse);
      expect(provider.sessaoDesbloqueada, isTrue);

      provider.dispose();
    });
  });

  group('AdminAuthRemoteDataSource — novos endpoints', () {
    late DioClient dioClient;
    late _RegistraAdapter adapter;
    late AdminAuthRemoteDataSource datasource;

    setUp(() {
      dioClient = DioClient();
      adapter = _RegistraAdapter(
        corpo: jsonEncode({
          'accessToken': 'access-x',
          'refreshToken': 'refresh-x',
        }),
      );
      dioClient.dio.httpClientAdapter = adapter;
      datasource = AdminAuthRemoteDataSource(dioClient);
    });

    test('login omite a senha quando não informada', () async {
      final resultado = await datasource.login('root');

      expect(resultado['accessToken'], 'access-x');
      expect(adapter.caminhos.single, endsWith('/admin/auth/login'));
      final corpo = adapter.corpos.single as Map<String, dynamic>;
      expect(corpo.keys, isNot(contains('senha')));
      expect(corpo['username'], 'root');
    });

    test('login inclui a senha quando informada', () async {
      await datasource.login('root', senha: 'senha-forte-1');

      final corpo = adapter.corpos.single as Map<String, dynamic>;
      expect(corpo['senha'], 'senha-forte-1');
    });

    test('refresh chama POST /admin/auth/refresh com o refreshToken',
        () async {
      final resultado = await datasource.refresh('refresh-1');

      expect(resultado['accessToken'], 'access-x');
      expect(adapter.caminhos.single, endsWith('/admin/auth/refresh'));
      final corpo = adapter.corpos.single as Map<String, dynamic>;
      expect(corpo['refreshToken'], 'refresh-1');
    });

    test('sendEmailCode envia o tempToken para /2fa/email/send', () async {
      await datasource.sendEmailCode('temp-1');

      expect(adapter.caminhos.single, endsWith('/admin/auth/2fa/email/send'));
      final corpo = adapter.corpos.single as Map<String, dynamic>;
      expect(corpo['tempToken'], 'temp-1');
    });

    test('verifyEmailCode devolve a sessão do /2fa/email/verify', () async {
      final resultado = await datasource.verifyEmailCode('temp-1', '12345678');

      expect(resultado['accessToken'], 'access-x');
      expect(adapter.caminhos.single, endsWith('/admin/auth/2fa/email/verify'));
      final corpo = adapter.corpos.single as Map<String, dynamic>;
      expect(corpo['codigo'], '12345678');
    });
  });

  group('AdminLoginScreen — 2FA-first', () {
    late _RepoFake repo;
    late AdminAuthProvider provider;

    setUp(() {
      repo = _RepoFake();
      provider = AdminAuthProvider(repo, DioClient());
    });

    testWidgets('passo 1 começa sem senha; "Usar senha" revela o campo',
        (tester) async {
      await _pumpAuth(tester, provider);

      expect(find.byType(TextFormField), findsOneWidget,
          reason: 'só o usuário no modo 2FA-first');
      expect(find.text('Usar senha'), findsOneWidget);

      await tester.tap(find.text('Usar senha'));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Usar senha'), findsNothing);
    });

    testWidgets('envia o login sem senha e avança para o código 2FA',
        (tester) async {
      await _pumpAuth(tester, provider);
      await tester.enterText(find.byType(TextFormField).first, 'root');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
      await tester.pumpAndSettle();

      expect(repo.loginSenha, isNull, reason: '2FA-first omite a senha');
      expect(find.text('Verificação em duas etapas'), findsOneWidget);
      expect(find.text('Receber código por e-mail'), findsOneWidget);
      expect(find.text('Usar senha'), findsOneWidget);
      expect(find.text('Usar outra conta'), findsOneWidget);
    });

    testWidgets('sem senha em conta sem 2FA revela o campo e avisa',
        (tester) async {
      repo.twoFactorNoLogin = false;
      await _pumpAuth(tester, provider);
      await tester.enterText(find.byType(TextFormField).first, 'root');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(2),
          reason: 'campo de senha revelado');
      expect(find.text('Informe a senha para continuar.'), findsOneWidget);
      expect(find.text('Verificação em duas etapas'), findsNothing);
    });

    testWidgets('"Receber código por e-mail" troca para OTP de 8 dígitos',
        (tester) async {
      await _pumpAuth(tester, provider);
      await tester.enterText(find.byType(TextFormField).first, 'root');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Receber código por e-mail'));
      await tester.pumpAndSettle();

      expect(repo.enviarTemp, 'temp-1');
      expect(find.text('Código enviado para o e-mail cadastrado.'),
          findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'Código enviado por e-mail (8 dígitos)'),
        findsOneWidget,
      );
      expect(find.text('Usar Google Authenticator'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '12345678');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Verificar código'));
      await tester.pumpAndSettle();

      expect(repo.emailCodigo, '12345678');
      expect(find.text('dashboard-ok'), findsOneWidget,
          reason: 'sessão emitida navega para o dashboard');
    });

    testWidgets('"Usar senha" no passo 2 volta ao passo 1 com o campo visível',
        (tester) async {
      await _pumpAuth(tester, provider);
      await tester.enterText(find.byType(TextFormField).first, 'root');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Usar senha'));
      await tester.pumpAndSettle();

      expect(find.text('Verificação em duas etapas'), findsNothing);
      expect(find.byType(TextFormField), findsNWidgets(2),
          reason: 'usuário + senha visível');
    });

    testWidgets('"Usar Google Authenticator" volta ao TOTP de 6 dígitos',
        (tester) async {
      await _pumpAuth(tester, provider);
      await tester.enterText(find.byType(TextFormField).first, 'root');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Receber código por e-mail'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Usar Google Authenticator'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(TextFormField, 'Código (6 dígitos)'),
        findsOneWidget,
      );
      expect(find.text('Receber código por e-mail'), findsOneWidget);
    });
  });

  group('AdminRecoverScreen — recuperação sem senha (R1)', () {
    late _RepoFake repo;
    late AdminAuthProvider provider;

    setUp(() {
      repo = _RepoFake();
      provider = AdminAuthProvider(repo, DioClient());
    });

    Future<GoRouter> pumpRecover(WidgetTester tester) async {
      final router = _routerAuth(provider);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AdminAuthProvider>.value(value: provider),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      router.go('/admin/auth/recover');
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('não tem campo de senha; nova senha é opcional',
        (tester) async {
      await pumpRecover(tester);

      expect(find.text('Entrar com código de recuperação'), findsOneWidget);
      expect(find.text('Nova senha (opcional)'), findsOneWidget);
      expect(find.text('Deixe em branco para manter a senha atual.'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Senha'), findsNothing,
          reason: 'o código de recuperação já autentica (R1)');
    });

    testWidgets('envia novaSenha e navega para o dashboard', (tester) async {
      await pumpRecover(tester);

      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'root');
      await tester.enterText(campos.at(1), 'ABCDE-FGHIJ');
      await tester.enterText(campos.at(2), 'senha-nova-123');

      await tester.ensureVisible(
          find.widgetWithText(ElevatedButton, 'Recuperar acesso'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Recuperar acesso'));
      await tester.pumpAndSettle();

      expect(repo.recoverSenha, isNull);
      expect(repo.recoverNovaSenha, 'senha-nova-123');

      // Sucesso mostra os novos códigos de recuperação antes do painel.
      expect(find.text('Novos códigos de recuperação'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Já salvei'));
      await tester.pumpAndSettle();

      expect(find.text('dashboard-ok'), findsOneWidget);
    });

    testWidgets('nova senha em branco vai como null (mantém a atual)',
        (tester) async {
      await pumpRecover(tester);

      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'root');
      await tester.enterText(campos.at(1), 'ABCDE-FGHIJ');

      await tester.ensureVisible(
          find.widgetWithText(ElevatedButton, 'Recuperar acesso'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Recuperar acesso'));
      await tester.pumpAndSettle();

      expect(repo.recoverNovaSenha, isNull);
      expect(find.text('Novos códigos de recuperação'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Já salvei'));
      await tester.pumpAndSettle();

      expect(find.text('dashboard-ok'), findsOneWidget);
    });

    testWidgets('nova senha curta bloqueia o envio', (tester) async {
      await pumpRecover(tester);

      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'root');
      await tester.enterText(campos.at(1), 'ABCDE-FGHIJ');
      await tester.enterText(campos.at(2), '123456');

      await tester.ensureVisible(
          find.widgetWithText(ElevatedButton, 'Recuperar acesso'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Recuperar acesso'));
      await tester.pumpAndSettle();

      expect(
        find.text('A nova senha deve ter no mínimo 8 caracteres'),
        findsOneWidget,
      );
      expect(repo.recoverNovaSenha, isNull);
      expect(find.text('dashboard-ok'), findsNothing);
    });
  });

  group('AdminBiometricGateScreen', () {
    Future<void> pumpGate(
      WidgetTester tester,
      _AdminFake admin,
      HardwareService hw,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AdminAuthProvider>.value(
          value: admin,
          child: MaterialApp(
            home: AdminBiometricGateScreen(hardwareService: hw),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('sem biometria disponível libera a sessão sozinho',
        (tester) async {
      final admin = _AdminFake();

      await pumpGate(tester, admin, _HardwareFake(disponivel: false));

      expect(admin.bloqueada, isFalse);
    });

    testWidgets('hardware com biometria: cancelar não libera', (tester) async {
      final admin = _AdminFake();
      final hw = _HardwareFake(disponivel: true, autentica: false);

      await pumpGate(tester, admin, hw);

      expect(hw.chamadas, equals(1));
      expect(admin.bloqueada, isTrue);
      expect(find.textContaining('cancelada'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
      expect(find.text('Sair'), findsOneWidget);

      hw.autentica = true;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();
      await tester.pump();

      expect(hw.chamadas, equals(2));
      expect(admin.bloqueada, isFalse);
    });

    testWidgets('"Sair" encerra a sessão admin', (tester) async {
      final admin = _AdminFake();
      final hw = _HardwareFake(disponivel: true)..lancarErro = true;

      await pumpGate(tester, admin, hw);

      expect(find.text('Sair'), findsOneWidget);
      await tester.tap(find.text('Sair'));
      await tester.pump();

      expect(admin.saiu, isTrue);
    });
  });

  group('AppRouter — gate admin (modo admin)', () {
    late DioClient dioClient;
    late AuthProvider auth;
    late _AdminFake adminAuth;

    setUp(() {
      dioClient = DioClient();
      auth = AuthProvider(
        AuthRepository(
          remoteDataSource: AuthRemoteDataSource(dioClient),
          dioClient: dioClient,
        ),
      );
      adminAuth = _AdminFake();
    });

    /// Árvore com os providers do app admin. O literal fica INLINE no
    /// MultiProvider para a inferência de tipos do provider não degradar
    /// os `create:` para `dynamic` (que sumaria o Provider do dashboard).
    Widget arvore(GoRouter router) => MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<AdminAuthProvider>.value(value: adminAuth),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            // O dashboard (rota inicial de sessão ativa) lê o AdminProvider.
            ChangeNotifierProvider(
              create: (_) => AdminProvider(
                AdminRepository(
                  remoteDataSource: AdminRemoteDataSource(dioClient),
                ),
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        );

    Future<void> pumpApp(WidgetTester tester, {required String rota}) async {
      final router = AppRouter.build(auth, adminAuth, modo: AppModo.admin);
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(arvore(router));
      router.go(rota);
      // Sem pumpAndSettle: o gate usa spinner indeterminado enquanto a
      // sessão está bloqueada (mesmo padrão do gate de tenant).
      await tester.pump();
      await tester.pump();
    }

    testWidgets(
        'sessão admin bloqueada: /admin/dashboard impõe o gate antes do conteúdo',
        (tester) async {
      await pumpApp(tester, rota: '/admin/dashboard');

      expect(find.byType(AdminBiometricGateScreen), findsOneWidget);
      expect(find.text('Login Administrator'), findsNothing);
    });

    testWidgets('sessão admin desbloqueada abre o conteúdo direto',
        (tester) async {
      adminAuth.bloqueada = false;
      final router = AppRouter.build(auth, adminAuth, modo: AppModo.admin);
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(arvore(router));
      router.go('/admin/seguranca');
      await tester.pumpAndSettle();

      expect(find.byType(AdminBiometricGateScreen), findsNothing);
      expect(find.byType(AdminSegurancaScreen), findsOneWidget);

      // Drena o timeout do carregamento do dashboard (HTTP de largada no
      // primeiro frame) para não deixar timer pendurado no fim do teste.
      await tester.pump(const Duration(seconds: 15));
      await tester.pumpAndSettle();
    });

    testWidgets('login da plataforma segue acessível com sessão trancada',
        (tester) async {
      await pumpApp(tester, rota: '/admin/auth/login');

      expect(find.byType(AdminBiometricGateScreen), findsNothing);
      expect(find.text('Login Administrator'), findsOneWidget);
    });

    testWidgets('modo cliente: /admin/biometria é bloqueado', (tester) async {
      final router = AppRouter.build(auth, adminAuth, modo: AppModo.cliente);
      await tester.pumpWidget(arvore(router));
      await tester.pumpAndSettle();
      router.go('/admin/biometria');
      await tester.pumpAndSettle();

      expect(find.byType(AdminBiometricGateScreen), findsNothing);
      expect(find.text('Login Administrator'), findsNothing);
    });
  });

  group('DioClient — refresh da sessão admin em 401', () {
    test('401 em rota /admin/** usa onAdminRefreshToken e retenta',
        () async {
      final dioClient = DioClient();
      final adapter = _Admin401Depois200Adapter();
      dioClient.dio.httpClientAdapter = adapter;
      dioClient.updateAdminToken('admin-antigo');

      var renovacoes = 0;
      dioClient.onAdminRefreshToken = () async {
        renovacoes++;
        dioClient.updateAdminToken('admin-novo');
        return true;
      };

      final resposta = await dioClient.dio.get('/admin/api/teste');

      expect(resposta.statusCode, 200);
      expect(renovacoes, 1, reason: 'um único refresh para o 401');
      expect(adapter.chamadas, 2);
      expect(adapter.headers.first, 'Bearer admin-antigo');
      expect(adapter.headers.last, 'Bearer admin-novo',
          reason: 'retry sai com o token renovado');
    });

    test('401 sem sucesso de refresh propaga o erro com a mensagem real',
        () async {
      final dioClient = DioClient();
      final adapter = _Admin401Depois200Adapter();
      dioClient.dio.httpClientAdapter = adapter;
      dioClient.updateAdminToken('admin-antigo');
      dioClient.onAdminRefreshToken = () async => false;

      await expectLater(
        dioClient.dio.get('/admin/api/teste'),
        throwsA(isA<DioException>().having(
          (e) => e.message,
          'message',
          contains('Sessão expirada'),
        )),
      );
      expect(adapter.chamadas, 1, reason: 'sem refresh não há retentativa');
    });

    test('o próprio /admin/auth/refresh nunca dispara refresh recursivo',
        () async {
      final dioClient = DioClient();
      final adapter = _Admin401Depois200Adapter();
      dioClient.dio.httpClientAdapter = adapter;
      dioClient.updateAdminToken('admin-antigo');
      var renovacoes = 0;
      dioClient.onAdminRefreshToken = () async {
        renovacoes++;
        return true;
      };

      await expectLater(
        dioClient.dio.post('/admin/auth/refresh', data: {'refreshToken': 'x'}),
        throwsA(isA<DioException>()),
      );
      expect(renovacoes, 0);
      expect(adapter.chamadas, 1);
    });
  });
}

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/core/theme/theme_provider.dart';
import 'package:chronos_pulse_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:chronos_pulse_app/features/auth/data/models/usuario_model.dart';
import 'package:chronos_pulse_app/features/auth/data/repositories/auth_repository.dart';
import 'package:chronos_pulse_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:chronos_pulse_app/features/auth/presentation/screens/perfil_two_factor_screen.dart';
import 'package:chronos_pulse_app/features/auth/presentation/screens/two_factor_login_screen.dart';

/// AuthRepository com o fluxo 2FA do colaborador interceptado.
class _RepoFake extends AuthRepository {
  _RepoFake()
      : super(
          remoteDataSource: AuthRemoteDataSource(DioClient()),
          dioClient: DioClient(),
        );

  bool requerTwoFactor = true;
  bool falharVerify = false;
  String? ultimoTempToken;
  bool? verifyPorEmail;
  int emailSendChamadas = 0;
  bool statusEnabled = false;
  bool confirmarOk = true;
  bool desabilitarOk = true;
  String? codigoRecebido;

  @override
  Future<UsuarioModel> login({
    required String cpf,
    required String senha,
  }) async {
    if (requerTwoFactor) {
      return UsuarioModel(
        token: '',
        tipo: 'Bearer',
        nome: 'Colaborador',
        email: 'colab@empresa.com',
        cpf: cpf,
        role: 'COLABORADOR',
        requiresTwoFactor: true,
        tempToken: 'temp-1',
      );
    }
    return _sessao();
  }

  @override
  Future<UsuarioModel> twoFactorVerify({
    required String tempToken,
    required String codigo,
    bool porEmail = false,
  }) async {
    ultimoTempToken = tempToken;
    verifyPorEmail = porEmail;
    if (falharVerify) throw Exception('Código inválido.');
    return _sessao();
  }

  @override
  Future<void> twoFactorEmailSend({required String tempToken}) async {
    ultimoTempToken = tempToken;
    emailSendChamadas++;
  }

  @override
  Future<bool> twoFactorStatus() async => statusEnabled;

  @override
  Future<Map<String, String>> twoFactorSetup() async => {
        'secret': 'SEGREDO123',
        'otpauthUri': 'otpauth://totp/ChronosPulse:12345678901',
      };

  @override
  Future<void> twoFactorConfirm({required String codigo}) async {
    codigoRecebido = codigo;
    if (!confirmarOk) throw Exception('Código inválido.');
    statusEnabled = true;
  }

  @override
  Future<void> twoFactorDisable({required String codigo}) async {
    codigoRecebido = codigo;
    if (!desabilitarOk) throw Exception('Código inválido.');
    statusEnabled = false;
  }

  UsuarioModel _sessao() => UsuarioModel(
        token: 'access-1',
        refreshToken: 'refresh-1',
        tipo: 'Bearer',
        nome: 'Colaborador',
        email: 'colab@empresa.com',
        cpf: '12345678901',
        role: 'COLABORADOR',
      );
}

/// Adapter que registra os caminhos/corpos e devolve 200 com um corpo fixo.
class _RegistraAdapter implements HttpClientAdapter {
  _RegistraAdapter({this.corpo = '{"ok": true}'});

  final String corpo;
  final List<String> caminhos = [];
  final List<String> metodos = [];
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

  // O canal do flutter_secure_storage não existe no ambiente de teste:
  // mockamos para que _saveSession (Keystore/Keychain) não trave o login.
  const secureStorage =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(secureStorage, (call) async {
    switch (call.method) {
      case 'readAll':
        return <String, String>{};
      case 'read':
        return null;
      default:
        return null;
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthProvider — 2FA-first do colaborador', () {
    late _RepoFake repo;
    late AuthProvider auth;

    setUp(() {
      repo = _RepoFake();
      auth = AuthProvider(repo);
    });

    test('login com 2FA expõe o tempToken e não autentica', () async {
      final ok = await auth.login('12345678901', 'senha123');

      expect(ok, isTrue);
      expect(auth.requiresTwoFactor, isTrue);
      expect(auth.tempToken, 'temp-1');
      expect(auth.isAuthenticated, isFalse,
          reason: 'sem tokens finais não há sessão');
      expect(auth.usuario, isNull);
    });

    test('login sem 2FA autentica direto', () async {
      repo.requerTwoFactor = false;

      final ok = await auth.login('12345678901', 'senha123');

      expect(ok, isTrue,
          reason: 'erro: ${auth.errorMessage}');
      expect(auth.isAuthenticated, isTrue);
      expect(auth.requiresTwoFactor, isFalse);
    });

    test('verificarTwoFactor troca o tempToken pela sessão', () async {
      await auth.login('12345678901', 'senha123');

      final ok = await auth.verificarTwoFactor('123456');

      expect(ok, isTrue);
      expect(repo.ultimoTempToken, 'temp-1');
      expect(repo.verifyPorEmail, isFalse);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.requiresTwoFactor, isFalse);
      expect(auth.tempToken, isNull);
    });

    test('verificarCodigoEmailTwoFactor usa o canal de e-mail', () async {
      await auth.login('12345678901', 'senha123');

      final ok = await auth.verificarCodigoEmailTwoFactor('12345678');

      expect(ok, isTrue);
      expect(repo.verifyPorEmail, isTrue);
      expect(auth.isAuthenticated, isTrue);
    });

    test('código errado mantém a etapa pendente com a mensagem', () async {
      await auth.login('12345678901', 'senha123');
      repo.falharVerify = true;

      final ok = await auth.verificarTwoFactor('000000');

      expect(ok, isFalse);
      expect(auth.errorMessage, 'Código inválido.');
      expect(auth.requiresTwoFactor, isTrue,
          reason: 'usuário pode tentar de novo');
      expect(auth.isAuthenticated, isFalse);
    });

    test('enviarCodigoEmailTwoFactor repassa o tempToken', () async {
      await auth.login('12345678901', 'senha123');

      final erro = await auth.enviarCodigoEmailTwoFactor();

      expect(erro, isNull);
      expect(repo.emailSendChamadas, 1);
      expect(repo.ultimoTempToken, 'temp-1');
    });

    test('sem tempToken pendente o envio devolve erro de sessão', () async {
      final erro = await auth.enviarCodigoEmailTwoFactor();

      expect(erro, 'Sessão expirada. Refaça o login.');
      expect(repo.emailSendChamadas, 0);
    });

    test('cancelarTwoFactor limpa a etapa pendente', () async {
      await auth.login('12345678901', 'senha123');

      auth.cancelarTwoFactor();

      expect(auth.requiresTwoFactor, isFalse);
      expect(auth.tempToken, isNull);
    });

    test('verificarTwoFactor sem tempToken devolve erro de sessão', () async {
      final ok = await auth.verificarTwoFactor('123456');

      expect(ok, isFalse);
      expect(auth.errorMessage, 'Sessão expirada. Refaça o login.');
    });
  });

  group('TwoFactorLoginScreen', () {
    late _RepoFake repo;
    late AuthProvider auth;

    setUp(() async {
      repo = _RepoFake();
      auth = AuthProvider(repo);
      await auth.login('12345678901', 'senha123');
    });

    Future<void> pumpTela(WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/login/2fa',
        routes: [
          GoRoute(
            path: '/login/2fa',
            builder: (context, state) => const TwoFactorLoginScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const Scaffold(body: Text('login-ok')),
          ),
          GoRoute(
            path: '/painel/home',
            builder: (context, state) => const Scaffold(body: Text('home-ok')),
          ),
        ],
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<ThemeProvider>(
              create: (_) => ThemeProvider(),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('valida 6 dígitos antes de verificar', (tester) async {
      await pumpTela(tester);

      expect(find.text('Verificação em duas etapas'), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('two_factor_codigo_field')), '12345');
      await tester.tap(find.byKey(const Key('two_factor_verificar_button')));
      await tester.pumpAndSettle();

      expect(find.text('O código deve conter 6 dígitos'), findsOneWidget);
      expect(auth.isAuthenticated, isFalse);
    });

    testWidgets('código TOTP válido conclui o login', (tester) async {
      await pumpTela(tester);

      await tester.enterText(
          find.byKey(const Key('two_factor_codigo_field')), '123456');
      await tester.tap(find.byKey(const Key('two_factor_verificar_button')));
      // sem pumpAndSettle: o login agenda o timer de inatividade (15 min)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(auth.isAuthenticated, isTrue);
      expect(repo.verifyPorEmail, isFalse);
      expect(find.text('O código deve conter 6 dígitos'), findsNothing);

      await auth.logout();
      await tester.pumpAndSettle();
    });

    testWidgets('código inválido mostra o erro do servidor', (tester) async {
      repo.falharVerify = true;
      await pumpTela(tester);

      await tester.enterText(
          find.byKey(const Key('two_factor_codigo_field')), '123456');
      await tester.tap(find.byKey(const Key('two_factor_verificar_button')));
      await tester.pumpAndSettle();

      expect(find.text('Código inválido.'), findsOneWidget);
      expect(auth.isAuthenticated, isFalse);

      // expira o snackbar para não enfileirar nos próximos pumps
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('receber código por e-mail troca a validação para 8 dígitos',
        (tester) async {
      await pumpTela(tester);

      await tester.tap(find.byKey(const Key('two_factor_por_email_button')));
      await tester.pumpAndSettle();

      expect(repo.emailSendChamadas, 1);
      expect(find.text('Código enviado para o seu e-mail.'), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('two_factor_codigo_field')), '123456');
      await tester.tap(find.byKey(const Key('two_factor_verificar_button')));
      await tester.pumpAndSettle();

      expect(find.text('O código deve conter 8 dígitos'), findsOneWidget);
      expect(auth.isAuthenticated, isFalse);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // código de 8 dígitos no canal de e-mail conclui o login
      await tester.enterText(
          find.byKey(const Key('two_factor_codigo_field')), '12345678');
      await tester.tap(find.byKey(const Key('two_factor_verificar_button')));
      // sem pumpAndSettle: o login agenda o timer de inatividade (15 min)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(auth.isAuthenticated, isTrue);
      expect(repo.verifyPorEmail, isTrue);

      await auth.logout();
      await tester.pumpAndSettle();
    });
  });

  group('PerfilTwoFactorScreen', () {
    late _RepoFake repo;
    late AuthProvider auth;

    setUp(() {
      repo = _RepoFake();
      auth = AuthProvider(repo);
    });

    Future<void> pumpTela(WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/perfil/2fa',
        routes: [
          GoRoute(
            path: '/perfil/2fa',
            builder: (context, state) => const PerfilTwoFactorScreen(),
          ),
          GoRoute(
            path: '/perfil',
            builder: (context, state) => const Scaffold(body: Text('perfil-ok')),
          ),
        ],
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('status desligado oferece a ativação via QR', (tester) async {
      await pumpTela(tester);

      expect(find.byKey(const Key('perfil_2fa_ativar_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('perfil_2fa_ativar_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('qr-perfil-2fa')), findsOneWidget);
      expect(find.byKey(const Key('perfil_2fa_confirmar_button')), findsOneWidget);
      expect(find.text('Chave manual'), findsNothing,
          reason: 'chave manual fica oculta por padrão');
    });

    testWidgets('confirmar o código ativa o 2FA', (tester) async {
      await pumpTela(tester);
      await tester.tap(find.byKey(const Key('perfil_2fa_ativar_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('perfil_2fa_codigo_field')), '123456');
      final confirmar =
          find.byKey(const Key('perfil_2fa_confirmar_button'));
      await tester.ensureVisible(confirmar);
      await tester.pumpAndSettle();
      await tester.tap(confirmar);
      await tester.pumpAndSettle();

      expect(repo.statusEnabled, isTrue);
      expect(repo.codigoRecebido, '123456');
      expect(find.text('Ativada neste dispositivo'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('status ligado oferece a desativação com código',
        (tester) async {
      repo.statusEnabled = true;

      await pumpTela(tester);

      expect(find.text('Ativada neste dispositivo'), findsOneWidget);
      expect(find.byKey(const Key('perfil_2fa_desativar_button')),
          findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('perfil_2fa_codigo_field')), '123456');
      final desativar =
          find.byKey(const Key('perfil_2fa_desativar_button'));
      await tester.ensureVisible(desativar);
      await tester.pumpAndSettle();
      await tester.tap(desativar);
      await tester.pumpAndSettle();

      expect(repo.statusEnabled, isFalse);
      expect(find.byKey(const Key('perfil_2fa_ativar_button')), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('código inválido na desativação mostra o erro',
        (tester) async {
      repo.statusEnabled = true;
      repo.desabilitarOk = false;

      await pumpTela(tester);

      await tester.enterText(
          find.byKey(const Key('perfil_2fa_codigo_field')), '111111');
      final desativar =
          find.byKey(const Key('perfil_2fa_desativar_button'));
      await tester.ensureVisible(desativar);
      await tester.pumpAndSettle();
      await tester.tap(desativar);
      await tester.pumpAndSettle();

      expect(find.text('Código inválido.'), findsOneWidget);
      expect(repo.statusEnabled, isTrue,
          reason: 'não pode desativar sem código válido');

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });

  group('AuthRemoteDataSource — endpoints do 2FA do colaborador', () {
    late DioClient dioClient;
    late _RegistraAdapter adapter;
    late AuthRemoteDataSource datasource;

    setUp(() {
      dioClient = DioClient();
      adapter = _RegistraAdapter(
        corpo: jsonEncode({
          'accessToken': 'access-x',
          'refreshToken': 'refresh-x',
          'requiresTwoFactor': false,
        }),
      );
      dioClient.dio.httpClientAdapter = adapter;
      datasource = AuthRemoteDataSource(dioClient);
    });

    test('twoFactorVerify faz POST /auth/2fa/verify com tempToken e código',
        () async {
      final resultado = await datasource.twoFactorVerify(
        tempToken: 'temp-1',
        codigo: ' 123456 ',
      );

      expect(resultado.token, 'access-x');
      expect(adapter.caminhos.single, endsWith('/auth/2fa/verify'));
      expect(adapter.metodos.single, 'POST');
      final corpo = adapter.corpos.single as Map<String, dynamic>;
      expect(corpo['tempToken'], 'temp-1');
      expect(corpo['codigo'], '123456');
    });

    test('twoFactorEmailSend faz POST /auth/2fa/email/send', () async {
      await datasource.twoFactorEmailSend(tempToken: 'temp-1');

      expect(adapter.caminhos.single, endsWith('/auth/2fa/email/send'));
      final corpo = adapter.corpos.single as Map<String, dynamic>;
      expect(corpo['tempToken'], 'temp-1');
    });

    test('twoFactorEmailVerify faz POST /auth/2fa/email/verify', () async {
      final resultado = await datasource.twoFactorEmailVerify(
        tempToken: 'temp-1',
        codigo: '12345678',
      );

      expect(resultado.token, 'access-x');
      expect(adapter.caminhos.single, endsWith('/auth/2fa/email/verify'));
      final corpo = adapter.corpos.single as Map<String, dynamic>;
      expect(corpo['codigo'], '12345678');
    });

    test('twoFactorStatus faz GET /auth/2fa/status', () async {
      adapter = _RegistraAdapter(corpo: '{"enabled": true}');
      dioClient.dio.httpClientAdapter = adapter;

      final enabled = await datasource.twoFactorStatus();

      expect(enabled, isTrue);
      expect(adapter.caminhos.single, endsWith('/auth/2fa/status'));
      expect(adapter.metodos.single, 'GET');
    });

    test('twoFactorSetup faz POST /auth/2fa/setup e lê secret/otpauthUri',
        () async {
      adapter = _RegistraAdapter(
          corpo: '{"secret": "ABC", "otpauthUri": "otpauth://totp/x"}');
      dioClient.dio.httpClientAdapter = adapter;

      final setup = await datasource.twoFactorSetup();

      expect(adapter.caminhos.single, endsWith('/auth/2fa/setup'));
      expect(setup['secret'], 'ABC');
      expect(setup['otpauthUri'], 'otpauth://totp/x');
    });

    test('twoFactorConfirm envia o código para /auth/2fa/confirm', () async {
      await datasource.twoFactorConfirm(codigo: ' 123456 ');

      expect(adapter.caminhos.single, endsWith('/auth/2fa/confirm'));
      final corpo = adapter.corpos.single as Map<String, dynamic>;
      expect(corpo['codigo'], '123456');
    });

    test('twoFactorDisable envia o código para /auth/2fa/disable', () async {
      await datasource.twoFactorDisable(codigo: '123456');

      expect(adapter.caminhos.single, endsWith('/auth/2fa/disable'));
      final corpo = adapter.corpos.single as Map<String, dynamic>;
      expect(corpo['codigo'], '123456');
    });
  });
}

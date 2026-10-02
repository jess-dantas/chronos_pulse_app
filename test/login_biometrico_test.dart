import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chronos_pulse_app/core/hardware/hardware_service.dart';
import 'package:chronos_pulse_app/core/network/conexao_service.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/core/security/device_token_store.dart';
import 'package:chronos_pulse_app/core/security/login_biometrico_store.dart';
import 'package:chronos_pulse_app/core/theme/theme_provider.dart';
import 'package:chronos_pulse_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:chronos_pulse_app/features/auth/data/models/usuario_model.dart';
import 'package:chronos_pulse_app/features/auth/data/repositories/auth_repository.dart';
import 'package:chronos_pulse_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:chronos_pulse_app/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';

const _cpf = '12345678901';

/// AuthRepository com login/alterarSenha interceptados (rede nunca tocada).
class _RepoFake extends AuthRepository {
  _RepoFake()
      : super(
          remoteDataSource: AuthRemoteDataSource(DioClient()),
          dioClient: DioClient(),
        );

  bool requerTwoFactor = false;
  bool falharLogin = false;
  int logins = 0;

  @override
  Future<UsuarioModel> login({
    required String cpf,
    required String senha,
  }) async {
    logins++;
    if (falharLogin) throw Exception('Credenciais inválidas.');
    if (requerTwoFactor) {
      return UsuarioModel(
        token: '',
        tipo: 'Bearer',
        nome: 'Colab',
        email: 'colab@empresa.com',
        cpf: cpf,
        role: 'COLABORADOR',
        requiresTwoFactor: true,
        tempToken: 'temp-1',
      );
    }
    return UsuarioModel(
      token: 'access-1',
      refreshToken: 'refresh-1',
      tipo: 'Bearer',
      nome: 'Colab',
      email: 'colab@empresa.com',
      cpf: cpf,
      role: 'COLABORADOR',
    );
  }

  @override
  Future<String> alterarSenha({required String novaSenha}) async => 'ok';
}

/// Hardware controlável (mesmo padrão do gate biométrico).
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
LoginBiometricoStore _credencial([Map<String, String>? base]) {
  final mapa = <String, String>{...?base};
  return LoginBiometricoStore(
    ler: (k) async => mapa[k],
    gravar: (k, v) async {
      mapa[k] = v;
    },
    remover: (k) async {
      mapa.remove(k);
    },
  );
}

/// Vínculo de dispositivo em memória, com dono opcional.
DeviceTokenStore _vinculoStore({String? cpf, bool ativo = false}) {
  final mem = <String, String>{};
  if (ativo) {
    mem[DeviceTokenStore.chaveToken] = 'dt-teste';
    mem[DeviceTokenStore.chaveCpcId] = 'cpc-1';
    mem[DeviceTokenStore.chaveNome] = 'Teste';
    mem[DeviceTokenStore.chaveExpiraEm] = DateTime.now()
        .toUtc()
        .add(const Duration(days: 1))
        .millisecondsSinceEpoch
        .toString();
    if (cpf != null) mem[DeviceTokenStore.chaveCpf] = cpf;
  }
  return DeviceTokenStore(
    ler: (k) async => mem[k],
    gravar: (k, v) async {
      mem[k] = v;
    },
    remover: (k) async {
      mem.remove(k);
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStoragePlatform.instance =
        TestFlutterSecureStoragePlatform(<String, String>{});
  });

  group('AuthProvider — credencial do login biométrico', () {
    late _RepoFake repo;
    late AuthProvider auth;
    late LoginBiometricoStore credencial;

    setUp(() {
      repo = _RepoFake();
      credencial = _credencial();
      auth = AuthProvider(repo, loginBiometrico: credencial);
      addTearDown(auth.dispose);
    });

    test('login por senha grava a credencial validada', () async {
      final ok = await auth.login(_cpf, 'senha123');

      expect(ok, isTrue);
      expect(await credencial.lerCpf(), _cpf);
      expect(await credencial.lerSenha(), 'senha123');
      expect(await credencial.possuiCredencial(), isTrue);
    });

    test('etapa 1 do 2FA também grava a credencial', () async {
      repo.requerTwoFactor = true;

      final ok = await auth.login(_cpf, 'senha123');

      expect(ok, isTrue, reason: 'senha validada na etapa 1');
      expect(auth.requiresTwoFactor, isTrue);
      expect(await credencial.possuiCredencial(), isTrue);
    });

    test('login falho não grava nem sobrescreve a credencial', () async {
      await credencial.salvar(cpf: _cpf, senha: 'senha-antiga');
      repo.falharLogin = true;

      final ok = await auth.login(_cpf, 'senha-errada');

      expect(ok, isFalse);
      expect(await credencial.lerSenha(), 'senha-antiga',
          reason: 'senha errada não pode apagar a credencial boa');
    });

    test('alterar senha atualiza a senha guardada', () async {
      await credencial.salvar(cpf: _cpf, senha: 'senha123');

      final ok = await auth.alterarSenha(novaSenha: 'nova-senha');

      expect(ok, isTrue);
      expect(await credencial.lerCpf(), _cpf);
      expect(await credencial.lerSenha(), 'nova-senha');
    });

    test('alterar senha sem credencial existente não cria uma', () async {
      final ok = await auth.alterarSenha(novaSenha: 'nova-senha');

      expect(ok, isTrue);
      expect(await credencial.possuiCredencial(), isFalse);
    });

    test('apagar meus dados (LGPD) limpa a credencial junto com a sessão',
        () async {
      await credencial.salvar(cpf: _cpf, senha: 'senha123');

      await auth.limparDadosLocais();

      expect(await credencial.possuiCredencial(), isFalse);
    });
  });

  group('LoginScreen — login por biometria', () {
    late AuthProvider auth;

    Future<void> pumpLogin(
      WidgetTester tester, {
      required LoginBiometricoStore credencial,
      required _HardwareFake hw,
      required DeviceTokenStore vinculo,
    }) async {
      auth = AuthProvider(
        _RepoFake(),
        loginBiometrico: credencial,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp(
            home: LoginScreen(
              conexao: ConexaoService(ping: () async => true),
              store: vinculo,
              hardware: hw,
              loginBiometrico: credencial,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();
    }

    testWidgets('sem credencial: segue o formulário sem oferta de biometria',
        (tester) async {
      final hw = _HardwareFake();
      await pumpLogin(
        tester,
        credencial: _credencial(),
        hw: hw,
        vinculo: _vinculoStore(),
      );

      expect(find.byKey(const Key('login_biometrico_button')), findsNothing);
      expect(find.text('Logar'), findsOneWidget);
      expect(hw.chamadas, equals(0), reason: 'não há o que confirmar');
      auth.dispose();
    });

    testWidgets('com credencial: dispara o prompt e oferece o botão',
        (tester) async {
      final hw = _HardwareFake();
      await pumpLogin(
        tester,
        credencial: _credencial({
          LoginBiometricoStore.chaveCpf: _cpf,
          LoginBiometricoStore.chaveSenha: 'senha123',
        }),
        hw: hw,
        vinculo: _vinculoStore(),
      );

      expect(hw.chamadas, equals(1),
          reason: 'auto-prompt deve abrir o prompt na entrada');
      expect(find.byKey(const Key('login_biometrico_button')), findsOneWidget);
      expect(find.text('Entrar com biometria'), findsOneWidget,
          reason: 'prompt concluído volta ao estado de repique');
      expect(auth.isAuthenticated, isTrue, reason: 'prompt aprovado loga');
      auth.dispose();
    });

    testWidgets('biometria indisponível: credencial fica escondida',
        (tester) async {
      final hw = _HardwareFake(disponivel: false);
      await pumpLogin(
        tester,
        credencial: _credencial({
          LoginBiometricoStore.chaveCpf: _cpf,
          LoginBiometricoStore.chaveSenha: 'senha123',
        }),
        hw: hw,
        vinculo: _vinculoStore(),
      );

      expect(hw.chamadas, equals(0));
      expect(find.byKey(const Key('login_biometrico_button')), findsNothing);
      expect(auth.isAuthenticated, isFalse);
      auth.dispose();
    });

    testWidgets('cancelou o prompt: credencial preservada e botão segue',
        (tester) async {
      final hw = _HardwareFake(autentica: false);
      final credencial = _credencial({
        LoginBiometricoStore.chaveCpf: _cpf,
        LoginBiometricoStore.chaveSenha: 'senha123',
      });
      await pumpLogin(
        tester,
        credencial: credencial,
        hw: hw,
        vinculo: _vinculoStore(),
      );

      expect(hw.chamadas, equals(1));
      expect(auth.isAuthenticated, isFalse);
      expect(find.byKey(const Key('login_biometrico_button')), findsOneWidget);
      expect(await credencial.possuiCredencial(), isTrue,
          reason: 'cancelar não pode apagar a credencial');
      auth.dispose();
    });

    testWidgets('senha trocada (login falho): avisa e mantém a credencial',
        (tester) async {
      final hw = _HardwareFake();
      final credencial = _credencial({
        LoginBiometricoStore.chaveCpf: _cpf,
        LoginBiometricoStore.chaveSenha: 'senha-velha',
      });
      // Provider com repo falho para o replay biométrico dar erro.
      auth = AuthProvider(
        _RepoFake()..falharLogin = true,
        loginBiometrico: credencial,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp(
            home: LoginScreen(
              conexao: ConexaoService(ping: () async => true),
              store: _vinculoStore(),
              hardware: hw,
              loginBiometrico: credencial,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.textContaining('Credenciais inválidas'), findsOneWidget);
      expect(await credencial.possuiCredencial(), isTrue,
          reason: 'próximo login por senha corrige a credencial');
      expect(find.byKey(const Key('login_biometrico_button')), findsOneWidget);

      // Drena o timer do snackbar antes de encerrar o teste.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      auth.dispose();
    });

    testWidgets('vínculo de OUTRO dono é invalidado no login biométrico',
        (tester) async {
      final credencial = _credencial({
        LoginBiometricoStore.chaveCpf: _cpf,
        LoginBiometricoStore.chaveSenha: 'senha123',
      });
      final vinculo =
          _vinculoStore(cpf: '99988877766', ativo: true); // outro dono

      await pumpLogin(
        tester,
        credencial: credencial,
        hw: _HardwareFake(),
        vinculo: vinculo,
      );

      expect(auth.isAuthenticated, isTrue);
      expect(await vinculo.lerAtivo(), isNull,
          reason: 'aparelho com dono antigo volta ao primeiro acesso');
      auth.dispose();
    });

    testWidgets('vínculo do MESMO dono permanece ativo', (tester) async {
      final credencial = _credencial({
        LoginBiometricoStore.chaveCpf: _cpf,
        LoginBiometricoStore.chaveSenha: 'senha123',
      });
      final vinculo = _vinculoStore(cpf: _cpf, ativo: true); // mesmo dono

      await pumpLogin(
        tester,
        credencial: credencial,
        hw: _HardwareFake(),
        vinculo: vinculo,
      );

      expect(auth.isAuthenticated, isTrue);
      expect(await vinculo.lerAtivo(), isNotNull);
      auth.dispose();
    });

    testWidgets('vínculo legado sem cpf é invalidado por segurança',
        (tester) async {
      final credencial = _credencial({
        LoginBiometricoStore.chaveCpf: _cpf,
        LoginBiometricoStore.chaveSenha: 'senha123',
      });
      final vinculo = _vinculoStore(ativo: true); // legado: sem cpf

      await pumpLogin(
        tester,
        credencial: credencial,
        hw: _HardwareFake(),
        vinculo: vinculo,
      );

      expect(auth.isAuthenticated, isTrue);
      expect(await vinculo.lerAtivo(), isNull,
          reason: 'dono desconhecido não sobrevive a um login');
      auth.dispose();
    });
  });
}

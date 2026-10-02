import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chronos_pulse_app/core/hardware/hardware_service.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/core/router/app_router.dart';
import 'package:chronos_pulse_app/core/theme/theme_provider.dart';
import 'package:chronos_pulse_app/features/admin/data/datasources/admin_auth_remote_datasource.dart';
import 'package:chronos_pulse_app/features/admin/data/repositories/admin_auth_repository_impl.dart';
import 'package:chronos_pulse_app/features/admin/presentation/providers/admin_auth_provider.dart';
import 'package:chronos_pulse_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:chronos_pulse_app/features/auth/data/models/usuario_model.dart';
import 'package:chronos_pulse_app/features/auth/data/repositories/auth_repository.dart';
import 'package:chronos_pulse_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:chronos_pulse_app/features/auth/presentation/screens/biometric_gate_screen.dart';
import 'package:chronos_pulse_app/features/home/presentation/screens/home_screen.dart';
import 'package:chronos_pulse_app/features/navigation/presentation/screens/main_shell.dart';
import 'package:chronos_pulse_app/features/ponto/data/datasources/ponto_local_datasource.dart';
import 'package:chronos_pulse_app/features/ponto/data/datasources/ponto_remote_datasource.dart';
import 'package:chronos_pulse_app/features/ponto/data/repositories/ponto_repository.dart';
import 'package:chronos_pulse_app/features/ponto/presentation/providers/ponto_provider.dart';
import 'package:chronos_pulse_app/features/privacidade/data/privacidade_datasource.dart';
import 'package:chronos_pulse_app/features/privacidade/presentation/providers/privacidade_provider.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';

UsuarioModel _usuario() => UsuarioModel(
      token: 'token',
      refreshToken: 'refresh',
      tipo: 'Bearer',
      nome: 'Maria',
      email: 'maria@example.com',
      cpf: '12345678901',
      role: 'COLABORADOR',
      modulos: const ['PONTO'],
    );

/// Hardware controlável: biometria disponível/ausente, sucesso/cancela/erro.
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

/// AuthProvider com sessão injetada e controle do estado do gate.
class _AuthFake extends AuthProvider {
  _AuthFake()
      : super(AuthRepository(
          remoteDataSource: AuthRemoteDataSource(DioClient()),
          dioClient: DioClient(),
        ));

  UsuarioModel? _sessao;
  bool bloqueada = true;
  bool saiu = false;

  void definirSessao(UsuarioModel usuario) => _sessao = usuario;

  @override
  UsuarioModel? get usuario => _sessao;

  @override
  bool get isAuthenticated => _sessao != null && _sessao!.token.isNotEmpty;

  @override
  bool get sessaoDesbloqueada => !bloqueada;

  /// Simula o resultado da biometria (o canal de plataforma real pendura
  /// em ambiente de teste; o comportamento do gate é coberto com _HardwareFake).
  void liberar() {
    bloqueada = false;
    notifyListeners();
  }

  @override
  void confirmarBiometria() => liberar();

  @override
  Future<void> logout() async {
    saiu = true;
    _sessao = null;
    notifyListeners();
  }
}

/// Datasource de privacidade em memória (sem rede) para o consentimento.
class _FakePrivacidadeDataSource extends PrivacidadeDataSource {
  _FakePrivacidadeDataSource() : super(DioClient());

  @override
  Future<Map<String, dynamic>> getPolitica() async {
    return {
      'versao': '1.0',
      'dataPublicacao': '2026-09-08',
      'texto': 'Política de privacidade v1',
    };
  }

  @override
  Future<Map<String, dynamic>> getStatusConsentimento() async {
    return {
      'versaoAtual': '1.0',
      'versaoAceita': '1.0',
      'dataConsentimento': '2026-09-08T10:00:00Z',
      'aceitePendente': false,
    };
  }

  @override
  Future<void> registrarConsentimento(String versaoPolitica) async {}
}

/// Sem timers de rede/heartbeat para pumpAndSettle previsível.
class _FakePonto extends PontoProvider {
  _FakePonto()
      : super(PontoRepository(
          localDataSource: PontoLocalDataSource(),
          remoteDataSource: PontoRemoteDataSource(DioClient()),
        ));

  @override
  Future<void> carregarDados() async {}

  @override
  void iniciarMonitoramento({Duration interval = const Duration(seconds: 30)}) {}
}

/// Repositório com refresh em memória (rede nunca é tocada no teste).
class _RepoRefreshFake extends AuthRepository {
  _RepoRefreshFake()
      : super(
          remoteDataSource: AuthRemoteDataSource(DioClient()),
          dioClient: DioClient(),
        );

  bool refreshChamado = false;

  @override
  Future<UsuarioModel> refreshToken(String refreshToken) async {
    refreshChamado = true;
    return _usuario();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpGate(
    WidgetTester tester,
    _AuthFake auth,
    HardwareService hw,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: MaterialApp(
          home: BiometricGateScreen(hardwareService: hw),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  group('BiometricGateScreen (login por biometria na abertura)', () {
    testWidgets('sem biometria disponível libera a sessão sozinho', (tester) async {
      final auth = _AuthFake()..definirSessao(_usuario());
      final hw = _HardwareFake(disponivel: false);

      await pumpGate(tester, auth, hw);

      expect(auth.bloqueada, isFalse);
      expect(hw.chamadas, equals(0),
          reason: 'sem o que confirmar, não dispara o prompt');
    });

    testWidgets('com biometria confirma automaticamente na abertura', (tester) async {
      final auth = _AuthFake()..definirSessao(_usuario());
      final hw = _HardwareFake(disponivel: true, autentica: true);

      await pumpGate(tester, auth, hw);

      expect(hw.chamadas, equals(1));
      expect(auth.bloqueada, isFalse);
    });

    testWidgets('cancelou: mostra recusa e permite tentar de novo', (tester) async {
      final auth = _AuthFake()..definirSessao(_usuario());
      final hw = _HardwareFake(disponivel: true, autentica: false);

      await pumpGate(tester, auth, hw);

      expect(auth.bloqueada, isTrue, reason: 'cancelar não pode liberar');
      expect(find.textContaining('cancelada'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);

      hw.autentica = true;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();
      await tester.pump();

      expect(hw.chamadas, equals(2));
      expect(auth.bloqueada, isFalse);
    });

    testWidgets('erro técnico exibe aviso e a saída', (tester) async {
      final auth = _AuthFake()..definirSessao(_usuario());
      final hw = _HardwareFake(disponivel: true)..lancarErro = true;

      await pumpGate(tester, auth, hw);

      expect(auth.bloqueada, isTrue);
      expect(find.textContaining('entre com sua senha'), findsOneWidget);
      expect(find.text('Sair'), findsOneWidget);

      await tester.tap(find.text('Sair'));
      await tester.pump();

      expect(auth.saiu, isTrue);
    });
  });

  group('AppRouter — gate biométrico', () {
    late _AuthFake auth;
    late AdminAuthProvider adminAuth;
    late GoRouter router;
    late _FakePonto ponto;

    setUpAll(() async {
      await initializeDateFormatting('pt_BR');
    });

    setUp(() {
      auth = _AuthFake()..definirSessao(_usuario());
      adminAuth = AdminAuthProvider(
        AdminAuthRepositoryImpl(AdminAuthRemoteDataSource(DioClient())),
        DioClient(),
      );
      ponto = _FakePonto();
      router = AppRouter.build(auth, adminAuth);
    });

    /// Tela de celular; monta o painel com os providers que a home exige.
    /// Sem pumpAndSettle aqui: o gate usa spinner indeterminado enquanto a
    /// sessão está bloqueada.
    Future<void> pumpApp(WidgetTester tester, {String rota = '/painel/home'}) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<AdminAuthProvider>.value(value: adminAuth),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(
              create: (_) => PrivacidadeProvider(_FakePrivacidadeDataSource()),
            ),
            ChangeNotifierProvider<PontoProvider>.value(value: ponto),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      router.go(rota);
      await tester.pump();
      await tester.pump();
    }

    testWidgets(
        'sessão bloqueada: o redirect impõe o gate antes do conteúdo; ao '
        'liberar, o painel abre', (tester) async {
      await pumpApp(tester);

      expect(find.byType(BiometricGateScreen), findsOneWidget,
          reason: 'conteúdo protegido não pode aparecer antes da biometria');
      expect(find.byType(MainShell), findsNothing);
      expect(find.byType(HomeScreen), findsNothing);

      auth.liberar();
      await tester.pumpAndSettle();

      expect(find.byType(BiometricGateScreen), findsNothing);
      expect(find.byType(MainShell), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('sessão já desbloqueada vai direto ao painel', (tester) async {
      auth.bloqueada = false;
      await pumpApp(tester);
      await tester.pumpAndSettle();

      expect(find.byType(BiometricGateScreen), findsNothing);
      expect(find.byType(MainShell), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('AuthProvider — restauração de sessão exige biometria', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStoragePlatform.instance =
          TestFlutterSecureStoragePlatform(<String, String>{
        'chronos_access_token': 'tok-restaurado',
        'chronos_refresh_token': 'ref-restaurado',
      });
    });

    test('tryRestoreSession deixa a sessão BLOQUEADA até a biometria', () async {
      final repo = _RepoRefreshFake();
      final auth = AuthProvider(repo);

      expect(auth.sessaoDesbloqueada, isTrue,
          reason: 'provedor novo (sem restaurar) nasce liberado');

      await auth.tryRestoreSession();

      expect(repo.refreshChamado, isTrue);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.sessaoDesbloqueada, isFalse,
          reason: 'sessão restaurada ao abrir exige o gate biométrico');

      auth.confirmarBiometria();
      expect(auth.sessaoDesbloqueada, isTrue);

      auth.dispose();
    });

    test('biometria desligada restaura a sessão já DESBLOQUEADA', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('chronos_biometria_ativa', false);

      final repo = _RepoRefreshFake();
      final auth = AuthProvider(repo);

      await auth.tryRestoreSession();

      expect(auth.isAuthenticated, isTrue);
      expect(auth.sessaoDesbloqueada, isTrue,
          reason: 'com o bloqueio desligado em Segurança o gate não é cobrado');

      auth.dispose();
    });
  });
}

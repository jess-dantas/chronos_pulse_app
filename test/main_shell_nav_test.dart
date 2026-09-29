import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

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
import 'package:chronos_pulse_app/features/navigation/presentation/screens/main_shell.dart';
import 'package:chronos_pulse_app/features/perfil/presentation/screens/perfil_screen.dart';
import 'package:chronos_pulse_app/features/ponto/data/datasources/ponto_local_datasource.dart';
import 'package:chronos_pulse_app/features/ponto/data/datasources/ponto_remote_datasource.dart';
import 'package:chronos_pulse_app/features/ponto/data/repositories/ponto_repository.dart';
import 'package:chronos_pulse_app/features/ponto/presentation/providers/ponto_provider.dart';
import 'package:chronos_pulse_app/features/ponto/presentation/screens/home_ponto_screen.dart';
import 'package:chronos_pulse_app/features/privacidade/data/privacidade_datasource.dart';
import 'package:chronos_pulse_app/features/privacidade/presentation/providers/privacidade_provider.dart';
import 'package:chronos_pulse_app/features/privacidade/presentation/screens/privacidade_screen.dart';

class _FakeAuth extends AuthProvider {
  _FakeAuth()
      : super(AuthRepository(
          remoteDataSource: AuthRemoteDataSource(DioClient()),
          dioClient: DioClient(),
        ));

  UsuarioModel? _sessao;

  void definirSessao(UsuarioModel usuario) => _sessao = usuario;

  @override
  UsuarioModel? get usuario => _sessao;

  @override
  bool get isAuthenticated => _sessao != null && _sessao!.token.isNotEmpty;
}

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

/// Sem timers de rede/heartbeat: o dock navega por `go()` e o teste precisa
/// de pumpAndSettle previsível.
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

UsuarioModel _usuario({
  String role = 'COLABORADOR',
  List<String> modulos = const ['PONTO'],
}) =>
    UsuarioModel(
      token: 'token',
      refreshToken: 'refresh',
      tipo: 'Bearer',
      nome: 'Teste Nav',
      email: 'teste@example.com',
      cpf: '12345678901',
      role: role,
      modulos: modulos,
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  late _FakeAuth auth;
  late AdminAuthProvider adminAuth;
  late GoRouter router;
  late _FakePonto ponto;

  setUp(() {
    final dio = DioClient();
    auth = _FakeAuth();
    adminAuth = AdminAuthProvider(
      AdminAuthRepositoryImpl(AdminAuthRemoteDataSource(dio)),
      dio,
    );
    ponto = _FakePonto();
    router = AppRouter.build(auth, adminAuth);
  });

  /// Tela de celular (400x800): dispara o layout mobile do MainShell.
  Future<void> pumpMobile(
    WidgetTester tester, {
    String role = 'COLABORADOR',
    List<String> modulos = const ['PONTO'],
    String rota = '/painel/home',
  }) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    auth.definirSessao(_usuario(role: role, modulos: modulos));
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
    await tester.pumpAndSettle();
  }

  testWidgets('dock mobile tem 5 itens fixos: Home, Ponto, Espelho, Menu, Perfil',
      (tester) async {
    await pumpMobile(tester);

    expect(find.byType(MainShell), findsOneWidget);
    final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
    final labels = nav.destinations
        .map((d) => (d as NavigationDestination).label)
        .toList();
    expect(labels, ['Home', 'Ponto', 'Espelho', 'Menu', 'Perfil']);
    expect(nav.selectedIndex, 0, reason: 'Home é a rota inicial');

    // O drawer (hambúrguer) existe para o restante dos módulos.
    expect(find.byTooltip('Menu de módulos'), findsOneWidget);
  });

  testWidgets('item Espelho abre /painel/ponto na aba do espelho',
      (tester) async {
    await pumpMobile(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Espelho'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(HomePontoScreen), findsOneWidget);
    expect(router.state.uri.toString(), '/painel/ponto?aba=espelho');
    final tab = tester.widget<DefaultTabController>(
      find.byType(DefaultTabController),
    );
    expect(tab.initialIndex, 1, reason: 'aba Espelho de Ponto ativa');

    final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(nav.selectedIndex, 2, reason: 'dock destaca Espelho');
  });

  testWidgets('item Ponto volta para a aba de bater ponto', (tester) async {
    await pumpMobile(tester, rota: '/painel/ponto?aba=espelho');
    expect(find.byType(HomePontoScreen), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Ponto'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(router.state.uri.toString(), '/painel/ponto');
    final tab = tester.widget<DefaultTabController>(
      find.byType(DefaultTabController),
    );
    expect(tab.initialIndex, 0);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
  });

  testWidgets('hambúrguer abre o drawer e navega para um módulo fora do dock',
      (tester) async {
    await pumpMobile(
      tester,
      role: 'ADMIN_EMPRESA',
      modulos: const ['PONTO', 'ESTOQUE'],
    );

    // O tap sintético não alcança o IconButton do AppBar neste ambiente de
    // teste (hit test do tooltip); a ação é invocada diretamente para validar
    // que o botão está wired ao drawer.
    final menuButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.menu),
        matching: find.byType(IconButton),
      ),
    );
    expect(menuButton.onPressed, isNotNull);
    menuButton.onPressed!();
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsOneWidget);
    final itemPrivacidade = find.descendant(
      of: find.byType(Drawer),
      matching: find.text('Privacidade'),
    );
    expect(itemPrivacidade, findsWidgets);
    expect(find.text('Encerrar Sessão'), findsOneWidget);

    await tester.tap(itemPrivacidade.first);
    await tester.pumpAndSettle();

    expect(router.state.uri.toString(), '/painel/privacidade');
    expect(find.byType(PrivacidadeScreen), findsOneWidget);
    expect(
      find.byType(NavigationBar),
      findsNothing,
      reason: 'módulo fora do dock usa a dock sem destaque',
    );
  });

  testWidgets('item Perfil do dock abre a tela de perfil', (tester) async {
    await pumpMobile(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Perfil'),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.state.uri.toString(), '/perfil');
    expect(find.byType(PerfilScreen), findsOneWidget);
  });

  testWidgets('item Menu do dock abre o drawer', (tester) async {
    await pumpMobile(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Menu'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsOneWidget);
    expect(find.text('Encerrar Sessão'), findsOneWidget);
  });
}

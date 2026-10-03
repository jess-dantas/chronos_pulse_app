import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/core/router/app_router.dart';
import 'package:chronos_pulse_app/core/theme/theme_provider.dart';
import 'package:chronos_pulse_app/features/admin/data/datasources/admin_auth_remote_datasource.dart';
import 'package:chronos_pulse_app/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:chronos_pulse_app/features/admin/data/repositories/admin_auth_repository_impl.dart';
import 'package:chronos_pulse_app/features/admin/data/repositories/admin_repository.dart';
import 'package:chronos_pulse_app/features/admin/presentation/providers/admin_auth_provider.dart';
import 'package:chronos_pulse_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:chronos_pulse_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:chronos_pulse_app/features/auth/data/models/usuario_model.dart';
import 'package:chronos_pulse_app/features/auth/data/repositories/auth_repository.dart';
import 'package:chronos_pulse_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:chronos_pulse_app/features/navigation/presentation/screens/admin_shell.dart';

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

UsuarioModel _usuario() => UsuarioModel(
      token: 'token',
      refreshToken: 'refresh',
      tipo: 'Bearer',
      nome: 'Admin Teste',
      email: 'admin@example.com',
      cpf: '12345678901',
      role: 'ADMIN_PLATAFORMA',
      modulos: const [],
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  late _FakeAuth auth;
  late AdminAuthProvider adminAuth;
  late AdminRepository adminRepository;
  late GoRouter router;

  setUp(() {
    final dio = DioClient();
    auth = _FakeAuth();
    adminAuth = AdminAuthProvider(
      AdminAuthRepositoryImpl(AdminAuthRemoteDataSource(dio)),
      dio,
    );
    adminRepository = AdminRepository(
      remoteDataSource: AdminRemoteDataSource(dio),
    );
    router = AppRouter.build(auth, adminAuth);
  });

  Future<void> pumpShell(
    WidgetTester tester, {
    Size tamanho = const Size(400, 800),
    String rota = '/admin/seguranca',
  }) async {
    tester.view.physicalSize = tamanho;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Sessão + rota definidas ANTES do primeiro frame: evita montar a
    // landing (pública) e o branch do Dashboard em viewport estreito.
    auth.definirSessao(_usuario());
    router.go(rota);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<AdminAuthProvider>.value(value: adminAuth),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(
            create: (_) => AdminProvider(adminRepository),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
      'layout estreito: dock de 3 (Home/Menu/Perfil), sem hambúrguer '
      'nem barra de conta/sair', (tester) async {
    await pumpShell(tester, rota: '/admin/dashboard');

    expect(find.byType(AdminShell), findsOneWidget);
    expect(find.byTooltip('Menu do admin'), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
    expect(
      find.byIcon(Icons.menu),
      findsOneWidget,
      reason: 'sem hambúrguer no AppBar: só o item Menu da dock',
    );
    expect(
      find.text('Admin Teste (Plataforma)'),
      findsNothing,
      reason: 'barra de conta/sair inferior foi removida',
    );

    final dock = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(
      dock.destinations,
      hasLength(3),
      reason: 'dock fixa em Home, Menu e Perfil (resto no drawer)',
    );
    expect(dock.selectedIndex, 0, reason: 'Home (Dashboard) é o branch inicial');
    for (final label in ['Home', 'Menu', 'Perfil']) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
        findsOneWidget,
        reason: 'dock lista o item $label',
      );
    }
  });

  testWidgets('item Menu da dock abre o drawer com as seções e navega',
      (tester) async {
    await pumpShell(tester); // /admin/seguranca — fora do dashboard

    expect(
      find.byType(NavigationBar),
      findsNothing,
      reason: 'rota fora do dashboard: dock renderizada sem destaque',
    );
    for (final label in ['Home', 'Menu', 'Perfil']) {
      expect(
        find.text(label),
        findsOneWidget,
        reason: 'dock sem destaque ainda renderiza os 3 itens',
      );
    }

    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsOneWidget);
    for (final secao in [
      'Dashboard',
      'Leads',
      'Empresas',
      'Contratos',
      'Módulos',
      'Alterar Senha',
      'Segurança',
    ]) {
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text(secao)),
        findsOneWidget,
        reason: 'drawer lista a seção $secao',
      );
    }
    expect(find.descendant(of: find.byType(Drawer), matching: find.text('Perfil')), findsOneWidget);
    expect(find.text('Encerrar Sessão'), findsOneWidget);

    await tester.tap(
      find.descendant(of: find.byType(Drawer), matching: find.text('Módulos')),
    );
    await tester.pumpAndSettle();

    expect(router.state.uri.toString(), '/admin/modulos');
    expect(find.byType(Drawer), findsNothing, reason: 'drawer fecha ao navegar');
    expect(
      find.byType(NavigationBar),
      findsNothing,
      reason: 'Módulos continua fora do dashboard: dock sem destaque',
    );
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Menu'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets('layout largo mantém o NavigationRail e esconde o hambúrguer',
      (tester) async {
    await pumpShell(tester, tamanho: const Size(1200, 900));

    expect(find.byType(AdminShell), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byTooltip('Menu do admin'), findsNothing);
    expect(find.byType(Drawer), findsNothing);
  });
}

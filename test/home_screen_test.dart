import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:chronos_pulse_app/features/home/presentation/screens/home_screen.dart';
import 'package:chronos_pulse_app/features/ponto/data/datasources/ponto_local_datasource.dart';
import 'package:chronos_pulse_app/features/ponto/data/datasources/ponto_remote_datasource.dart';
import 'package:chronos_pulse_app/features/ponto/data/repositories/ponto_repository.dart';
import 'package:chronos_pulse_app/features/ponto/presentation/providers/ponto_provider.dart';
import 'package:chronos_pulse_app/features/ponto/presentation/screens/home_ponto_screen.dart';
import 'package:chronos_pulse_app/features/privacidade/data/privacidade_datasource.dart';
import 'package:chronos_pulse_app/features/privacidade/presentation/providers/privacidade_provider.dart';

/// AuthProvider com sessão injetada (mesmo padrão de shell_layout_test.dart),
/// sem tocar em rede/armazenamento nativo.
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

UsuarioModel _usuario({
  String role = 'COLABORADOR',
  List<String> modulos = const ['PONTO'],
}) =>
    UsuarioModel(
      token: 'token',
      refreshToken: 'refresh',
      tipo: 'Bearer',
      nome: 'Maria Colaboradora',
      email: 'maria@example.com',
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
  late PontoProvider ponto;

  setUp(() {
    auth = _FakeAuth();
    adminAuth = AdminAuthProvider(
      AdminAuthRepositoryImpl(AdminAuthRemoteDataSource(DioClient())),
      DioClient(),
    );
    final dio = DioClient();
    ponto = PontoProvider(
      PontoRepository(
        localDataSource: PontoLocalDataSource(),
        remoteDataSource: PontoRemoteDataSource(dio),
      ),
    );
  });

  Future<void> pumpTela(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    auth.definirSessao(_usuario());
    final goRouter = AppRouter.build(auth, adminAuth);

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
        child: MaterialApp.router(routerConfig: goRouter),
      ),
    );
    goRouter.go('/painel/home');
    await tester.pumpAndSettle();
  }

  testWidgets('Home exibe saudação, status do dia e atalhos', (tester) async {
    await pumpTela(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Bem-vindo, Maria Colaboradora'), findsOneWidget);
    expect(find.text('Marcações de hoje'), findsOneWidget);
    expect(find.text('Sincronização'), findsOneWidget);
    expect(find.text('Atalhos'), findsOneWidget);
    expect(find.text('Bater Ponto'), findsOneWidget);
    expect(find.text('Espelho de Ponto'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets('sem módulo RH não mostra a fila de aprovação', (tester) async {
    await pumpTela(tester);

    expect(find.text('Ajustes aguardando aprovação'), findsNothing);
  });

  testWidgets('atalho "Bater Ponto" navega para o módulo de ponto',
      (tester) async {
    await pumpTela(tester);

    final atalho = find.text('Bater Ponto');
    await tester.ensureVisible(atalho);
    await tester.pumpAndSettle();
    await tester.tap(atalho);
    // HomePontoScreen tem relógio com timer de 1s: evita pumpAndSettle eterno.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(HomePontoScreen), findsOneWidget);
  });
}

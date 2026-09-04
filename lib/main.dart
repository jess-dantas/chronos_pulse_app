import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/network/dio_client.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/landing/presentation/screens/landing_screen.dart';
import 'features/colaborador/data/datasources/colaborador_remote_datasource.dart';
import 'features/colaborador/data/repositories/colaborador_repository.dart';
import 'features/colaborador/presentation/providers/colaborador_provider.dart';
import 'features/estoque/data/datasources/estoque_remote_datasource.dart';
import 'features/estoque/data/repositories/estoque_repository.dart';
import 'features/estoque/presentation/providers/estoque_provider.dart';
import 'features/ponto/data/datasources/ponto_local_datasource.dart';
import 'features/ponto/data/datasources/ponto_remote_datasource.dart';
import 'features/ponto/data/repositories/ponto_repository.dart';
import 'features/ponto/presentation/providers/ponto_provider.dart';
import 'features/navigation/presentation/screens/main_navigation_screen.dart';
import 'features/admin/data/datasources/admin_remote_datasource.dart';
import 'features/admin/data/repositories/admin_repository.dart';
import 'features/admin/presentation/providers/admin_provider.dart';
import 'features/admin/presentation/screens/admin_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  final temaInicial = await ThemeProvider.carregarTema();

  final dioClient = DioClient();

  final authRemoteDataSource = AuthRemoteDataSource(dioClient);
  final authRepository = AuthRepository(
    remoteDataSource: authRemoteDataSource,
    dioClient: dioClient,
  );

  final colaboradorRemoteDataSource = ColaboradorRemoteDataSource(dioClient);
  final colaboradorRepository =
      ColaboradorRepository(remoteDataSource: colaboradorRemoteDataSource);

  final estoqueRemoteDataSource = EstoqueRemoteDataSource(dioClient);
  final estoqueRepository =
      EstoqueRepository(remoteDataSource: estoqueRemoteDataSource);

  final pontoLocalDataSource = PontoLocalDataSource();
  final pontoRemoteDataSource = PontoRemoteDataSource(dioClient);
  final pontoRepository = PontoRepository(
    localDataSource: pontoLocalDataSource,
    remoteDataSource: pontoRemoteDataSource,
  );

  final adminRemoteDataSource = AdminRemoteDataSource(dioClient);
  final adminRepository = AdminRepository(remoteDataSource: adminRemoteDataSource);

  final authProvider = AuthProvider(authRepository);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(initialMode: temaInicial)),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ColaboradorProvider(colaboradorRepository)),
        ChangeNotifierProvider(create: (_) => EstoqueProvider(estoqueRepository)),
        ChangeNotifierProvider(create: (_) => PontoProvider(pontoRepository)),
        ChangeNotifierProvider(create: (_) => AdminProvider(adminRepository)),
      ],
      child: ChronosPulseApp(authProvider: authProvider),
    ),
  );
}

class ChronosPulseApp extends StatefulWidget {
  final AuthProvider authProvider;

  const ChronosPulseApp({super.key, required this.authProvider});

  @override
  State<ChronosPulseApp> createState() => _ChronosPulseAppState();
}

class _ChronosPulseAppState extends State<ChronosPulseApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
    widget.authProvider.tryRestoreSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    super.dispose();
  }

  bool _onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      widget.authProvider.registrarAtividade();
    }
    return false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.authProvider.verificarInatividade();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => widget.authProvider.registrarAtividade(),
      onPointerMove: (_) => widget.authProvider.registrarAtividade(),
      child: MaterialApp(
        title: 'Chronos Pulse',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeProvider.themeMode,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  void _mostrarMotivoEncerramento(AuthProvider authProvider) {
    final motivo = authProvider.consumirMotivoEncerramento();
    if (motivo != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(motivo),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 6),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      _mostrarMotivoEncerramento(authProvider);
      return const LandingScreen();
    }

    final usuario = authProvider.usuario;
    if (usuario != null && usuario.isGestorPlataforma) {
      return const AdminNavigationScreen();
    }
    return const MainNavigationScreen();
  }
}

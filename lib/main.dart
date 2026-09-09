import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/network/dio_client.dart';
import 'core/security/session_storage.dart';
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
import 'features/compras/data/datasources/compras_remote_datasource.dart';
import 'features/compras/data/repositories/compras_repository.dart';
import 'features/compras/presentation/providers/compras_provider.dart';
import 'features/licitacoes/data/datasources/licitacoes_remote_datasource.dart';
import 'features/licitacoes/data/repositories/licitacoes_repository.dart';
import 'features/licitacoes/presentation/providers/licitacoes_provider.dart';
import 'features/ponto/data/datasources/ponto_local_datasource.dart';
import 'features/ponto/data/datasources/ponto_remote_datasource.dart';
import 'features/ponto/data/repositories/ponto_repository.dart';
import 'features/ponto/presentation/providers/ponto_provider.dart';
import 'features/navigation/presentation/screens/main_navigation_screen.dart';
import 'features/admin/data/datasources/admin_remote_datasource.dart';
import 'features/admin/data/repositories/admin_repository.dart';
import 'features/admin/presentation/providers/admin_provider.dart';
import 'features/admin/presentation/screens/admin_navigation_screen.dart';
import 'features/patrimonio/data/datasources/patrimonio_remote_datasource.dart';
import 'features/patrimonio/data/datasources/desfazimento_remote_datasource.dart';
import 'features/patrimonio/data/datasources/inventario_remote_datasource.dart';
import 'features/patrimonio/data/datasources/transferencia_remote_datasource.dart';
import 'features/patrimonio/data/repositories/patrimonio_repository.dart';
import 'features/patrimonio/data/repositories/desfazimento_repository.dart';
import 'features/patrimonio/data/repositories/inventario_repository.dart';
import 'features/patrimonio/data/repositories/transferencia_repository.dart';
import 'features/patrimonio/presentation/providers/patrimonio_provider.dart';
import 'features/patrimonio/presentation/providers/desfazimento_provider.dart';
import 'features/patrimonio/presentation/providers/inventario_provider.dart';
import 'features/patrimonio/presentation/providers/transferencia_provider.dart';
import 'features/frota/data/datasources/frota_remote_datasource.dart';
import 'features/frota/data/repositories/frota_repository.dart';
import 'features/frota/presentation/providers/frota_provider.dart';
import 'features/protocolo/data/datasources/protocolo_remote_datasource.dart';
import 'features/protocolo/data/repositories/protocolo_repository.dart';
import 'features/protocolo/presentation/providers/protocolo_provider.dart';
import 'features/privacidade/data/privacidade_datasource.dart';
import 'features/privacidade/presentation/providers/privacidade_provider.dart';
import 'features/transparencia/data/datasources/transparencia_remote_datasource.dart';
import 'features/transparencia/data/repositories/transparencia_repository.dart';
import 'features/transparencia/presentation/providers/transparencia_provider.dart';

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

  final comprasRemoteDataSource = ComprasRemoteDataSource(dioClient);
  final comprasRepository =
      ComprasRepository(remoteDataSource: comprasRemoteDataSource);

  final licitacoesRemoteDataSource = LicitacoesRemoteDataSource(dioClient);
  final licitacoesRepository =
      LicitacoesRepository(remoteDataSource: licitacoesRemoteDataSource);

  final pontoLocalDataSource = PontoLocalDataSource();
  final pontoRemoteDataSource = PontoRemoteDataSource(dioClient);
  final pontoRepository = PontoRepository(
    localDataSource: pontoLocalDataSource,
    remoteDataSource: pontoRemoteDataSource,
  );

  final adminRemoteDataSource = AdminRemoteDataSource(dioClient);
  final adminRepository = AdminRepository(remoteDataSource: adminRemoteDataSource);

  final patrimonioRemoteDataSource = PatrimonioRemoteDataSource(dioClient);
  final patrimonioRepository =
      PatrimonioRepository(remoteDataSource: patrimonioRemoteDataSource);

  final desfazimentoRemoteDataSource = DesfazimentoRemoteDataSource(dioClient);
  final desfazimentoRepository =
      DesfazimentoRepository(remoteDataSource: desfazimentoRemoteDataSource);

  final inventarioRemoteDataSource = InventarioRemoteDataSource(dioClient);
  final inventarioRepository =
      InventarioRepository(remoteDataSource: inventarioRemoteDataSource);

  final transferenciaRemoteDataSource = TransferenciaRemoteDataSource(dioClient);
  final transferenciaRepository =
      TransferenciaRepository(remoteDataSource: transferenciaRemoteDataSource);

  final frotaRemoteDataSource = FrotaRemoteDataSource(dioClient);
  final frotaRepository = FrotaRepository(remoteDataSource: frotaRemoteDataSource);

  final protocoloRemoteDataSource = ProtocoloRemoteDataSource(dioClient);
  final protocoloRepository =
      ProtocoloRepository(remoteDataSource: protocoloRemoteDataSource);

  final privacidadeProvider = PrivacidadeProvider(PrivacidadeDataSource(dioClient));

  final transparenciaRemoteDataSource = TransparenciaRemoteDataSource(dioClient);
  final transparenciaRepository =
      TransparenciaRepository(remoteDataSource: transparenciaRemoteDataSource);

  final authProvider = AuthProvider(authRepository);

  dioClient.onRefreshToken = () async {
    final refreshToken = await SessionStorage.readToken(AuthProvider.keyRefreshToken);
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final novo = await authRepository.refreshToken(refreshToken);
      await SessionStorage.writeToken(AuthProvider.keyAccessToken, novo.token);
      if (novo.refreshToken != null && novo.refreshToken!.isNotEmpty) {
        await SessionStorage.writeToken(AuthProvider.keyRefreshToken, novo.refreshToken!);
      }
      authProvider.restaurarSessaoAposRefresh(novo);
      return true;
    } catch (_) {
      await authProvider.logout();
      return false;
    }
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(initialMode: temaInicial)),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ColaboradorProvider(colaboradorRepository)),
        ChangeNotifierProvider(create: (_) => EstoqueProvider(estoqueRepository)),
        ChangeNotifierProvider(create: (_) => ComprasProvider(comprasRepository)),
        ChangeNotifierProvider(create: (_) => LicitacoesProvider(licitacoesRepository)),
        ChangeNotifierProvider(create: (_) => PontoProvider(pontoRepository)),
        ChangeNotifierProvider(create: (_) => AdminProvider(adminRepository)),
        ChangeNotifierProvider(create: (_) => PatrimonioProvider(patrimonioRepository)),
        ChangeNotifierProvider(create: (_) => DesfazimentoProvider(desfazimentoRepository)),
        ChangeNotifierProvider(create: (_) => InventarioProvider(inventarioRepository)),
        ChangeNotifierProvider(create: (_) => TransferenciaProvider(transferenciaRepository)),
        ChangeNotifierProvider(create: (_) => FrotaProvider(frotaRepository)),
        ChangeNotifierProvider(create: (_) => ProtocoloProvider(protocoloRepository)),
        ChangeNotifierProvider(create: (_) => TransparenciaProvider(transparenciaRepository)),
        ChangeNotifierProvider.value(value: privacidadeProvider),
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

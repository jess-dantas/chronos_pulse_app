import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/network/dio_client.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
        ChangeNotifierProvider(create: (_) => ColaboradorProvider(colaboradorRepository)),
        ChangeNotifierProvider(create: (_) => EstoqueProvider(estoqueRepository)),
        ChangeNotifierProvider(create: (_) => PontoProvider(pontoRepository)),
      ],
      child: const ChronosPulseApp(),
    ),
  );
}

class ChronosPulseApp extends StatelessWidget {
  const ChronosPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chronos Pulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isAuthenticated) {
      return const MainNavigationScreen();
    }
    return const LoginScreen();
  }
}

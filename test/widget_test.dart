import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:chronos_pulse_app/features/auth/data/repositories/auth_repository.dart';
import 'package:chronos_pulse_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:chronos_pulse_app/features/estoque/data/datasources/estoque_remote_datasource.dart';
import 'package:chronos_pulse_app/features/estoque/data/repositories/estoque_repository.dart';
import 'package:chronos_pulse_app/features/estoque/presentation/providers/estoque_provider.dart';
import 'package:chronos_pulse_app/features/ponto/data/datasources/ponto_local_datasource.dart';
import 'package:chronos_pulse_app/features/ponto/data/datasources/ponto_remote_datasource.dart';
import 'package:chronos_pulse_app/features/ponto/data/repositories/ponto_repository.dart';
import 'package:chronos_pulse_app/features/ponto/presentation/providers/ponto_provider.dart';
import 'package:chronos_pulse_app/main.dart';

void main() {
  testWidgets('Renderiza tela de login por padrão com logo e slogan', (WidgetTester tester) async {
    final dioClient = DioClient();
    final authRemoteDataSource = AuthRemoteDataSource(dioClient);
    final authRepository = AuthRepository(
      remoteDataSource: authRemoteDataSource,
      dioClient: dioClient,
    );

    final estoqueRemoteDataSource = EstoqueRemoteDataSource(dioClient);
    final estoqueRepository = EstoqueRepository(remoteDataSource: estoqueRemoteDataSource);

    final pontoLocalDataSource = PontoLocalDataSource();
    final pontoRemoteDataSource = PontoRemoteDataSource(dioClient);
    final pontoRepository = PontoRepository(
      localDataSource: pontoLocalDataSource,
      remoteDataSource: pontoRemoteDataSource,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
          ChangeNotifierProvider(create: (_) => EstoqueProvider(estoqueRepository)),
          ChangeNotifierProvider(create: (_) => PontoProvider(pontoRepository)),
        ],
        child: const ChronosPulseApp(),
      ),
    );

    expect(find.text('Chronos Pulse'), findsWidgets);
    expect(find.text('Acessar Sistema'), findsOneWidget);
    expect(find.text('Gestão Pública Integrada • Ponto & Almoxarifado'), findsOneWidget);
  });
}

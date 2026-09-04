import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/core/theme/theme_provider.dart';
import 'package:chronos_pulse_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:chronos_pulse_app/features/auth/data/repositories/auth_repository.dart';
import 'package:chronos_pulse_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:chronos_pulse_app/features/colaborador/data/datasources/colaborador_remote_datasource.dart';
import 'package:chronos_pulse_app/features/colaborador/data/repositories/colaborador_repository.dart';
import 'package:chronos_pulse_app/features/colaborador/presentation/providers/colaborador_provider.dart';
import 'package:chronos_pulse_app/features/estoque/data/datasources/estoque_remote_datasource.dart';
import 'package:chronos_pulse_app/features/estoque/data/repositories/estoque_repository.dart';
import 'package:chronos_pulse_app/features/estoque/presentation/providers/estoque_provider.dart';
import 'package:chronos_pulse_app/features/ponto/data/datasources/ponto_local_datasource.dart';
import 'package:chronos_pulse_app/features/ponto/data/datasources/ponto_remote_datasource.dart';
import 'package:chronos_pulse_app/features/ponto/data/repositories/ponto_repository.dart';
import 'package:chronos_pulse_app/features/ponto/presentation/providers/ponto_provider.dart';
import 'package:chronos_pulse_app/main.dart';

void main() {
  testWidgets('Renderiza Landing Page inicial deslogada com descrição, módulos e botão Login', (WidgetTester tester) async {
    final dioClient = DioClient();
    final authRemoteDataSource = AuthRemoteDataSource(dioClient);
    final authRepository = AuthRepository(
      remoteDataSource: authRemoteDataSource,
      dioClient: dioClient,
    );

    final colaboradorRemoteDataSource = ColaboradorRemoteDataSource(dioClient);
    final colaboradorRepository = ColaboradorRepository(remoteDataSource: colaboradorRemoteDataSource);

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
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
          ChangeNotifierProvider(create: (_) => ColaboradorProvider(colaboradorRepository)),
          ChangeNotifierProvider(create: (_) => EstoqueProvider(estoqueRepository)),
          ChangeNotifierProvider(create: (_) => PontoProvider(pontoRepository)),
        ],
        child: const ChronosPulseApp(),
      ),
    );

    // Valida título da aplicação e slogan institucional
    expect(find.text('Chronos Pulse'), findsWidgets);
    expect(find.text('Módulos da Plataforma'), findsOneWidget);
    expect(find.text('Ponto Eletrônico & Espelho Digital'), findsOneWidget);
    expect(find.text('Almoxarifado & Gestão Contábil'), findsOneWidget);
    expect(find.text('Gestão de Servidores & RBAC'), findsOneWidget);

    // Valida presença do botão Login na Landing Page
    expect(find.byKey(const Key('landing_appbar_login_button')), findsOneWidget);

    // Clica no botão Login do topo e navega para LoginScreen
    await tester.tap(find.byKey(const Key('landing_appbar_login_button')));
    await tester.pumpAndSettle();

    // Valida que abriu a tela de login e o botão possui o texto 'Logar'
    expect(find.text('Logar'), findsOneWidget);
    expect(find.text('Acessar Sistema'), findsNothing);
    expect(find.byType(TextFormField), findsNWidgets(2)); // CPF e Senha
  });
}

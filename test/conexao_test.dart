import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:chronos_pulse_app/core/network/conexao_service.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/core/security/device_token_store.dart';
import 'package:chronos_pulse_app/core/theme/theme_provider.dart';
import 'package:chronos_pulse_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:chronos_pulse_app/features/auth/data/repositories/auth_repository.dart';
import 'package:chronos_pulse_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:chronos_pulse_app/features/auth/presentation/screens/login_screen.dart';
import 'package:chronos_pulse_app/features/home_deslogada/presentation/screens/home_deslogada_screen.dart';

/// Store em memória (sem Keystore) para simular presença/ausência de vínculo.
DeviceTokenStore fakeStore({bool comVinculo = false}) {
  final mem = <String, String>{};
  if (comVinculo) {
    mem[DeviceTokenStore.chaveToken] = 'token-teste';
    mem[DeviceTokenStore.chaveCpcId] = 'cpc-1';
    mem[DeviceTokenStore.chaveNome] = 'Teste';
    mem[DeviceTokenStore.chaveExpiraEm] = DateTime.now()
        .toUtc()
        .add(const Duration(days: 1))
        .millisecondsSinceEpoch
        .toString();
  }
  return DeviceTokenStore(
    ler: (k) async => mem[k],
    gravar: (k, v) async => mem[k] = v,
    remover: (k) async => mem.remove(k),
  );
}

ConexaoService get _online => ConexaoService(ping: () async => true);
ConexaoService get _offline => ConexaoService(ping: () async => false);

void main() {
  group('HomeDeslogadaScreen — diagnóstico de conexão na abertura', () {
    Future<void> pumpHome(
      WidgetTester tester, {
      required ConexaoService conexao,
      required DeviceTokenStore store,
    }) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                HomeDeslogadaScreen(conexao: conexao, store: store),
          ),
          GoRoute(
            path: '/ponto/dispositivo',
            builder: (context, state) =>
                const Scaffold(body: Text('DESTINO_PONTO')),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) =>
                const Scaffold(body: Text('DESTINO_LOGIN')),
          ),
        ],
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump(); // executa a cadeia assíncrona do diagnóstico
      await tester.pumpAndSettle(); // renderiza aviso/rota
    }

    testWidgets('online: sem aviso e permanece na home', (tester) async {
      await pumpHome(tester, conexao: _online, store: fakeStore());
      expect(find.byType(HomeDeslogadaScreen), findsOneWidget);
      expect(find.text('Sem conexão!'), findsNothing);
      expect(find.text('DESTINO_PONTO'), findsNothing);
    });

    testWidgets('offline sem vínculo: toast "Sem conexão!" e fica na home',
        (tester) async {
      await pumpHome(tester, conexao: _offline, store: fakeStore());
      expect(find.text('Sem conexão!'), findsOneWidget);
      expect(find.byType(HomeDeslogadaScreen), findsOneWidget);
      expect(find.text('DESTINO_PONTO'), findsNothing);
      // Drena o timer de expiração do snackbar antes de encerrar o teste.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'offline com vínculo: toast "Sem conexão!" e redireciona para '
        '/ponto/dispositivo', (tester) async {
      await pumpHome(
        tester,
        conexao: _offline,
        store: fakeStore(comVinculo: true),
      );
      expect(find.text('Sem conexão!'), findsOneWidget);
      expect(find.text('DESTINO_PONTO'), findsOneWidget);
      expect(find.byType(HomeDeslogadaScreen), findsNothing);
      // Drena o timer de expiração do snackbar antes de encerrar o teste.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });

  group('LoginScreen — diagnóstico de conexão', () {
    Future<void> pumpLogin(
      WidgetTester tester, {
      required ConexaoService conexao,
      required DeviceTokenStore store,
    }) async {
      final dioClient = DioClient();
      final repository = AuthRepository(
        remoteDataSource: AuthRemoteDataSource(dioClient),
        dioClient: dioClient,
      );
      final authProvider = AuthProvider(repository);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp(home: LoginScreen(conexao: conexao, store: store)),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();
    }

    testWidgets('online: sem aviso de conexão', (tester) async {
      await pumpLogin(tester, conexao: _online, store: fakeStore());
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Sem conexão!'), findsNothing);
    });

    testWidgets(
        'offline: toast "Sem conexão!" sem redirecionar (usuário escolheu logar)',
        (tester) async {
      await pumpLogin(
        tester,
        conexao: _offline,
        store: fakeStore(comVinculo: true),
      );
      expect(find.text('Sem conexão!'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('DESTINO_PONTO'), findsNothing);
      // Drena o timer de expiração do snackbar antes de encerrar o teste.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });
}

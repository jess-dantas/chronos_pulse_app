import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/features/admin/data/datasources/admin_auth_remote_datasource.dart';
import 'package:chronos_pulse_app/features/admin/data/repositories/admin_auth_repository_impl.dart';
import 'package:chronos_pulse_app/features/admin/presentation/providers/admin_auth_provider.dart';
import 'package:chronos_pulse_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:chronos_pulse_app/features/auth/data/models/usuario_model.dart';
import 'package:chronos_pulse_app/features/auth/data/repositories/auth_repository.dart';
import 'package:chronos_pulse_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:chronos_pulse_app/features/perfil/presentation/screens/perfil_screen.dart';

/// AuthProvider com sessão injetada (mesmo padrão de shell_layout_test.dart),
/// sem tocar em rede/armazenamento nativo.
class _FakeAuth extends AuthProvider {
  _FakeAuth()
      : super(AuthRepository(
          remoteDataSource: AuthRemoteDataSource(DioClient()),
          dioClient: DioClient(),
        ));

  UsuarioModel? _sessao;
  bool logoutChamado = false;

  void definirSessao(UsuarioModel usuario) => _sessao = usuario;

  @override
  UsuarioModel? get usuario => _sessao;

  @override
  bool get isAuthenticated => _sessao != null && _sessao!.token.isNotEmpty;

  @override
  Future<void> logout() async {
    logoutChamado = true;
    _sessao = null;
    notifyListeners();
  }
}

UsuarioModel _usuario() => UsuarioModel(
      token: 'token',
      refreshToken: 'refresh',
      tipo: 'Bearer',
      nome: 'Maria Colaboradora',
      email: 'maria@example.com',
      cpf: '12345678901',
      role: 'COLABORADOR',
      modulos: const ['PONTO'],
    );

void main() {
  late _FakeAuth auth;
  late AdminAuthProvider adminAuth;

  setUp(() {
    auth = _FakeAuth();
    adminAuth = AdminAuthProvider(
      AdminAuthRepositoryImpl(AdminAuthRemoteDataSource(DioClient())),
      DioClient(),
    );
  });

  Future<void> pumpTela(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<AdminAuthProvider>.value(value: adminAuth),
        ],
        child: const MaterialApp(home: PerfilScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('exibe a troca de foto nos detalhes do perfil', (tester) async {
    auth.definirSessao(_usuario());
    await pumpTela(tester);

    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Alterar foto'), findsOneWidget);
    expect(find.byTooltip('Alterar foto de perfil'), findsOneWidget);
    expect(find.text('Maria Colaboradora'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
  });

  testWidgets('mantém a ação Sair logo abaixo dos detalhes do perfil',
      (tester) async {
    auth.definirSessao(_usuario());
    await pumpTela(tester);

    // O card de vínculo de dispositivo cresceu a lista: "Sair" pode ficar
    // fora da viewport inicial (o ListView só monta o que é visível).
    final sair = find.text('Sair');
    await tester.scrollUntilVisible(sair, 400);
    await tester.pumpAndSettle();
    expect(sair, findsOneWidget);

    // A foto vem antes de "Sair" (mesmo card/rolagem).
    final alterarFoto = find.text('Alterar foto');
    expect(tester.getTopLeft(alterarFoto).dy,
        lessThan(tester.getTopLeft(sair).dy));
  });

  testWidgets('Sair pede confirmação e encerra a sessão', (tester) async {
    auth.definirSessao(_usuario());
    await pumpTela(tester);

    final sair = find.text('Sair');
    await tester.scrollUntilVisible(sair, 400);
    await tester.pumpAndSettle();
    await tester.ensureVisible(sair);
    await tester.pumpAndSettle();
    await tester.tap(sair);
    await tester.pumpAndSettle();

    expect(find.text('Sair da sessão'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Sim'));
    await tester.pumpAndSettle();

    expect(auth.logoutChamado, isTrue);
    expect(auth.usuario, isNull);
  });
}

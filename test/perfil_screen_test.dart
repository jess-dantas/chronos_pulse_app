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
  String? novaSenhaChamada;

  void definirSessao(UsuarioModel usuario) => _sessao = usuario;

  @override
  Future<bool> alterarSenha({required String novaSenha}) async {
    novaSenhaChamada = novaSenha;
    return true;
  }

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
    // Viewport alta o bastante para "Alterar foto" (topo) e "Sair" (fim)
    // ficarem montados ao mesmo tempo (o ListView só monta o que é visível).
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    auth.definirSessao(_usuario());
    await pumpTela(tester);

    final sair = find.text('Sair');
    final alterarFoto = find.text('Alterar foto');
    expect(sair, findsOneWidget);
    expect(alterarFoto, findsOneWidget);
    expect(tester.getTopLeft(alterarFoto).dy, lessThan(tester.getTopLeft(sair).dy));
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

  testWidgets('Alterar senha dispensa senha atual e pede confirmação',
      (tester) async {
    auth.definirSessao(_usuario());
    await pumpTela(tester);

    final alterar = find.text('Alterar senha');
    await tester.scrollUntilVisible(alterar, 400);
    await tester.pumpAndSettle();
    await tester.ensureVisible(alterar);
    await tester.pumpAndSettle();
    await tester.tap(alterar);
    await tester.pumpAndSettle();

    expect(find.text('Senha atual'), findsNothing);
    expect(find.text('Nova senha'), findsOneWidget);
    expect(find.text('Confirmar nova senha'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Nova@1234');
    await tester.enterText(find.byType(TextFormField).at(1), 'Nova@1234');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Certeza de alterar senha?'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Desistir'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Alterar'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Desistir'));
    await tester.pumpAndSettle();
    expect(auth.novaSenhaChamada, isNull);
    expect(find.text('Nova senha'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Alterar'));
    await tester.pumpAndSettle();

    expect(auth.novaSenhaChamada, 'Nova@1234');
    expect(find.text('Senha alterada com sucesso.'), findsOneWidget);
    expect(find.text('Nova senha'), findsNothing);
  });
}

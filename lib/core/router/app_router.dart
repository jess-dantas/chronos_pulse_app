import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/app_modo.dart';
import '../../features/admin/presentation/screens/admin_alterar_senha_screen.dart';
import '../../features/admin/presentation/screens/admin_auth_screen.dart';
import '../../features/admin/presentation/screens/admin_biometric_gate_screen.dart';
import '../../features/admin/presentation/screens/admin_bootstrap_screen.dart';
import '../../features/admin/presentation/screens/admin_contratos_screen.dart';
import '../../features/admin/presentation/screens/admin_recover_screen.dart';
import '../../features/admin/presentation/screens/admin_reset_senha_screen.dart';
import '../../features/admin/presentation/screens/admin_recovery_codes_screen.dart';
import '../../features/admin/presentation/screens/admin_setup_2fa_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_empresas_screen.dart';
import '../../features/admin/presentation/screens/admin_modulos_screen.dart';
import '../../features/admin/presentation/screens/admin_seguranca_screen.dart';
import '../../features/admin/presentation/providers/admin_auth_provider.dart';
import '../../features/ponto/presentation/screens/aprovacao_ajustes_screen.dart';
import '../../features/ponto/presentation/screens/modo_ponto_screen.dart';
import '../../features/auth/data/models/usuario_model.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/biometric_gate_screen.dart';
import '../../features/auth/presentation/screens/cadastrar_empresa_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/perfil_two_factor_screen.dart';
import '../../features/auth/presentation/screens/two_factor_login_screen.dart';
import '../../features/auth/presentation/screens/recuperar_senha_screen.dart';
import '../../features/colaborador/presentation/screens/colaboradores_screen.dart';
import '../../features/compras/presentation/screens/compras_home_screen.dart';
import '../../features/estoque/presentation/screens/estoque_home_screen.dart';
import '../../features/frota/presentation/screens/frota_home_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home_deslogada/presentation/screens/home_deslogada_screen.dart';
import '../../features/landing/presentation/screens/landing_screen.dart';
import '../../features/leads/presentation/screens/admin_leads_screen.dart';
import '../../features/licitacoes/presentation/screens/licitacoes_home_screen.dart';
import '../../features/navigation/presentation/screens/admin_shell.dart';
import '../../features/navigation/presentation/screens/main_shell.dart';
import '../../features/patrimonio/presentation/screens/patrimonio_home_screen.dart';
import '../../features/perfil/presentation/screens/perfil_screen.dart';
import '../../features/ponto/presentation/screens/home_ponto_screen.dart';
import '../../features/privacidade/presentation/screens/privacidade_screen.dart';
import '../../features/protocolo/presentation/screens/protocolo_home_screen.dart';
import '../../features/titularidade/presentation/screens/transferir_titularidade_screen.dart';
import '../../features/transparencia/presentation/screens/transparencia_home_screen.dart';

/// Roteamento centralizado com URLs limpas (`/`, `/login`, `/painel/<modulo>`, `/admin`).
class AppRouter {
  AppRouter._();

  static const String rotaInicial = '/';

  /// Gate biométrico de abertura (login por biometria): toda sessão
  /// RESTORADA ao abrir o app passa por aqui antes de liberar o conteúdo.
  static const String rotaBiometrico = '/biometria';

  /// Gate biométrico da área AdminPlataforma (sessão admin restaurada).
  static const String rotaBiometricoAdmin = '/admin/biometria';

  /// Rota inicial (`/`) em qualquer modo — o que `/` *renderiza* é que muda:
  /// - [AppModo.cliente] (app mobile): home de ponto (botão "Bater ponto" +
  ///   "Logar") — o login fica a um toque;
  /// - [AppModo.completo] (web): landing; [AppModo.admin]: redirect cai no
  ///   `/admin/auth/login` (regra de área logo abaixo).
  static String rotaInicialPara(String modo) => rotaInicial;

  /// Ordem fixa dos módulos do painel. Cada posição corresponde ao índice
  /// do branch no [StatefulShellRoute] do `/painel` (e também à ordem da
  /// `NavigationRail` no [MainShell]).
  static const List<String> painelOrdem = [
    'home',
    'ponto',
    'aprovacao-ajustes',
    'colaboradores',
    'estoque',
    'compras',
    'licitacoes',
    'patrimonio',
    'frota',
    'protocolo',
    'transparencia',
    'privacidade',
  ];

  /// Ordem das abas do painel administrativo (`/admin`).
  static const List<String> adminOrdem = [
    'dashboard',
    'leads',
    'empresas',
    'contratos',
    'modulos',
    'senha',
    'seguranca',
  ];

  static bool podeModuloPainel(UsuarioModel usuario, String modulo) {
    if (modulo == 'home' || modulo == 'privacidade') return true;

    // Associação estrita: o módulo precisa estar na lista do usuário.
    // (Admin Empresa recebe a lista completa dos módulos contratados no login/refresh/me.)
    bool contratado(String codigo) => usuario.modulos.contains(codigo);

    // Gate por role (alinhado ao backend / rbac.md) E por módulo associado.
    return switch (modulo) {
      'ponto' =>
        (usuario.isAdminOrRh || usuario.isColaborador) && contratado('PONTO'),
      'aprovacao-ajustes' => usuario.isGestorRh && contratado('PONTO'),
      'colaboradores' =>
        usuario.isAdminOrRh && contratado('RECURSOS_HUMANOS'),
      'estoque' => usuario.temAcessoEstoque && contratado('ESTOQUE'),
      'compras' => usuario.temAcessoEstoque && contratado('COMPRAS'),
      'licitacoes' => usuario.temAcessoEstoque && contratado('LICITACOES'),
      'patrimonio' =>
        (usuario.isAdminOrRh || usuario.isColaborador) &&
            contratado('PATRIMONIO'),
      'frota' =>
        (usuario.isAdminOrRh || usuario.isColaborador) && contratado('FROTA'),
      'protocolo' =>
        (usuario.isAdminOrRh || usuario.isColaborador) &&
            contratado('PROTOCOLO'),
      'transparencia' =>
        (usuario.isAdminOrRh ||
            usuario.isColaborador ||
            usuario.acessoEstoque) &&
            contratado('TRANSPARENCIA'),
      _ => false,
    };
  }

  /// Primeira rota acessível do painel para o usuário, na ordem fixa dos módulos.
  static String primeiraRotaPainel(UsuarioModel usuario) {
    final modulo = painelOrdem.firstWhere(
      (m) => podeModuloPainel(usuario, m),
      orElse: () => 'privacidade',
    );
    return '/painel/$modulo';
  }

  static GoRouter build(
    AuthProvider authProvider,
    AdminAuthProvider adminAuthProvider, {
    // Modo do build (APP_MODE via --dart-define). O default mantém o
    // comportamento atual do app (web de produção não envia o define).
    String modo = AppModo.atual,
  }) {
    return GoRouter(
      initialLocation: rotaInicialPara(modo),
      refreshListenable: Listenable.merge([authProvider, adminAuthProvider]),
      redirect: (context, state) =>
          _redirect(authProvider, adminAuthProvider, state, modo),
      routes: [
        GoRoute(
          path: '/',
          // App cliente (mobile): home de ponto. Web/admin: landing.
          builder: (context, state) => modo == AppModo.cliente
              ? const HomeDeslogadaScreen()
              : const LandingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        // Etapa 2 do login 2FA-first (código TOTP ou OTP por e-mail).
        GoRoute(
          path: '/login/2fa',
          builder: (context, state) => const TwoFactorLoginScreen(),
        ),
        GoRoute(
          path: '/cadastro',
          builder: (context, state) => const CadastrarEmpresaScreen(),
        ),
        GoRoute(
          path: '/recuperar-senha',
          builder: (context, state) => const RecuperarSenhaScreen(),
        ),
        // Modo "bater ponto sem login" (vínculo de dispositivo + biometria).
        // Rota PÚBLICA por definição: é o único caminho autenticado sem
        // sessão (guard próprio de vínculo + biometria dentro da tela).
        GoRoute(
          path: '/ponto/dispositivo',
          builder: (context, state) => const ModoPontoScreen(),
        ),
        // Profile (acessível pelo toque no profile do rail; não é item de menu)
        GoRoute(
          path: '/perfil',
          builder: (context, state) => const PerfilScreen(),
        ),
        GoRoute(
          path: '/perfil/titularidade',
          builder: (context, state) => const TransferirTitularidadeScreen(),
        ),
        // Gestão do 2FA do colaborador (ativação via QR e desativação).
        GoRoute(
          path: '/perfil/2fa',
          builder: (context, state) => const PerfilTwoFactorScreen(),
        ),
        // Gate biométrico de abertura (login por biometria) — sessão
        // restaurada exige a biometria do aparelho antes do conteúdo.
        GoRoute(
          path: rotaBiometrico,
          builder: (context, state) => const BiometricGateScreen(),
        ),
        // Gate biométrico da área admin (sessão admin restaurada).
        GoRoute(
          path: rotaBiometricoAdmin,
          builder: (context, state) => const AdminBiometricGateScreen(),
        ),
        // Admin auth routes (públicas, não requerem autenticação)
        GoRoute(
          path: '/admin/auth/login',
          builder: (context, state) => const AdminAuthScreen(),
        ),
        GoRoute(
          path: '/admin/auth/logout',
          builder: (context, state) => const AdminAuthScreen(),
        ),
        GoRoute(
          path: '/admin/auth/bootstrap',
          builder: (context, state) => const AdminBootstrapScreen(),
        ),
        GoRoute(
          path: '/admin/auth/setup-2fa',
          builder: (context, state) => const AdminSetup2FAScreen(),
        ),
        GoRoute(
          path: '/admin/auth/codigos-recuperacao',
          builder: (context, state) => const AdminRecoveryCodesScreen(),
        ),
        GoRoute(
          path: '/admin/auth/recover',
          builder: (context, state) => const AdminRecoverScreen(),
        ),
        GoRoute(
          path: '/admin/auth/reset-senha',
          builder: (context, state) => const AdminResetSenhaScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MainShell(navigationShell: navigationShell),
          branches: [
            for (final modulo in painelOrdem)
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/painel/$modulo',
                    builder: (context, state) =>
                        _painelScreen(modulo, state.uri.queryParameters),
                  ),
                ],
              ),
          ],
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AdminShell(navigationShell: navigationShell),
          branches: [
            for (final modulo in adminOrdem)
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/admin/$modulo',
                    builder: (context, state) => _adminScreen(modulo),
                  ),
                ],
              ),
          ],
        ),
      ],
      errorBuilder: (context, state) => const _RouteErrorScreen(),
    );
  }

  static String? _redirect(
    AuthProvider auth,
    AdminAuthProvider adminAuth,
    GoRouterState state,
    String modo,
  ) {
    final location = state.matchedLocation;
    final ehModoAdmin = modo == AppModo.admin;
    final bloqueiaAdmin = modo == AppModo.cliente;

    // Login/ logout/ bootstrap/ setup/ recover do AdminPlataforma:
    // rotas separadas, sempre públicas (podem usar tempToken ou nenhum token).
    // No app-cliente elas ficam bloqueadas: a área admin vive no app Admin.
    if (location.startsWith('/admin/auth/') && !bloqueiaAdmin) {
      return null;
    }

    // App Admin (dono da plataforma): só existe /admin (+ /perfil).
    // Landing, login de cliente e painel de tenant são redirecionados.
    if (ehModoAdmin) {
      final ehAuth = location.startsWith('/admin/auth/');
      final ehGate = location == rotaBiometricoAdmin;
      final areaAdminModo =
          location == '/admin' || location.startsWith('/admin/');
      final areaPerfil =
          location == '/perfil' || location.startsWith('/perfil/');

      // Gate: sessão admin restaurada fica TRANCADA até a biometria.
      if (ehGate) {
        if (!adminAuth.isAuthenticated) return '/admin/auth/login';
        if (adminAuth.sessaoDesbloqueada) return '/admin/dashboard';
        return null;
      }
      if (!areaAdminModo && !areaPerfil) {
        return adminAuth.isAuthenticated
            ? '/admin/dashboard'
            : '/admin/auth/login';
      }
      if (areaAdminModo && !ehAuth && !adminAuth.isAuthenticated) {
        return '/admin/auth/login';
      }
      if (adminAuth.isAuthenticated &&
          !adminAuth.sessaoDesbloqueada &&
          ((areaAdminModo && !ehAuth) || areaPerfil)) {
        return rotaBiometricoAdmin;
      }
    }

    // App cliente: nenhuma rota /admin é acessível (nem deep link).
    if (bloqueiaAdmin &&
        (location == '/admin' || location.startsWith('/admin/'))) {
      return rotaInicialPara(modo);
    }

    // Modo dispositivo (bater ponto sem login): público nos dois sentidos —
    // não exige sessão e uma sessão ativa não é redirecionada para o painel
    // quando o usuário escolhe este caminho (o guard da tela decide).
    if (location == '/ponto/dispositivo') {
      return null;
    }

    // Gate biométrico de abertura (login por biometria): sessão RESTORIDA
    // exige confirmar a biometria do aparelho antes de qualquer conteúdo.
    // Login explícito por senha nasce desbloqueado (AuthProvider.login);
    // sem biometria disponível o próprio gate se libera. A área admin do
    // AdminPlataforma (separada) segue fora deste gate.
    final ehAreaAdmin = location == '/admin' || location.startsWith('/admin/');
    if (!ehAreaAdmin && !adminAuth.isAuthenticated) {
      final gateAtivo = auth.isAuthenticated && !auth.sessaoDesbloqueada;
      if (location == rotaBiometrico) {
        if (gateAtivo) return null;
        if (auth.isAuthenticated && auth.usuario != null) {
          return primeiraRotaPainel(auth.usuario!);
        }
        return rotaInicialPara(modo);
      }
      if (gateAtivo) return rotaBiometrico;
    }

    // Profile (inclui /perfil/titularidade): acessível a qualquer sessão
    // ativa (admin root ou usuário). A sub-rota de transferência é
    // exclusiva de ADMIN_EMPRESA.
    if (location.startsWith('/perfil')) {
      if (!(auth.isAuthenticated || adminAuth.isAuthenticated)) {
        return rotaInicialPara(modo);
      }
      if (location == '/perfil/titularidade') {
        final usuario = auth.usuario;
        if (usuario == null || !usuario.isAdminEmpresa) return '/perfil';
      }
      return null;
    }

    final areaAdmin = location == '/admin' || location.startsWith('/admin/');

    // Sessão AdminPlataforma (root): acesso exclusivo à área /admin.
    // Não cai no painel de usuário nem na landing (rotas não se misturam).
    if (adminAuth.isAuthenticated) {
      return areaAdmin ? null : '/admin/dashboard';
    }

    final autenticado = auth.isAuthenticated;
    final usuario = auth.usuario;

    const publicas = ['/', '/login', '/login/2fa', '/cadastro', '/recuperar-senha'];
    final areaPainel = location == '/painel' || location.startsWith('/painel/');

    if (!autenticado) {
      if (publicas.contains(location)) return null;
      return rotaInicialPara(modo);
    }

    if (usuario == null) return null;

    // Gestor da plataforma navega apenas na área administrativa.
    if (usuario.isGestorPlataforma) {
      if (areaAdmin) return null;
      return '/admin/dashboard';
    }

    if (areaPainel) {
      if (location == '/painel') {
        return primeiraRotaPainel(usuario);
      }
      final modulo = location.replaceFirst('/painel/', '');
      if (podeModuloPainel(usuario, modulo)) return null;
      return primeiraRotaPainel(usuario);
    }

    if (areaAdmin) {
      return primeiraRotaPainel(usuario);
    }

    return primeiraRotaPainel(usuario);
  }

  static Widget _painelScreen(String modulo, Map<String, String> query) {
    switch (modulo) {
      case 'home':
        return const HomeScreen();
      case 'ponto':
        // Deep link do dock mobile: /painel/ponto?aba=espelho abre a aba do
        // espelho. A key garante remontagem do estado ao trocar de aba.
        final espelho = query['aba'] == 'espelho';
        return HomePontoScreen(
          key: ValueKey('ponto-${espelho ? 'espelho' : 'bater'}'),
          abaInicial: espelho ? 1 : 0,
        );
      case 'aprovacao-ajustes':
        return const AprovacaoAjustesScreen();
      case 'colaboradores':
        return const ColaboradoresScreen();
      case 'estoque':
        return const EstoqueHomeScreen();
      case 'compras':
        return const ComprasHomeScreen();
      case 'licitacoes':
        return const LicitacoesHomeScreen();
      case 'patrimonio':
        return const PatrimonioHomeScreen();
      case 'frota':
        return const FrotaHomeScreen();
      case 'protocolo':
        return const ProtocoloHomeScreen();
      case 'transparencia':
        return const TransparenciaHomeScreen();
      case 'privacidade':
        return const PrivacidadeScreen();
      default:
        return const PrivacidadeScreen();
    }
  }

  static Widget _adminScreen(String modulo) {
    switch (modulo) {
      case 'dashboard':
        return const AdminDashboardScreen();
      case 'leads':
        return const AdminLeadsScreen();
      case 'empresas':
        return const AdminEmpresasScreen();
      case 'contratos':
        return const AdminContratosScreen();
      case 'modulos':
        return const AdminModulosScreen();
      case 'senha':
        return const AdminAlterarSenhaScreen();
      case 'seguranca':
        return const AdminSegurancaScreen();
      default:
        return const AdminDashboardScreen();
    }
  }
}

class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chronos Pulse')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Página não encontrada.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Voltar ao início'),
            ),
          ],
        ),
      ),
    );
  }
}
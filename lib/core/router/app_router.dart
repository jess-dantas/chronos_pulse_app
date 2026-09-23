import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/admin_alterar_senha_screen.dart';
import '../../features/admin/presentation/screens/admin_auth_screen.dart';
import '../../features/admin/presentation/screens/admin_bootstrap_screen.dart';
import '../../features/admin/presentation/screens/admin_contratos_screen.dart';
import '../../features/admin/presentation/screens/admin_recover_screen.dart';
import '../../features/admin/presentation/screens/admin_recovery_codes_screen.dart';
import '../../features/admin/presentation/screens/admin_setup_2fa_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_empresas_screen.dart';
import '../../features/admin/presentation/screens/admin_modulos_screen.dart';
import '../../features/admin/presentation/screens/admin_seguranca_screen.dart';
import '../../features/admin/presentation/providers/admin_auth_provider.dart';
import '../../features/ponto/presentation/screens/aprovacao_ajustes_screen.dart';
import '../../features/auth/data/models/usuario_model.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/cadastrar_empresa_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/recuperar_senha_screen.dart';
import '../../features/colaborador/presentation/screens/colaboradores_screen.dart';
import '../../features/compras/presentation/screens/compras_home_screen.dart';
import '../../features/estoque/presentation/screens/estoque_home_screen.dart';
import '../../features/frota/presentation/screens/frota_home_screen.dart';
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

  /// Ordem fixa dos módulos do painel. Cada posição corresponde ao índice
  /// do branch no [StatefulShellRoute] do `/painel` (e também à ordem da
  /// `NavigationRail` no [MainShell]).
  static const List<String> painelOrdem = [
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
    'privacidade',
  ];

  static bool podeModuloPainel(UsuarioModel usuario, String modulo) {
    if (modulo == 'privacidade') return true;

    // Associação estrita: o módulo precisa estar na lista do usuário.
    // (Admin Empresa recebe a lista completa dos módulos contratados no login/refresh/me.)
    bool contratado(String codigo) => usuario.modulos.contains(codigo);

    // Gate por role (alinhado ao backend / rbac.md) E por módulo associado.
    return switch (modulo) {
      'ponto' =>
        (usuario.isAdminOrRh || usuario.isColaborador) && contratado('PONTO'),
      'aprovacao-ajustes' =>
        usuario.isAdminOrRh && contratado('PONTO'),
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
    AdminAuthProvider adminAuthProvider,
  ) {
    return GoRouter(
      initialLocation: rotaInicial,
      refreshListenable: Listenable.merge([authProvider, adminAuthProvider]),
      redirect: (context, state) =>
          _redirect(authProvider, adminAuthProvider, state),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const LandingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/cadastro',
          builder: (context, state) => const CadastrarEmpresaScreen(),
        ),
        GoRoute(
          path: '/recuperar-senha',
          builder: (context, state) => const RecuperarSenhaScreen(),
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
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MainShell(navigationShell: navigationShell),
          branches: [
            for (final modulo in painelOrdem)
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/painel/$modulo',
                    builder: (context, state) => _painelScreen(modulo),
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
  ) {
    final location = state.matchedLocation;

    // Login/ logout/ bootstrap/ setup/ recover do AdminPlataforma:
    // rotas separadas, sempre públicas (podem usar tempToken ou nenhum token).
    if (location.startsWith('/admin/auth/')) {
      return null;
    }

    // Profile (inclui /perfil/titularidade): acessível a qualquer sessão
    // ativa (admin root ou usuário). A sub-rota de transferência é
    // exclusiva de ADMIN_EMPRESA.
    if (location.startsWith('/perfil')) {
      if (!(auth.isAuthenticated || adminAuth.isAuthenticated)) return '/';
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

    const publicas = ['/', '/login', '/cadastro', '/recuperar-senha'];
    final areaPainel = location == '/painel' || location.startsWith('/painel/');

    if (!autenticado) {
      if (publicas.contains(location)) return null;
      return '/';
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

  static Widget _painelScreen(String modulo) {
    switch (modulo) {
      case 'ponto':
        return const HomePontoScreen();
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
      case 'privacidade':
        return const PrivacidadeScreen();
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
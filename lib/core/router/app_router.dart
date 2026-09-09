import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/admin_alterar_senha_screen.dart';
import '../../features/admin/presentation/screens/admin_colaboradores_screen.dart';
import '../../features/admin/presentation/screens/admin_contratos_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_empresas_screen.dart';
import '../../features/admin/presentation/screens/admin_modulos_screen.dart';
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
import '../../features/licitacoes/presentation/screens/licitacoes_home_screen.dart';
import '../../features/navigation/presentation/screens/admin_shell.dart';
import '../../features/navigation/presentation/screens/main_shell.dart';
import '../../features/patrimonio/presentation/screens/patrimonio_home_screen.dart';
import '../../features/ponto/presentation/screens/home_ponto_screen.dart';
import '../../features/privacidade/presentation/screens/privacidade_screen.dart';
import '../../features/protocolo/presentation/screens/protocolo_home_screen.dart';
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
    'empresas',
    'colaboradores',
    'contratos',
    'modulos',
    'senha',
    'privacidade',
  ];

  static bool podeModuloPainel(UsuarioModel usuario, String modulo) {
    switch (modulo) {
      case 'ponto':
        return usuario.temModuloPonto;
      case 'colaboradores':
        return usuario.isAdminOrRh && usuario.temModuloRh;
      case 'estoque':
        return usuario.temModuloEstoque;
      case 'compras':
        return usuario.temModuloCompras;
      case 'licitacoes':
        return usuario.temModuloLicitacoes;
      case 'patrimonio':
        return usuario.temModuloPatrimonio;
      case 'frota':
        return usuario.temModuloFrota;
      case 'protocolo':
        return usuario.temModuloProtocolo;
      case 'transparencia':
        return usuario.temModuloTransparencia;
      case 'privacidade':
        return true;
      default:
        return false;
    }
  }

  /// Primeira rota acessível do painel para o usuário, na ordem fixa dos módulos.
  static String primeiraRotaPainel(UsuarioModel usuario) {
    final modulo = painelOrdem.firstWhere(
      (m) => podeModuloPainel(usuario, m),
      orElse: () => 'privacidade',
    );
    return '/painel/$modulo';
  }

  static GoRouter build(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: rotaInicial,
      refreshListenable: authProvider,
      redirect: (context, state) => _redirect(authProvider, state),
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

  static String? _redirect(AuthProvider auth, GoRouterState state) {
    final location = state.matchedLocation;
    final autenticado = auth.isAuthenticated;
    final usuario = auth.usuario;

    const publicas = ['/', '/login', '/cadastro', '/recuperar-senha'];
    final areaAdmin = location == '/admin' || location.startsWith('/admin/');
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
      case 'empresas':
        return const AdminEmpresasScreen();
      case 'colaboradores':
        return const AdminColaboradoresScreen();
      case 'contratos':
        return const AdminContratosScreen();
      case 'modulos':
        return const AdminModulosScreen();
      case 'senha':
        return const AdminAlterarSenhaScreen();
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
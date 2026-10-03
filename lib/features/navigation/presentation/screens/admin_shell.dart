import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/logout_helper.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../admin/presentation/providers/admin_auth_provider.dart';

class _AdminDestino {
  final int branchIndex;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _AdminDestino({
    required this.branchIndex,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

class AdminShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AdminShell({super.key, required this.navigationShell});

  static const Map<String, ({String label, IconData icon, IconData selected})>
      _metadados = {
    'dashboard': (
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selected: Icons.dashboard,
    ),
    'leads': (
      label: 'Leads',
      icon: Icons.mail_outline,
      selected: Icons.mail,
    ),
    'empresas': (
      label: 'Empresas',
      icon: Icons.business_outlined,
      selected: Icons.business,
    ),
    'contratos': (
      label: 'Contratos',
      icon: Icons.description_outlined,
      selected: Icons.description,
    ),
    'modulos': (
      label: 'Módulos',
      icon: Icons.widgets_outlined,
      selected: Icons.widgets,
    ),
    'senha': (
      label: 'Alterar Senha',
      icon: Icons.password_outlined,
      selected: Icons.password,
    ),
    'seguranca': (
      label: 'Segurança',
      icon: Icons.security_outlined,
      selected: Icons.security,
    ),
  };

  /// Único branch destacável da dock mobile: o Dashboard.
  static int get _branchHome => AppRouter.adminOrdem.indexOf('dashboard');

  List<_AdminDestino> _destinos() {
    return List.generate(
      AppRouter.adminOrdem.length,
      (i) {
        final slug = AppRouter.adminOrdem[i];
        final meta = _metadados[slug]!;
        return _AdminDestino(
          branchIndex: i,
          label: meta.label,
          icon: meta.icon,
          selectedIcon: meta.selected,
        );
      },
    );
  }

  /// Dock mobile do admin (espelho do `_dockMobile` do MainShell): 3 itens
  /// fixos — Home (Dashboard), Menu (abre o drawer com as demais seções) e
  /// Perfil. `Builder` mantém o context DENTRO do Scaffold para o item
  /// Menu chamar `Scaffold.of(dockContext).openDrawer()`.
  Widget _dockAdmin(BuildContext context) {
    final emHome = navigationShell.currentIndex == _branchHome;
    return Builder(
      builder: (dockContext) {
        final itens = <_DockItem>[
          _DockItem(
            label: 'Home',
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            onTap: () => navigationShell.goBranch(_branchHome),
          ),
          _DockItem(
            label: 'Menu',
            icon: Icons.menu,
            selectedIcon: Icons.menu,
            onTap: () => Scaffold.of(dockContext).openDrawer(),
          ),
          _DockItem(
            label: 'Perfil',
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            onTap: () => context.push('/perfil'),
          ),
        ];

        // Home é o único branch destacável (Menu é ação; Perfil fica fora
        // do shell). Rota de outra seção → dock sem destaque.
        if (!emHome) return _DockAdminSemDestaque(itens: itens);

        return NavigationBar(
          selectedIndex: 0,
          onDestinationSelected: (i) => itens[i].onTap(),
          destinations: itens
              .map(
                (d) => NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon, color: Colors.deepPurple),
                  label: d.label,
                ),
              )
              .toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final adminAuth = context.watch<AdminAuthProvider>();
    final usuario = authProvider.usuario;
    final destinos = _destinos();
    final currentIndex = navigationShell.currentIndex;
    final posicaoAtual =
        destinos.indexWhere((d) => d.branchIndex == currentIndex);
    final selecionado = posicaoAtual >= 0 ? posicaoAtual : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        final appBar = AppBar(
          elevation: 1,
          // Sem hambúrguer: sem `automaticallyImplyLeading` o Flutter injeta
          // o DrawerButton automático quando existe drawer — o item Menu da
          // dock é o caminho oficial para abrir as seções.
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 36,
                  fit: BoxFit.contain,
                  semanticLabel: 'Logo Chronos Pulse',
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.hub, color: Colors.deepPurple),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Chronos Pulse — Admin',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          actions: [
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) => IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                tooltip: themeProvider.isDarkMode ? 'Tema Claro' : 'Tema Escuro',
                onPressed: () => themeProvider.toggleTheme(),
              ),
            ),
            if (adminAuth.isAuthenticated) ...[
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 320 : 160),
                child: Text(
                  '${(adminAuth.currentAdmin?.nomeCompleto.isNotEmpty ?? false) ? adminAuth.currentAdmin!.nomeCompleto : 'Administrador'} (Plataforma)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.onLilasSurface(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ] else if (usuario != null) ...[
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 320 : 160),
                child: Text(
                  '${usuario.nome.isNotEmpty ? usuario.nome : 'Admin'} (${usuario.role})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.onLilasSurface(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ],
        );

        Future<void> encerrarSessao() => encerrarSessaoConfirmada(context);

        String nomeExibicao() {
          if (adminAuth.isAuthenticated) {
            return (adminAuth.currentAdmin?.nomeCompleto.isNotEmpty ?? false)
                ? adminAuth.currentAdmin!.nomeCompleto
                : 'Administrador';
          }
          if (usuario != null && usuario.nome.isNotEmpty) return usuario.nome;
          return 'Administrador';
        }

        final rail = NavigationRail(
          selectedIndex: selecionado,
          onDestinationSelected: (index) =>
              navigationShell.goBranch(destinos[index].branchIndex),
          labelType: NavigationRailLabelType.all,
          leading: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Icon(
              Icons.admin_panel_settings,
              size: 20,
              color: Colors.deepPurple,
            ),
          ),
          destinations: destinos
              .map(
                (d) => NavigationRailDestination(
                  icon: Icon(d.icon, size: 20),
                  selectedIcon: Icon(
                    d.selectedIcon,
                    size: 20,
                    color: Colors.deepPurple,
                  ),
                  label: Text(d.label, style: const TextStyle(fontSize: 11)),
                ),
              )
              .toList(),
        );

        /// Bloco fixo no rodapé do rail: profile (toque → /perfil) e,
        /// abaixo dele, o botão de sair.
        Widget blocoInferior() {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => context.push('/perfil'),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      children: [
                        UserAvatar(
                          nome: nomeExibicao(),
                          icone: Icons.admin_panel_settings,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nomeExibicao(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Plataforma',
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                IconButton(
                  icon: const Icon(Icons.logout, size: 20),
                  tooltip: 'Encerrar Sessão',
                  onPressed: () => encerrarSessao(),
                ),
              ],
            ),
          );
        }

        if (isWide) {
          return Scaffold(
            appBar: appBar,
            body: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Column(
                    children: [
                      Expanded(child: rail),
                      blocoInferior(),
                    ],
                  ),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: navigationShell),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: appBar,
          drawer: _MenuAdmin(
            destinos: destinos,
            branchAtual: currentIndex,
            onNavegar: (destino) =>
                navigationShell.goBranch(destino.branchIndex),
            onPerfil: () => context.push('/perfil'),
            onSair: () => encerrarSessao(),
          ),
          body: navigationShell,
          bottomNavigationBar: _dockAdmin(context),
        );
      },
    );
  }
}

/// Item da dock mobile do admin (espelho do `_DockItem` do MainShell).
class _DockItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final VoidCallback onTap;

  const _DockItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.onTap,
  });
}

/// Drawer do layout estreito com as seções do admin, atalho de perfil e
/// sair — espelho do `_MenuLateral` do MainShell. Aberto pelo item Menu
/// da dock (não há mais hambúrguer no AppBar).
class _MenuAdmin extends StatelessWidget {
  final List<_AdminDestino> destinos;
  final int branchAtual;
  final void Function(_AdminDestino destino) onNavegar;
  final VoidCallback onPerfil;
  final VoidCallback onSair;

  const _MenuAdmin({
    required this.destinos,
    required this.branchAtual,
    required this.onNavegar,
    required this.onPerfil,
    required this.onSair,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const ListTile(
              leading: Icon(
                Icons.admin_panel_settings,
                color: Colors.deepPurple,
              ),
              title: Text(
                'Chronos Pulse — Admin',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                children: [
                  for (final destino in destinos)
                    ListTile(
                      leading: Icon(destino.icon),
                      title: Text(destino.label),
                      selected: destino.branchIndex == branchAtual,
                      onTap: () {
                        Navigator.pop(context);
                        onNavegar(destino);
                      },
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.pop(context);
                onPerfil();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Encerrar Sessão'),
              onTap: () {
                Navigator.pop(context);
                onSair();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Dock do Admin sem item destacado (rota fora do dashboard, ex.: Contratos,
/// alcançada pelo drawer). Mesmo visual da NavigationBar, só que sem
/// indicador de seleção — espelho do `_DockSemDestaque` do MainShell.
class _DockAdminSemDestaque extends StatelessWidget {
  final List<_DockItem> itens;

  const _DockAdminSemDestaque({required this.itens});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 6,
      color: scheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (final item in itens)
                Expanded(
                  child: InkWell(
                    onTap: item.onTap,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item.icon, color: scheme.onSurfaceVariant),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
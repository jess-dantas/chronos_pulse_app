import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/dialogs/confirm_logout_dialog.dart';
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
              const Text(
                'Chronos Pulse — Admin',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
              Text(
                '${(adminAuth.currentAdmin?.nomeCompleto.isNotEmpty ?? false) ? adminAuth.currentAdmin!.nomeCompleto : 'Administrador'} (Plataforma)',
                style: TextStyle(
                  color: AppTheme.onLilasSurface(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 16),
            ] else if (usuario != null) ...[
              Text(
                '${usuario.nome.isNotEmpty ? usuario.nome : 'Admin'} (${usuario.role})',
                style: TextStyle(
                  color: AppTheme.onLilasSurface(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 16),
            ],
          ],
        );

        Future<void> encerrarSessao() async {
          final confirmado = await ConfirmLogoutDialog.show(context);
          if (confirmado != true || !context.mounted) return;
          final admin = context.read<AdminAuthProvider>();
          final auth = context.read<AuthProvider>();
          if (admin.isAuthenticated) admin.logout();
          if (auth.isAuthenticated) auth.logout();
        }

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
          body: navigationShell,
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NavigationBar(
                selectedIndex: selecionado,
                onDestinationSelected: (index) =>
                    navigationShell.goBranch(destinos[index].branchIndex),
                destinations: destinos
                    .map(
                      (d) => NavigationDestination(
                        icon: Icon(d.icon),
                        selectedIcon:
                            Icon(d.selectedIcon, color: Colors.deepPurple),
                        label: d.label,
                      ),
                    )
                    .toList(),
              ),
              Material(
                elevation: 6,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        UserAvatar(
                          nome: nomeExibicao(),
                          icone: Icons.admin_panel_settings,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${nomeExibicao()} (Plataforma)',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout),
                          tooltip: 'Encerrar Sessão',
                          onPressed: () => encerrarSessao(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
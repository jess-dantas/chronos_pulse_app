import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

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
    'empresas': (
      label: 'Empresas',
      icon: Icons.business_outlined,
      selected: Icons.business,
    ),
    'colaboradores': (
      label: 'Colaboradores',
      icon: Icons.people_outline,
      selected: Icons.people,
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
    'privacidade': (
      label: 'Privacidade',
      icon: Icons.privacy_tip_outlined,
      selected: Icons.privacy_tip,
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
            if (usuario != null) ...[
              Chip(
                avatar: const Icon(Icons.admin_panel_settings, size: 18),
                label: Text(
                  '${usuario.nome.isNotEmpty ? usuario.nome : 'Admin'} (${usuario.role})',
                ),
                backgroundColor: AppTheme.lilasSurface(context, lightAlpha: 0.08),
              ),
              const SizedBox(width: 12),
            ],
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Encerrar Sessão',
              onPressed: () => authProvider.logout(),
            ),
            const SizedBox(width: 16),
          ],
        );

        final rail = NavigationRail(
          selectedIndex: selecionado,
          onDestinationSelected: (index) =>
              navigationShell.goBranch(destinos[index].branchIndex),
          labelType: NavigationRailLabelType.all,
          leading: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Icon(Icons.admin_panel_settings, color: Colors.deepPurple),
          ),
          destinations: destinos
              .map(
                (d) => NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon, color: Colors.deepPurple),
                  label: Text(d.label),
                ),
              )
              .toList(),
        );

        if (isWide) {
          return Scaffold(
            appBar: appBar,
            body: Row(
              children: [
                rail,
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: navigationShell),
              ],
            ),
          );
        }

        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: NavigationBar(
            selectedIndex: selecionado,
            onDestinationSelected: (index) =>
                navigationShell.goBranch(destinos[index].branchIndex),
            destinations: destinos
                .map(
                  (d) => NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon, color: Colors.deepPurple),
                    label: d.label,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}
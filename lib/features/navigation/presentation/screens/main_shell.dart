import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/data/models/usuario_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class _ShellDestino {
  final int branchIndex;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _ShellDestino({
    required this.branchIndex,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  static const Map<String, ({String label, IconData icon, IconData selected})>
      _metadados = {
    'ponto': (label: 'Ponto', icon: Icons.fingerprint, selected: Icons.fingerprint),
    'colaboradores': (
      label: 'Colaboradores',
      icon: Icons.people_outline,
      selected: Icons.people,
    ),
    'estoque': (
      label: 'Estoque',
      icon: Icons.inventory_2_outlined,
      selected: Icons.inventory_2,
    ),
    'compras': (
      label: 'Compras',
      icon: Icons.shopping_cart_outlined,
      selected: Icons.shopping_cart,
    ),
    'licitacoes': (
      label: 'Licitações',
      icon: Icons.gavel_outlined,
      selected: Icons.gavel,
    ),
    'patrimonio': (
      label: 'Patrimônio',
      icon: Icons.inventory_outlined,
      selected: Icons.inventory,
    ),
    'frota': (
      label: 'Frota',
      icon: Icons.local_shipping_outlined,
      selected: Icons.local_shipping,
    ),
    'protocolo': (
      label: 'Protocolo',
      icon: Icons.assignment_outlined,
      selected: Icons.assignment,
    ),
    'transparencia': (
      label: 'Transparência',
      icon: Icons.public_outlined,
      selected: Icons.public,
    ),
    'privacidade': (
      label: 'Privacidade',
      icon: Icons.privacy_tip_outlined,
      selected: Icons.privacy_tip,
    ),
  };

  List<_ShellDestino> _destinos(UsuarioModel? usuario) {
    if (usuario == null) return const [];
    final destinos = <_ShellDestino>[];
    for (var i = 0; i < AppRouter.painelOrdem.length; i++) {
      final slug = AppRouter.painelOrdem[i];
      final meta = _metadados[slug]!;
      if (AppRouter.podeModuloPainel(usuario, slug)) {
        destinos.add(
          _ShellDestino(
            branchIndex: i,
            label: meta.label,
            icon: meta.icon,
            selectedIcon: meta.selected,
          ),
        );
      }
    }
    return destinos;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final usuario = authProvider.usuario;
    final destinos = _destinos(usuario);
    final currentIndex = navigationShell.currentIndex;
    final posicaoAtual =
        destinos.indexWhere((d) => d.branchIndex == currentIndex);
    final selecionado = posicaoAtual >= 0 ? posicaoAtual : 0;

    final aba = _AbaShell(
      destinos: destinos,
      selecionado: selecionado,
      onSelecionado: (i) =>
          navigationShell.goBranch(destinos[i].branchIndex),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        final appBar = _construirAppBar(context, authProvider, usuario);

        if (isWide) {
          return Scaffold(
            appBar: appBar,
            body: Row(
              children: [
                if (destinos.length > 1) ...[
                  NavigationRail(
                    selectedIndex: selecionado,
                    onDestinationSelected: aba.onSelecionado,
                    labelType: NavigationRailLabelType.all,
                    leading: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Icon(Icons.menu_open, color: Colors.deepPurple),
                    ),
                    destinations: aba.destinationsRail,
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                ],
                Expanded(child: navigationShell),
              ],
            ),
          );
        }

        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: destinos.length > 1
              ? NavigationBar(
                  selectedIndex: selecionado,
                  onDestinationSelected: aba.onSelecionado,
                  destinations: aba.destinationsBar,
                )
              : null,
        );
      },
    );
  }

  PreferredSizeWidget _construirAppBar(
    BuildContext context,
    AuthProvider authProvider,
    UsuarioModel? usuario,
  ) {
    return AppBar(
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
            'Chronos Pulse Suite',
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
            avatar: const Icon(Icons.account_circle, size: 18),
            label: Text(
              '${usuario.nome.isNotEmpty ? usuario.nome : usuario.role} (${usuario.role})',
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
  }
}

class _AbaShell {
  final List<_ShellDestino> destinos;
  final int selecionado;
  final ValueChanged<int> onSelecionado;

  _AbaShell({
    required this.destinos,
    required this.selecionado,
    required this.onSelecionado,
  });

  List<NavigationRailDestination> get destinationsRail => destinos
      .map(
        (d) => NavigationRailDestination(
          icon: Icon(d.icon),
          selectedIcon:
              Icon(d.selectedIcon, color: Colors.deepPurple),
          label: Text(d.label),
        ),
      )
      .toList();

  List<NavigationDestination> get destinationsBar => destinos
      .map(
        (d) => NavigationDestination(
          icon: Icon(d.icon),
          selectedIcon: Icon(d.selectedIcon, color: Colors.deepPurple),
          label: d.label,
        ),
      )
      .toList();
}
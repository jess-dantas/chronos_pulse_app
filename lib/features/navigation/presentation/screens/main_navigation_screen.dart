import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../colaborador/presentation/screens/colaboradores_screen.dart';
import '../../../estoque/presentation/screens/estoque_home_screen.dart';
import '../../../frota/presentation/screens/frota_home_screen.dart';
import '../../../patrimonio/presentation/screens/patrimonio_home_screen.dart';
import '../../../ponto/presentation/screens/home_ponto_screen.dart';
import '../../../protocolo/presentation/screens/protocolo_home_screen.dart';

class _NavigationItem {
  final Widget screen;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _NavigationItem({
    required this.screen,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final usuario = authProvider.usuario;

    final List<_NavigationItem> items = [];

    // 1. Módulo de Ponto Eletrônico (usuários com módulo PONTO ativo)
    if (usuario != null && usuario.temModuloPonto) {
      items.add(
        const _NavigationItem(
          screen: HomePontoScreen(),
          label: 'Ponto',
          icon: Icons.fingerprint,
          selectedIcon: Icons.fingerprint,
        ),
      );
    }

    // 2. Gestão de Colaboradores (Admin Plataforma, Admin Empresa e Gestor de RH com módulo RH ativo)
    if (usuario != null && usuario.isAdminOrRh && usuario.temModuloRh) {
      items.add(
        const _NavigationItem(
          screen: ColaboradoresScreen(),
          label: 'Colaboradores',
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
        ),
      );
    }

    // 3. Módulo de Estoque e Almoxarifado (usuários com módulo ESTOQUE ativo)
    if (usuario != null && usuario.temModuloEstoque) {
      items.add(
        const _NavigationItem(
          screen: EstoqueHomeScreen(),
          label: 'Estoque',
          icon: Icons.inventory_2_outlined,
          selectedIcon: Icons.inventory_2,
        ),
      );
    }

    // 4. Módulo de Patrimônio (usuários com módulo PATRIMONIO ativo)
    if (usuario != null && usuario.temModuloPatrimonio) {
      items.add(
        const _NavigationItem(
          screen: PatrimonioHomeScreen(),
          label: 'Patrimônio',
          icon: Icons.inventory_outlined,
          selectedIcon: Icons.inventory,
        ),
      );
    }

    // 5. Módulo de Frota (usuários com módulo FROTA ativo)
    if (usuario != null && usuario.temModuloFrota) {
      items.add(
        const _NavigationItem(
          screen: FrotaHomeScreen(),
          label: 'Frota',
          icon: Icons.local_shipping_outlined,
          selectedIcon: Icons.local_shipping,
        ),
      );
    }

    // 6. Módulo de Protocolo (usuários com módulo PROTOCOLO ativo)
    if (usuario != null && usuario.temModuloProtocolo) {
      items.add(
        const _NavigationItem(
          screen: ProtocoloHomeScreen(),
          label: 'Protocolo',
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment,
        ),
      );
    }

    final safeIndex = (_currentIndex < items.length) ? _currentIndex : 0;
    final screens = items.map((e) => e.screen).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        if (isWide) {
          // Layout Web / Desktop com NavigationRail lateral
          return Scaffold(
            appBar: AppBar(
              elevation: 1,
              title: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 36,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.hub, color: Colors.deepPurple),
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
                    label: Text('${usuario.nome.isNotEmpty ? usuario.nome : usuario.role} (${usuario.role})'),
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
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
            ),
            body: Row(
              children: [
                if (items.length > 1) ...[
                  NavigationRail(
                    selectedIndex: safeIndex,
                    onDestinationSelected: (index) {
                      setState(() => _currentIndex = index);
                    },
                    labelType: NavigationRailLabelType.all,
                    leading: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Icon(Icons.menu_open, color: Colors.deepPurple),
                    ),
                    destinations: items
                        .map(
                          (item) => NavigationRailDestination(
                            icon: Icon(item.icon),
                            selectedIcon: Icon(item.selectedIcon, color: Colors.deepPurple),
                            label: Text(item.label),
                          ),
                        )
                        .toList(),
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                ],
                Expanded(
                  child: IndexedStack(
                    index: safeIndex,
                    children: screens,
                  ),
                ),
              ],
            ),
          );
        }

        // Layout Mobile com BottomNavigationBar
        return Scaffold(
          body: IndexedStack(
            index: safeIndex,
            children: screens,
          ),
          bottomNavigationBar: items.length > 1
              ? NavigationBar(
                  selectedIndex: safeIndex,
                  onDestinationSelected: (index) {
                    setState(() => _currentIndex = index);
                  },
                  destinations: items
                      .map(
                        (item) => NavigationDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.selectedIcon, color: Colors.deepPurple),
                          label: item.label,
                        ),
                      )
                      .toList(),
                )
              : null,
        );
      },
    );
  }
}

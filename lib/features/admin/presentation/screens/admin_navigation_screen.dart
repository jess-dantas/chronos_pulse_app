import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/admin_empresas_screen.dart';
import '../screens/admin_colaboradores_screen.dart';
import '../screens/admin_contratos_screen.dart';
import '../screens/admin_alterar_senha_screen.dart';

class _AdminNavItem {
  final Widget screen;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _AdminNavItem({
    required this.screen,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

class AdminNavigationScreen extends StatefulWidget {
  const AdminNavigationScreen({super.key});

  @override
  State<AdminNavigationScreen> createState() => _AdminNavigationScreenState();
}

class _AdminNavigationScreenState extends State<AdminNavigationScreen> {
  int _currentIndex = 0;

  static const List<_AdminNavItem> _items = [
    _AdminNavItem(
      screen: AdminDashboardScreen(),
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    _AdminNavItem(
      screen: AdminEmpresasScreen(),
      label: 'Empresas',
      icon: Icons.business_outlined,
      selectedIcon: Icons.business,
    ),
    _AdminNavItem(
      screen: AdminColaboradoresScreen(),
      label: 'Colaboradores',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
    ),
    _AdminNavItem(
      screen: AdminContratosScreen(),
      label: 'Contratos',
      icon: Icons.description_outlined,
      selectedIcon: Icons.description,
    ),
    _AdminNavItem(
      screen: AdminAlterarSenhaScreen(),
      label: 'Alterar Senha',
      icon: Icons.password_outlined,
      selectedIcon: Icons.password,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final usuario = authProvider.usuario;

    final safeIndex = (_currentIndex < _items.length) ? _currentIndex : 0;
    final screens = _items.map((e) => e.screen).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        if (isWide) {
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
                    label: Text('${usuario.nome.isNotEmpty ? usuario.nome : 'Admin'} (${usuario.role})'),
                    backgroundColor: Colors.deepPurple.withOpacity(0.08),
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
                NavigationRail(
                  selectedIndex: safeIndex,
                  onDestinationSelected: (index) {
                    setState(() => _currentIndex = index);
                  },
                  labelType: NavigationRailLabelType.all,
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Icon(Icons.admin_panel_settings, color: Colors.deepPurple),
                  ),
                  destinations: _items
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

        // Layout Mobile
        return Scaffold(
          body: IndexedStack(
            index: safeIndex,
            children: screens,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: safeIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            destinations: _items
                .map(
                  (item) => NavigationDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon, color: Colors.deepPurple),
                    label: item.label,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

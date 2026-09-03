import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../estoque/presentation/screens/estoque_home_screen.dart';
import '../../../ponto/presentation/screens/home_ponto_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomePontoScreen(),
    EstoqueHomeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final usuario = authProvider.usuario;

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
                if (usuario != null) ...[
                  Chip(
                    avatar: const Icon(Icons.account_circle, size: 18),
                    label: Text('${usuario.nome} (${usuario.role})'),
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
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) {
                    setState(() => _currentIndex = index);
                  },
                  labelType: NavigationRailLabelType.all,
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Icon(Icons.menu_open, color: Colors.deepPurple),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.fingerprint),
                      selectedIcon: Icon(Icons.fingerprint, color: Colors.deepPurple),
                      label: Text('Ponto'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.inventory_2_outlined),
                      selectedIcon: Icon(Icons.inventory_2, color: Colors.deepPurple),
                      label: Text('Estoque'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
                ),
              ],
            ),
          );
        }

        // Layout Mobile com BottomNavigationBar
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.fingerprint),
                label: 'Ponto',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2),
                label: 'Estoque',
              ),
            ],
          ),
        );
      },
    );
  }
}

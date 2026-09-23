import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/dialogs/confirm_logout_dialog.dart';
import '../../../../core/widgets/dialogs/consentimento_gate.dart';
import '../../../../core/widgets/user_avatar.dart';
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
    'aprovacao-ajustes': (
      label: 'Aprovação Ajustes',
      icon: Icons.how_to_reg_outlined,
      selected: Icons.how_to_reg,
    ),
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
                SizedBox(
                  width: 120,
                  child: Column(
                    children: [
                      Expanded(
                        child: NavigationRail(
                          selectedIndex: selecionado,
                          onDestinationSelected: aba.onSelecionado,
                          labelType: NavigationRailLabelType.all,
                          leading: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Icon(
                              Icons.menu_open,
                              size: 20,
                              color: Colors.deepPurple,
                            ),
                          ),
                          destinations: aba.destinationsRail,
                        ),
                      ),
                      if (usuario != null)
                        _blocoInferior(context, authProvider, usuario),
                    ],
                  ),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: ConsentimentoGate(child: navigationShell),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: appBar,
          body: ConsentimentoGate(child: navigationShell),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (destinos.length > 1)
                NavigationBar(
                  selectedIndex: selecionado,
                  onDestinationSelected: aba.onSelecionado,
                  destinations: aba.destinationsBar,
                ),
              if (usuario != null)
                Material(
                  elevation: 6,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Row(
                        children: [
                          UserAvatar(
                            nome: usuario.nome.isNotEmpty
                                ? usuario.nome
                                : usuario.role,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${usuario.nome.isNotEmpty ? usuario.nome : usuario.role} (${usuario.role})',
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
                            onPressed: () =>
                                _encerrarSessao(context, authProvider),
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

  /// Bloco fixo no rodapé do rail: profile (toque → /perfil) e,
  /// abaixo dele, o botão de sair.
  Widget _blocoInferior(
    BuildContext context,
    AuthProvider authProvider,
    UsuarioModel usuario,
  ) {
    final nome = usuario.nome.isNotEmpty ? usuario.nome : usuario.role;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
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
                  UserAvatar(nome: nome),
                  const SizedBox(height: 4),
                  Text(
                    nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    usuario.role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
            onPressed: () => _encerrarSessao(context, authProvider),
          ),
        ],
      ),
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
          Text(
            '${usuario.nome.isNotEmpty ? usuario.nome : usuario.role} (${usuario.role})',
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
  }

  Future<void> _encerrarSessao(BuildContext context, AuthProvider authProvider) async {
    final confirmado = await ConfirmLogoutDialog.show(context);
    if (confirmado == true && context.mounted) {
      authProvider.logout();
    }
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
          icon: Icon(d.icon, size: 20),
          selectedIcon:
              Icon(d.selectedIcon, size: 20, color: Colors.deepPurple),
          label: Text(d.label, style: const TextStyle(fontSize: 11)),
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
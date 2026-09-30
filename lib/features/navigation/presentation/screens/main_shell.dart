import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/dialogs/consentimento_gate.dart';
import '../../../../core/widgets/logout_helper.dart';
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
      metadados = {
    'home': (label: 'Home', icon: Icons.home_outlined, selected: Icons.home),
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
      final meta = metadados[slug]!;
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

  /// Localização atual do GoRouter (path + query) para o dock mobile saber
  /// em que aba está (ex.: `/painel/ponto?aba=espelho`).
  ({String path, Map<String, String> query}) _localizacaoAtual(
      BuildContext context) {
    try {
      final uri = GoRouter.of(context)
          .routerDelegate
          .currentConfiguration
          .uri;
      return (path: uri.path, query: uri.queryParameters);
    } catch (_) {
      return (path: '', query: const <String, String>{});
    }
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
        final appBar = _construirAppBar(context, authProvider, usuario, comMenu: !isWide);

        if (isWide) {
          return Scaffold(
            appBar: appBar,
            body: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Column(
                    children: [
                      // Com 12+ destinos (admin/gestor) o rail estourava a
                      // altura e cobria o perfil. `scrollable: true` rola só
                      // os destinos dentro do rail (altura fina preservada);
                      // ScrollConfiguration esconde a barra de rolagem.
                      // Perfil e logout permanecem fixos no rodapé.
                      Expanded(
                        child: ScrollConfiguration(
                          behavior:
                              const ScrollBehavior().copyWith(scrollbars: false),
                          child: NavigationRail(
                            scrollable: true,
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

        final local = _localizacaoAtual(context);

        return Scaffold(
          appBar: appBar,
          drawer: _MenuLateral(
            destinos: destinos,
            branchAtual: currentIndex,
            usuario: usuario,
            onNavegar: (destino) => context
                .go('/painel/${AppRouter.painelOrdem[destino.branchIndex]}'),
            onPerfil: () => context.push('/perfil'),
            onSair: () => encerrarSessaoConfirmada(context),
          ),
          body: ConsentimentoGate(child: navigationShell),
          bottomNavigationBar: _dockMobile(
            context,
            usuario,
            pathAtual: local.path,
            queryAtual: local.query,
          ),
        );
      },
    );
  }

  /// Dock inferior mobile: 5 itens fixos (Home, Ponto, Espelho, Menu, Perfil).
  /// O restante dos módulos fica no drawer (hambúrguer). O item Menu abre o
  /// drawer direto da dock, alinhado à direita, logo antes de Perfil.
  Widget _dockMobile(
    BuildContext context,
    UsuarioModel? usuario, {
    required String pathAtual,
    required Map<String, String> queryAtual,
  }) {
    if (usuario == null) return const SizedBox.shrink();

    final temPonto = AppRouter.podeModuloPainel(usuario, 'ponto');
    final espelhoAtivo =
        pathAtual == '/painel/ponto' && queryAtual['aba'] == 'espelho';

    // Builder: o context do bottomNavigationBar fica DENTRO do Scaffold,
    // permitindo Scaffold.of(context).openDrawer() para o item Menu.
    return Builder(
      builder: (dockContext) {
        final itens = <_DockItem>[
          _DockItem(
            label: 'Home',
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            onTap: () => context.go('/painel/home'),
          ),
          if (temPonto) ...[
            _DockItem(
              label: 'Ponto',
              icon: Icons.fingerprint,
              selectedIcon: Icons.fingerprint,
              onTap: () => context.go('/painel/ponto'),
            ),
            _DockItem(
              label: 'Espelho',
              icon: Icons.receipt_long_outlined,
              selectedIcon: Icons.receipt_long,
              onTap: () => context.go('/painel/ponto?aba=espelho'),
            ),
          ],
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

        // Nenhum destaque quando a rota atual é outro módulo (chegou pelo drawer)
        // ou o perfil, que fica fora do shell. Menu é ação (abre drawer),
        // nunca fica destacado.
        int selecionado = -1;
        if (pathAtual == '/painel/home') {
          selecionado = 0;
        } else if (espelhoAtivo) {
          selecionado = temPonto ? 2 : -1;
        } else if (pathAtual == '/painel/ponto' && temPonto) {
          selecionado = 1;
        }

        if (selecionado < 0 || selecionado >= itens.length) {
          // NavigationBar não aceita -1: renderiza a dock sem destaque.
          return _DockSemDestaque(itens: itens);
        }

        return NavigationBar(
          selectedIndex: selecionado,
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
                  UserAvatar(
                    nome: nome,
                    fotoBytes: usuario.temFoto ? usuario.fotoBytes : null,
                  ),
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
            onPressed: () => encerrarSessaoConfirmada(context),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _construirAppBar(
    BuildContext context,
    AuthProvider authProvider,
    UsuarioModel? usuario, {
    required bool comMenu,
  }) {
    return AppBar(
      elevation: 1,
      // Hambúrguer mobile: abre o drawer com todos os módulos acessíveis.
      leading: comMenu
          ? Builder(
              builder: (menuContext) => IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Menu de módulos',
                onPressed: () => Scaffold.of(menuContext).openDrawer(),
              ),
            )
          : null,
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
          // Flexible + ellipsis: em telas estreitas o título encolhe em vez
          // de estourar por cima do nome exibido em `actions`.
          Flexible(
            child: Text(
              'Chronos Pulse Suite',
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
        if (usuario != null) ...[
          // ConstrainedBox + ellipsis: o nome nunca ultrapassa o limite,
          // garantindo largura para o título (evita sobreposição).
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: comMenu ? 160 : 320),
            child: Text(
              '${usuario.nome.isNotEmpty ? usuario.nome : usuario.role} (${usuario.role})',
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
}

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

/// Dock sem item destacado (usuário está em módulo que não é do dock).
/// Mesmo visual da NavigationBar, só que sem indicador de seleção.
class _DockSemDestaque extends StatelessWidget {
  final List<_DockItem> itens;

  const _DockSemDestaque({required this.itens});

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

/// Drawer (hambúrguer) mobile com todos os módulos acessíveis do usuário,
/// atalho de perfil e sair.
class _MenuLateral extends StatelessWidget {
  final List<_ShellDestino> destinos;
  final int branchAtual;
  final UsuarioModel? usuario;
  final void Function(_ShellDestino destino) onNavegar;
  final VoidCallback onPerfil;
  final VoidCallback onSair;

  const _MenuLateral({
    required this.destinos,
    required this.branchAtual,
    required this.usuario,
    required this.onNavegar,
    required this.onPerfil,
    required this.onSair,
  });

  @override
  Widget build(BuildContext context) {
    final nome = usuario == null
        ? ''
        : (usuario!.nome.isNotEmpty ? usuario!.nome : usuario!.role);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            if (usuario != null)
              ListTile(
                leading: UserAvatar(
                  nome: nome,
                  fotoBytes: usuario!.temFoto ? usuario!.fotoBytes : null,
                ),
                title: Text(
                  nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(usuario!.role, style: const TextStyle(fontSize: 12)),
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
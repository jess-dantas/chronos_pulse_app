import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Card com os switches de associação de módulos do colaborador.
/// Exibe os módulos em [visiveis] (catálogo filtrado pelos módulos do
/// usuário logado) agrupados pelos [grupos] fixos e notifica o conjunto
/// completo selecionado.
class AcessosModulosCard extends StatelessWidget {
  /// Catálogo completo dos módulos de tenant (sem PRIVACIDADE).
  static const List<String> codigosGlobais = [
    'PONTO',
    'RECURSOS_HUMANOS',
    'ESTOQUE',
    'COMPRAS',
    'LICITACOES',
    'PATRIMONIO',
    'FROTA',
    'PROTOCOLO',
    'TRANSPARENCIA',
  ];

  /// Agrupadores fixos dos módulos de tenant (definidos no código, na ordem
  /// aprovada — não vêm do backend nem da configuração da empresa).
  static const List<({String nome, List<String> codigos})> grupos = [
    (nome: 'RH', codigos: ['PONTO', 'RECURSOS_HUMANOS']),
    (nome: 'Estoque', codigos: ['ESTOQUE']),
    (nome: 'Compras', codigos: ['COMPRAS', 'LICITACOES']),
    (nome: 'Logística', codigos: ['PATRIMONIO', 'FROTA', 'PROTOCOLO']),
    (nome: 'Transparência', codigos: ['TRANSPARENCIA']),
  ];

  static const Map<String, ({IconData icon, String title, String subtitle})>
      _catalogo = {
    'PONTO': (
      icon: Icons.fingerprint,
      title: 'Ponto Eletrônico',
      subtitle: 'Registro de ponto, espelho digital e ajustes.',
    ),
    'RECURSOS_HUMANOS': (
      icon: Icons.people_outline,
      title: 'Recursos Humanos',
      subtitle: 'Gestão de colaboradores, cadastros e RH.',
    ),
    'ESTOQUE': (
      icon: Icons.inventory_2_outlined,
      title: 'Estoque e Almoxarifado',
      subtitle: 'Catálogo, saldos, movimentações e requisições de materiais.',
    ),
    'COMPRAS': (
      icon: Icons.shopping_cart_outlined,
      title: 'Compras e Fornecedores',
      subtitle: 'Pedidos, NFe, cotações e fornecedores.',
    ),
    'LICITACOES': (
      icon: Icons.gavel_outlined,
      title: 'Licitações',
      subtitle: 'Processos licitatórios (Lei 14.133/2021).',
    ),
    'PATRIMONIO': (
      icon: Icons.warehouse_outlined,
      title: 'Patrimônio',
      subtitle: 'Bens, tombamentos e inventários patrimoniais.',
    ),
    'FROTA': (
      icon: Icons.directions_bus_outlined,
      title: 'Frota',
      subtitle: 'Veículos, manutenção, abastecimento e viagens.',
    ),
    'PROTOCOLO': (
      icon: Icons.folder_shared_outlined,
      title: 'Protocolo',
      subtitle: 'Processos, documentos e tramitação eletrônica.',
    ),
    'TRANSPARENCIA': (
      icon: Icons.public_outlined,
      title: 'Transparência',
      subtitle: 'Portal da transparência e indicadores (LC 131/2009).',
    ),
  };

  /// Códigos que serão exibidos como switches.
  final List<String> visiveis;

  /// Módulos atualmente associados ao colaborador.
  final Set<String> selecionados;

  final ValueChanged<Set<String>> onChanged;

  const AcessosModulosCard({
    super.key,
    required this.visiveis,
    required this.selecionados,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.onLilasSurface(context);
    final visiveisSet = visiveis.toSet();
    final emGrupo = grupos.expand((g) => g.codigos).toSet();
    final foraDoGrupo =
        codigosGlobais.where((c) => !emGrupo.contains(c)).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lilasSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lilasBorder(context)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.apps_outlined, size: 18, color: accent),
                const SizedBox(width: 8),
                Text(
                  'Acessos aos Módulos da Plataforma',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final grupo in grupos) ...[
            if (grupo.codigos.any(visiveisSet.contains))
              _cabecalhoGrupo(grupo.nome, accent),
            for (final codigo in grupo.codigos)
              if (visiveis.contains(codigo)) _switchDoModulo(codigo, accent),
          ],
          if (foraDoGrupo.any(visiveisSet.contains)) ...[
            _cabecalhoGrupo('Outros', accent),
            for (final codigo in foraDoGrupo)
              if (visiveis.contains(codigo)) _switchDoModulo(codigo, accent),
          ],
        ],
      ),
    );
  }

  Widget _cabecalhoGrupo(String nome, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 2),
      child: Text(
        nome.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: accent,
        ),
      ),
    );
  }

  Widget _switchDoModulo(String codigo, Color accent) {
    final meta = _catalogo[codigo]!;
    // Material transparente próprio: o card tem fundo colorido (DecoratedBox)
    // e o ListTile pintaria fundo/ink no Material distante — assert de debug.
    return Material(
      type: MaterialType.transparency,
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        secondary: Icon(meta.icon, color: accent, size: 22),
        title: Text(
          meta.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(meta.subtitle, style: const TextStyle(fontSize: 12)),
        value: selecionados.contains(codigo),
        activeThumbColor: accent,
        onChanged: (v) {
          final novo = Set<String>.from(selecionados);
          if (v) {
            novo.add(codigo);
          } else {
            novo.remove(codigo);
          }
          onChanged(novo);
        },
      ),
    );
  }
}

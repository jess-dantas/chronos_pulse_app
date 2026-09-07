import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Card com os switches de acesso por módulo do colaborador
/// (Estoque, Patrimônio, Frota e Protocolo) sobre fundo lilás.
class AcessosModulosCard extends StatelessWidget {
  final bool acessoEstoque;
  final bool acessoPatrimonio;
  final bool acessoFrota;
  final bool acessoProtocolo;
  final void Function(bool estoque, bool patrimonio, bool frota, bool protocolo)
      onChanged;

  const AcessosModulosCard({
    super.key,
    required this.acessoEstoque,
    required this.acessoPatrimonio,
    required this.acessoFrota,
    required this.acessoProtocolo,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.onLilasSurface(context);

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
          _buildSwitch(
            context,
            icon: Icons.inventory_2_outlined,
            title: 'Estoque e Almoxarifado',
            subtitle: 'Catálogo, saldos, movimentações e requisições de materiais.',
            value: acessoEstoque,
            onChanged: (v) => onChanged(
              v,
              acessoPatrimonio,
              acessoFrota,
              acessoProtocolo,
            ),
          ),
          _buildSwitch(
            context,
            icon: Icons.warehouse_outlined,
            title: 'Patrimônio',
            subtitle: 'Bens, tombamentos e inventários patrimoniais.',
            value: acessoPatrimonio,
            onChanged: (v) => onChanged(
              acessoEstoque,
              v,
              acessoFrota,
              acessoProtocolo,
            ),
          ),
          _buildSwitch(
            context,
            icon: Icons.directions_bus_outlined,
            title: 'Frota',
            subtitle: 'Veículos, manutenção, abastecimento e viagens.',
            value: acessoFrota,
            onChanged: (v) => onChanged(
              acessoEstoque,
              acessoPatrimonio,
              v,
              acessoProtocolo,
            ),
          ),
          _buildSwitch(
            context,
            icon: Icons.folder_shared_outlined,
            title: 'Protocolo',
            subtitle: 'Processos, documentos e tramitação eletrônica.',
            value: acessoProtocolo,
            onChanged: (v) => onChanged(
              acessoEstoque,
              acessoPatrimonio,
              acessoFrota,
              v,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final accent = AppTheme.onLilasSurface(context);
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      secondary: Icon(icon, color: accent, size: 22),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      activeThumbColor: accent,
      onChanged: onChanged,
    );
  }
}
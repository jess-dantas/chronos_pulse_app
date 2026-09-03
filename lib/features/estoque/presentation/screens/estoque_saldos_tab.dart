import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/estoque_provider.dart';
import 'dialogs/nova_entrada_dialog.dart';
import 'dialogs/nova_saida_dialog.dart';

class EstoqueSaldosTab extends StatelessWidget {
  const EstoqueSaldosTab({super.key});

  @override
  Widget build(BuildContext context) {
    final estoqueProvider = context.watch<EstoqueProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final numberFormat = NumberFormat('#,##0.000', 'pt_BR');

    return RefreshIndicator(
      onRefresh: () => estoqueProvider.carregarTudo(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cards de Métricas
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                return GridView.count(
                  crossAxisCount: isWide ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: isWide ? 2.2 : 1.6,
                  children: [
                    _MetricCard(
                      title: 'Itens em Estoque',
                      value: '${estoqueProvider.totalItensDistintos}',
                      icon: Icons.inventory_2,
                      color: Colors.blue,
                    ),
                    _MetricCard(
                      title: 'Patrimônio Total (PMP)',
                      value: currencyFormat.format(estoqueProvider.valorTotalEstoque),
                      icon: Icons.account_balance_wallet,
                      color: Colors.green,
                    ),
                    _MetricCard(
                      title: 'Estoque Baixo / Crítico',
                      value: '${estoqueProvider.itensAbaixoMinimo}',
                      icon: Icons.warning_amber_rounded,
                      color: estoqueProvider.itensAbaixoMinimo > 0 ? Colors.orange : Colors.grey,
                    ),
                    _MetricCard(
                      title: 'Requisições Pendentes',
                      value: '${estoqueProvider.totalRequisicoesPendentes}',
                      icon: Icons.pending_actions,
                      color: Colors.purple,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Barra de Filtros e Ações
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Busca
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320, minWidth: 200),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Buscar por descrição, CATMAT...',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) => estoqueProvider.setSearchQuery(val),
                      ),
                    ),

                    // Filtro de Almoxarifado
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: DropdownButtonFormField<String?>(
                        decoration: InputDecoration(
                          labelText: 'Filtrar Almoxarifado',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        value: estoqueProvider.selectedAlmoxarifadoId,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Todos os Almoxarifados'),
                          ),
                          ...estoqueProvider.almoxarifados.map((a) {
                            return DropdownMenuItem(
                              value: a.id,
                              child: Text(a.nome, overflow: TextOverflow.ellipsis),
                            );
                          }),
                        ],
                        onChanged: (val) => estoqueProvider.filtrarPorAlmoxarifado(val),
                      ),
                    ),

                    // Botões de Ação
                    Wrap(
                      spacing: 8,
                      children: [
                        FilledButton.icon(
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: const Text('Entrada (NFe)'),
                          style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => const NovaEntradaDialog(),
                            );
                          },
                        ),
                        FilledButton.icon(
                          icon: const Icon(Icons.output, size: 18),
                          label: const Text('Saída / Baixa'),
                          style: FilledButton.styleFrom(backgroundColor: Colors.orange[800]),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => const NovaSaidaDialog(),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tabela / Cards de Saldos
            if (estoqueProvider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (estoqueProvider.saldos.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhum item em saldo encontrado.',
                        style: TextStyle(color: Colors.grey[700], fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
                    columns: const [
                      DataColumn(label: Text('Item / Descrição', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Almoxarifado', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Saldo Físico', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Custo Médio (PMP)', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Valor Total', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Lote / Validade', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Ações', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: estoqueProvider.saldos.map((saldo) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (saldo.isAbaixoMinimo)
                                  const Tooltip(
                                    message: 'Saldo abaixo do estoque mínimo!',
                                    child: Padding(
                                      padding: EdgeInsets.only(right: 6.0),
                                      child: Icon(Icons.warning, color: Colors.amber, size: 18),
                                    ),
                                  ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      saldo.materialDescricao ?? 'Item',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    if (saldo.codigoCatmat != null)
                                      Text(
                                        'CATMAT: ${saldo.codigoCatmat}',
                                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          DataCell(Text(saldo.almoxarifadoNome ?? '-')),
                          DataCell(
                            Text(
                              '${numberFormat.format(saldo.quantidadeAtual)} ${saldo.unidadeMedida ?? "UN"}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: saldo.isAbaixoMinimo ? Colors.red[700] : Colors.black87,
                              ),
                            ),
                          ),
                          DataCell(Text(currencyFormat.format(saldo.custoMedioUnitario))),
                          DataCell(Text(currencyFormat.format(saldo.valorTotal), style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(
                            Text(
                              saldo.lote != null && saldo.lote!.isNotEmpty
                                  ? '${saldo.lote}${saldo.dataValidade != null ? " (${saldo.dataValidade})" : ""}'
                                  : 'Geral',
                              style: TextStyle(color: Colors.grey[700], fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.output, size: 18, color: Colors.orange),
                                  tooltip: 'Dar baixa rápida neste item',
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => NovaSaidaDialog(itemPreSelecionado: saldo),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

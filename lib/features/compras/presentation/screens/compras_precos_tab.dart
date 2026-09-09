import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/compras_provider.dart';

class ComprasPrecosTab extends StatelessWidget {
  const ComprasPrecosTab({super.key});

  static final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ComprasProvider>();

    return Column(
      children: [
        if (provider.errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              provider.errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        Expanded(
          child: provider.isLoading && provider.precos.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => context.read<ComprasProvider>().carregarTudo(),
                  child: provider.precos.isEmpty
                      ? ListView(
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  'O banco de preços é alimentado automaticamente '
                                  'conforme os pedidos de compra são emitidos.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: provider.precos.length,
                          itemBuilder: (context, index) {
                            final preco = provider.precos[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.stacked_bar_chart,
                                  color: Colors.deepPurple,
                                ),
                                title: Text(preco.materialDescricao),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Unidade: ${preco.unidadeMedida.isEmpty ? '-' : preco.unidadeMedida}'
                                      '  •  Última compra: ${preco.ultimaCompraEmFormatada.isEmpty ? '-' : preco.ultimaCompraEmFormatada}'
                                      '  •  ${preco.totalEntradas} entrada(s)',
                                    ),
                                    Text(
                                      'Último: ${_moeda.format(preco.ultimoValorUnitario)}  '
                                      '•  Médio: ${_moeda.format(preco.valorMedioUnitario)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }
}
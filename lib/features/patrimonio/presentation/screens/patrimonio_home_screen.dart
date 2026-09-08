import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/csv_export.dart';
import '../../data/models/patrimonio_models.dart';
import '../providers/patrimonio_provider.dart';
import 'desfazimento_screen.dart';
import 'dialogs/novo_bem_dialog.dart';

class PatrimonioHomeScreen extends StatefulWidget {
  const PatrimonioHomeScreen({super.key});

  @override
  State<PatrimonioHomeScreen> createState() => _PatrimonioHomeScreenState();
}

class _PatrimonioHomeScreenState extends State<PatrimonioHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatrimonioProvider>().carregarBens();
    });
  }

  Future<void> _abrirNovoBem() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const NovoBemDialog(),
    );
    if (ok == true && mounted) {
      context.read<PatrimonioProvider>().carregarBens();
    }
  }

  Future<void> _exportarCsv(List<PatrimonioModel> bens) async {
    if (bens.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sem bens para exportar.')),
        );
      }
      return;
    }
    final exportado = await CsvExport.exportar(
      arquivoNome: 'patrimonio_${DateTime.now().toIso8601String().substring(0, 10)}.csv',
      cabecalho: const [
        'Tombamento',
        'Descrição',
        'Categoria',
        'Estado',
        'Localização',
        'Data de Aquisição',
        'Valor de Aquisição (R\$)',
        'Responsável',
        'Nota Fiscal',
        'Observações',
      ],
      linhas: bens.map((b) {
        return [
          b.tombamento ?? '',
          b.descricao,
          b.categoria ?? '',
          b.estado,
          b.localizacao ?? '',
          b.dataAquisicao ?? '',
          b.valorAquisicao ?? '',
          b.responsavelNome ?? '',
          b.numeroNotaFiscal ?? '',
          b.observacoes ?? '',
        ];
      }).toList(),
    );
    if (mounted && exportado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV exportado com sucesso.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatrimonioProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.inventory, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Patrimônio Público'),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            tooltip: 'Desfazimento de Bens',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DesfazimentoScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Exportar CSV',
            onPressed: () => _exportarCsv(provider.bens),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: () => context.read<PatrimonioProvider>().carregarBens(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirNovoBem,
        icon: const Icon(Icons.add),
        label: const Text('Novo Bem'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          provider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context.read<PatrimonioProvider>().carregarBens(),
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : provider.bens.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Nenhum bem patrimonial cadastrado.'),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.bens.length + (provider.hasMore ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (index >= provider.bens.length) {
                          return Center(
                            child: OutlinedButton.icon(
                              onPressed: provider.carregandoMais
                                  ? null
                                  : () => context.read<PatrimonioProvider>().carregarMaisBens(),
                              icon: provider.carregandoMais
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.expand_more),
                              label: const Text('Carregar mais bens'),
                            ),
                          );
                        }
                        final bem = provider.bens[index];
                        return Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.lilasSurface(context),
                              child: Icon(Icons.inventory, color: AppTheme.onLilasSurface(context)),
                            ),
                            title: Text(
                              bem.descricao,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Tombamento: ${bem.tombamento ?? '—'} | Categoria: ${bem.categoria ?? '—'}',
                                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                ),
                                if (bem.localizacao != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Local: ${bem.localizacao}',
                                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                  ),
                                ],
                                if (bem.valorAquisicao != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Valor: R\$ ${bem.valorAquisicao}',
                                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                  ),
                                ],
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.lilasSurface(context),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                bem.estado,
                                style: TextStyle(
                                  color: AppTheme.onLilasSurface(context),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
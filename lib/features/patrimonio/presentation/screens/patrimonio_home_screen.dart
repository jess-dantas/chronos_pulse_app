import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/patrimonio_provider.dart';
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
                      itemCount: provider.bens.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final bem = provider.bens[index];
                        return Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: Colors.deepPurple.withOpacity(0.1),
                              child: const Icon(Icons.inventory, color: Colors.deepPurple),
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
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                ),
                                if (bem.localizacao != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Local: ${bem.localizacao}',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  ),
                                ],
                                if (bem.valorAquisicao != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Valor: R\$ ${bem.valorAquisicao}',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  ),
                                ],
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                bem.estado,
                                style: const TextStyle(
                                  color: Colors.deepPurple,
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
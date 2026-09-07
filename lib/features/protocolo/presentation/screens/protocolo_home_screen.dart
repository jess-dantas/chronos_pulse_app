import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/protocolo_models.dart';
import '../providers/protocolo_provider.dart';
import 'dialogs/alterar_status_dialog.dart';
import 'dialogs/novo_protocolo_dialog.dart';

class ProtocoloHomeScreen extends StatefulWidget {
  const ProtocoloHomeScreen({super.key});

  @override
  State<ProtocoloHomeScreen> createState() => _ProtocoloHomeScreenState();
}

class _ProtocoloHomeScreenState extends State<ProtocoloHomeScreen> {
  bool _somenteRecebido = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProtocoloProvider>().carregarProtocolos();
    });
  }

  Future<void> _abrirNovoProtocolo() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => const NovoProtocoloDialog());
    if (ok == true && mounted) context.read<ProtocoloProvider>().carregarProtocolos();
  }

  Future<void> _abrirAlterarStatus(ProtocoloModel p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlterarStatusDialog(protocolo: p),
    );
    if (ok == true && mounted) context.read<ProtocoloProvider>().carregarProtocolos();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProtocoloProvider>();
    final parcial = provider.isLoading && provider.protocolos.isEmpty;
    final erro = provider.errorMessage != null && provider.protocolos.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.assignment_ind, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Protocolo'),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Recarregar',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ProtocoloProvider>().carregarProtocolos(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirNovoProtocolo,
        icon: const Icon(Icons.add),
        label: const Text('Novo Protocolo'),
      ),
      body: parcial
          ? const Center(child: CircularProgressIndicator())
          : erro
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(provider.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context.read<ProtocoloProvider>().carregarProtocolos(),
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: SegmentedButton<bool>(
                        segments: [
                          const ButtonSegment(value: true, label: Text('Recebidos')),
                          ButtonSegment(
                            value: false,
                            label: Text('Todos (${provider.protocolos.length})'),
                          ),
                        ],
                        selected: {_somenteRecebido},
                        onSelectionChanged: (s) => setState(() => _somenteRecebido = s.first),
                      ),
                    ),
                    Expanded(child: _buildLista(provider)),
                  ],
                ),
    );
  }

  Widget _buildLista(ProtocoloProvider provider) {
    final lista = _somenteRecebido ? provider.protocolosRecebido : provider.protocolos;
    if (lista.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Nenhum protocolo encontrado.'),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: lista.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final p = lista[index];
        final status = p.status;
        final cor = status == 'RECEBIDO'
            ? Colors.orange
            : status == 'ARQUIVADO'
                ? Colors.grey
                : Colors.deepPurple;
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple.withOpacity(0.1),
              child: Text(
                p.numeroProtocolo.isEmpty ? '#' : p.numeroProtocolo.split('-').last,
                style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(p.assunto, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${p.numeroProtocolo} • ${p.tipo}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                if (p.remetente != null && p.remetente!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Remetente: ${p.remetente}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
                if (p.dataProtocolo != null && p.dataProtocolo!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Protocolado em: ${p.dataProtocolo!.replaceFirst('T', ' ').substring(0, 16)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: cor.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (s) {
                    if (s == 'alterar_status') _abrirAlterarStatus(p);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'alterar_status', child: Text('Alterar status')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
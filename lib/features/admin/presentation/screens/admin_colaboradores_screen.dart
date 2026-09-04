import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';

class AdminColaboradoresScreen extends StatefulWidget {
  const AdminColaboradoresScreen({super.key});

  @override
  State<AdminColaboradoresScreen> createState() => _AdminColaboradoresScreenState();
}

class _AdminColaboradoresScreenState extends State<AdminColaboradoresScreen> {
  String _filtro = 'Todos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().carregarColaboradores();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final lista = adminProvider.colaboradores;

    final filtrados = _filtro == 'Todos'
        ? lista
        : lista.where((c) => c['ativo'] == true).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Colaboradores',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text(
                      'Total: ${lista.length} colaborador(es) em todas as empresas',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'Todos', label: Text('Todos')),
                        ButtonSegment(value: 'Ativos', label: Text('Ativos')),
                      ],
                      selected: {_filtro},
                      onSelectionChanged: (s) =>
                          setState(() => _filtro = s.first),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (adminProvider.isLoading && lista.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (filtrados.isEmpty)
                  Card(
                    elevation: 0,
                    color: Colors.grey[100],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.people_outline, size: 48, color: Colors.grey),
                            SizedBox(height: 12),
                            Text(
                              'Nenhum colaborador encontrado.',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtrados.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final c = filtrados[index];
                      final ativo = c['ativo'] == true;
                      final acessoEstoque = c['acessoEstoque'] == true;
                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: (ativo ? Colors.green : Colors.red).withOpacity(0.1),
                            child: Icon(
                              Icons.person,
                              color: ativo ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(
                            c['nome']?.toString() ?? 'Sem nome',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 12,
                                  children: [
                                    if (c['tenantNome'] != null)
                                      _chip(
                                        Icon(Icons.business, size: 14),
                                        c['tenantNome'].toString(),
                                        Colors.blue,
                                      ),
                                    if (c['matricula'] != null)
                                      _chip(
                                        Icon(Icons.badge, size: 14),
                                        'Mat. ${c['matricula']}',
                                        Colors.deepPurple,
                                      ),
                                    if (c['cargo'] != null)
                                      _chip(
                                        Icon(Icons.work_outline, size: 14),
                                        c['cargo'].toString(),
                                        Colors.orange.shade800,
                                      ),
                                    _chip(
                                      Icon(Icons.warehouse, size: 14),
                                      acessoEstoque ? 'Estoque' : 'Sem estoque',
                                      acessoEstoque ? Colors.teal : Colors.grey,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${c['email'] ?? 'Sem e-mail'} • CPF: ${c['cpf'] ?? '—'}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (ativo ? Colors.green : Colors.red).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: (ativo ? Colors.green : Colors.red).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              ativo ? 'ATIVO' : 'INATIVO',
                              style: TextStyle(
                                color: (ativo ? Colors.green : Colors.red).shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(Icon icono, String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icono,
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
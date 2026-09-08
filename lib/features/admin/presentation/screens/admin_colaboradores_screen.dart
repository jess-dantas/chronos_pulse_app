import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/admin_models.dart';
import '../providers/admin_provider.dart';
import 'dialogs/admin_editar_colaborador_dialog.dart';
import 'dialogs/admin_novo_colaborador_dialog.dart';

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
      final provider = context.read<AdminProvider>();
      provider.carregarColaboradores();
      if (provider.empresas.isEmpty) {
        provider.carregarEmpresas();
      }
    });
  }

  Future<void> _abrirNovoColaborador() async {
    final adminProvider = context.read<AdminProvider>();
    await showDialog<void>(
      context: context,
      builder: (context) => AdminNovoColaboradorDialog(
        empresas: adminProvider.empresas,
      ),
    );
  }

  Future<void> _editarColaborador(AdminColaboradorModel colaborador) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AdminEditarColaboradorDialog(colaborador: colaborador),
    );
  }

  Future<void> _excluirColaborador(AdminColaboradorModel colaborador) async {
    final nome = colaborador.nome.isNotEmpty ? colaborador.nome : 'este colaborador';
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Deseja realmente excluir $nome?\n\nEsta ação irá remover o acesso do colaborador à plataforma.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    final provider = context.read<AdminProvider>();
    final sucesso = await provider.excluirColaborador(colaborador.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sucesso
              ? 'Colaborador excluído com sucesso!'
              : provider.errorMessage ?? 'Erro ao excluir colaborador.'),
          backgroundColor: sucesso ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final lista = adminProvider.colaboradores;

    final filtrados = _filtro == 'Todos'
        ? lista
        : lista.where((c) => c.ativo).toList();

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
                    Wrap(
                      spacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'Todos', label: Text('Todos')),
                            ButtonSegment(value: 'Ativos', label: Text('Ativos')),
                          ],
                          selected: {_filtro},
                          onSelectionChanged: (s) =>
                              setState(() => _filtro = s.first),
                        ),
                        FilledButton.icon(
                          onPressed: _abrirNovoColaborador,
                          icon: const Icon(Icons.person_add),
                          label: const Text('Novo Colaborador'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (adminProvider.errorMessage != null)
                  Card(
                    color: Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red[700]),
                          const SizedBox(width: 12),
                          Expanded(child: Text(adminProvider.errorMessage!)),
                        ],
                      ),
                    ),
                  ),
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
                      final ativo = c.ativo;
                      final acessoEstoque = c.acessoEstoque;
                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: (ativo ? Colors.green : Colors.red).withValues(alpha: 0.1),
                            child: Icon(
                              Icons.person,
                              color: ativo ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(
                            c.nome.isNotEmpty ? c.nome : 'Sem nome',
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
                                    if (c.tenantNome != null)
                                      _chip(
                                        Icon(Icons.business, size: 14),
                                        c.tenantNome!,
                                        Colors.blue,
                                      ),
                                    if (c.matricula != null)
                                      _chip(
                                        Icon(Icons.badge, size: 14),
                                        'Mat. ${c.matricula}',
                                        Colors.deepPurple,
                                      ),
                                    if (c.cargo != null)
                                      _chip(
                                        Icon(Icons.work_outline, size: 14),
                                        c.cargo!,
                                        Colors.orange.shade800,
                                      ),
                                    _chip(
                                      Icon(Icons.warehouse, size: 14),
                                      acessoEstoque ? 'Estoque' : 'Sem estoque',
                                      acessoEstoque ? Colors.teal : Colors.grey,
                                    ),
                                    if (c.acessoPatrimonio)
                                      _chip(
                                        Icon(Icons.inventory_2, size: 14),
                                        'Patrimônio',
                                        Colors.indigo,
                                      ),
                                    if (c.acessoFrota)
                                      _chip(
                                        Icon(Icons.directions_bus, size: 14),
                                        'Frota',
                                        Colors.teal.shade700,
                                      ),
                                    if (c.acessoProtocolo)
                                      _chip(
                                        Icon(Icons.folder_shared, size: 14),
                                        'Protocolo',
                                        Colors.cyan.shade700,
                                      ),
                                    if (c.dataDesligamento != null)
                                      _chip(
                                        Icon(Icons.event_busy, size: 14),
                                        'Desligado em ${c.dataDesligamento}',
                                        Colors.red,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${c.email ?? 'Sem e-mail'} • CPF: ${c.cpf.isEmpty ? '—' : c.cpf}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (ativo ? Colors.green : Colors.red).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: (ativo ? Colors.green : Colors.red).withValues(alpha: 0.3),
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
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Editar',
                                onPressed: () => _editarColaborador(c),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                tooltip: 'Excluir',
                                onPressed: () => _excluirColaborador(c),
                              ),
                            ],
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
        color: cor.withValues(alpha: 0.1),
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
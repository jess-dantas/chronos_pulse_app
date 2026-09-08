import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/admin_models.dart';
import '../providers/admin_provider.dart';
import 'admin_nova_empresa_screen.dart';

class AdminEmpresasScreen extends StatefulWidget {
  const AdminEmpresasScreen({super.key});

  @override
  State<AdminEmpresasScreen> createState() => _AdminEmpresasScreenState();
}

class _AdminEmpresasScreenState extends State<AdminEmpresasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().carregarEmpresas();
    });
  }

  Future<void> _abrirNovaEmpresa() async {
    final cadastrou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AdminNovaEmpresaScreen()),
    );

    if (cadastrou == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Empresa cadastrada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _editarEmpresa(AdminEmpresaModel empresa) async {
    final nomeController = TextEditingController(
      text: empresa.nome,
    );
    final formKey = GlobalKey<FormState>();

    final salvar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Editar Empresa'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nomeController,
            decoration: const InputDecoration(
              labelText: 'Nome / Razão Social',
              prefixIcon: Icon(Icons.business),
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (salvar != true || !mounted) return;

    final provider = context.read<AdminProvider>();
    final sucesso = await provider.atualizarEmpresa(
      id: empresa.id,
      nome: nomeController.text.trim(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sucesso
              ? 'Empresa atualizada com sucesso!'
              : provider.errorMessage ?? 'Erro ao atualizar empresa.'),
          backgroundColor: sucesso ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _alternarAtivo(AdminEmpresaModel empresa, bool ativo) async {
    final nome = empresa.nome.isNotEmpty ? empresa.nome : 'esta empresa';
    final novoEstado = !ativo;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(novoEstado ? 'Reativar Empresa' : 'Inativar Empresa'),
        content: Text(novoEstado
            ? 'Deseja reativar $nome?'
            : 'Deseja inativar $nome?\n\nA empresa deixará de ter acesso à plataforma enquanto estiver inativa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: novoEstado ? Colors.green : Colors.red,
            ),
            child: Text(
              novoEstado ? 'Reativar' : 'Inativar',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    final provider = context.read<AdminProvider>();
    final sucesso = await provider.atualizarEmpresa(
      id: empresa.id,
      ativo: novoEstado,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sucesso
              ? (novoEstado ? 'Empresa reativada!' : 'Empresa inativada!')
              : provider.errorMessage ?? 'Erro ao alterar a empresa.'),
          backgroundColor: sucesso ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final empresas = adminProvider.empresas;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Empresas (Tenants)',
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton.icon(
                      onPressed: _abrirNovaEmpresa,
                      icon: const Icon(Icons.add_business),
                      label: const Text('Nova Empresa'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Atualizar',
                      onPressed: () => context.read<AdminProvider>().carregarEmpresas(),
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
                if (adminProvider.isLoading && empresas.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (empresas.isEmpty)
                  Card(
                    elevation: 0,
                    color: Colors.grey[100],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.business_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 12),
                            Text(
                              'Nenhuma empresa cadastrada.',
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
                    itemCount: empresas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final e = empresas[index];
                      final ativo = e.ativo;
                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.withValues(alpha: 0.1),
                            child: const Icon(Icons.business, color: Colors.blue),
                          ),
                          title: Text(
                            e.nome.isNotEmpty ? e.nome : 'Sem nome',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'CNPJ: ${e.cnpj.isEmpty ? '—' : e.cnpj}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                              if (e.responsavelNome != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Responsável: ${e.responsavelNome}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                ),
                              ],
                              if (e.responsavelEmail != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Email: ${e.responsavelEmail}',
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
                                onPressed: () => _editarEmpresa(e),
                              ),
                              IconButton(
                                icon: Icon(
                                  ativo ? Icons.block : Icons.check_circle_outline,
                                  color: ativo ? Colors.red : Colors.green,
                                ),
                                tooltip: ativo ? 'Inativar' : 'Reativar',
                                onPressed: () => _alternarAtivo(e, ativo),
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
}
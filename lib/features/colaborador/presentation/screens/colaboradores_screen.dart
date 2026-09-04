import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/colaborador_provider.dart';
import 'editar_colaborador_dialog.dart';
import 'novo_colaborador_dialog.dart';

class ColaboradoresScreen extends StatefulWidget {
  const ColaboradoresScreen({super.key});

  @override
  State<ColaboradoresScreen> createState() => _ColaboradoresScreenState();
}

class _ColaboradoresScreenState extends State<ColaboradoresScreen> {
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ColaboradorProvider>().carregarColaboradores();
    });
  }

  void _abrirDialogNovoColaborador() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const NovoColaboradorDialog(),
    );
  }

  void _abrirDialogEditarColaborador(colaborador) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditarColaboradorDialog(colaborador: colaborador),
    );
  }

  void _confirmarExclusao(colaborador) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Deseja realmente excluir o colaborador ${colaborador.nome}?\n\nEsta ação irá desativar o acesso do colaborador à plataforma.',
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

    if (confirmar == true && mounted) {
      final provider = context.read<ColaboradorProvider>();
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
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ColaboradorProvider>();
    final colaboradores = provider.colaboradores.where((c) {
      if (_filtro.isEmpty) return true;
      final query = _filtro.toLowerCase();
      return c.nome.toLowerCase().contains(query) ||
          c.cpf.contains(query) ||
          c.matricula.toLowerCase().contains(query) ||
          c.cargo.toLowerCase().contains(query) ||
          c.departamento.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Gestão de Colaboradores',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar lista',
            onPressed: () => provider.carregarColaboradores(),
          ),
          if (MediaQuery.sizeOf(context).width >= 600) ...[
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Novo Colaborador'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue.shade800,
                  elevation: 0,
                ),
                onPressed: _abrirDialogNovoColaborador,
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirDialogNovoColaborador,
        icon: const Icon(Icons.person_add),
        label: const Text('Novo Colaborador'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Barra de Busca e Métricas
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Buscar por nome, CPF, matrícula, cargo ou setor...',
                          border: InputBorder.none,
                        ),
                        onChanged: (val) => setState(() => _filtro = val),
                      ),
                    ),
                    if (_filtro.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _filtro = ''),
                      ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        '${colaboradores.length} colaborador(es)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      backgroundColor: Colors.blue.shade50,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Conteúdo da Lista
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                              const SizedBox(height: 12),
                              Text(
                                provider.errorMessage!,
                                style: const TextStyle(fontSize: 16, color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => provider.carregarColaboradores(),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Tentar Novamente'),
                              ),
                            ],
                          ),
                        )
                      : colaboradores.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    _filtro.isEmpty
                                        ? 'Nenhum colaborador cadastrado.'
                                        : 'Nenhum colaborador encontrado para "$_filtro".',
                                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 16),
                                  if (_filtro.isEmpty)
                                    ElevatedButton.icon(
                                      onPressed: _abrirDialogNovoColaborador,
                                      icon: const Icon(Icons.person_add),
                                      label: const Text('Cadastrar Primeiro Colaborador'),
                                    ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: colaboradores.length,
                              itemBuilder: (context, index) {
                                final colab = colaboradores[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: Colors.blue.shade100,
                                          child: Text(
                                            colab.nome.isNotEmpty
                                                ? colab.nome.substring(0, 1).toUpperCase()
                                                : 'C',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade900,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    colab.nome,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  if (colab.matricula.isNotEmpty)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                          horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey.shade200,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        colab.matricula,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.grey.shade800,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${colab.cargo.isNotEmpty ? colab.cargo : 'Cargo não informado'} • ${colab.departamento.isNotEmpty ? colab.departamento : 'Geral'}',
                                                style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Icon(Icons.credit_card,
                                                      size: 14, color: Colors.grey.shade600),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'CPF: ${colab.cpf}',
                                                    style: TextStyle(
                                                        fontSize: 12, color: Colors.grey.shade600),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Icon(Icons.email_outlined,
                                                      size: 14, color: Colors.grey.shade600),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    colab.email,
                                                    style: TextStyle(
                                                        fontSize: 12, color: Colors.grey.shade600),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            // Badge Permissão de Estoque
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: colab.acessoEstoque
                                                    ? Colors.green.shade50
                                                    : Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: colab.acessoEstoque
                                                      ? Colors.green.shade300
                                                      : Colors.grey.shade300,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    colab.acessoEstoque
                                                        ? Icons.inventory_2
                                                        : Icons.lock_outline,
                                                    size: 14,
                                                    color: colab.acessoEstoque
                                                        ? Colors.green.shade800
                                                        : Colors.grey.shade600,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    colab.acessoEstoque
                                                        ? 'Acesso ao Estoque'
                                                        : 'Apenas Ponto',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: colab.acessoEstoque
                                                          ? Colors.green.shade900
                                                          : Colors.grey.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            // Botões de Ação
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: Icon(Icons.edit_outlined,
                                                      size: 18, color: Colors.blue.shade600),
                                                  tooltip: 'Editar Colaborador',
                                                  onPressed: () =>
                                                      _abrirDialogEditarColaborador(colab),
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.delete_outline,
                                                      size: 18, color: Colors.red.shade400),
                                                  tooltip: 'Excluir Colaborador',
                                                  onPressed: () =>
                                                      _confirmarExclusao(colab),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/compras_models.dart';
import '../providers/compras_provider.dart';

class ComprasFornecedoresTab extends StatefulWidget {
  const ComprasFornecedoresTab({super.key});

  @override
  State<ComprasFornecedoresTab> createState() => _ComprasFornecedoresTabState();
}

class _ComprasFornecedoresTabState extends State<ComprasFornecedoresTab> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ComprasProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Buscar fornecedor',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: provider.setSearchQuery,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                icon: const Icon(Icons.add_business_outlined, size: 18),
                label: const Text('Novo Fornecedor'),
                style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple),
                onPressed: () => _exibirDialogFornecedor(context),
              ),
            ],
          ),
        ),
        if (provider.errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              provider.errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        Expanded(
          child: Provider.of<ComprasProvider>(context).isLoading &&
                  provider.fornecedores.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => context.read<ComprasProvider>().carregarTudo(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: provider.fornecedores.length,
                    itemBuilder: (context, index) {
                      final f = provider.fornecedores[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: f.ativo
                                ? Colors.deepPurple.shade100
                                : Colors.grey[350],
                            child: Icon(
                              Icons.storefront,
                              color: f.ativo ? Colors.deepPurple : Colors.grey[700],
                            ),
                          ),
                          title: Text(f.razaoSocial),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text('CNPJ: ${f.cnpjFormatado}'),
                              if (f.email != null && f.email!.isNotEmpty)
                                Text('E-mail: ${f.email}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _StatusChip(ativo: f.ativo),
                              PopupMenuButton<String>(
                                tooltip: 'Ações',
                                onSelected: (acao) {
                                  if (acao == 'editar') {
                                    _exibirDialogFornecedor(context, fornecedor: f);
                                  } else if (acao == 'alternar') {
                                    context.read<ComprasProvider>().inativarFornecedor(f.id);
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'editar',
                                    child: ListTile(
                                      leading: Icon(Icons.edit_outlined),
                                      title: Text('Editar'),
                                      dense: true,
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'alternar',
                                    child: ListTile(
                                      leading: Icon(
                                        f.ativo ? Icons.block : Icons.check,
                                      ),
                                      title: Text(f.ativo ? 'Inativar' : 'Reativar'),
                                      dense: true,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () => _exibirDialogFornecedor(context, fornecedor: f),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _exibirDialogFornecedor(
    BuildContext context, {
    FornecedorModel? fornecedor,
  }) async {
    final form = GlobalKey<FormState>();
    String? cnpj = fornecedor?.cnpj;
    String? razaoSocial = fornecedor?.razaoSocial;
    String? nomeFantasia = fornecedor?.nomeFantasia;
    String? inscricaoEstadual = fornecedor?.inscricaoEstadual;
    String? email = fornecedor?.email;
    String? telefone = fornecedor?.telefone;
    String? logradouro = fornecedor?.enderecoLogradouro;
    String? numero = fornecedor?.enderecoNumero;
    String? bairro = fornecedor?.enderecoBairro;
    String? cidade = fornecedor?.enderecoCidade;
    String? uf = fornecedor?.enderecoUf;
    String? cep = fornecedor?.enderecoCep;
    String? observacoes = fornecedor?.observacoes;

    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(fornecedor == null ? 'Cadastrar Fornecedor' : 'Editar Fornecedor'),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: cnpj,
                  decoration: const InputDecoration(labelText: 'CNPJ (somente dígitos)'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe o CNPJ';
                    if (v.replaceAll(RegExp('[^0-9A-Za-z]'), '').length != 14) {
                      return 'CNPJ deve conter 14 caracteres';
                    }
                    return null;
                  },
                  onChanged: (v) => cnpj = v,
                ),
                TextFormField(
                  initialValue: razaoSocial,
                  decoration: const InputDecoration(labelText: 'Razão Social'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe a razão social' : null,
                  onChanged: (v) => razaoSocial = v,
                ),
                TextFormField(
                  initialValue: nomeFantasia,
                  decoration: const InputDecoration(labelText: 'Nome Fantasia'),
                  onChanged: (v) => nomeFantasia = v,
                ),
                TextFormField(
                  initialValue: inscricaoEstadual,
                  decoration: const InputDecoration(labelText: 'Inscrição Estadual'),
                  onChanged: (v) => inscricaoEstadual = v,
                ),
                TextFormField(
                  initialValue: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  onChanged: (v) => email = v,
                ),
                TextFormField(
                  initialValue: telefone,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                  onChanged: (v) => telefone = v,
                ),
                TextFormField(
                  initialValue: logradouro,
                  decoration: const InputDecoration(labelText: 'Logradouro'),
                  onChanged: (v) => logradouro = v,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: numero,
                        decoration: const InputDecoration(labelText: 'Número'),
                        onChanged: (v) => numero = v,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: bairro,
                        decoration: const InputDecoration(labelText: 'Bairro'),
                        onChanged: (v) => bairro = v,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: cidade,
                        decoration: const InputDecoration(labelText: 'Cidade'),
                        onChanged: (v) => cidade = v,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: uf,
                        decoration: const InputDecoration(labelText: 'UF'),
                        maxLength: 2,
                        onChanged: (v) => uf = v.toUpperCase(),
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  initialValue: cep,
                  decoration: const InputDecoration(labelText: 'CEP'),
                  onChanged: (v) => cep = v,
                ),
                TextFormField(
                  initialValue: observacoes,
                  decoration: const InputDecoration(labelText: 'Observações'),
                  maxLines: 2,
                  onChanged: (v) => observacoes = v,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!form.currentState!.validate()) return;
              final provider2 = context.read<ComprasProvider>();
              final sucesso = fornecedor == null
                  ? await provider2.cadastrarFornecedor(CadastrarFornecedorDTO(
                      cnpj: cnpj!,
                      razaoSocial: razaoSocial!,
                      nomeFantasia: nomeFantasia,
                      inscricaoEstadual: inscricaoEstadual,
                      email: email,
                      telefone: telefone,
                      enderecoLogradouro: logradouro,
                      enderecoNumero: numero,
                      enderecoBairro: bairro,
                      enderecoCidade: cidade,
                      enderecoUf: uf,
                      enderecoCep: cep,
                      observacoes: observacoes,
                    ))
                  : await provider2.atualizarFornecedor(
                      fornecedor.id,
                      AtualizarFornecedorDTO(
                        razaoSocial: razaoSocial,
                        nomeFantasia: nomeFantasia,
                        inscricaoEstadual: inscricaoEstadual,
                        email: email,
                        telefone: telefone,
                        enderecoLogradouro: logradouro,
                        enderecoNumero: numero,
                        enderecoBairro: bairro,
                        enderecoCidade: cidade,
                        enderecoUf: uf,
                        enderecoCep: cep,
                        observacoes: observacoes,
                      ),
                    );

              if (dialogContext.mounted && sucesso) {
                Navigator.of(dialogContext).pop(true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(fornecedor == null
                        ? 'Fornecedor cadastrado com sucesso.'
                        : 'Fornecedor atualizado com sucesso.'),
                  ),
                );
              } else if (provider2.errorMessage != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(provider2.errorMessage!)),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool ativo;

  const _StatusChip({required this.ativo});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(ativo ? 'Ativo' : 'Inativo'),
      labelStyle: TextStyle(
        fontSize: 12,
        color: ativo ? Colors.green.shade800 : Colors.grey[700],
      ),
      backgroundColor: ativo ? Colors.green.shade50 : Colors.grey[200],
      visualDensity: VisualDensity.compact,
    );
  }
}
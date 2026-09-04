import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/cpf_input_formatter.dart';
import '../../data/models/colaborador_model.dart';
import '../providers/colaborador_provider.dart';

class EditarColaboradorDialog extends StatefulWidget {
  final ColaboradorModel colaborador;

  const EditarColaboradorDialog({super.key, required this.colaborador});

  @override
  State<EditarColaboradorDialog> createState() => _EditarColaboradorDialogState();
}

class _EditarColaboradorDialogState extends State<EditarColaboradorDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeController;
  late final TextEditingController _cpfController;
  late final TextEditingController _emailController;
  late final TextEditingController _matriculaController;
  late final TextEditingController _cargoController;
  late final TextEditingController _departamentoController;

  late DateTime _dataNascimento;
  late DateTime _dataAdmissao;
  late bool _acessoEstoque;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final colab = widget.colaborador;
    _nomeController = TextEditingController(text: colab.nome);
    _cpfController = TextEditingController(text: colab.cpf);
    _emailController = TextEditingController(text: colab.email);
    _matriculaController = TextEditingController(text: colab.matricula);
    _cargoController = TextEditingController(text: colab.cargo);
    _departamentoController = TextEditingController(text: colab.departamento);
    _dataNascimento = colab.dataNascimento != null
        ? DateTime.tryParse(colab.dataNascimento!) ?? DateTime(1995, 1, 1)
        : DateTime(1995, 1, 1);
    _dataAdmissao = colab.dataAdmissao != null
        ? DateTime.tryParse(colab.dataAdmissao!) ?? DateTime.now()
        : DateTime.now();
    _acessoEstoque = colab.acessoEstoque;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _matriculaController.dispose();
    _cargoController.dispose();
    _departamentoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData(BuildContext context, bool isNascimento) async {
    final dataInicial = isNascimento ? _dataNascimento : _dataAdmissao;
    final primeiraData = isNascimento ? DateTime(1940) : DateTime(2000);
    final ultimaData = isNascimento ? DateTime.now() : DateTime(2030);

    final DateTime? escolhida = await showDatePicker(
      context: context,
      initialDate: dataInicial,
      firstDate: primeiraData,
      lastDate: ultimaData,
    );

    if (escolhida != null) {
      setState(() {
        if (isNascimento) {
          _dataNascimento = escolhida;
        } else {
          _dataAdmissao = escolhida;
        }
      });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = context.read<ColaboradorProvider>();
    final dateFormat = DateFormat('yyyy-MM-dd');

    final sucesso = await provider.atualizarColaborador(
      id: widget.colaborador.id,
      nome: _nomeController.text.trim(),
      emailCorporativo: _emailController.text.trim(),
      matricula: _matriculaController.text.trim(),
      cargo: _cargoController.text.trim(),
      departamento: _departamentoController.text.trim(),
      dataNascimento: dateFormat.format(_dataNascimento),
      dataAdmissao: dateFormat.format(_dataAdmissao),
      acessoEstoque: _acessoEstoque,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (sucesso) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Colaborador atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Erro ao atualizar colaborador.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmarExclusao() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Deseja realmente excluir o colaborador ${widget.colaborador.nome}?\n\nEsta ação irá desativar o acesso do colaborador à plataforma.',
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
      setState(() => _isLoading = true);
      final provider = context.read<ColaboradorProvider>();
      final sucesso = await provider.excluirColaborador(widget.colaborador.id);

      if (mounted) {
        setState(() => _isLoading = false);
        if (sucesso) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Colaborador excluído com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Erro ao excluir colaborador.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue.shade700, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Editar Colaborador',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nomeController,
                          decoration: const InputDecoration(
                            labelText: 'Nome Completo *',
                            prefixIcon: Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Informe o nome completo'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: TextFormField(
                                controller: _cpfController,
                                keyboardType: TextInputType.number,
                                enabled: false,
                                inputFormatters: [CpfInputFormatter()],
                                decoration: const InputDecoration(
                                  labelText: 'CPF (não editável)',
                                  prefixIcon: Icon(Icons.credit_card),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 5,
                              child: TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'E-mail Corporativo *',
                                  prefixIcon: Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => (v == null || !v.contains('@'))
                                    ? 'Informe um e-mail válido'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _matriculaController,
                                decoration: const InputDecoration(
                                  labelText: 'Matrícula',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 4,
                              child: TextFormField(
                                controller: _cargoController,
                                decoration: const InputDecoration(
                                  labelText: 'Cargo',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 4,
                              child: TextFormField(
                                controller: _departamentoController,
                                decoration: const InputDecoration(
                                  labelText: 'Departamento / Setor',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.cake_outlined, size: 20),
                                label: Text('Nasc.: ${dateFormat.format(_dataNascimento)}'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () => _selecionarData(context, true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_today, size: 20),
                                label: Text('Admissão: ${dateFormat.format(_dataAdmissao)}'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () => _selecionarData(context, false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Acesso ao Módulo de Estoque e Almoxarifado',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: const Text(
                              'Habilita a visualização do catálogo, saldos, movimentações e requisições públicas de materiais.',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: _acessoEstoque,
                            activeThumbColor: Colors.blue.shade700,
                            onChanged: (val) => setState(() => _acessoEstoque = val),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _confirmarExclusao,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Excluir'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _salvar,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save),
                        label: const Text('Salvar Alterações'),
                        style: ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

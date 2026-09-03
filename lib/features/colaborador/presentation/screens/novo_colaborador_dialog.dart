import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/colaborador_provider.dart';

class NovoColaboradorDialog extends StatefulWidget {
  const NovoColaboradorDialog({super.key});

  @override
  State<NovoColaboradorDialog> createState() => _NovoColaboradorDialogState();
}

class _NovoColaboradorDialogState extends State<NovoColaboradorDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _matriculaController = TextEditingController();
  final _cargoController = TextEditingController();
  final _departamentoController = TextEditingController();

  DateTime _dataNascimento = DateTime(1995, 1, 1);
  DateTime _dataAdmissao = DateTime.now();
  bool _acessoEstoque = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
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

    // Remove caracteres não numéricos do CPF
    final cpfLimpo = _cpfController.text.replaceAll(RegExp(r'\D'), '');

    final sucesso = await provider.cadastrarColaborador(
      cpf: cpfLimpo,
      nome: _nomeController.text.trim(),
      emailCorporativo: _emailController.text.trim(),
      senha: _senhaController.text,
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
            content: Text('Colaborador cadastrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Erro ao cadastrar colaborador.'),
            backgroundColor: Colors.red,
          ),
        );
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
                      Icon(Icons.person_add, color: Colors.blue.shade700, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Novo Colaborador',
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
                        // Nome Completo
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

                        // CPF e E-mail Corporativo
                        Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: TextFormField(
                                controller: _cpfController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'CPF (11 dígitos) *',
                                  prefixIcon: Icon(Icons.credit_card),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  final limpo = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                                  if (limpo.length != 11) return 'CPF inválido';
                                  return null;
                                },
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

                        // Senha Temporária
                        TextFormField(
                          controller: _senhaController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Senha de Acesso Inicial *',
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.length < 6)
                              ? 'Senha deve ter no mínimo 6 caracteres'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Matrícula, Cargo e Departamento
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

                        // Datas (Nascimento e Admissão)
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

                        // Permissão de Módulo: Estoque & Almoxarifado
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
                            activeColor: Colors.blue.shade700,
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
                mainAxisAlignment: MainAxisAlignment.end,
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
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Salvar Colaborador'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
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

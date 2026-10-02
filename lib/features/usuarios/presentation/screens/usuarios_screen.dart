import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/cpf_input_formatter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/usuario_conta_model.dart';
import '../providers/usuario_provider.dart';

/// Gestão de contas administrativas da empresa (ADMIN_EMPRESA):
/// listar, criar (papéis GESTOR_RH/ADMIN_EMPRESA) e suspender.
class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsuarioProvider>().carregarUsuarios();
    });
  }

  String _papelLabel(String role) {
    switch (role) {
      case 'ADMIN_EMPRESA':
        return 'Admin da Empresa';
      case 'GESTOR_RH':
        return 'Gestor de RH';
      default:
        return role;
    }
  }

  Future<void> _confirmarSuspensao(UsuarioContaModel conta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Suspensão'),
        content: Text(
          'Deseja suspender o acesso de ${conta.nome} (${_papelLabel(conta.role)})?\n\n'
          'A conta deixa de autenticar (login, refresh e requisições) imediatamente '
          'após a próxima chamada; a reativação não está disponível nesta tela.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Suspender', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      final provider = context.read<UsuarioProvider>();
      final sucesso = await provider.suspenderUsuario(conta.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(sucesso
                ? 'Usuário ${conta.nome} suspenso com sucesso!'
                : provider.errorMessage ?? 'Erro ao suspender usuário.'),
            backgroundColor: sucesso ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _abrirDialogNovoUsuario() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const NovoUsuarioDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UsuarioProvider>();
    final logado = context.watch<AuthProvider>().usuario;
    final usuarios = provider.usuarios.where((u) {
      if (_filtro.isEmpty) return true;
      final query = _filtro.toLowerCase();
      return u.nome.toLowerCase().contains(query) ||
          u.cpf.contains(query) ||
          u.email.toLowerCase().contains(query) ||
          u.role.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Usuários da Empresa',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar lista',
            onPressed: () => provider.carregarUsuarios(),
          ),
          if (MediaQuery.sizeOf(context).width >= 600) ...[
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Novo Usuário'),
                onPressed: _abrirDialogNovoUsuario,
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirDialogNovoUsuario,
        icon: const Icon(Icons.person_add),
        label: const Text('Novo Usuário'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Buscar por nome, CPF, e-mail ou papel...',
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
                        '${usuarios.length} usuário(s)',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      backgroundColor: Colors.blue.shade50,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 48, color: Colors.red.shade400),
                              const SizedBox(height: 12),
                              Text(
                                provider.errorMessage!,
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => provider.carregarUsuarios(),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Tentar Novamente'),
                              ),
                            ],
                          ),
                        )
                      : usuarios.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.manage_accounts_outlined,
                                      size: 64,
                                      color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    _filtro.isEmpty
                                        ? 'Nenhuma conta administrativa cadastrada.'
                                        : 'Nenhum usuário encontrado para "$_filtro".',
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: usuarios.length,
                              itemBuilder: (context, index) {
                                final conta = usuarios[index];
                                final proprio =
                                    logado?.cpf != null &&
                                    logado!.cpf == conta.cpf;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor:
                                              Colors.deepPurple.shade50,
                                          child: Text(
                                            conta.nome.isNotEmpty
                                                ? conta.nome
                                                    .substring(0, 1)
                                                    .toUpperCase()
                                                : 'U',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  Colors.deepPurple.shade700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      conta.nome,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Chip(
                                                    label: Text(
                                                      _papelLabel(conta.role),
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight
                                                              .bold),
                                                    ),
                                                    backgroundColor:
                                                        Colors
                                                            .deepPurple.shade50,
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                  ),
                                                  if (proprio) ...[
                                                    const SizedBox(width: 4),
                                                    Chip(
                                                      label: const Text(
                                                        'Você',
                                                        style: TextStyle(
                                                            fontSize: 11),
                                                      ),
                                                      backgroundColor: Colors
                                                          .grey.shade200,
                                                      visualDensity:
                                                          VisualDensity
                                                              .compact,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Icon(Icons.credit_card,
                                                      size: 14,
                                                      color: Colors
                                                          .grey.shade600),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'CPF: ${conta.cpf}',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors
                                                            .grey.shade600),
                                                  ),
                                                  if (conta.email.isNotEmpty) ...[
                                                    const SizedBox(width: 16),
                                                    Icon(Icons.email_outlined,
                                                        size: 14,
                                                        color: Colors
                                                            .grey.shade600),
                                                    const SizedBox(width: 4),
                                                    Flexible(
                                                      child: Text(
                                                        conta.email,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors
                                                                .grey
                                                                .shade600),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: conta.ativo
                                                    ? Colors.green.shade50
                                                    : Colors.red.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: conta.ativo
                                                      ? Colors.green.shade300
                                                      : Colors.red.shade200,
                                                ),
                                              ),
                                              child: Text(
                                                conta.ativo
                                                    ? 'Ativo'
                                                    : 'Suspenso',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: conta.ativo
                                                      ? Colors.green.shade800
                                                      : Colors.red.shade800,
                                                ),
                                              ),
                                            ),
                                            if (conta.ativo && !proprio) ...[
                                              const SizedBox(height: 8),
                                              OutlinedButton.icon(
                                                icon: const Icon(
                                                    Icons.block,
                                                    size: 16),
                                                label:
                                                    const Text('Suspender'),
                                                style:
                                                    OutlinedButton.styleFrom(
                                                  foregroundColor:
                                                      Colors.red,
                                                  side: const BorderSide(
                                                      color: Colors.red),
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                ),
                                                onPressed: () =>
                                                    _confirmarSuspensao(
                                                        conta),
                                              ),
                                            ],
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

/// Dialog de criação de conta administrativa (papéis GESTOR_RH/ADMIN_EMPRESA).
class NovoUsuarioDialog extends StatefulWidget {
  const NovoUsuarioDialog({super.key});

  @override
  State<NovoUsuarioDialog> createState() => _NovoUsuarioDialogState();
}

class _NovoUsuarioDialogState extends State<NovoUsuarioDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  String _papel = 'GESTOR_RH';
  bool _isLoading = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final provider = context.read<UsuarioProvider>();
    final criado = await provider.criarUsuario(
      cpf: _cpfController.text.trim(),
      nome: _nomeController.text.trim(),
      emailCorporativo: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      senha: _senhaController.text,
      papel: _papel,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (criado != null) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuário criado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(provider.errorMessage ?? 'Erro ao criar usuário.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
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
                      Icon(Icons.person_add_alt,
                          color: Colors.deepPurple.shade700, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Novo Usuário',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
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
              Flexible(
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
                        TextFormField(
                          controller: _cpfController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [CpfInputFormatter()],
                          decoration: const InputDecoration(
                            labelText: 'CPF *',
                            prefixIcon: Icon(Icons.credit_card),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            final digits =
                                (v ?? '').replaceAll(RegExp(r'\D'), '');
                            if (digits.length != 11) {
                              return 'Informe um CPF com 11 dígitos';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'E-mail Corporativo',
                            hintText: 'Opcional',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            if (!v.contains('@') || !v.contains('.')) {
                              return 'Informe um e-mail válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _papel,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Papel *',
                            prefixIcon: Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'GESTOR_RH',
                              child: Text('Gestor de RH'),
                            ),
                            DropdownMenuItem(
                              value: 'ADMIN_EMPRESA',
                              child: Text('Admin da Empresa'),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _papel = v ?? 'GESTOR_RH'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _senhaController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Senha *',
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            final senha = v ?? '';
                            if (senha.length < 8) {
                              return 'Mínimo de 8 caracteres';
                            }
                            final temMaiuscula = senha.contains(RegExp(r'[A-Z]'));
                            final temMinuscula = senha.contains(RegExp(r'[a-z]'));
                            final temDigito = senha.contains(RegExp(r'\d'));
                            final temSimbolo =
                                senha.contains(RegExp(r'[^A-Za-z0-9]'));
                            if (!(temMaiuscula &&
                                temMinuscula &&
                                temDigito &&
                                temSimbolo)) {
                              return 'Use maiúscula, minúscula, número e símbolo';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmarSenhaController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirmar Senha *',
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v != _senhaController.text
                                  ? 'As senhas não coincidem'
                                  : null,
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
                    onPressed:
                        _isLoading ? null : () => Navigator.pop(context),
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
                    label: const Text('Criar Usuário'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
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

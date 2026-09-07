import 'package:flutter/material.dart';
import '../services/dados_publicos_service.dart';
import '../utils/cep_input_formatter.dart';
import '../utils/cnpj_input_formatter.dart';
import '../utils/cnpj_validator.dart';
import '../utils/cpf_input_formatter.dart';
import '../utils/telefone_input_formatter.dart';

/// Formulário reutilizável de cadastro de empresa.
///
/// Usado pela tela pública "Cadastrar Empresa" e pela tela admin "Nova Empresa".
/// Quando [mostrarCredenciaisResponsavel] é `true`, inclui os campos CPF e Senha
/// do responsável (jornada deslogada). No fluxo ADMIN_PLATAFORMA, fica `false`
/// para cadastrar apenas os dados da empresa e o contato do responsável.
class EmpresaFormFields extends StatefulWidget {
  const EmpresaFormFields({
    super.key,
    this.mostrarCredenciaisResponsavel = false,
    this.tituloSecaoContato = 'Dados do Administrador (responsável comercial)',
  });

  final bool mostrarCredenciaisResponsavel;
  final String tituloSecaoContato;

  @override
  EmpresaFormFieldsState createState() => EmpresaFormFieldsState();
}

class EmpresaFormFieldsState extends State<EmpresaFormFields> {
  final _formKey = GlobalKey<FormState>();

  final _cnpjController = TextEditingController();
  final _nomeEmpresaController = TextEditingController();
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _celularController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();
  final _senhaController = TextEditingController();

  final _endLogradouroController = TextEditingController();
  final _endNumeroController = TextEditingController();
  final _endComplementoController = TextEditingController();
  final _endBairroController = TextEditingController();
  final _endCidadeController = TextEditingController();
  final _endUfController = TextEditingController();
  final _endCepController = TextEditingController();

  bool _obscurePassword = true;
  bool _consultandoCnpj = false;
  bool _consultandoCep = false;

  final _dadosPublicosService = DadosPublicosService();

  bool validate() => _formKey.currentState?.validate() ?? false;

  String? _vazioOuNulo(TextEditingController controller) {
    final texto = controller.text.trim();
    return texto.isNotEmpty ? texto : null;
  }

  String get cnpj =>
      _cnpjController.text.replaceAll(RegExp(r'[^0-9A-Za-z]'), '').toUpperCase();

  String get nomeEmpresa => _nomeEmpresaController.text.trim();

  String get responsavelNome => _nomeController.text.trim();

  String? get responsavelCpf => _vazioOuNulo(_cpfController);

  String? get responsavelSenha =>
      widget.mostrarCredenciaisResponsavel ? _senhaController.text : null;

  String? get responsavelEmail => _vazioOuNulo(_emailController);

  String? get responsavelTelefone => _vazioOuNulo(_telefoneController);

  String? get responsavelCelular => _vazioOuNulo(_celularController);

  String? get enderecoLogradouro => _vazioOuNulo(_endLogradouroController);

  String? get enderecoNumero => _vazioOuNulo(_endNumeroController);

  String? get enderecoComplemento => _vazioOuNulo(_endComplementoController);

  String? get enderecoBairro => _vazioOuNulo(_endBairroController);

  String? get enderecoCidade => _vazioOuNulo(_endCidadeController);

  String? get enderecoUf => _vazioOuNulo(_endUfController);

  String? get enderecoCep => _vazioOuNulo(_endCepController);

  @override
  void dispose() {
    _cnpjController.dispose();
    _nomeEmpresaController.dispose();
    _nomeController.dispose();
    _telefoneController.dispose();
    _celularController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _senhaController.dispose();
    _endLogradouroController.dispose();
    _endNumeroController.dispose();
    _endComplementoController.dispose();
    _endBairroController.dispose();
    _endCidadeController.dispose();
    _endUfController.dispose();
    _endCepController.dispose();
    super.dispose();
  }

  Future<void> _consultarCnpj() async {
    if (!CnpjInputFormatter.isValidLength(_cnpjController.text)) {
      _mostrarErro('Informe um CNPJ com 14 caracteres antes de consultar.');
      return;
    }
    setState(() => _consultandoCnpj = true);
    final razaoSocial =
        await _dadosPublicosService.consultarRazaoSocialCnpj(_cnpjController.text);
    if (!mounted) return;
    setState(() => _consultandoCnpj = false);

    if (razaoSocial == null || razaoSocial.isEmpty) {
      _mostrarErro('CNPJ não encontrado. Verifique os dados e tente novamente.');
      return;
    }
    if (_nomeEmpresaController.text.trim().isEmpty) {
      _nomeEmpresaController.text = razaoSocial;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Razão Social preenchida com sucesso!')),
      );
    }
  }

  Future<void> _consultarCep() async {
    if (!CepInputFormatter.isValidLength(_endCepController.text)) {
      _mostrarErro('Informe um CEP com 8 dígitos antes de consultar.');
      return;
    }
    setState(() => _consultandoCep = true);
    final dados = await _dadosPublicosService.consultarCep(_endCepController.text);
    if (!mounted) return;
    setState(() => _consultandoCep = false);

    if (dados == null) {
      _mostrarErro('CEP não encontrado. Verifique os dados e tente novamente.');
      return;
    }
    _endLogradouroController.text = dados.rua ?? '';
    _endBairroController.text = dados.bairro ?? '';
    _endCidadeController.text = dados.cidade ?? '';
    _endUfController.text = dados.uf ?? '';
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Endereço preenchido com sucesso!')),
    );
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Legenda de obrigatoriedade
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '* = Obrigatório',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
          const SizedBox(height: 24),

          // Seção: Dados da Empresa
          _buildSectionHeader(context, 'Dados da Empresa', Icons.business),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cnpjController,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [CnpjInputFormatter()],
                  decoration: InputDecoration(
                    labelText: 'CNPJ *',
                    hintText: '00.000.000/0001-00',
                    prefixIcon: const Icon(Icons.assignment_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o CNPJ';
                    }
                    if (CnpjInputFormatter.clean(value).length != 14) {
                      return 'O CNPJ deve conter 14 caracteres';
                    }
                    if (!CnpjValidator.isValid(value)) {
                      return 'CNPJ inválido';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: _consultandoCnpj ? null : _consultarCnpj,
                  icon: _consultandoCnpj
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.search),
                  label: const Text('Consultar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _nomeEmpresaController,
            decoration: InputDecoration(
              labelText: 'Razão Social / Nome da Empresa *',
              prefixIcon: const Icon(Icons.business_center),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Informe o nome da empresa'
                : null,
          ),
          const SizedBox(height: 24),

          // Seção: Endereço
          _buildSectionHeader(context, 'Endereço', Icons.location_on_outlined),
          const SizedBox(height: 12),

          _buildEnderecoFields(),
          const SizedBox(height: 24),

          // Seção: Contato do Responsável
          _buildSectionHeader(
            context,
            widget.tituloSecaoContato,
            Icons.admin_panel_settings,
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _nomeController,
            decoration: InputDecoration(
              labelText: 'Nome Completo *',
              prefixIcon: const Icon(Icons.badge_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (v) {
              final nome = v?.trim() ?? '';
              if (nome.isEmpty) return 'Informe o nome completo';
              if (nome.length < 3) return 'Nome deve ter no mínimo 3 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _telefoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              TelefoneInputFormatter(digitCount: TelDigitCount.fixo),
            ],
            decoration: InputDecoration(
              labelText: 'Telefone',
              hintText: '(00) 0000-0000',
              prefixIcon: const Icon(Icons.call_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return null;
              return TelefoneInputFormatter.isValidLength(value)
                  ? null
                  : 'Telefone deve ter 10 dígitos';
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _celularController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              TelefoneInputFormatter(digitCount: TelDigitCount.celular),
            ],
            decoration: InputDecoration(
              labelText: 'Celular',
              hintText: '(00) 00000-0000',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return null;
              return TelefoneInputFormatter.isValidLength(value)
                  ? null
                  : 'Celular deve ter 11 dígitos';
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'E-mail *',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Informe o e-mail';
              }
              if (!v.contains('@') || !v.contains('.')) {
                return 'Informe um e-mail válido';
              }
              return null;
            },
          ),

          if (widget.mostrarCredenciaisResponsavel) ...[
            const SizedBox(height: 16),

            TextFormField(
              controller: _cpfController,
              keyboardType: TextInputType.number,
              inputFormatters: [CpfInputFormatter()],
              decoration: InputDecoration(
                labelText: 'CPF (Login) *',
                hintText: '000.000.000-00',
                prefixIcon: const Icon(Icons.credit_card),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o CPF';
                }
                if (!CpfInputFormatter.isValidLength(value)) {
                  return 'CPF deve ter 11 dígitos';
                }
                if (!CpfInputFormatter.isValid(value)) {
                  return 'CPF inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _senhaController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Senha *',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Informe a senha';
                }
                if (v.length < 6) {
                  return 'A senha deve ter no mínimo 6 caracteres';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEnderecoFields() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final emColuna = constraints.maxWidth < 520;

        final campoCep = _buildCampoCep();
        final campoLogradouro = _buildCampoEndereco(
          controller: _endLogradouroController,
          label: 'Logradouro',
          hint: 'Rua, Avenida...',
          icon: Icons.signpost_outlined,
        );
        final campoNumero = _buildCampoEndereco(
          controller: _endNumeroController,
          label: 'Número',
          hint: 'Nº',
          icon: Icons.tag,
        );
        final campoComplemento = _buildCampoEndereco(
          controller: _endComplementoController,
          label: 'Complemento',
          hint: 'Bloco, Apto, Andar...',
          icon: Icons.add_home_outlined,
        );
        final campoBairro = _buildCampoEndereco(
          controller: _endBairroController,
          label: 'Bairro',
          hint: 'Bairro',
          icon: Icons.location_city,
        );
        final campoCidade = _buildCampoEndereco(
          controller: _endCidadeController,
          label: 'Cidade',
          hint: 'Cidade',
          icon: Icons.location_on_outlined,
        );
        final campoUf = _buildCampoEndereco(
          controller: _endUfController,
          label: 'UF',
          hint: 'UF',
          icon: Icons.map_outlined,
        );

        if (emColuna) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              campoCep,
              const SizedBox(height: 12),
              campoLogradouro,
              const SizedBox(height: 12),
              campoNumero,
              const SizedBox(height: 12),
              campoComplemento,
              const SizedBox(height: 12),
              campoBairro,
              const SizedBox(height: 12),
              campoCidade,
              const SizedBox(height: 12),
              campoUf,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            campoCep,
            const SizedBox(height: 12),
            campoLogradouro,
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: campoNumero,
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: campoComplemento,
                ),
              ],
            ),
            const SizedBox(height: 12),
            campoBairro,
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: campoCidade,
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: campoUf,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCampoCep() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _endCepController,
            keyboardType: TextInputType.number,
            inputFormatters: [CepInputFormatter()],
            decoration: InputDecoration(
              labelText: 'CEP',
              hintText: '00000-000',
              prefixIcon: const Icon(Icons.mail_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                if (!CepInputFormatter.isValidLength(value)) {
                  return 'CEP deve ter 8 dígitos';
                }
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: _consultandoCep ? null : _consultarCep,
            icon: _consultandoCep
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.search),
            label: const Text('Consultar'),
          ),
        ),
      ],
    );
  }

  Widget _buildCampoEndereco({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
          ),
        ),
        const Expanded(child: Divider(indent: 12)),
      ],
    );
  }
}
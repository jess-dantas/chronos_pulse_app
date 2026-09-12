import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/dados_publicos_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/cep_input_formatter.dart';
import '../../../../core/utils/cnpj_input_formatter.dart';
import '../../../../core/utils/cnpj_validator.dart';
import '../../../../core/utils/telefone_input_formatter.dart';
import '../../data/repositories/lead_repository.dart';

class CadastrarEmpresaScreen extends StatefulWidget {
  const CadastrarEmpresaScreen({super.key});

  @override
  State<CadastrarEmpresaScreen> createState() => _CadastrarEmpresaScreenState();
}

class _CadastrarEmpresaScreenState extends State<CadastrarEmpresaScreen> {
  static const List<String> _etapas = [
    'Dados da Empresa',
    'Endereço',
    'Contato',
  ];

  final _formKey = GlobalKey<FormState>();

  final _cnpjController = TextEditingController();
  final _razaoSocialController = TextEditingController();

  final _endCepController = TextEditingController();
  final _endLogradouroController = TextEditingController();
  final _endNumeroController = TextEditingController();
  final _endComplementoController = TextEditingController();
  final _endBairroController = TextEditingController();
  final _endCidadeController = TextEditingController();
  final _endUfController = TextEditingController();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _celularController = TextEditingController();
  final _observacaoController = TextEditingController();

  final _dadosPublicosService = DadosPublicosService();

  int _etapa = 0;
  bool _consultandoCnpj = false;
  bool _consultandoCep = false;
  bool _enviando = false;
  bool _sucesso = false;

  @override
  void dispose() {
    _cnpjController.dispose();
    _razaoSocialController.dispose();
    _endCepController.dispose();
    _endLogradouroController.dispose();
    _endNumeroController.dispose();
    _endComplementoController.dispose();
    _endBairroController.dispose();
    _endCidadeController.dispose();
    _endUfController.dispose();
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _celularController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  String? _vazioOuNulo(TextEditingController controller) {
    final texto = controller.text.trim();
    return texto.isNotEmpty ? texto : null;
  }

  Future<void> _consultarCnpj() async {
    if (CnpjInputFormatter.clean(_cnpjController.text).length != 14) {
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
    if (_razaoSocialController.text.trim().isEmpty) {
      _razaoSocialController.text = razaoSocial;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Razão Social preenchida com sucesso!')),
      );
    }
  }

  Future<void> _consultarCep() async {
    if (CepInputFormatter.clean(_endCepController.text).length != 8) {
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
    setState(() {
      _endLogradouroController.text = dados.rua ?? '';
      _endBairroController.text = dados.bairro ?? '';
      _endCidadeController.text = dados.cidade ?? '';
      _endUfController.text = dados.uf ?? '';
    });
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

  void _avancar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _etapa = _etapa + 1);
  }

  void _voltar() {
    if (_etapa == 0) {
      context.go('/');
      return;
    }
    setState(() => _etapa = _etapa - 1);
  }

  Future<void> _enviar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _enviando = true);
    try {
      await context.read<LeadRepository>().cadastrar(
            LeadEmpresaRequest(
              cnpj: _cnpjController.text,
              razaoSocial: _razaoSocialController.text.trim(),
              contatoNome: _nomeController.text.trim(),
              contatoEmail: _emailController.text.trim(),
              contatoTelefone: _vazioOuNulo(_telefoneController),
              contatoCelular: _vazioOuNulo(_celularController),
              enderecoLogradouro: _vazioOuNulo(_endLogradouroController),
              enderecoNumero: _vazioOuNulo(_endNumeroController),
              enderecoComplemento: _vazioOuNulo(_endComplementoController),
              enderecoBairro: _vazioOuNulo(_endBairroController),
              enderecoCidade: _vazioOuNulo(_endCidadeController),
              enderecoUf: _vazioOuNulo(_endUfController),
              enderecoCep: _vazioOuNulo(_endCepController),
              observacao: _vazioOuNulo(_observacaoController),
            ),
          );
      if (mounted) setState(() => _sucesso = true);
    } catch (e) {
      _mostrarErro(e.toString());
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Voltar',
          onPressed: () => context.go('/'),
        ),
        title: const Text('Cadastro de Empresa'),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            tooltip: themeProvider.isDarkMode ? 'Tema Claro' : 'Tema Escuro',
            onPressed: () => themeProvider.toggleTheme(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: _sucesso
                      ? _buildSucesso(colorScheme)
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildCabecalho(colorScheme),
                            const SizedBox(height: 16),
                            _buildIndicadorEtapas(colorScheme),
                            const SizedBox(height: 16),
                            Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildEtapaConteudo(),
                                  const SizedBox(height: 24),
                                  _buildNavegacao(),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCabecalho(ColorScheme colorScheme) {
    return Column(
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/logo.png',
              height: 64,
              fit: BoxFit.contain,
              semanticLabel: 'Logo Chronos Pulse',
              errorBuilder: (context, error, stackTrace) => Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fingerprint,
                  size: 32,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Quero experimentar o Chronos Pulse',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Passo rápido e sem compromisso — sem criar conta, sem CPF e sem senha. '
          'Nossa equipe entrará em contato para agendar uma conversa.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }

  Widget _buildIndicadorEtapas(ColorScheme colorScheme) {
    return Row(
      children: [
        for (var i = 0; i < _etapas.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 3,
                color: i <= _etapa
                    ? colorScheme.primary
                    : Colors.grey.shade300,
              ),
            ),
          _circuloEtapa(i, colorScheme),
        ],
      ],
    );
  }

  Widget _circuloEtapa(int i, ColorScheme colorScheme) {
    final ativo = i <= _etapa;
    return Tooltip(
      message: _etapas[i],
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ativo ? colorScheme.primary : Colors.grey.shade300,
        ),
        child: Icon(
          _etapaConcluida(i) ? Icons.check : _iconeEtapa(i),
          size: 18,
          color: ativo ? colorScheme.onPrimary : Colors.grey.shade600,
        ),
      ),
    );
  }

  bool _etapaConcluida(int i) => i < _etapa;

  IconData _iconeEtapa(int i) {
    switch (i) {
      case 0:
        return Icons.business_outlined;
      case 1:
        return Icons.location_on_outlined;
      default:
        return Icons.admin_panel_settings_outlined;
    }
  }

  Widget _buildEtapaConteudo() {
    switch (_etapa) {
      case 0:
        return _buildEtapaEmpresa();
      case 1:
        return _buildEtapaEndereco();
      default:
        return _buildEtapaContato();
    }
  }

  Widget _buildEtapaEmpresa() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('Dados da Empresa'),
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
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: const Text('Consultar'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _razaoSocialController,
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
      ],
    );
  }

  Widget _buildEtapaEndereco() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('Endereço'),
        const SizedBox(height: 4),
        Text(
          'Opcional. Podemos preencher automaticamente pelo CEP.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        const SizedBox(height: 12),
        _buildCampoCep(),
        const SizedBox(height: 12),
        _buildCampoEndereco(
          controller: _endLogradouroController,
          label: 'Logradouro',
          hint: 'Rua, Avenida...',
          icon: Icons.signpost_outlined,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildCampoEndereco(
                controller: _endNumeroController,
                label: 'Número',
                hint: 'Nº',
                icon: Icons.tag,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: _buildCampoEndereco(
                controller: _endComplementoController,
                label: 'Complemento',
                hint: 'Bloco, Apto, Andar...',
                icon: Icons.add_home_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCampoEndereco(
          controller: _endBairroController,
          label: 'Bairro',
          hint: 'Bairro',
          icon: Icons.location_city,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _buildCampoEndereco(
                controller: _endCidadeController,
                label: 'Cidade',
                hint: 'Cidade',
                icon: Icons.location_on_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _buildCampoEndereco(
                controller: _endUfController,
                label: 'UF',
                hint: 'UF',
                icon: Icons.map_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEtapaContato() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('Contato Comercial'),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nomeController,
          decoration: InputDecoration(
            labelText: 'Nome do Responsável *',
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _telefoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [TelefoneInputFormatter(digitCount: TelDigitCount.fixo)],
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
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _celularController,
                keyboardType: TextInputType.phone,
                inputFormatters: [TelefoneInputFormatter(digitCount: TelDigitCount.celular)],
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
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'E-mail para Contato *',
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
        const SizedBox(height: 16),
        TextFormField(
          controller: _observacaoController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Como você conheceu o Chronos Pulse?',
            prefixIcon: const Icon(Icons.chat_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavegacao() {
    final ehUltimaEtapa = _etapa == _etapas.length - 1;
    return Row(
      children: [
        if (_etapa > 0)
          OutlinedButton.icon(
            onPressed: _enviando ? null : _voltar,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Voltar'),
          ),
        const Spacer(),
        if (!ehUltimaEtapa)
          FilledButton.icon(
            onPressed: _avancar,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Continuar'),
          )
        else
          ElevatedButton.icon(
            onPressed: _enviando ? null : _enviar,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAction(context),
              foregroundColor: Colors.white,
            ),
            icon: _enviando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_outlined),
            label: Text(_enviando ? 'Enviando...' : 'Enviar Interesse'),
          ),
      ],
    );
  }

  Widget _buildSucesso(ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle, size: 72, color: Colors.green),
        const SizedBox(height: 16),
        Text(
          'Recebemos seus dados!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Nossa equipe entrará em contato para agendar uma conversa '
          'sobre o Chronos Pulse na sua empresa.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: () => context.go('/'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAction(context),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Voltar ao início',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
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
                if (CepInputFormatter.clean(value).length != 8) {
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
                    child: CircularProgressIndicator(strokeWidth: 2),
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

  Widget _buildSectionHeader(String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider(indent: 4)),
      ],
    );
  }
}
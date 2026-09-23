import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/hardware/hardware_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../colaborador/data/models/colaborador_model.dart';
import '../../../colaborador/presentation/providers/colaborador_provider.dart';
import '../providers/titularidade_provider.dart';

/// Assistente de transferência de titularidade (`/perfil/titularidade`).
///
/// Etapas:
/// 1. Seleciona o novo titular e confirma a biometria do solicitante
///    (no Web a biometria é confirmada automaticamente — limitação do
///    `local_auth` no navegador).
/// 2. Envia OTP para o e-mail do titular atual e exige a confirmação do
///    celular do novo titular (booleano de atestação).
/// 3. Envia OTP para o e-mail corporativo do novo titular e conclui
///    (sessão encerrada — o novo titular precisa logar novamente).
class TransferirTitularidadeScreen extends StatefulWidget {
  const TransferirTitularidadeScreen({super.key});

  @override
  State<TransferirTitularidadeScreen> createState() =>
      _TransferirTitularidadeScreenState();
}

class _TransferirTitularidadeScreenState
    extends State<TransferirTitularidadeScreen> {
  final HardwareService _hardware = HardwareService();
  final _codigoCelularController = TextEditingController();
  final _codigoEmailController = TextEditingController();

  ColaboradorModel? _novoTitular;
  bool _celularConfirmado = false;
  bool _acaoEmAndamento = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final colaboradores = context.read<ColaboradorProvider>();
      if (colaboradores.colaboradores.isEmpty) {
        colaboradores.carregarColaboradores();
      }
      // Estado limpo a cada entrada (transferências antigas ficam no backend
      // e são canceladas automaticamente ao iniciar uma nova).
      context.read<TitularidadeProvider>().limpar();
    });
  }

  @override
  void dispose() {
    _codigoCelularController.dispose();
    _codigoEmailController.dispose();
    super.dispose();
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.redAccent),
    );
  }

  void _mostrarSucesso(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.green.shade700),
    );
  }

  Future<void> _iniciarEConfirmarBiometria() async {
    final titProvider = context.read<TitularidadeProvider>();
    final selecionado = _novoTitular;

    if (selecionado == null) {
      _mostrarErro('Selecione o novo titular da empresa.');
      return;
    }

    setState(() => _acaoEmAndamento = true);
    try {
      if (titProvider.iniciado == null) {
        final iniciado = await titProvider.iniciar(selecionado.id);
        if (iniciado == null) {
          _mostrarErro(titProvider.errorMessage ?? 'Erro ao iniciar.');
          return;
        }
      }

      final autenticado = await _hardware
          .autenticarBiometria()
          .timeout(const Duration(seconds: 8));
      if (!autenticado) {
        _mostrarErro('Autenticação biométrica cancelada.');
        return;
      }

      final ok = await titProvider.confirmarBiometria();
      if (!ok) {
        _mostrarErro(titProvider.errorMessage ?? 'Falha na biometria.');
        return;
      }
      setState(() {});
    } catch (e) {
      _mostrarErro(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _acaoEmAndamento = false);
    }
  }

  Future<void> _enviarCodigoCelular() async {
    final titProvider = context.read<TitularidadeProvider>();
    setState(() => _acaoEmAndamento = true);
    try {
      final destino = await titProvider.enviarCodigoCelular();
      if (destino == null) {
        _mostrarErro(titProvider.errorMessage ?? 'Erro ao enviar o código.');
        return;
      }
      _mostrarSucesso(destino.isEmpty
          ? 'Código enviado com sucesso.'
          : 'Código enviado para $destino.');
    } finally {
      if (mounted) setState(() => _acaoEmAndamento = false);
    }
  }

  Future<void> _verificarCelular() async {
    final titProvider = context.read<TitularidadeProvider>();
    final codigo = _codigoCelularController.text.trim();

    if (!_celularConfirmado) {
      _mostrarErro('Confirme o celular do novo titular.');
      return;
    }
    if (codigo.length != 6) {
      _mostrarErro('Informe o código de 6 dígitos.');
      return;
    }

    setState(() => _acaoEmAndamento = true);
    try {
      final ok = await titProvider.verificarCelular(
        codigo: codigo,
        celularConfirmado: true,
      );
      if (!ok) {
        _mostrarErro(titProvider.errorMessage ?? 'Código inválido.');
        return;
      }
      _codigoCelularController.clear();
      setState(() {});
    } finally {
      if (mounted) setState(() => _acaoEmAndamento = false);
    }
  }

  Future<void> _enviarCodigoEmail() async {
    final titProvider = context.read<TitularidadeProvider>();
    setState(() => _acaoEmAndamento = true);
    try {
      final destino = await titProvider.enviarCodigoEmail();
      if (destino == null) {
        _mostrarErro(titProvider.errorMessage ?? 'Erro ao enviar o código.');
        return;
      }
      _mostrarSucesso(destino.isEmpty
          ? 'Código enviado com sucesso.'
          : 'Código enviado para $destino.');
    } finally {
      if (mounted) setState(() => _acaoEmAndamento = false);
    }
  }

  Future<void> _verificarEmailEConcluir() async {
    final titProvider = context.read<TitularidadeProvider>();
    final codigo = _codigoEmailController.text.trim();

    if (codigo.length != 6) {
      _mostrarErro('Informe o código de 6 dígitos.');
      return;
    }

    setState(() => _acaoEmAndamento = true);
    try {
      final ok = await titProvider.verificarEmail(codigo: codigo);
      if (!ok) {
        _mostrarErro(titProvider.errorMessage ?? 'Código inválido.');
        return;
      }
      _codigoEmailController.clear();
      setState(() {});
    } finally {
      if (mounted) setState(() => _acaoEmAndamento = false);
    }
  }

  Future<void> _concluir() async {
    final titProvider = context.read<TitularidadeProvider>();
    final auth = context.read<AuthProvider>();

    setState(() => _acaoEmAndamento = true);
    try {
      final ok = await titProvider.concluir();
      if (!ok) {
        _mostrarErro(
            titProvider.errorMessage ?? 'Erro ao concluir a transferência.');
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Titularidade transferida. Sua sessão será encerrada — o novo '
            'titular deve entrar novamente.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );
      await auth.logout();
      if (mounted) context.go('/login');
    } finally {
      if (mounted) setState(() => _acaoEmAndamento = false);
    }
  }

  Future<void> _cancelar() async {
    final titProvider = context.read<TitularidadeProvider>();
    setState(() => _acaoEmAndamento = true);
    try {
      final ok = await titProvider.cancelar();
      if (!ok) {
        _mostrarErro(titProvider.errorMessage ?? 'Erro ao cancelar.');
        return;
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _acaoEmAndamento = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titProvider = context.watch<TitularidadeProvider>();
    final colaboradorProvider = context.watch<ColaboradorProvider>();
    final auth = context.watch<AuthProvider>();
    final etapa = titProvider.etapa;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transferir titularidade'),
        actions: [
          if (titProvider.iniciado != null && !titProvider.concluida)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancelar transferência',
              onPressed: _acaoEmAndamento ? null : _cancelar,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Como funciona',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'A transferência exige 3 confirmações: biometria do '
                    'titular atual, código enviado ao e-mail do titular atual '
                    'com confirmação do celular do novo titular e código '
                    'enviado ao e-mail corporativo do novo titular. '
                    'A validade de cada etapa é de 30 minutos.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _IndicadorEtapas(etapaAtual: etapa),
          const SizedBox(height: 16),
          if (etapa == 1)
            _etapa1SelecaoBiometria(
                context, titProvider, colaboradorProvider, auth),
          if (etapa == 2) _etapa2Celular(context, titProvider),
          if (etapa >= 3) _etapa3Email(context, titProvider),
          if (titProvider.errorMessage != null &&
              titProvider.errorMessage!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              titProvider.errorMessage!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
        ],
      ),
    );
  }

  Widget _etapa1SelecaoBiometria(
    BuildContext context,
    TitularidadeProvider titProvider,
    ColaboradorProvider colaboradorProvider,
    AuthProvider auth,
  ) {
    final cpfAtual = auth.usuario?.cpf;
    final cpcAtual = auth.usuario?.cpcId;
    final candidatos = colaboradorProvider.colaboradores.where((c) {
      if (!c.ativo) return false;
      if (cpfAtual != null && cpfAtual.isNotEmpty && c.cpf == cpfAtual) {
        return false;
      }
      if (cpcAtual != null && cpcAtual.isNotEmpty && c.cpcUsuarioId == cpcAtual) {
        return false;
      }
      return true;
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Novo titular + biometria',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Escolha o colaborador que receberá a titularidade e confirme '
              'sua identidade por biometria.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            if (colaboradorProvider.isLoading && candidatos.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ))
            else if (candidatos.isEmpty)
              const Text('Nenhum colaborador elegível encontrado.')
            else
              RadioGroup<ColaboradorModel>(
                groupValue: _novoTitular,
                onChanged: (valor) {
                  if (titProvider.iniciado != null) return;
                  setState(() => _novoTitular = valor);
                },
                child: Column(
                  children: candidatos
                      .map(
                        (c) => RadioListTile<ColaboradorModel>(
                          value: c,
                          title: Text(c.nome),
                          subtitle: Text(
                            [
                              if (c.cargo.isNotEmpty) c.cargo,
                              if (c.email.isNotEmpty) c.email,
                              if (c.celular != null && c.celular!.isNotEmpty)
                                'Celular: ${c.celular}',
                            ].join(' • '),
                          ),
                          dense: true,
                        ),
                      )
                      .toList(),
                ),
              ),
            const SizedBox(height: 8),
            if (titProvider.iniciado != null &&
                titProvider.biometriaConfirmada)
              const ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('Biometria confirmada'),
                subtitle: Text('Etapa 1 concluída — siga para a etapa 2.'),
                dense: true,
              )
            else ...[
              if (titProvider.iniciado != null && _novoTitular != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Novo titular: ${titProvider.iniciado!.novoTitularNome}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              FilledButton.icon(
                onPressed:
                    _acaoEmAndamento ? null : _iniciarEConfirmarBiometria,
                icon: _acaoEmAndamento
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.fingerprint),
                label: Text(
                  titProvider.iniciado == null
                      ? 'Iniciar e confirmar biometria'
                      : 'Confirmar biometria',
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'No navegador a biometria é confirmada automaticamente '
              '(limitação do suporte a biometria em Web).',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _etapa2Celular(
      BuildContext context, TitularidadeProvider titProvider) {
    final celular = titProvider.iniciado?.novoTitularCelular ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '2. Celular do novo titular',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Um código de 6 dígitos será enviado ao e-mail do titular '
              'atual. Confirme também o celular do novo titular.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.phone_iphone),
              title: Text(
                celular.isEmpty ? 'Celular não informado' : celular,
              ),
              subtitle: const Text('Celular do novo titular'),
              dense: true,
            ),
            CheckboxListTile(
              value: _celularConfirmado,
              title: const Text(
                'Confirmo que este é o celular correto do novo titular',
                style: TextStyle(fontSize: 14),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              onChanged: (valor) =>
                  setState(() => _celularConfirmado = valor ?? false),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _acaoEmAndamento
                        ? null
                        : _enviarCodigoCelular,
                    icon: const Icon(Icons.mail_outline),
                    label: Text(titProvider.destinoCelular == null
                        ? 'Enviar código'
                        : 'Reenviar código'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _codigoCelularController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Código (6 dígitos)',
                      counterText: '',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _acaoEmAndamento ? null : _verificarCelular,
                icon: _acaoEmAndamento
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified_user_outlined),
                label: const Text('Confirmar celular e código'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _etapa3Email(
      BuildContext context, TitularidadeProvider titProvider) {
    final prontoParaConcluir = titProvider.podeConcluir;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '3. E-mail corporativo do novo titular',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              titProvider.emailVerificado
                  ? 'E-mail confirmado. Conclua a transferência abaixo.'
                  : 'Um código de 6 dígitos será enviado ao e-mail '
                      'corporativo de ${titProvider.iniciado?.novoTitularNome ?? 'novo titular'}.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            if (!titProvider.emailVerificado) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _acaoEmAndamento ? null : _enviarCodigoEmail,
                      icon: const Icon(Icons.alternate_email),
                      label: Text(titProvider.destinoEmail == null
                          ? 'Enviar código'
                          : 'Reenviar código'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _codigoEmailController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'Código (6 dígitos)',
                        counterText: '',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _acaoEmAndamento ? null : _verificarEmailEConcluir,
                  icon: _acaoEmAndamento
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.mark_email_read_outlined),
                  label: const Text('Confirmar e-mail do novo titular'),
                ),
              ),
            ] else ...[
              const ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('E-mail do novo titular confirmado'),
                dense: true,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: (_acaoEmAndamento || !prontoParaConcluir)
                      ? null
                      : _concluir,
                  icon: _acaoEmAndamento
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.swap_horiz),
                  label: const Text('Concluir transferência'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ao concluir, seu papel vira COLABORADOR e a sessão é '
                'encerrada. O novo titular fará login para assumir a empresa.',
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IndicadorEtapas extends StatelessWidget {
  final int etapaAtual;

  const _IndicadorEtapas({required this.etapaAtual});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const rotulos = ['Biometria', 'Celular', 'E-mail'];

    return Row(
      children: [
        for (var i = 1; i <= 3; i++) ...[
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: etapaAtual > i
                      ? Colors.green
                      : etapaAtual == i
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                  child: etapaAtual > i
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text(
                          '$i',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: etapaAtual == i
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  rotulos[i - 1],
                  style: TextStyle(
                    fontSize: 11,
                    color: etapaAtual >= i
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (i < 3)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 18),
                color: etapaAtual > i
                    ? Colors.green
                    : colorScheme.surfaceContainerHighest,
              ),
            ),
        ],
      ],
    );
  }
}

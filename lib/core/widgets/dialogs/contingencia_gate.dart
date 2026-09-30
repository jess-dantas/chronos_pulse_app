import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/privacidade/presentation/providers/privacidade_provider.dart';
import '../../config/app_modo.dart';
import '../../errors/mensagens_erro.dart';
import '../../hardware/hardware_service.dart';
import '../../security/device_token_store.dart';
import '../../telemetry/telemetry_service.dart';

/// Gate de contingência "Bater ponto sem login" — 1º acesso no app cliente.
///
/// Modal bloqueante (espelha o [ConsentimentoGate]): quando a sessão abriu
/// **sem vínculo de dispositivo ativo** e o aparelho **tem biometria
/// cadastrada**, o usuário deve ativar a contingência para prosseguir
/// (roadmap: forçar o cadastro de biometria no primeiro acesso).
///
/// Saídas (o gate nunca trava o app):
/// - aparelho **sem biometria** → explica a indisponibilidade e permite
///   continuar (bater ponto passa a depender do login);
/// - **falha técnica** na ativação (rede/servidor) → permite continuar;
/// - **biometria cancelada** → permanece no modal com "Tentar novamente"
///   (a saída livre exigiria exatamente a biometria que se quer garantir).
///
/// Sequência: só avalia depois que o Termo de Ciência (LGPD) não está
/// pendente — nunca dois modais empilhados. Após ativar, mostra o toast de
/// sucesso. Inativo em web/admin (`ativo`).
class ContingenciaGate extends StatefulWidget {
  final Widget child;

  /// null = padrão do build (`APP_MODE=cliente` e não-web).
  final bool? ativo;

  /// Injeções opcionais (testes).
  final DeviceTokenStore? store;
  final HardwareService? hardwareService;

  const ContingenciaGate({
    super.key,
    required this.child,
    this.ativo,
    this.store,
    this.hardwareService,
  });

  @override
  State<ContingenciaGate> createState() => _ContingenciaGateState();
}

class _ContingenciaGateState extends State<ContingenciaGate> {
  bool _verificado = false;
  bool _modalAberto = false;

  bool get _ativo =>
      widget.ativo ?? (AppModo.atual == AppModo.cliente && !kIsWeb);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verificar());
  }

  Future<void> _verificar() async {
    if (!mounted || _verificado || !_ativo) return;
    _verificado = true;

    try {
      // 1) Termo de Ciência primeiro: se o aceite está pendente, o
      //    ConsentimentoGate cuida disso — não empilhamos um segundo modal
      //    (e reavaliamos na próxima sessão, com o termo já aceito).
      final privacidade = context.read<PrivacidadeProvider>();
      await privacidade.carregarStatusConsentimento();
      if (!mounted || privacidade.consentimentoPendente) return;

      // 2) Só com sessão ativa (belt: o shell só monta autenticado).
      if (!context.read<AuthProvider>().isAuthenticated) return;

      // 3) Contingência já pronta? nada a fazer.
      final store = widget.store ?? DeviceTokenStore.instancia;
      if (await store.vinculoAtivo()) return;
      if (!mounted) return;

      _abrirModal();
    } catch (_) {
      // Fail-safe: qualquer erro adia o gate para a próxima sessão.
    }
  }

  void _abrirModal() {
    if (_modalAberto || !mounted) return;
    _modalAberto = true;
    final auth = context.read<AuthProvider>();
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ContingenciaDialog(
        authProvider: auth,
        hardwareService: widget.hardwareService ?? HardwareService(),
      ),
    ).then((ativou) {
      _modalAberto = false;
      if (ativou == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bater ponto sem login ativado!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

enum _EstadoDialogo { checando, pronto, processando, semBiometria, cancelada, erroTecnico }

class _ContingenciaDialog extends StatefulWidget {
  final AuthProvider authProvider;
  final HardwareService hardwareService;

  const _ContingenciaDialog({
    required this.authProvider,
    required this.hardwareService,
  });

  @override
  State<_ContingenciaDialog> createState() => _ContingenciaDialogState();
}

class _ContingenciaDialogState extends State<_ContingenciaDialog> {
  _EstadoDialogo _estado = _EstadoDialogo.checando;
  String? _mensagem;

  @override
  void initState() {
    super.initState();
    _checarDisponibilidade();
  }

  Future<void> _checarDisponibilidade() async {
    bool disponivel = false;
    try {
      disponivel = await widget.hardwareService.biometriaDisponivel();
    } catch (_) {
      disponivel = false;
    }
    if (!mounted) return;
    setState(() {
      _estado = disponivel ? _EstadoDialogo.pronto : _EstadoDialogo.semBiometria;
      _mensagem = null;
    });
  }

  Future<void> _ativar() async {
    setState(() {
      _estado = _EstadoDialogo.processando;
      _mensagem = null;
    });

    bool autenticado;
    try {
      autenticado = await widget.hardwareService
          .autenticarBiometria()
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      if (!mounted) return;
      context.telemetria?.registrar(
        tipo: TipoEventoTelemetria.contingencia,
        modulo: 'PONTO',
        mensagem: 'Falha técnica no gate de contingência',
        detalhe: 'biometria',
      );
      setState(() {
        _estado = _EstadoDialogo.erroTecnico;
        _mensagem = mensagemErroAmigavel(
          e,
          fallback: 'Não foi possível validar sua biometria.',
        );
      });
      return;
    }

    if (!autenticado) {
      if (!mounted) return;
      context.telemetria?.registrar(
        tipo: TipoEventoTelemetria.contingencia,
        modulo: 'PONTO',
        mensagem: 'Biometria cancelada no gate de contingência',
      );
      setState(() {
        _estado = _EstadoDialogo.cancelada;
        _mensagem = 'Autenticação biométrica cancelada.';
      });
      return;
    }

    final expira = await widget.authProvider.ativarVinculoDispositivo();
    if (!mounted) return;
    if (expira == null) {
      context.telemetria?.registrar(
        tipo: TipoEventoTelemetria.contingencia,
        modulo: 'PONTO',
        mensagem: 'Falha técnica no gate de contingência',
        detalhe: 'ativacao_vinculo',
      );
      setState(() {
        _estado = _EstadoDialogo.erroTecnico;
        _mensagem = widget.authProvider.errorMessage ??
            'Não foi possível ativar o Bater ponto sem login. Tente novamente.';
      });
      return;
    }
    context.telemetria?.registrar(
      tipo: TipoEventoTelemetria.contingencia,
      modulo: 'PONTO',
      mensagem: 'Contingência ativada no 1º acesso',
    );
    Navigator.of(context).pop(true);
  }

  void _continuarSemContingencia() => Navigator.of(context).pop(false);

  Widget _icone(Color cor, IconData icone) => Icon(icone, size: 48, color: cor);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    Widget? conteudo;
    List<Widget>? acoes;

    switch (_estado) {
      case _EstadoDialogo.checando:
        conteudo = const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Verificando biometria...'),
          ],
        );
        acoes = const [];
      case _EstadoDialogo.processando:
        conteudo = const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Ativando...'),
          ],
        );
        acoes = const [];
      case _EstadoDialogo.pronto:
        conteudo = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _icone(tema.colorScheme.primary, Icons.fingerprint),
            const SizedBox(height: 16),
            const Text(
              'Com a contingência ativada você bate ponto com a biometria '
              'sem precisar logar — e até sem internet (a batida fica na '
              'fila e sincroniza quando a conexão voltar).',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Válido por 7 dias. Você continua livre para logar quando '
              'quiser.',
              textAlign: TextAlign.center,
              style: tema.textTheme.bodySmall,
            ),
          ],
        );
        acoes = [
          FilledButton.icon(
            key: const Key('contingencia_ativar_button'),
            icon: const Icon(Icons.fingerprint),
            label: const Text('Ativar agora'),
            onPressed: _ativar,
          ),
        ];
      case _EstadoDialogo.cancelada:
        conteudo = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _icone(Colors.orange, Icons.fingerprint),
            const SizedBox(height: 16),
            Text(_mensagem ?? '', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'A contingência precisa da biometria para seguir.',
              textAlign: TextAlign.center,
              style: tema.textTheme.bodySmall,
            ),
          ],
        );
        acoes = [
          FilledButton(
            key: const Key('contingencia_retry_button'),
            onPressed: _ativar,
            child: const Text('Tentar novamente'),
          ),
        ];
      case _EstadoDialogo.semBiometria:
        conteudo = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _icone(Colors.orange, Icons.no_encryption),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma biometria cadastrada neste aparelho.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sem digital ou rosto, a contingência fica indisponível: para '
              'bater ponto você precisará logar normalmente. Cadastre uma '
              'biometria nas configurações do dispositivo e volte para '
              'ativar.',
              textAlign: TextAlign.center,
            ),
          ],
        );
        acoes = [
          OutlinedButton(
            key: const Key('contingencia_retry_button'),
            onPressed: _checarDisponibilidade,
            child: const Text('Tentar novamente'),
          ),
          TextButton(
            key: const Key('contingencia_continuar_button'),
            onPressed: _continuarSemContingencia,
            child: const Text('Continuar sem contingência'),
          ),
        ];
      case _EstadoDialogo.erroTecnico:
        conteudo = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _icone(Colors.redAccent, Icons.error_outline),
            const SizedBox(height: 16),
            Text(_mensagem ?? '', textAlign: TextAlign.center),
          ],
        );
        acoes = [
          OutlinedButton(
            key: const Key('contingencia_retry_button'),
            onPressed: _ativar,
            child: const Text('Tentar novamente'),
          ),
          TextButton(
            key: const Key('contingencia_continuar_button'),
            onPressed: _continuarSemContingencia,
            child: const Text('Continuar sem contingência'),
          ),
        ];
    }

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.fingerprint),
          SizedBox(width: 8),
          Expanded(child: Text('Bater ponto sem login')),
        ],
      ),
      content: SingleChildScrollView(child: conteudo),
      actions: acoes,
      actionsAlignment: MainAxisAlignment.center,
    );
  }
}

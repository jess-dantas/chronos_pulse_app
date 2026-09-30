import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/mensagens_erro.dart';
import '../../../../core/hardware/hardware_service.dart';
import '../../../../core/security/device_token_store.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/registro_ponto_model.dart';
import '../providers/ponto_provider.dart';
import '../../domain/services/sequencia_ponto.dart';
import 'camera_screen.dart';
import 'espelho_ponto_tab.dart';

class HomePontoScreen extends StatefulWidget {
  /// 0 = Bater Ponto, 1 = Espelho de Ponto (deep link `?aba=espelho`).
  final int abaInicial;

  /// Modo "bater ponto sem login" (mobile): identidade do vínculo de
  /// dispositivo. Quando presente, substitui a sessão em tudo que depende
  /// do colaborador (fila local, payload e card de identificação) e o
  /// espelho de ponto fica oculto (exige sessão; o modo só registra).
  final VinculoDispositivo? modoDispositivo;

  const HomePontoScreen({
    super.key,
    this.abaInicial = 0,
    this.modoDispositivo,
  });

  @override
  State<HomePontoScreen> createState() => _HomePontoScreenState();
}

class _HomePontoScreenState extends State<HomePontoScreen>
    with WidgetsBindingObserver {
  final HardwareService _hardwareService = HardwareService();
  late Timer _timer;

  DateTime _horarioAtual = DateTime.now();
  bool _isLoading = false;

  final Map<String, String> _nomesTipos = {
    'ENTRADA': 'Entrada',
    'INTERVALO': 'Intervalo',
    'RETORNO': 'Retorno',
    'SAIDA': 'Saída',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Recarrega pós-construção: a leitura disparada no construtor do provider
    // roda enquanto o SQLite ainda está abrindo (ou com id nulo); offline, sem
    // este retry a home ficaria com o histórico vazio e o botão voltando para
    // "Bater Entrada" mesmo com batidas do dia.
    Future.microtask(() {
      if (mounted) {
        context.read<PontoProvider>().carregarDados();
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _horarioAtual = DateTime.now());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    super.dispose();
  }

  /// Offline-first: ao voltar para o app (ex.: saiu do modo avião), não espera
  /// o heartbeat de 30s para equalizar a fila local com o servidor.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<PontoProvider>().checarConexao(autoSync: true);
    }
  }

  String _obterLabelBotao(String tipo, int totalRegistros) {
    final nome = _nomesTipos[tipo] ?? tipo;
    if (totalRegistros >= 4 && tipo == 'ENTRADA') {
      return 'Bater $nome (Extra)';
    }
    return 'Bater $nome';
  }

  Color _obterCorTipo(String tipo) {
    switch (tipo) {
      case 'ENTRADA':
        return Colors.green;
      case 'INTERVALO':
        return Colors.orange;
      case 'RETORNO':
        return Colors.blue;
      case 'SAIDA':
        return Colors.redAccent;
      default:
        return Colors.deepPurple;
    }
  }

  Future<void> _sincronizarPendentes(PontoProvider pontoProvider) async {
    final sincronizados = await pontoProvider.sincronizar();
    final falhaServidor = pontoProvider.ultimaFalhaServidor;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sincronizados > 0
                ? '$sincronizados batida(s) sincronizada(s) com sucesso!'
                : (falhaServidor != null
                    ? 'O servidor recusou a sincronização: $falhaServidor'
                    : (pontoProvider.isOnline
                        ? 'Todos os registros já estão sincronizados com o servidor.'
                        : 'Servidor offline. Os pontos permanecem salvos em segurança no dispositivo.')),
          ),
          backgroundColor: sincronizados > 0
              ? Colors.green
              : (falhaServidor != null
                  ? Colors.red
                  : (pontoProvider.isOnline ? Colors.green : Colors.orange)),
        ),
      );
    }
  }

  Future<void> _baterPonto(PontoProvider pontoProvider) async {
    setState(() => _isLoading = true);

    try {
      await _executarRegistro(pontoProvider).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException(
          'A operação demorou demais. Tente novamente.',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is TimeoutException
                  ? (e.message?.toString() ?? 'A operação demorou demais.')
                  : mensagemErroAmigavel(e),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _executarRegistro(PontoProvider pontoProvider) async {
    final authProvider = context.read<AuthProvider>();
    final proximoTipo = SequenciaPonto.proximo(pontoProvider.historico);

    // 1. Validação Biométrica (ou bypass em Web) — com timeout para nunca travar
    final autenticado = await _hardwareService
        .autenticarBiometria()
        .timeout(const Duration(seconds: 8));
    if (!autenticado) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Autenticação biométrica cancelada.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // 2. Captura de GPS (com fallback seguro em caso de indisponibilidade)
    double latitude = -23.550520;
    double longitude = -46.633308;
    double precisao = 5.0;

    try {
      final posicao = await _hardwareService
          .obterLocalizacaoAtual()
          .timeout(const Duration(seconds: 5));
      if (posicao != null) {
        latitude = posicao.latitude;
        longitude = posicao.longitude;
        precisao = posicao.accuracy;
      }
    } catch (gpsError) {
      debugPrint('Aviso GPS: $gpsError (utilizando coordenadas padrão)');
    }

    // 3. Captura da Foto (apenas no Mobile nativo)
    final String caminhoFotoPadrao =
        "https://s3.amazonaws.com/chronos-pulse/fotos/ponto_padrao.jpg";
    String caminhoFoto = caminhoFotoPadrao;

    if (!kIsWeb) {
      if (!mounted) return;
      final fotoCapturada = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(caminhoSemFoto: caminhoFotoPadrao),
        ),
      );

      if (fotoCapturada == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Captura de foto cancelada.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      caminhoFoto = fotoCapturada;
    }

    // 4. Montagem do modelo de ponto
    final novoRegistro = RegistroPontoModel(
      idLocal: const Uuid().v4(),
      // Mesmo fallback do build(): após restaurar sessão (ou refresh do token)
      // o UsuarioModel pode vir sem colaboradorId (só cpcId). Salvar null aqui
      // torna o registro invisível aos filtros locais (colaboradorId = ?) —
      // a fila offline e o histórico local deixam de encontrar o registro.
      // No modo dispositivo o dono é o vínculo (cpcId) — a sessão é null.
      colaboradorId: widget.modoDispositivo?.cpcId ??
          authProvider.usuario?.colaboradorId ??
          authProvider.usuario?.cpcId,
      dataHoraDispositivo: DateTime.now().toUtc(),
      tipoRegistro: proximoTipo,
      latitude: latitude,
      longitude: longitude,
      precisaoGps: precisao,
      fotoUrl: caminhoFoto,
      hashLocal: 'local_${const Uuid().v4().substring(0, 8)}',
      sincronizadoOffline: false,
    );

    // 5. Salva offline e tenta sincronizar online via PontoProvider
    final foiSincronizado = await pontoProvider.registrarPonto(novoRegistro);
    final falhaServidor = pontoProvider.ultimaFalhaServidor;
    final falhaLocal = pontoProvider.ultimaFalhaLocal;

    if (mounted) {
      // Precedência: falha local é a mais grave — sem linha local não existe
      // fila offline nem histórico (sequência do botão volta ao início).
      final texto = falhaLocal != null
          ? (foiSincronizado
              ? 'Registrada no servidor, mas o histórico local ficou '
                  'incompleto: $falhaLocal'
              : 'Não foi possível salvar no dispositivo: $falhaLocal')
          : (foiSincronizado
              ? '${_nomesTipos[proximoTipo]} registrada e sincronizada com sucesso!'
              : (falhaServidor != null
                  ? '${_nomesTipos[proximoTipo]} salva localmente. O servidor recusou a sincronização: $falhaServidor'
                  : '${_nomesTipos[proximoTipo]} salva localmente! Sincronização pendente com o servidor.'));
      final cor = (falhaLocal != null && !foiSincronizado)
          ? Colors.red
          : foiSincronizado
              ? Colors.green
              : (falhaServidor != null || falhaLocal != null
                  ? Colors.red
                  : Colors.orange);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(texto), backgroundColor: cor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final pontoProvider = context.watch<PontoProvider>();
    final usuario = authProvider.usuario;
    final modo = widget.modoDispositivo;
    final ehModoDispositivo = modo != null;

    // No modo dispositivo o dono da fila vem do vínculo; sem sessão, a
    // identificação precisa continuar fixada para o histórico local filtrar.
    final colabId = modo?.cpcId ?? usuario?.colaboradorId ?? usuario?.cpcId;
    if (pontoProvider.colaboradorId != colabId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        pontoProvider.definirColaborador(colabId);
      });
    }

    final horaFormatada = DateFormat('HH:mm:ss').format(_horarioAtual);
    final dataFormatada =
        DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(_horarioAtual);
    final proximoTipo = SequenciaPonto.proximo(pontoProvider.historico);
    final corBotao = _obterCorTipo(proximoTipo);

    // Sem sessão não há espelho (exige Bearer): o modo dispositivo só
    // registra batidas — a aba do espelho some por completo.
    final corpoBaterPonto = _buildBaterPontoTab(
      context,
      authProvider,
      pontoProvider,
      horaFormatada,
      dataFormatada,
      proximoTipo,
      corBotao,
    );

    if (ehModoDispositivo) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Bater Ponto · Sem Login',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Sair do modo dispositivo',
            onPressed: () => context.go('/'),
          ),
        ),
        body: corpoBaterPonto,
      );
    }

    return DefaultTabController(
      length: 2,
      initialIndex: widget.abaInicial.clamp(0, 1),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Controle de Ponto',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 1,
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.touch_app),
                text: 'Bater Ponto',
              ),
              Tab(
                icon: Icon(Icons.receipt_long),
                text: 'Espelho de Ponto',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            corpoBaterPonto,
            const EspelhoPontoTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildBaterPontoTab(
    BuildContext context,
    AuthProvider authProvider,
    PontoProvider pontoProvider,
    String horaFormatada,
    String dataFormatada,
    String proximoTipo,
    Color corBotao,
  ) {
    final usuario = authProvider.usuario;
    final modo = widget.modoDispositivo;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sensor de Conectividade com o Backend (Heartbeat)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: pontoProvider.isOnline
                        ? Colors.green.shade300
                        : Colors.orange.shade300,
                  ),
                ),
                color: pontoProvider.isOnline
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        pontoProvider.isOnline
                            ? Icons.cloud_done
                            : Icons.cloud_off,
                        color: pontoProvider.isOnline
                            ? Colors.green.shade700
                            : Colors.orange.shade800,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pontoProvider.isOnline
                              ? 'Servidor Conectado (Online)'
                              : 'Servidor Indisponível (Modo Offline)',
                          style: TextStyle(
                            color: pontoProvider.isOnline
                                ? Colors.green.shade900
                                : Colors.orange.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (pontoProvider.isVerificando)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 18),
                          tooltip: 'Verificar conexão com o servidor',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          color: pontoProvider.isOnline
                              ? Colors.green.shade800
                              : Colors.orange.shade800,
                          onPressed: () =>
                              pontoProvider.checarConexao(autoSync: true),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Card de Informações do Colaborador (sessão ativa) ou do
              // vínculo de dispositivo (modo sem login).
              if (usuario != null || modo != null)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        UserAvatar(
                          nome: (usuario?.nome.isNotEmpty ?? false)
                              ? usuario!.nome
                              : (modo?.nome.isNotEmpty ?? false)
                                  ? modo!.nome
                                  : 'Colaborador',
                          raio: 26,
                          fotoBytes: usuario?.temFoto == true
                              ? usuario!.fotoBytes
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (usuario?.nome.isNotEmpty ?? false)
                                    ? usuario!.nome
                                    : (modo?.nome.isNotEmpty ?? false)
                                        ? modo!.nome
                                        : 'Colaborador',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                usuario != null
                                    ? (usuario.email.isNotEmpty
                                        ? usuario.email
                                        : usuario.role)
                                    : 'Válido até ${DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(modo!.expiraEm.toLocal())}',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: modo != null
                                ? Colors.green[50]
                                : Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: modo != null
                                  ? Colors.green.shade200
                                  : Colors.blue.shade200,
                            ),
                          ),
                          child: Text(
                            modo != null
                                ? 'SEM LOGIN'
                                : usuario!.role.replaceAll('ROLE_', ''),
                            style: TextStyle(
                              color: modo != null
                                  ? Colors.green[800]
                                  : Colors.blue[800],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Card do Relógio em Tempo Real
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text(
                        dataFormatada,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        horaFormatada,
                        style:
                            Theme.of(context).textTheme.displayLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Banner de Status de Sincronização Offline
              if (pontoProvider.pendentesCount > 0)
                Card(
                  color: Colors.orange[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.orange.shade300),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_upload_outlined,
                            color: Colors.orange[800]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${pontoProvider.pendentesCount} batida(s) salva(s) offline.',
                            style: TextStyle(
                              color: Colors.orange[900],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: pontoProvider.isSincronizando
                              ? null
                              : () => _sincronizarPendentes(pontoProvider),
                          icon: pontoProvider.isSincronizando
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.sync, size: 18),
                          label: const Text('Sincronizar'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (pontoProvider.pendentesCount > 0) const SizedBox(height: 16),

              // Botão de Batida Automática Sequencial
              SizedBox(
                height: 58,
                child: ElevatedButton.icon(
                  onPressed:
                      _isLoading ? null : () => _baterPonto(pontoProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: corBotao,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(Icons.touch_app, size: 26),
                  label: Text(
                    _isLoading
                        ? 'Processando Registro...'
                        : _obterLabelBotao(
                            proximoTipo, pontoProvider.historico.length),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Seção de Histórico de Batidas de Hoje
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Batidas de Hoje',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Total: ${pontoProvider.historico.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (pontoProvider.historico.isEmpty)
                Card(
                  elevation: 0,
                  color: Colors.grey[200],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.history, size: 36, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'Nenhum registro de ponto efetuado hoje.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
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
                  itemCount: pontoProvider.historico.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final registro = pontoProvider.historico[index];
                    final hora = DateFormat('HH:mm:ss')
                        .format(registro.dataHoraDispositivo.toLocal());
                    final cor = _obterCorTipo(registro.tipoRegistro);
                    final nomeTipo = _nomesTipos[registro.tipoRegistro] ??
                        registro.tipoRegistro;

                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cor.withValues(alpha: 0.15),
                          child: Icon(Icons.access_time, color: cor),
                        ),
                        title: Text(
                          '$nomeTipo (#${index + 1})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: cor,
                          ),
                        ),
                        subtitle: Text(
                          'Horário: $hora',
                          style: const TextStyle(fontSize: 13),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: registro.sincronizadoOffline
                                ? Colors.green[50]
                                : Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: registro.sincronizadoOffline
                                  ? Colors.green.shade200
                                  : Colors.orange.shade200,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                registro.sincronizadoOffline
                                    ? Icons.cloud_done
                                    : Icons.cloud_off,
                                size: 14,
                                color: registro.sincronizadoOffline
                                    ? Colors.green[700]
                                    : Colors.orange[800],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                registro.sincronizadoOffline
                                    ? 'Sincronizado'
                                    : 'Pendente',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: registro.sincronizadoOffline
                                      ? Colors.green[800]
                                      : Colors.orange[900],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

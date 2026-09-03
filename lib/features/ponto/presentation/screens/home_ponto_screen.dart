import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/hardware/hardware_service.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/ponto_local_datasource.dart';
import '../../data/datasources/ponto_remote_datasource.dart';
import '../../data/models/registro_ponto_model.dart';
import '../../data/repositories/ponto_repository.dart';
import 'camera_screen.dart';

class HomePontoScreen extends StatefulWidget {
  const HomePontoScreen({super.key});

  @override
  State<HomePontoScreen> createState() => _HomePontoScreenState();
}

class _HomePontoScreenState extends State<HomePontoScreen> {
  final HardwareService _hardwareService = HardwareService();
  late final PontoRepository _pontoRepository;
  late Timer _timer;

  DateTime _horarioAtual = DateTime.now();
  bool _isLoading = false;
  bool _isSincronizando = false;
  int _pendentesCount = 0;

  final List<RegistroPontoModel> _historicoHoje = [];

  final Map<String, String> _nomesTipos = {
    'ENTRADA': 'Entrada',
    'INTERVALO': 'Intervalo',
    'RETORNO': 'Retorno',
    'SAIDA': 'Saída',
  };

  @override
  void initState() {
    super.initState();
    final dioClient = DioClient();
    _pontoRepository = PontoRepository(
      localDataSource: PontoLocalDataSource(),
      remoteDataSource: PontoRemoteDataSource(dioClient),
    );
    _carregarHistoricoEPendentes();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _horarioAtual = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _determinarProximoTipo() {
    final count = _historicoHoje.length;
    switch (count % 4) {
      case 0:
        return 'ENTRADA';
      case 1:
        return 'INTERVALO';
      case 2:
        return 'RETORNO';
      case 3:
        return 'SAIDA';
      default:
        return 'ENTRADA';
    }
  }

  String _obterLabelBotao(String tipo) {
    final nome = _nomesTipos[tipo] ?? tipo;
    if (_historicoHoje.length >= 4 && tipo == 'ENTRADA') {
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

  Future<void> _carregarHistoricoEPendentes() async {
    final historico = await _pontoRepository.obterHistorico();
    final pendentes = await _pontoRepository.obterQuantidadePendentes();
    if (mounted) {
      setState(() {
        _historicoHoje.clear();
        _historicoHoje.addAll(historico);
        _pendentesCount = pendentes;
      });
    }
  }

  Future<void> _sincronizarPendentes() async {
    if (_pendentesCount == 0) return;
    setState(() => _isSincronizando = true);

    try {
      final sincronizados = await _pontoRepository.sincronizarPendentes();
      await _carregarHistoricoEPendentes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              sincronizados > 0
                  ? '$sincronizados batida(s) sincronizada(s) com sucesso!'
                  : 'Nenhuma conexão com o servidor. Os pontos permanecem salvos offline.',
            ),
            backgroundColor: sincronizados > 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSincronizando = false);
    }
  }

  Future<void> _baterPonto() async {
    final authProvider = context.read<AuthProvider>();
    final proximoTipo = _determinarProximoTipo();

    setState(() => _isLoading = true);

    try {
      // 1. Validação Biométrica (ou bypass em Web)
      final autenticado = await _hardwareService.autenticarBiometria();
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
        final posicao = await _hardwareService.obterLocalizacaoAtual();
        if (posicao != null) {
          latitude = posicao.latitude;
          longitude = posicao.longitude;
          precisao = posicao.accuracy;
        }
      } catch (gpsError) {
        debugPrint('Aviso GPS: $gpsError (utilizando coordenadas padrão)');
      }

      // 3. Captura da Foto (apenas no Mobile nativo)
      String caminhoFoto =
          "https://s3.amazonaws.com/chronos-pulse/fotos/ponto_padrao.jpg";

      if (!kIsWeb) {
        final fotoCapturada = await Navigator.push<String>(
          context,
          MaterialPageRoute(builder: (context) => const CameraScreen()),
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
        colaboradorId: authProvider.usuario?.colaboradorId,
        dataHoraDispositivo: DateTime.now().toUtc(),
        tipoRegistro: proximoTipo,
        latitude: latitude,
        longitude: longitude,
        precisaoGps: precisao,
        fotoUrl: caminhoFoto,
        hashLocal: 'local_${const Uuid().v4().substring(0, 8)}',
        sincronizadoOffline: false,
      );

      // 5. Salva offline e tenta sincronizar online
      final foiSincronizado = await _pontoRepository.registrarPonto(
        registro: novoRegistro,
      );

      await _carregarHistoricoEPendentes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              foiSincronizado
                  ? '${_nomesTipos[proximoTipo]} registrada e sincronizada com sucesso!'
                  : '${_nomesTipos[proximoTipo]} salva offline! Sincronização pendente.',
            ),
            backgroundColor: foiSincronizado ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao bater ponto: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final usuario = authProvider.usuario;
    final horaFormatada = DateFormat('HH:mm:ss').format(_horarioAtual);
    final dataFormatada =
        DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(_horarioAtual);
    final proximoTipo = _determinarProximoTipo();
    final corBotao = _obterCorTipo(proximoTipo);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Chronos Pulse',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 1,
        actions: [
          IconButton(
            tooltip: 'Sair da conta',
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirmar Saída'),
                  content: const Text('Deseja realmente desconectar do sistema?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        authProvider.logout();
                      },
                      child: const Text('Sair'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card de Informações do Colaborador
                if (usuario != null)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(
                              Icons.person,
                              size: 28,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  usuario.nome.isNotEmpty
                                      ? usuario.nome
                                      : 'Colaborador',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  usuario.email.isNotEmpty
                                      ? usuario.email
                                      : usuario.role,
                                  style: TextStyle(
                                    color: Colors.grey[600],
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
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              usuario.role.replaceAll('ROLE_', ''),
                              style: TextStyle(
                                color: Colors.blue[800],
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
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
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
                if (_pendentesCount > 0)
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
                          Icon(Icons.cloud_off, color: Colors.orange[800]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '$_pendentesCount batida(s) salva(s) offline.',
                              style: TextStyle(
                                color: Colors.orange[900],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed:
                                _isSincronizando ? null : _sincronizarPendentes,
                            icon: _isSincronizando
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
                if (_pendentesCount > 0) const SizedBox(height: 16),

                // Botão de Batida Automática Sequencial
                SizedBox(
                  height: 58,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _baterPonto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: corBotao,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
                        : const Icon(Icons.fingerprint, size: 30),
                    label: Text(
                      _isLoading ? 'Registrando...' : _obterLabelBotao(proximoTipo),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Lista de Histórico do Dia
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Histórico de Hoje (${_historicoHoje.length})',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      tooltip: 'Atualizar histórico',
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: _carregarHistoricoEPendentes,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                _historicoHoje.isEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(Icons.access_time,
                                size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'Nenhum ponto registrado hoje.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _historicoHoje.length,
                        itemBuilder: (context, index) {
                          final item = _historicoHoje[index];
                          final horaItem = DateFormat('HH:mm:ss')
                              .format(item.dataHoraDispositivo.toLocal());
                          final corItem = _obterCorTipo(item.tipoRegistro);
                          final nomeTipo =
                              _nomesTipos[item.tipoRegistro] ?? item.tipoRegistro;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: corItem.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  item.sincronizadoOffline
                                      ? Icons.cloud_done
                                      : Icons.cloud_off,
                                  color: item.sincronizadoOffline
                                      ? corItem
                                      : Colors.orange,
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                nomeTipo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                item.sincronizadoOffline
                                    ? 'Sincronizado online'
                                    : 'Pendente de sincronização',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: item.sincronizadoOffline
                                      ? Colors.grey[600]
                                      : Colors.orange[800],
                                ),
                              ),
                              trailing: Text(
                                horaItem,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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
      ),
    );
  }
}

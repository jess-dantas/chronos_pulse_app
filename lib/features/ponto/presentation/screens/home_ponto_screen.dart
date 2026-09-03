import 'package:uuid/uuid.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/ponto_remote_datasource.dart';
import '../../data/models/registro_ponto_model.dart';
import '../../data/datasources/ponto_local_datasource.dart';
import '../../data/repositories/ponto_repository.dart';
import '../../../../core/hardware/hardware_service.dart';

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
  String _tipoSelecionado = 'ENTRADA';
  bool _isLoading = false;

  final List<RegistroPontoModel> _historicoHoje = [];

  final Map<String, String> _tiposRegistro = {
    'ENTRADA': 'Entrada',
    'PAUSA_INICIO': 'Saída Intervalo',
    'PAUSA_FIM': 'Retorno Intervalo',
    'SAIDA': 'Saída',
  };

  @override
  void initState() {
    super.initState();
    _pontoRepository = PontoRepository(
      localDataSource: PontoLocalDataSource(),
      remoteDataSource: PontoRemoteDataSource(DioClient()),
    );
    _carregarHistorico();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _horarioAtual = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _carregarHistorico() async {
    final historico = await _pontoRepository.obterHistorico();
    if (mounted) {
      setState(() {
        _historicoHoje.clear();
        _historicoHoje.addAll(historico);
      });
    }
  }

  Future<void> _baterPonto() async {
    setState(() => _isLoading = true);

    try {
      // 1. Validação Biométrica
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

      // 2. Captura de GPS Real
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
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('GPS Necessário'),
              content: Text(
                kIsWeb
                    ? 'A permissão de localização foi negada no navegador. Clique no ícone de "Cadeado" ou "Configurações do Site" na barra de endereço para permitir o acesso ao GPS.'
                    : gpsError.toString().replaceAll('Exception: ', ''),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entendido'),
                ),
                if (!kIsWeb)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Geolocator
                          .openAppSettings(); // Executado APENAS em dispositivos nativos
                    },
                    child: const Text('Abrir Configurações'),
                  ),
              ],
            ),
          );
        }
        return; // Interrompe a batida do ponto
      }

      // 3. Monta o Modelo com os dados reais capturados
      final novoRegistro = RegistroPontoModel(
        idLocal: const Uuid().v4(),
        colaboradorId: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
        dataHoraDispositivo: DateTime.now().toUtc(),
        tipoRegistro: _tipoSelecionado,
        latitude: latitude,
        longitude: longitude,
        precisaoGps: precisao,
        fotoUrl: "https://s3.amazonaws.com/chronos-pulse/fotos/ponto1.jpg",
        sincronizadoOffline: false,
      );

      final foiSincronizado = await _pontoRepository.registrarPonto(
        registro: novoRegistro,
        cpfColaborador: "12345678901",
      );

      await _carregarHistorico();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              foiSincronizado
                  ? 'Ponto de ${_tiposRegistro[_tipoSelecionado]} registrado e sincronizado!'
                  : 'Ponto salvo offline! Sincronização pendente.',
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
    final horaFormatada = DateFormat('HH:mm:ss').format(_horarioAtual);
    final dataFormatada =
        DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(_horarioAtual);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chronos Pulse',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Card do Relógio em Tempo Real
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
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
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Seleção de Tipo de Registro
            SegmentedButton<String>(
              segments: _tiposRegistro.entries
                  .map((e) => ButtonSegment<String>(
                        value: e.key,
                        label:
                            Text(e.value, style: const TextStyle(fontSize: 12)),
                      ))
                  .toList(),
              selected: {_tipoSelecionado},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _tipoSelecionado = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 24),

            // Botão Principal de Registro
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _baterPonto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.fingerprint, size: 28),
                label: Text(
                  _isLoading
                      ? 'Registrando...'
                      : 'Confirmar ${_tiposRegistro[_tipoSelecionado]}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Lista de Histórico do Dia
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Registros de Hoje',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            _historicoHoje.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('Nenhum ponto registrado hoje.',
                        style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _historicoHoje.length,
                    itemBuilder: (context, index) {
                      final item = _historicoHoje[index];
                      final horaItem = DateFormat('HH:mm:ss')
                          .format(item.dataHoraDispositivo.toLocal());
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.check_circle,
                              color: Colors.green),
                          title: Text(_tiposRegistro[item.tipoRegistro] ??
                              item.tipoRegistro),
                          trailing: Text(
                            horaItem,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

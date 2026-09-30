import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/mensagens_erro.dart';
import '../../../../core/hardware/hardware_service.dart';
import '../../../../core/security/device_token_store.dart';
import '../../../../core/telemetry/telemetry_service.dart';
import 'home_ponto_screen.dart';

/// Entrada do modo "bater ponto sem login" (mobile only).
///
/// Guard próprio desta rota pública:
/// 1. vínculo de dispositivo ativo (token de 7 dias emitido no perfil);
/// 2. biometria obrigatória para embarcar.
///
/// Depois de embarcado, cada batida passa pela biometria normal do fluxo de
/// ponto (inalterado) e a sincronização usa o header `X-Device-Token`.
class ModoPontoScreen extends StatefulWidget {
  /// Injeções opcionais (testes): store de vínculo e serviço de biometria.
  final DeviceTokenStore? store;
  final HardwareService? hardwareService;

  const ModoPontoScreen({super.key, this.store, this.hardwareService});

  @override
  State<ModoPontoScreen> createState() => _ModoPontoScreenState();
}

class _ModoPontoScreenState extends State<ModoPontoScreen> {
  late final DeviceTokenStore _store =
      widget.store ?? DeviceTokenStore.instancia;
  late final HardwareService _hardwareService =
      widget.hardwareService ?? HardwareService();

  VinculoDispositivo? _vinculo;
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      // Observabilidade do fluxo de contingência: entrada na rota pública.
      context.telemetria?.registrar(
        tipo: TipoEventoTelemetria.modoDispositivo,
        modulo: 'PONTO',
        mensagem: 'Entrada no modo ponto (rota pública)',
      );
    }
    _embarcar();
  }

  Future<void> _embarcar() async {
    if (kIsWeb) {
      setState(() {
        _carregando = false;
        _erro = 'O modo de ponto sem login está disponível apenas no app '
            'celular.';
      });
      return;
    }

    final vinculo = await _store.lerAtivo();
    if (vinculo == null) {
      setState(() {
        _carregando = false;
        _erro = 'O vínculo deste aparelho expirou ou foi desativado. '
            'Faça login e ative "Bater ponto sem login" no Perfil para '
            'usar este modo (válido por 7 dias).';
      });
      return;
    }

    try {
      final autenticado = await _hardwareService
          .autenticarBiometria()
          .timeout(const Duration(seconds: 8));
      if (!autenticado) {
        setState(() {
          _carregando = false;
          _erro = 'Autenticação biométrica cancelada.';
        });
        return;
      }
    } catch (e) {
      setState(() {
        _carregando = false;
        _erro = mensagemErroAmigavel(e,
            fallback: 'Não foi possível validar sua biometria.');
      });
      return;
    }

    setState(() {
      _vinculo = vinculo;
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Validando biometria...'),
            ],
          ),
        ),
      );
    }

    if (_erro != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bater Ponto')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.fingerprint, size: 56, color: Colors.orange),
                const SizedBox(height: 16),
                Text(
                  _erro!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('Ir para o login'),
                  onPressed: () => context.go('/login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return HomePontoScreen(modoDispositivo: _vinculo);
  }
}

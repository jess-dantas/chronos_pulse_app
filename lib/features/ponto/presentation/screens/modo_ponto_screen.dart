import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/mensagens_erro.dart';
import '../../../../core/hardware/hardware_service.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/security/device_token_store.dart';
import '../../../../core/telemetry/telemetry_service.dart';
import '../../../auth/data/datasources/auth_remote_datasource.dart';
import 'home_ponto_screen.dart';
import 'modo_ponto_two_factor_screen.dart';

/// Entrada do modo "bater ponto sem login" (mobile only).
///
/// Guard próprio desta rota pública — ordem das etapas:
/// 1. **biometria** do aparelho;
/// 2. **2FA** (código TOTP/OTP por e-mail) quando o dono do vínculo tem a
///    autenticação em duas etapas habilitada (flag local do vínculo,
///    sincronizada pelo `device/status`);
/// 3. **vínculo** — confirmação no servidor (`device/status`; offline o
///    vínculo local segue valendo, a batida entra na fila).
///
/// Depois de embarcado, cada batida passa pela biometria normal do fluxo de
/// ponto (inalterado) e a sincronização usa o header `X-Device-Token`.
class ModoPontoScreen extends StatefulWidget {
  /// Injeções opcionais (testes): store de vínculo, serviço de biometria e
  /// datasource do modo sem login (`device/status` + `device/verificar`).
  final DeviceTokenStore? store;
  final HardwareService? hardwareService;
  final AuthRemoteDataSource? dataSource;

  const ModoPontoScreen({
    super.key,
    this.store,
    this.hardwareService,
    this.dataSource,
  });

  @override
  State<ModoPontoScreen> createState() => _ModoPontoScreenState();
}

class _ModoPontoScreenState extends State<ModoPontoScreen> {
  late final DeviceTokenStore _store =
      widget.store ?? DeviceTokenStore.instancia;
  late final HardwareService _hardwareService =
      widget.hardwareService ?? HardwareService();
  late final AuthRemoteDataSource _dataSource =
      widget.dataSource ?? AuthRemoteDataSource(DioClient());

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

    // Pré-requisito: vínculo local de 7 dias (o token é a credencial do
    // modo — sem ele não há o que validar).
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

    // Etapa 1: biometria do aparelho.
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

    // Etapa 2: 2FA quando o vínculo exige (flag gravada na ativação).
    var doisFatorOk = false;
    if (await _store.lerTwoFactor()) {
      doisFatorOk = await _validarTwoFactor(vinculo.token);
      if (!doisFatorOk) return; // erro/cancelamento tratado na tela de código
    }

    // Etapa 3: vínculo — confirmação no servidor (offline segue com o local).
    try {
      final status = await _dataSource.deviceStatus(token: vinculo.token);
      if (status.revogado) {
        await _store.limpar();
        setState(() {
          _carregando = false;
          _erro = 'O vínculo deste aparelho foi revogado. Faça login e ative '
              '"Bater ponto sem login" novamente no Perfil.';
        });
        return;
      }
      if (!status.offline) {
        await _store.salvarTwoFactor(status.twoFactorEnabled);
        // Cache desatualizado (2FA ligado depois da ativação): cobra aqui.
        if (status.twoFactorEnabled && !doisFatorOk) {
          doisFatorOk = await _validarTwoFactor(vinculo.token);
          if (!doisFatorOk) return;
        }
      }
    } catch (e) {
      setState(() {
        _carregando = false;
        _erro = mensagemErroAmigavel(
            e, fallback: 'Não foi possível confirmar o vínculo do aparelho.');
      });
      return;
    }

    setState(() {
      _vinculo = vinculo;
      _carregando = false;
    });
  }

  /// Abre a etapa 2FA; `false` = não concluída (erro já exibido).
  Future<bool> _validarTwoFactor(String token) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ModoPontoTwoFactorScreen(
          deviceToken: token,
          dataSource: _dataSource,
        ),
      ),
    );
    if (ok == true) return true;
    if (mounted) {
      setState(() {
        _carregando = false;
        _erro = 'A verificação em duas etapas não foi concluída.';
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Validando o acesso a este aparelho...',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  'Este modo confirma: 1) biometria, 2) código do 2FA '
                  '(se ativado) e 3) o vínculo de 7 dias.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
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
                Text(_erro!, textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/hardware/hardware_service.dart';
import '../providers/admin_auth_provider.dart';

/// Gate biométrico da área AdminPlataforma (app admin, flavor `admin`).
///
/// Sessão RESTORADA ao abrir o app fica trancada até a biometria local.
/// Sem biometria cadastrada/suportada o gate se libera sozinho; login
/// explícito nasce desbloqueado e nunca cai aqui. No web não há trava.
class AdminBiometricGateScreen extends StatefulWidget {
  const AdminBiometricGateScreen({super.key, this.hardwareService});

  /// Injeção para testes; em produção usa o serviço real.
  final HardwareService? hardwareService;

  @override
  State<AdminBiometricGateScreen> createState() =>
      _AdminBiometricGateScreenState();
}

enum _EstadoGate { checando, autenticando, cancelado, erro }

class _AdminBiometricGateScreenState extends State<AdminBiometricGateScreen> {
  late final HardwareService _hw;
  _EstadoGate _estado = _EstadoGate.checando;
  String? _mensagem;

  @override
  void initState() {
    super.initState();
    _hw = widget.hardwareService ?? HardwareService();
    _iniciar();
  }

  Future<void> _iniciar() async {
    bool disponivel = false;
    try {
      disponivel = await _hw.biometriaDisponivel();
    } catch (_) {
      disponivel = false;
    }
    if (!mounted) return;
    if (!disponivel) {
      // Sem biometria: libera a sessão admin (sem trava local não há o que
      // confirmar) e o roteador segue para o dashboard.
      context.read<AdminAuthProvider>().confirmarBiometria();
      return;
    }
    await _autenticar();
  }

  Future<void> _autenticar() async {
    setState(() {
      _estado = _EstadoGate.autenticando;
      _mensagem = null;
    });

    bool autenticado;
    try {
      autenticado = await _hw
          .autenticarBiometria(
            motivo: 'Confirme sua identidade para acessar a área '
                'da plataforma',
          )
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _estado = _EstadoGate.erro;
        _mensagem = 'Não foi possível validar sua biometria. '
            'Tente novamente ou entre com sua senha em outro momento.';
      });
      return;
    }

    if (!mounted) return;
    if (autenticado) {
      context.read<AdminAuthProvider>().confirmarBiometria();
    } else {
      setState(() {
        _estado = _EstadoGate.cancelado;
        _mensagem = 'Autenticação biométrica cancelada.';
      });
    }
  }

  Future<void> _sair() async {
    await context.read<AdminAuthProvider>().logout();
  }

  String get _titulo {
    switch (_estado) {
      case _EstadoGate.checando:
        return 'Verificando biometria';
      case _EstadoGate.autenticando:
        return 'Confirme sua identidade';
      case _EstadoGate.cancelado:
        return 'Biometria não confirmada';
      case _EstadoGate.erro:
        return 'Não foi possível validar';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final aguardando =
        _estado == _EstadoGate.checando || _estado == _EstadoGate.autenticando;

    return Scaffold(
      backgroundColor: tema.colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                aguardando
                    ? Icons.fingerprint
                    : Icons.lock_person_outlined,
                size: 88,
                color: tema.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                _titulo,
                textAlign: TextAlign.center,
                style: tema.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                _mensagem ??
                    'Este app está protegido pela biometria do seu '
                        'aparelho (digital ou rosto).',
                textAlign: TextAlign.center,
                style: tema.textTheme.bodyMedium
                    ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              if (aguardando)
                const CircularProgressIndicator()
              else ...[
                ElevatedButton.icon(
                  onPressed: _autenticar,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Tentar novamente'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _sair,
                  child: const Text('Sair'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

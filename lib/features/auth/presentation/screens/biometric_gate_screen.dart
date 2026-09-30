import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/hardware/hardware_service.dart';
import '../providers/auth_provider.dart';

/// Gate biométrico de abertura (login por biometria).
///
/// Intercepta a sessão RESTORIDA ao abrir o app: antes de liberar qualquer
/// conteúdo, exige a biometria cadastrada no aparelho. Sem biometria
/// disponível (web, aparelho sem cadastro, falha técnica de leitura) o gate
/// se libera sozinho — a autenticação da conta continua sendo o login por
/// senha. Login explícito por senha já entra desbloqueado e nunca cai aqui.
class BiometricGateScreen extends StatefulWidget {
  const BiometricGateScreen({super.key, this.hardwareService});

  /// Injeção para testes; em produção usa o serviço real.
  final HardwareService? hardwareService;

  @override
  State<BiometricGateScreen> createState() => _BiometricGateScreenState();
}

enum _EstadoGate { checando, autenticando, cancelado, erro }

class _BiometricGateScreenState extends State<BiometricGateScreen> {
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
      // Sem biometria cadastrada/suportada: libera a sessão (sem trava
      // local não há o que confirmar) e o roteador segue para o painel.
      context.read<AuthProvider>().confirmarBiometria();
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
          .autenticarBiometria()
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
      context.read<AuthProvider>().confirmarBiometria();
    } else {
      setState(() {
        _estado = _EstadoGate.cancelado;
        _mensagem = 'Autenticação biométrica cancelada.';
      });
    }
  }

  Future<void> _sair() async {
    await context.read<AuthProvider>().logout();
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

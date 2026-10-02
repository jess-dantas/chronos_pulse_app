import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/errors/mensagens_erro.dart';
import '../../../auth/data/datasources/auth_remote_datasource.dart';

/// Etapa 2 do modo "bater ponto sem login" (ordem biometria → 2FA → vínculo).
///
/// Valida o código do colaborador contra `POST /auth/device/verificar`
/// (header `X-Device-Token`, sem sessão): TOTP de 6 dígitos do app
/// autenticador ou OTP de 8 dígitos enviado ao e-mail corporativo.
/// Devolve `true` via `Navigator.pop` quando o código confere.
class ModoPontoTwoFactorScreen extends StatefulWidget {
  final String deviceToken;
  final AuthRemoteDataSource dataSource;

  const ModoPontoTwoFactorScreen({
    super.key,
    required this.deviceToken,
    required this.dataSource,
  });

  @override
  State<ModoPontoTwoFactorScreen> createState() =>
      _ModoPontoTwoFactorScreenState();
}

class _ModoPontoTwoFactorScreenState extends State<ModoPontoTwoFactorScreen> {
  final _controlador = TextEditingController();
  bool _porEmail = false;
  bool _enviado = false;
  bool _processando = false;
  String? _erro;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  int get _digitos => _porEmail ? 8 : 6;

  Future<void> _verificar() async {
    final codigo = _controlador.text.trim();
    if (codigo.length != _digitos) {
      setState(() => _erro = 'O código deve conter $_digitos dígitos.');
      return;
    }
    setState(() {
      _processando = true;
      _erro = null;
    });
    try {
      final r = await widget.dataSource.deviceVerificar(
        token: widget.deviceToken,
        codigo: codigo,
        porEmail: _porEmail,
      );
      if (!mounted) return;
      if (r.offline) {
        setState(() => _erro =
            'Sem conexão com a internet. Conecte-se para validar o código '
            'do 2FA.');
        return;
      }
      if (r.verificado) {
        Navigator.of(context).pop(true);
        return;
      }
      setState(() => _erro = 'Código inválido. Tente novamente.');
    } catch (e) {
      if (mounted) {
        setState(() => _erro = mensagemErroAmigavel(
            e, fallback: 'Não foi possível validar o código.'));
      }
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _enviarPorEmail() async {
    setState(() {
      _processando = true;
      _erro = null;
    });
    try {
      final r = await widget.dataSource.deviceVerificar(
        token: widget.deviceToken,
        porEmail: true,
      );
      if (!mounted) return;
      if (r.offline) {
        setState(() => _erro =
            'Sem conexão com a internet. Conecte-se para receber o código '
            'por e-mail.');
        return;
      }
      setState(() {
        _porEmail = true;
        _enviado = r.enviado;
        _erro = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _erro = mensagemErroAmigavel(
            e, fallback: 'Não foi possível enviar o código.'));
      }
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  void _voltarParaAppAutenticador() {
    setState(() {
      _porEmail = false;
      _enviado = false;
      _erro = null;
      _controlador.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verificação em duas etapas')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Aviso da ordem do modo sem login (biometria → 2FA → vínculo).
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.deepPurple),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Por segurança, o modo "Bater ponto sem login" valida '
                        'sua biometria e depois este código a cada uso.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _porEmail
                  ? 'Digite o código de 8 dígitos enviado ao seu e-mail '
                      'corporativo'
                  : 'Digite o código de 6 dígitos do seu app autenticador',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (_porEmail && _enviado) ...[
              const SizedBox(height: 8),
              Text(
                'Código enviado. Ele expira em alguns minutos.',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('modo_ponto_2fa_codigo_field'),
              controller: _controlador,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(_digitos),
              ],
              decoration: InputDecoration(
                labelText: _porEmail ? 'Código (8 dígitos)' : 'Código (6 dígitos)',
                border: const OutlineInputBorder(),
              ),
              onFieldSubmitted: (_) => _processando ? null : _verificar(),
            ),
            if (_erro != null) ...[
              const SizedBox(height: 12),
              Text(
                _erro!,
                key: const Key('modo_ponto_2fa_erro'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('modo_ponto_2fa_verificar_button'),
              onPressed: _processando ? null : _verificar,
              child: _processando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Verificar'),
            ),
            const SizedBox(height: 8),
            if (!_porEmail)
              TextButton(
                key: const Key('modo_ponto_2fa_por_email_button'),
                onPressed: _processando ? null : _enviarPorEmail,
                child: const Text('Receber código por e-mail'),
              )
            else
              TextButton(
                key: const Key('modo_ponto_2fa_voltar_totp_button'),
                onPressed: _processando ? null : _voltarParaAppAutenticador,
                child: const Text('Usar o código do app autenticador'),
              ),
          ],
        ),
      ),
    );
  }
}

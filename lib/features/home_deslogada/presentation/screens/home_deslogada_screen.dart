import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/conexao_service.dart';
import '../../../../core/security/device_token_store.dart';
import '../../../../core/telemetry/telemetry_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';

/// Primeira tela do app cliente (mobile) deslogado — ponto em primeiro plano.
///
/// UX definida no roadmap (apenas `APP_MODE=cliente`): ícone de ponto +
/// botão **"Bater ponto"** (rota pública `/ponto/dispositivo`, guard de
/// vínculo + biometria) e, abaixo, o botão **"Logar"**. Web e admin
/// continuam com landing/login como antes.
///
/// Ao montar, diagnostica a conexão (`GET /auth/ping`): sem conexão, avisa
/// com o toast **"Sem conexão!"** e — havendo vínculo de contingência — já
/// redireciona para a tela de batida offline (biometria).
class HomeDeslogadaScreen extends StatefulWidget {
  /// Injeções opcionais (testes): diagnóstico de conexão e store do vínculo.
  final ConexaoService? conexao;
  final DeviceTokenStore? store;

  const HomeDeslogadaScreen({super.key, this.conexao, this.store});

  @override
  State<HomeDeslogadaScreen> createState() => _HomeDeslogadaScreenState();
}

class _HomeDeslogadaScreenState extends State<HomeDeslogadaScreen> {
  late final ConexaoService _conexao = widget.conexao ?? ConexaoService();
  late final DeviceTokenStore _store =
      widget.store ?? DeviceTokenStore.instancia;

  @override
  void initState() {
    super.initState();
    // Contingência é exclusiva do app mobile; web não participa.
    if (!kIsWeb) _verificarConexao();
  }

  Future<void> _verificarConexao() async {
    final diagnostico = await _conexao.diagnosticar(store: _store);
    if (!mounted || diagnostico == DiagnosticoConexao.online) return;

    ConexaoService.avisarSemConexao(context);
    context.telemetria?.registrar(
      tipo: TipoEventoTelemetria.conexaoOffline,
      modulo: 'HOME',
      mensagem: 'Sem conexão na abertura do app',
      detalhe: diagnostico.name,
    );
    if (diagnostico == DiagnosticoConexao.offlineComVinculo) {
      // Sem internet + vínculo ativo: objetivo é bater ponto — ir direto
      // para a batida offline (guard da tela valida a biometria).
      context.go('/ponto/dispositivo');
    }
    // offlineSemVinculo: fica na home (o próprio botão "Bater ponto" leva
    // ao guard, que orienta a ativar a contingência pelo login).
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            tooltip: themeProvider.isDarkMode ? 'Tema Claro' : 'Tema Escuro',
            onPressed: () => themeProvider.toggleTheme(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Ícone de ponto
                  Center(
                    child: Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.fingerprint,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Chronos Pulse',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bater ponto é rápido — funciona até mesmo sem internet.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                  ),
                  const SizedBox(height: 36),

                  // Botão primário: contingência de ponto (vínculo + biometria)
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      key: const Key('home_deslogada_bater_ponto_button'),
                      icon: const Icon(Icons.fingerprint, size: 28),
                      label: const Text(
                        'Bater ponto',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryAction(context),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => context.go('/ponto/dispositivo'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Acesso ao painel (histórico, foto, PDF, demais módulos)
                  OutlinedButton.icon(
                    key: const Key('home_deslogada_login_button'),
                    icon: const Icon(Icons.login, size: 20),
                    label: const Text(
                      'Logar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => context.go('/login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

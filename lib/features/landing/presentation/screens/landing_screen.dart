import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/screens/cadastrar_empresa_screen.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  void _navigateToLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  void _navigateToCadastro(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CadastrarEmpresaScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = themeProvider.isDarkMode;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: isDesktop ? 32 : 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.png',
                width: 36,
                height: 36,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.fingerprint,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Chronos Pulse',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDark ? 'Modo Claro' : 'Modo Escuro',
            onPressed: () => themeProvider.toggleTheme(),
          ),
          if (isDesktop) ...[
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(right: 32),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _navigateToCadastro(context),
                    icon: const Icon(Icons.business_center, size: 18),
                    label: const Text('Cadastrar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    key: const Key('landing_appbar_login_button'),
                    onPressed: () => _navigateToLogin(context),
                    icon: const Icon(Icons.login, size: 18),
                    label: const Text('Login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            _buildHeroSection(context, isDesktop),

            // Badges / Destaques
            _buildHighlightsSection(context, isDesktop),

            // Módulos da Plataforma
            _buildModulesSection(context, isDesktop),

            // Recursos Tecnológicos & Diferenciais
            _buildFeaturesSection(context, isDesktop),

            // Call to Action (CTA)
            _buildCtaSection(context),

            // Footer
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 24,
        vertical: isDesktop ? 64 : 40,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF0F172A),
                  const Color(0xFF1E293B),
                ]
              : [
                  const Color(0xFFEFF6FF),
                  const Color(0xFFF8FAFC),
                ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Suíte de Gestão Pública Integrada & Corporativa',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Eficiência, Conformidade e\nControle em Tempo Real',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: isDesktop ? 44 : 30,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 750),
                child: Text(
                  'O Chronos Pulse unifica o registro eletrônico de ponto inteligente com a gestão completa de almoxarifado público e controle patrimonial contábil, garantindo total conformidade legal e suporte offline.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: isDesktop ? 18 : 15,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    key: const Key('landing_hero_login_button'),
                    onPressed: () => _navigateToLogin(context),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Login na Plataforma'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 18,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                  ),
                  OutlinedButton.icon(
                    key: const Key('landing_hero_register_button'),
                    onPressed: () => _navigateToCadastro(context),
                    icon: const Icon(Icons.business_center),
                    label: const Text('Cadastrar Empresa'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 18,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(color: colorScheme.primary, width: 2),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightsSection(BuildContext context, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 20,
        vertical: 36,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              _buildHighlightCard(
                context,
                icon: Icons.gavel,
                title: 'Portaria MTP 671/2021',
                description: 'Ponto Eletrônico homologado com AEJ e comprovante digital assinado.',
                color: Colors.blue,
              ),
              _buildHighlightCard(
                context,
                icon: Icons.calculate_outlined,
                title: 'MCASP & STN',
                description: 'Cálculo de Custo Médio Ponderado (PMP) e conformidade contábil.',
                color: Colors.teal,
              ),
              _buildHighlightCard(
                context,
                icon: Icons.wifi_off,
                title: 'Offline-First Total',
                description: 'Marcações e conferências locais com sincronização automática.',
                color: Colors.amber.shade800,
              ),
              _buildHighlightCard(
                context,
                icon: Icons.security,
                title: 'Multi-Tenant & RBAC',
                description: 'Isolamento seguro de dados por órgão e controle estrito de acessos.',
                color: Colors.purple,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.75),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModulesSection(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 20,
        vertical: 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Text(
                'Módulos da Plataforma',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Soluções completas e modulares para atender servidores, gestores e auditores.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 36),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = isDesktop ? (constraints.maxWidth - 40) / 3 : constraints.maxWidth;
                  return Wrap(
                    spacing: 20,
                    runSpacing: 24,
                    children: [
                      _buildModuleDetailCard(
                        context,
                        width: cardWidth,
                        icon: Icons.fingerprint,
                        color: Colors.blueAccent,
                        tag: 'MÓDULO DE PONTO',
                        title: 'Ponto Eletrônico & Espelho Digital',
                        features: [
                          'Ciclo sequencial inteligente (Entrada, Intervalo, Retorno e Saída).',
                          'Geolocalização GPS de alta precisão e foto de biometria.',
                          'Espelho de Ponto individual com exportação oficial em PDF.',
                          'Ajustes manuais com seleção de justificativas legais padronizadas.',
                          'Comprovante digital automático por e-mail com Hash SHA-256.',
                        ],
                      ),
                      _buildModuleDetailCard(
                        context,
                        width: cardWidth,
                        icon: Icons.inventory_2_outlined,
                        color: const Color(0xFF0D9488),
                        tag: 'MÓDULO DE ESTOQUE',
                        title: 'Almoxarifado & Gestão Contábil',
                        features: [
                          'Catálogo padronizado de materiais (CATMAT) e classes de consumo.',
                          'Custo Médio Ponderado (PMP) automático a cada entrada.',
                          'Entrada vinculada a NF-e e Empenhos (Lei nº 14.133/2021).',
                          'Requisições públicas setoriais com fluxo de aprovação e baixa.',
                          'Controle de saldos e alertas de estoque mínimo e crítico.',
                        ],
                      ),
                      _buildModuleDetailCard(
                        context,
                        width: cardWidth,
                        icon: Icons.people_alt_outlined,
                        color: const Color(0xFF7C3AED),
                        tag: 'MÓDULO DE PESSOAS',
                        title: 'Gestão de Servidores & RBAC',
                        features: [
                          'Cadastro de colaboradores com máscara e validação de CPF oficial.',
                          'Perfis de acesso: Administrador, Gestor de RH, Colaborador e Almoxarife.',
                          'Controle granular de acesso ao módulo de estoque por servidor.',
                          'Sessão autenticada via tokens JWT com renovação contínua.',
                          'Trilha de auditoria completa para órgãos fiscalizadores e TCEs.',
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleDetailCard(
    BuildContext context, {
    required double width,
    required IconData icon,
    required Color color,
    required String tag,
    required String title,
    required List<String> features,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: width,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tag,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          ...features.map(
            (feat) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, size: 18, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feat,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 20,
        vertical: 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Text(
                'Diferenciais Tecnológicos',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 24,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: [
                  _buildFeatureItem(
                    context,
                    icon: Icons.sync,
                    title: 'Auto-Sincronização & Sensor Ativo',
                    description: 'Monitoramento contínuo de conectividade que envia lotes offline silenciosamente quando a conexão é restabelecida.',
                  ),
                  _buildFeatureItem(
                    context,
                    icon: Icons.email_outlined,
                    title: 'Disparo de Comprovantes por E-mail',
                    description: 'Notificação imediata ao servidor com dados da batida, NSR sequencial e código hash de integridade.',
                  ),
                  _buildFeatureItem(
                    context,
                    icon: Icons.picture_as_pdf_outlined,
                    title: 'Exportações Oficiais em PDF',
                    description: 'Geração do Espelho de Ponto pronto para assinatura digital e relatórios contábeis para auditoria.',
                  ),
                  _buildFeatureItem(
                    context,
                    icon: Icons.devices,
                    title: 'Web, Mobile & Desktop',
                    description: 'Interface totalmente responsiva adaptada para computadores de mesa, tablets e smartphones.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.primary, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.75),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCtaSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            color: colorScheme.primary,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                children: [
                  const Text(
                    'Pronto para acessar o Chronos Pulse?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Entre com suas credenciais ou cadastre sua empresa para gerenciar batidas de ponto, estoques e requisições públicas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _navigateToLogin(context),
                        icon: const Icon(Icons.login),
                        label: const Text('Login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 36,
                            vertical: 16,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _navigateToCadastro(context),
                        icon: const Icon(Icons.business_center),
                        label: const Text('Cadastrar Empresa'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 36,
                            vertical: 16,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Colors.white54, width: 2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Center(
        child: Text(
          '© 2026 Chronos Pulse · Gestão Pública Integrada. Todos os direitos reservados.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

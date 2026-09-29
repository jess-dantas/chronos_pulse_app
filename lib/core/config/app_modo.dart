/// Modo de compilacao do app, definido via `--dart-define=APP_MODE`.
///
/// Valores:
/// - [completo] (padrao): comportamento atual do app — rotas de cliente
///   (`/login`, `/painel/*`) E admin (`/admin/*`) disponiveis. Usado no
///   build web de producao (sem define), que permanece identico ao atual.
/// - [cliente]: app para clientes finais — o login da plataforma
///   (`/admin/*`) fica inacessivel (deep link tambem redireciona).
/// - [admin]: app exclusivo do dono da plataforma — somente a area
///   `/admin` (e `/perfil`); landing/login de cliente e ignorados.
class AppModo {
  AppModo._();

  static const String completo = 'completo';
  static const String cliente = 'cliente';
  static const String admin = 'admin';

  static const String atual =
      String.fromEnvironment('APP_MODE', defaultValue: completo);

  static bool get ehAdmin => atual == admin;

  /// True quando as rotas de admin devem ficar bloqueadas neste build.
  static bool get bloqueiaAdmin => atual == cliente;
}

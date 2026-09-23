import '../datasources/titularidade_remote_datasource.dart';
import '../models/titularidade_model.dart';

class TitularidadeRepository {
  final TitularidadeRemoteDataSource remoteDataSource;

  TitularidadeRepository({required this.remoteDataSource});

  Future<TitularidadeIniciado> iniciar(String novoTitularId) async {
    final json = await remoteDataSource.iniciar(novoTitularId);
    return TitularidadeIniciado.fromJson(json);
  }

  Future<void> confirmarBiometria(
      String transferenciaId, bool confirmado) {
    return remoteDataSource.confirmarBiometria(transferenciaId, confirmado);
  }

  Future<String> enviarCodigoCelular(String transferenciaId) async {
    final json = await remoteDataSource.enviarCodigoCelular(transferenciaId);
    return json['destino']?.toString() ?? '';
  }

  Future<void> verificarCelular(
    String transferenciaId, {
    required String codigo,
    required bool celularConfirmado,
  }) {
    return remoteDataSource.verificarCelular(
      transferenciaId,
      codigo: codigo,
      celularConfirmado: celularConfirmado,
    );
  }

  Future<String> enviarCodigoEmail(String transferenciaId) async {
    final json = await remoteDataSource.enviarCodigoEmail(transferenciaId);
    return json['destino']?.toString() ?? '';
  }

  Future<void> verificarEmail(
    String transferenciaId, {
    required String codigo,
  }) {
    return remoteDataSource.verificarEmail(transferenciaId, codigo: codigo);
  }

  Future<void> concluir(String transferenciaId) {
    return remoteDataSource.concluir(transferenciaId);
  }

  Future<void> cancelar(String transferenciaId) {
    return remoteDataSource.cancelar(transferenciaId);
  }
}

import 'package:uuid/uuid.dart';

class RegistroPontoModel {
  final String idLocal;
  final String? colaboradorId;
  final DateTime dataHoraDispositivo;
  final String tipoRegistro; // "ENTRADA", "INTERVALO", "RETORNO", "SAIDA"
  final double latitude;
  final double longitude;
  final double precisaoGps;
  final String? fotoUrl;
  final String? hashLocal;
  final bool sincronizadoOffline;

  RegistroPontoModel({
    required this.idLocal,
    this.colaboradorId,
    required this.dataHoraDispositivo,
    required this.tipoRegistro,
    required this.latitude,
    required this.longitude,
    required this.precisaoGps,
    this.fotoUrl,
    this.hashLocal,
    this.sincronizadoOffline = false,
  });

  /// Formato salvo localmente no SQLite / Web storage
  Map<String, dynamic> toJson() {
    return {
      'idLocal': idLocal,
      'colaboradorId': colaboradorId,
      'dataHoraDispositivo': dataHoraDispositivo.toIso8601String(),
      'tipoRegistro': tipoRegistro,
      'latitude': latitude,
      'longitude': longitude,
      'precisaoGps': precisaoGps,
      'fotoUrl': fotoUrl,
      'hashLocal': hashLocal,
      'sincronizadoOffline': sincronizadoOffline ? 1 : 0,
    };
  }

  /// Formato enviado para a API REST backend (/api/v1/pontos/sincronizar)
  Map<String, dynamic> toApiJson() {
    return {
      'idLocal': idLocal,
      'dataHoraDispositivo': dataHoraDispositivo.toUtc().toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'precisaoGps': precisaoGps,
      'fotoUrl': fotoUrl,
      'hashLocal': hashLocal,
    };
  }

  factory RegistroPontoModel.fromJson(Map<String, dynamic> json) {
    return RegistroPontoModel(
      idLocal: json['idLocal'] ?? const Uuid().v4(),
      colaboradorId: json['colaboradorId'],
      dataHoraDispositivo: DateTime.parse(json['dataHoraDispositivo']),
      tipoRegistro: json['tipoRegistro'] ?? 'ENTRADA',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      precisaoGps: (json['precisaoGps'] as num).toDouble(),
      fotoUrl: json['fotoUrl'],
      hashLocal: json['hashLocal'],
      sincronizadoOffline: (json['sincronizadoOffline'] == true || json['sincronizadoOffline'] == 1),
    );
  }
}

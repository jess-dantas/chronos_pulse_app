import 'package:uuid/uuid.dart';

class RegistroPontoModel {
  final String idLocal;
  final String colaboradorId;
  final DateTime dataHoraDispositivo;
  final String tipoRegistro; // "ENTRADA", "SAIDA", etc.
  final double latitude;
  final double longitude;
  final double precisaoGps;
  final String? fotoUrl;
  final bool sincronizadoOffline;

  RegistroPontoModel({
    required this.idLocal,
    required this.colaboradorId,
    required this.dataHoraDispositivo,
    required this.tipoRegistro,
    required this.latitude,
    required this.longitude,
    required this.precisaoGps,
    this.fotoUrl,
    this.sincronizadoOffline = false,
  });

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
      'sincronizadoOffline': sincronizadoOffline ? 1 : 0,
    };
  }

  factory RegistroPontoModel.fromJson(Map<String, dynamic> json) {
    return RegistroPontoModel(
      idLocal: json['idLocal'] ?? const Uuid().v4(),
      colaboradorId: json['colaboradorId'],
      dataHoraDispositivo: DateTime.parse(json['dataHoraDispositivo']),
      tipoRegistro: json['tipoRegistro'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      precisaoGps: (json['precisaoGps'] as num).toDouble(),
      fotoUrl: json['fotoUrl'],
      sincronizadoOffline: (json['sincronizadoOffline'] == true || json['sincronizadoOffline'] == 1),
    );
  }
}

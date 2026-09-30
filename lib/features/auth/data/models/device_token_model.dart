/// Resposta de `POST /auth/device/vincular`.
class DeviceTokenModel {
  final String deviceToken;
  final DateTime expiraEm;

  const DeviceTokenModel({required this.deviceToken, required this.expiraEm});

  factory DeviceTokenModel.fromJson(Map<String, dynamic> json) {
    final expiraRaw = json['expiraEm'];
    DateTime expiraEm;
    if (expiraRaw is String) {
      expiraEm = DateTime.tryParse(expiraRaw)?.toUtc() ??
          DateTime.now().toUtc().add(const Duration(days: 7));
    } else {
      expiraEm = DateTime.now().toUtc().add(const Duration(days: 7));
    }
    return DeviceTokenModel(
      deviceToken: (json['deviceToken'] ?? '') as String,
      expiraEm: expiraEm,
    );
  }
}

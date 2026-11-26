class DeviceStatus {
  final bool? lightOn;
  final bool? coolingOn; // Peltier cooling unit
  final bool? doorLocked; // Solenoid door lock
  final bool? roofOpen; // Atap teras / rumah (true = buka, false = tutup)
  final bool? buzzerOn; // Buzzer alarm khusus bahaya Flame & MQ-2
  final bool? porchCameraActive; // Kamera teras aktif ketika PIR deteksi gerakan

  final bool lightAutoMode;
  final bool coolingAutoMode;
  final bool roofAutoMode; // Mode otomatis atap berdasarkan sensor hujan
  final double targetTemperature;
  final int? peltierPwm; // Duty cycle PWM modul MOSFET pendingin (0-100%)
  final String doorTransition; // 'idle', 'opening', 'closing'
  final bool doorOnline;
  final DateTime lastUpdated;

  const DeviceStatus({
    this.lightOn,
    this.coolingOn,
    this.doorLocked,
    this.roofOpen,
    this.buzzerOn,
    this.porchCameraActive,
    this.lightAutoMode = true,
    this.coolingAutoMode = true,
    this.roofAutoMode = true,
    this.targetTemperature = 24.0,
    this.peltierPwm,
    this.doorTransition = 'idle',
    this.doorOnline = false,
    required this.lastUpdated,
  });

  bool get isDoorBusy =>
      doorTransition == 'opening' || doorTransition == 'closing';

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value.toString().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      lightOn: _parseBool(json['light_on']),
      coolingOn: _parseBool(json['cooling_on']),
      doorLocked: _parseBool(json['door_locked']),
      roofOpen: _parseBool(json['roof_open']),
      buzzerOn: _parseBool(json['buzzer_on']),
      porchCameraActive: _parseBool(json['porch_camera_active']),
      lightAutoMode: _parseBool(json['light_auto_mode']) ?? true,
      coolingAutoMode: _parseBool(json['cooling_auto_mode']) ?? true,
      roofAutoMode: _parseBool(json['roof_auto_mode']) ?? true,
      targetTemperature:
          (json['target_temperature'] as num?)?.toDouble() ?? 24.0,
      peltierPwm: _parseInt(json['peltier_pwm']),
      doorTransition: json['door_transition']?.toString() ?? 'idle',
      doorOnline: _parseBool(json['door_online']) ?? false,
      lastUpdated: json['last_updated'] != null
          ? DateTime.tryParse(json['last_updated'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'light_on': lightOn,
      'cooling_on': coolingOn,
      'door_locked': doorLocked,
      'roof_open': roofOpen,
      'buzzer_on': buzzerOn,
      'porch_camera_active': porchCameraActive,
      'light_auto_mode': lightAutoMode,
      'cooling_auto_mode': coolingAutoMode,
      'roof_auto_mode': roofAutoMode,
      'target_temperature': targetTemperature,
      'peltier_pwm': peltierPwm,
      'door_transition': doorTransition,
      'door_online': doorOnline,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  DeviceStatus copyWith({
    bool? lightOn,
    bool? coolingOn,
    bool? doorLocked,
    bool? roofOpen,
    bool? buzzerOn,
    bool? porchCameraActive,
    bool? lightAutoMode,
    bool? coolingAutoMode,
    bool? roofAutoMode,
    double? targetTemperature,
    int? peltierPwm,
    String? doorTransition,
    bool? doorOnline,
    DateTime? lastUpdated,
  }) {
    return DeviceStatus(
      lightOn: lightOn ?? this.lightOn,
      coolingOn: coolingOn ?? this.coolingOn,
      doorLocked: doorLocked ?? this.doorLocked,
      roofOpen: roofOpen ?? this.roofOpen,
      buzzerOn: buzzerOn ?? this.buzzerOn,
      porchCameraActive: porchCameraActive ?? this.porchCameraActive,
      lightAutoMode: lightAutoMode ?? this.lightAutoMode,
      coolingAutoMode: coolingAutoMode ?? this.coolingAutoMode,
      roofAutoMode: roofAutoMode ?? this.roofAutoMode,
      targetTemperature: targetTemperature ?? this.targetTemperature,
      peltierPwm: peltierPwm ?? this.peltierPwm,
      doorTransition: doorTransition ?? this.doorTransition,
      doorOnline: doorOnline ?? this.doorOnline,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

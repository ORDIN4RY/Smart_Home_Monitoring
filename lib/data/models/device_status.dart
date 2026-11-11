class DeviceStatus {
  final bool lightOn;
  final bool coolingOn; // Peltier cooling unit
  final bool doorLocked;// Solenoid door lock
  final bool roofOpen;  // Atap teras / rumah (true = buka, false = tutup)
  final bool buzzerOn;  // Buzzer alarm khusus bahaya Flame & MQ-2
  final bool porchCameraActive; // Kamera teras aktif ketika PIR deteksi gerakan

  final bool lightAutoMode;
  final bool coolingAutoMode;
  final bool roofAutoMode; // Mode otomatis atap berdasarkan sensor hujan
  final double targetTemperature;
  final int peltierPwm; // Duty cycle PWM modul MOSFET pendingin (0-100%)
  final DateTime lastUpdated;

  const DeviceStatus({
    this.lightOn = false,
    this.coolingOn = false,
    this.doorLocked = true,
    this.roofOpen = true,
    this.buzzerOn = false,
    this.porchCameraActive = false,
    this.lightAutoMode = true,
    this.coolingAutoMode = true,
    this.roofAutoMode = true,
    this.targetTemperature = 24.0,
    this.peltierPwm = 0,
    required this.lastUpdated,
  });

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      lightOn: json['light_on'] as bool? ?? false,
      coolingOn: json['cooling_on'] as bool? ?? false,
      doorLocked: json['door_locked'] as bool? ?? true,
      roofOpen: json['roof_open'] as bool? ?? true,
      buzzerOn: json['buzzer_on'] as bool? ?? false,
      porchCameraActive: json['porch_camera_active'] as bool? ?? false,
      lightAutoMode: json['light_auto_mode'] as bool? ?? true,
      coolingAutoMode: json['cooling_auto_mode'] as bool? ?? true,
      roofAutoMode: json['roof_auto_mode'] as bool? ?? true,
      targetTemperature: (json['target_temperature'] as num?)?.toDouble() ?? 24.0,
      peltierPwm: (json['peltier_pwm'] as num?)?.toInt() ?? 0,
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
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class DeviceStatus {
  final bool lightOn;
  final bool coolingOn; // Peltier cooling unit
  final bool doorLocked;// Solenoid door lock

  final bool lightAutoMode;
  final bool coolingAutoMode;
  final double targetTemperature;
  final DateTime lastUpdated;

  const DeviceStatus({
    this.lightOn = false,
    this.coolingOn = false,
    this.doorLocked = true,
    this.lightAutoMode = true,
    this.coolingAutoMode = true,
    this.targetTemperature = 24.0,
    required this.lastUpdated,
  });

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      lightOn: json['light_on'] as bool? ?? false,
      coolingOn: json['cooling_on'] as bool? ?? false,
      doorLocked: json['door_locked'] as bool? ?? true,
      lightAutoMode: json['light_auto_mode'] as bool? ?? true,
      coolingAutoMode: json['cooling_auto_mode'] as bool? ?? true,
      targetTemperature: (json['target_temperature'] as num?)?.toDouble() ?? 24.0,
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
      'light_auto_mode': lightAutoMode,
      'cooling_auto_mode': coolingAutoMode,
      'target_temperature': targetTemperature,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  DeviceStatus copyWith({
    bool? lightOn,
    bool? coolingOn,
    bool? doorLocked,
    bool? lightAutoMode,
    bool? coolingAutoMode,
    double? targetTemperature,
    DateTime? lastUpdated,
  }) {
    return DeviceStatus(
      lightOn: lightOn ?? this.lightOn,
      coolingOn: coolingOn ?? this.coolingOn,
      doorLocked: doorLocked ?? this.doorLocked,
      lightAutoMode: lightAutoMode ?? this.lightAutoMode,
      coolingAutoMode: coolingAutoMode ?? this.coolingAutoMode,
      targetTemperature: targetTemperature ?? this.targetTemperature,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

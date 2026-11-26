class SensorReading {
  final double? temperature;
  final double? humidity;
  final double? lightIntensity;
  final double? gasPpm;
  final bool? flameDetected;
  final bool? motionDetected;
  final bool? rainDetected;
  final bool? doorOpen;
  final DateTime timestamp;

  const SensorReading({
    this.temperature,
    this.humidity,
    this.lightIntensity,
    this.gasPpm,
    this.flameDetected,
    this.motionDetected,
    this.rainDetected,
    this.doorOpen,
    required this.timestamp,
  });

  bool get isGasDanger => gasPpm != null && gasPpm! >= 400;
  bool get isGasWarning => gasPpm != null && gasPpm! >= 200 && gasPpm! < 400;
  bool get isTempHigh => temperature != null && temperature! >= 32;
  bool get isDark => lightIntensity != null && lightIntensity! < 30.0;
  bool get isRaining => rainDetected == true;
  bool get isPorchCameraActive => motionDetected == true;
  bool get buzzerActive => flameDetected == true || isGasDanger;
  bool get hasEmergency => flameDetected == true || isGasDanger;
  bool get hasAnyData =>
      temperature != null ||
      humidity != null ||
      lightIntensity != null ||
      gasPpm != null ||
      flameDetected != null ||
      motionDetected != null ||
      rainDetected != null ||
      doorOpen != null;

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value.toString().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return null;
  }

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      temperature: _parseDouble(json['temperature']),
      humidity: _parseDouble(json['humidity']),
      lightIntensity: _parseDouble(json['light_intensity']),
      gasPpm: _parseDouble(json['gas_ppm']),
      flameDetected: _parseBool(json['flame_detected']),
      motionDetected: _parseBool(json['motion_detected']),
      rainDetected: _parseBool(json['rain_detected']),
      doorOpen: _parseBool(json['door_open']),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'light_intensity': lightIntensity,
      'gas_ppm': gasPpm,
      'flame_detected': flameDetected,
      'motion_detected': motionDetected,
      'rain_detected': rainDetected,
      'door_open': doorOpen,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  SensorReading copyWith({
    double? temperature,
    double? humidity,
    double? lightIntensity,
    double? gasPpm,
    bool? flameDetected,
    bool? motionDetected,
    bool? rainDetected,
    bool? doorOpen,
    DateTime? timestamp,
  }) {
    return SensorReading(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      lightIntensity: lightIntensity ?? this.lightIntensity,
      gasPpm: gasPpm ?? this.gasPpm,
      flameDetected: flameDetected ?? this.flameDetected,
      motionDetected: motionDetected ?? this.motionDetected,
      rainDetected: rainDetected ?? this.rainDetected,
      doorOpen: doorOpen ?? this.doorOpen,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class SensorReading {
  final double temperature;
  final double humidity;
  final double lightIntensity;
  final double gasPpm;
  final bool flameDetected;
  final bool motionDetected;
  final bool rainDetected;
  final bool doorOpen;
  final DateTime timestamp;

  const SensorReading({
    required this.temperature,
    required this.humidity,
    required this.lightIntensity,
    required this.gasPpm,
    required this.flameDetected,
    required this.motionDetected,
    this.rainDetected = false,
    required this.doorOpen,
    required this.timestamp,
  });

  bool get isGasDanger => gasPpm >= 400;
  bool get isGasWarning => gasPpm >= 200 && gasPpm < 400;
  bool get isTempHigh => temperature >= 32;
  bool get isDark => lightIntensity < 30.0;
  bool get isRaining => rainDetected;
  bool get isPorchCameraActive => motionDetected;
  bool get buzzerActive => flameDetected || isGasDanger;
  bool get hasEmergency => flameDetected || isGasDanger;

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0.0,
      lightIntensity: (json['light_intensity'] as num?)?.toDouble() ?? 0.0,
      gasPpm: (json['gas_ppm'] as num?)?.toDouble() ?? 0.0,
      flameDetected: json['flame_detected'] as bool? ?? false,
      motionDetected: json['motion_detected'] as bool? ?? false,
      rainDetected: json['rain_detected'] as bool? ?? false,
      doorOpen: json['door_open'] as bool? ?? false,
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

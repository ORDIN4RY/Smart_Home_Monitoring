class SensorReading {
  final double temperature;
  final double humidity;
  final double lightIntensity;
  final double gasPpm;
  final bool flameDetected;
  final bool motionDetected;
  final bool doorOpen;
  final DateTime timestamp;

  const SensorReading({
    required this.temperature,
    required this.humidity,
    required this.lightIntensity,
    required this.gasPpm,
    required this.flameDetected,
    required this.motionDetected,
    required this.doorOpen,
    required this.timestamp,
  });

  bool get isGasDanger => gasPpm >= 400;
  bool get isGasWarning => gasPpm >= 200 && gasPpm < 400;
  bool get isTempHigh => temperature >= 32;
  bool get hasEmergency => flameDetected || isGasDanger;

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0.0,
      lightIntensity: (json['light_intensity'] as num?)?.toDouble() ?? 0.0,
      gasPpm: (json['gas_ppm'] as num?)?.toDouble() ?? 0.0,
      flameDetected: json['flame_detected'] as bool? ?? false,
      motionDetected: json['motion_detected'] as bool? ?? false,
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
      doorOpen: doorOpen ?? this.doorOpen,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

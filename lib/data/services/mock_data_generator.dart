import 'dart:math';
import '../models/user_model.dart';
import '../models/sensor_reading.dart';
import '../models/device_status.dart';
import '../models/event_log.dart';
import '../models/face_model.dart';

class MockDataGenerator {
  static final Random _random = Random();

  static UserModel currentUser = const UserModel(
    id: 'usr_001',
    name: 'Administrator Rumah',
    email: 'admin@smarthome.id',
    role: 'Home Owner',
    token: 'mock_jwt_token_sample_abc123',
  );

  static DeviceStatus deviceStatus = DeviceStatus(
    lightOn: false,
    coolingOn: true,
    doorLocked: true,
    lightAutoMode: true,
    coolingAutoMode: true,
    targetTemperature: 24.0,
    lastUpdated: DateTime.now(),
  );

  static SensorReading currentSensor = SensorReading(
    temperature: 28.4,
    humidity: 62.0,
    lightIntensity: 42.0,
    gasPpm: 95.0,
    flameDetected: false,
    motionDetected: false,
    doorOpen: false,
    timestamp: DateTime.now(),
  );

  static final List<RegisteredFace> registeredFaces = [
    RegisteredFace(
      id: 'fc_001',
      name: 'Ahmad Fauzi',
      role: 'Kepala Keluarga',
      registeredAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    RegisteredFace(
      id: 'fc_002',
      name: 'Siti Rahma',
      role: 'Istri',
      registeredAt: DateTime.now().subtract(const Duration(days: 28)),
    ),
    RegisteredFace(
      id: 'fc_003',
      name: 'Dimas Pratama',
      role: 'Anak',
      registeredAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
  ];

  static final List<AccessAttempt> accessAttempts = [
    AccessAttempt(
      id: 'acc_001',
      matchedName: 'Ahmad Fauzi',
      isLivenessPassed: true,
      livenessScore: 0.98,
      isAuthorized: true,
      message: 'Wajah Asli Terverifikasi (MiniFasNet). Pintu Terbuka.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
    ),
    AccessAttempt(
      id: 'acc_002',
      matchedName: 'Ahmad Fauzi (Manipulasi)',
      isLivenessPassed: false,
      livenessScore: 0.14,
      isAuthorized: false,
      message: '⚠️ MiniFasNet: Manipulasi Wajah Terdeteksi! (Serangan Foto/Layar)',
      timestamp: DateTime.now().subtract(const Duration(minutes: 38)),
    ),
    AccessAttempt(
      id: 'acc_003',
      matchedName: null,
      isLivenessPassed: true,
      livenessScore: 0.92,
      isAuthorized: false,
      message: 'Orang Tidak Dikenal (Wajah belum terdaftar di sistem)',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];

  static final List<EventLog> eventLogs = [
    EventLog(
      id: 'evt_001',
      title: '🚨 PERINGATAN SPOOFING (MiniFasNet)',
      description: 'Seseorang mencoba membuka pintu menggunakan foto/layar digital. Akses ditolak!',
      category: 'door',
      severity: EventSeverity.danger,
      timestamp: DateTime.now().subtract(const Duration(minutes: 38)),
    ),
    EventLog(
      id: 'evt_002',
      title: 'Akses Pintu Berhasil',
      description: 'Ahmad Fauzi terverifikasi (Liveness Pass 98%).',
      category: 'door',
      severity: EventSeverity.normal,
      timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
    ),
    EventLog(
      id: 'evt_003',
      title: 'Pendingin Peltier Aktif',
      description: 'Suhu 29.5°C melebihi target 24°C, Peltier otomatis dinyalakan.',
      category: 'device',
      severity: EventSeverity.normal,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    EventLog(
      id: 'evt_004',
      title: 'Peringatan Gas MQ-2',
      description: 'Sensor mendeteksi kenaikan gas hingga 210 PPM (Status: Waspada).',
      category: 'gas',
      severity: EventSeverity.warning,
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
    ),
  ];

  /// Generate dynamic slight updates to simulate live real-world sensors
  static SensorReading tickSensorData() {
    final tempDelta = (_random.nextDouble() - 0.48) * 0.4;
    final humDelta = (_random.nextDouble() - 0.5) * 0.8;
    final lightDelta = (_random.nextDouble() - 0.5) * 2.0;
    final gasDelta = (_random.nextDouble() - 0.5) * 4.0;

    double newTemp = (currentSensor.temperature + tempDelta).clamp(20.0, 38.0);
    double newHum = (currentSensor.humidity + humDelta).clamp(30.0, 90.0);
    double newLight = (currentSensor.lightIntensity + lightDelta).clamp(0.0, 100.0);
    double newGas = (currentSensor.gasPpm + gasDelta).clamp(40.0, 600.0);

    bool newMotion = _random.nextInt(10) > 7;

    currentSensor = currentSensor.copyWith(
      temperature: double.parse(newTemp.toStringAsFixed(1)),
      humidity: double.parse(newHum.toStringAsFixed(1)),
      lightIntensity: double.parse(newLight.toStringAsFixed(1)),
      gasPpm: double.parse(newGas.toStringAsFixed(1)),
      motionDetected: newMotion,
      timestamp: DateTime.now(),
    );

    // Automated device rules
    if (deviceStatus.lightAutoMode) {
      bool shouldLightBeOn = currentSensor.lightIntensity < 30.0;
      if (shouldLightBeOn != deviceStatus.lightOn) {
        deviceStatus = deviceStatus.copyWith(lightOn: shouldLightBeOn);
      }
    }

    if (deviceStatus.coolingAutoMode) {
      bool shouldCoolingBeOn = currentSensor.temperature > deviceStatus.targetTemperature;
      if (shouldCoolingBeOn != deviceStatus.coolingOn) {
        deviceStatus = deviceStatus.copyWith(coolingOn: shouldCoolingBeOn);
      }
    }

    return currentSensor;
  }

  /// History
  static List<SensorReading> getMockHistory() {
    final List<SensorReading> list = [];
    final now = DateTime.now();
    for (int i = 12; i >= 0; i--) {
      list.add(
        SensorReading(
          temperature: 26.0 + (_random.nextDouble() * 5.0),
          humidity: 55.0 + (_random.nextDouble() * 15.0),
          lightIntensity: 20.0 + (_random.nextDouble() * 60.0),
          gasPpm: 70.0 + (_random.nextDouble() * 60.0),
          flameDetected: false,
          motionDetected: i % 4 == 0,
          doorOpen: false,
          timestamp: now.subtract(Duration(minutes: i * 10)),
        ),
      );
    }
    return list;
  }

  /// Update mock device state
  static DeviceStatus updateDevice(String deviceKey, dynamic value) {
    switch (deviceKey) {
      case 'light':
        deviceStatus = deviceStatus.copyWith(lightOn: value as bool);
        break;
      case 'cooling':
        deviceStatus = deviceStatus.copyWith(coolingOn: value as bool);
        break;
      case 'door_lock':
        deviceStatus = deviceStatus.copyWith(doorLocked: value as bool);
        eventLogs.insert(
          0,
          EventLog(
            id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
            title: value == true ? 'Pintu Dikunci' : 'Pintu Dibuka Manual',
            description: value == true
                ? 'Solenoid door lock dikunci melalui aplikasi.'
                : 'Solenoid door lock dibuka manual dari aplikasi smartphone.',
            category: 'door',
            severity: EventSeverity.normal,
            timestamp: DateTime.now(),
          ),
        );
        break;
      case 'target_temp':
        deviceStatus = deviceStatus.copyWith(targetTemperature: (value as num).toDouble());
        break;
      case 'light_auto_mode':
        deviceStatus = deviceStatus.copyWith(lightAutoMode: value as bool);
        break;
      case 'cooling_auto_mode':
        deviceStatus = deviceStatus.copyWith(coolingAutoMode: value as bool);
        break;
    }
    deviceStatus = deviceStatus.copyWith(lastUpdated: DateTime.now());
    return deviceStatus;
  }

  /// Register new face
  static RegisteredFace registerFace(String name, String role) {
    final newFace = RegisteredFace(
      id: 'fc_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      role: role,
      registeredAt: DateTime.now(),
    );
    registeredFaces.insert(0, newFace);
    eventLogs.insert(
      0,
      EventLog(
        id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Pendaftaran Wajah Baru',
        description: 'Wajah "$name" ($role) berhasil didaftarkan ke sistem pengenal wajah.',
        category: 'door',
        severity: EventSeverity.normal,
        timestamp: DateTime.now(),
      ),
    );
    return newFace;
  }

  static void deleteFace(String id) {
    registeredFaces.removeWhere((f) => f.id == id);
  }
}

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
    roofOpen: true,
    buzzerOn: false,
    porchCameraActive: false,
    lightAutoMode: true,
    coolingAutoMode: true,
    roofAutoMode: true,
    targetTemperature: 24.0,
    peltierPwm: 75,
    lastUpdated: DateTime.now(),
  );

  static SensorReading currentSensor = SensorReading(
    temperature: 28.4,
    humidity: 62.0,
    lightIntensity: 42.0,
    gasPpm: 95.0,
    flameDetected: false,
    motionDetected: false,
    rainDetected: false,
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
    // Sesekali simulasi status hujan berubah
    bool newRain = currentSensor.rainDetected;
    if (_random.nextInt(35) == 0) {
      newRain = !newRain;
    }

    currentSensor = currentSensor.copyWith(
      temperature: double.parse(newTemp.toStringAsFixed(1)),
      humidity: double.parse(newHum.toStringAsFixed(1)),
      lightIntensity: double.parse(newLight.toStringAsFixed(1)),
      gasPpm: double.parse(newGas.toStringAsFixed(1)),
      motionDetected: newMotion,
      rainDetected: newRain,
      timestamp: DateTime.now(),
    );

    // 1. Logika PIR & LDR untuk Lampu & Teras (Kamera aktif saat ada gerakan)
    bool newLightOn = deviceStatus.lightOn;
    if (deviceStatus.lightAutoMode) {
      // Lampu menyala jika intensitas cahaya redup (< 30) ATAU terdeteksi gerakan PIR
      newLightOn = currentSensor.lightIntensity < 30.0 || newMotion;
    }
    bool cameraActive = newMotion;

    // 2. Logika Sensor Flame & MQ-2: Peringatan HANYA ke Buzzer
    bool buzzerAlert = currentSensor.flameDetected || currentSensor.isGasDanger;

    // 3. Logika Sensor Hujan & Atap Rumah (Otomatis vs Manual)
    bool newRoofOpen = deviceStatus.roofOpen;
    if (deviceStatus.roofAutoMode) {
      // Otomatis: Hujan -> Atap Menutup; Kering -> Atap Membuka
      newRoofOpen = !newRain;
    }

    // 4. Logika Peltier & Modul MOSFET PWM (Penyesuaian Suhu Otomatis)
    int calculatedPwm = 0;
    if (deviceStatus.coolingOn) {
      if (deviceStatus.coolingAutoMode) {
        // Otomatis menyesuaikan suhu ruangan ke targetTemperature via duty cycle PWM
        double diff = currentSensor.temperature - deviceStatus.targetTemperature;
        if (diff > 0) {
          calculatedPwm = ((diff / 4.0) * 80 + 20).clamp(20, 100).round();
        } else {
          calculatedPwm = 0;
        }
      } else {
        calculatedPwm = 80;
      }
    } else {
      calculatedPwm = 0;
    }

    deviceStatus = deviceStatus.copyWith(
      lightOn: newLightOn,
      porchCameraActive: cameraActive,
      buzzerOn: buzzerAlert,
      roofOpen: newRoofOpen,
      peltierPwm: calculatedPwm,
      lastUpdated: DateTime.now(),
    );

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
          rainDetected: false,
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
        final isOn = value as bool;
        int pwm = 0;
        if (isOn) {
          double diff = currentSensor.temperature - deviceStatus.targetTemperature;
          pwm = deviceStatus.coolingAutoMode
              ? (diff > 0 ? ((diff / 4.0) * 80 + 20).clamp(20, 100).round() : 0)
              : 80;
        }
        deviceStatus = deviceStatus.copyWith(coolingOn: isOn, peltierPwm: pwm);
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
      case 'roof':
        deviceStatus = deviceStatus.copyWith(roofOpen: value as bool);
        eventLogs.insert(
          0,
          EventLog(
            id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
            title: value == true ? 'Atap Dibuka Manual' : 'Atap Ditutup Manual',
            description: value == true
                ? 'Atap rumah dibuka secara manual dari aplikasi.'
                : 'Atap rumah ditutup secara manual dari aplikasi.',
            category: 'device',
            severity: EventSeverity.normal,
            timestamp: DateTime.now(),
          ),
        );
        break;
      case 'roof_auto_mode':
        final isAuto = value as bool;
        bool roofState = deviceStatus.roofOpen;
        if (isAuto) {
          roofState = !currentSensor.rainDetected;
        }
        deviceStatus = deviceStatus.copyWith(roofAutoMode: isAuto, roofOpen: roofState);
        break;
      case 'target_temp':
        final newTarget = (value as num).toDouble();
        int pwm = deviceStatus.peltierPwm;
        if (deviceStatus.coolingOn && deviceStatus.coolingAutoMode) {
          double diff = currentSensor.temperature - newTarget;
          pwm = diff > 0 ? ((diff / 4.0) * 80 + 20).clamp(20, 100).round() : 0;
        }
        deviceStatus = deviceStatus.copyWith(targetTemperature: newTarget, peltierPwm: pwm);
        break;
      case 'light_auto_mode':
        deviceStatus = deviceStatus.copyWith(lightAutoMode: value as bool);
        break;
      case 'cooling_auto_mode':
        final auto = value as bool;
        int pwm = 0;
        if (deviceStatus.coolingOn) {
          if (auto) {
            double diff = currentSensor.temperature - deviceStatus.targetTemperature;
            pwm = diff > 0 ? ((diff / 4.0) * 80 + 20).clamp(20, 100).round() : 0;
          } else {
            pwm = 80;
          }
        }
        deviceStatus = deviceStatus.copyWith(coolingAutoMode: auto, peltierPwm: pwm);
        break;
      case 'buzzer':
        deviceStatus = deviceStatus.copyWith(buzzerOn: value as bool);
        break;
      case 'rain_simulate':
        final isRain = value as bool;
        currentSensor = currentSensor.copyWith(rainDetected: isRain);
        if (deviceStatus.roofAutoMode) {
          deviceStatus = deviceStatus.copyWith(roofOpen: !isRain);
        }
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

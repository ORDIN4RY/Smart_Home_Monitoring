import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import '../../core/config/api_config.dart';
import '../models/device_status.dart';
import '../models/event_log.dart';
import '../models/face_model.dart';
import '../models/sensor_reading.dart';
import 'alert_manager.dart';
import 'mqtt_client_io.dart' if (dart.library.js_interop) 'mqtt_client_web.dart';
import 'server_connection_manager.dart';
import 'sync_manager.dart';

class MqttService {
  static const String topicSensors = 'homatix/mobile/sensors';
  static const String topicDevices = 'homatix/mobile/devices';
  static const String topicEvents = 'homatix/mobile/events';
  static const String topicRecognition = 'homatix/mobile/recognition';

  static final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);
  static final ValueNotifier<AccessAttempt?> latestRecognition =
      ValueNotifier<AccessAttempt?>(null);

  static MqttClient? _client;
  static StreamSubscription<List<MqttReceivedMessage<MqttMessage?>>>? _sub;
  static Timer? _reconnectTimer;
  static bool _connecting = false;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    ServerConnectionManager.currentBaseUrl.addListener(_onBaseUrlChanged);
    await connect();
  }

  static void _onBaseUrlChanged() {
    reconnect();
  }

  static Future<void> reconnect() async {
    disconnect();
    await connect();
  }

  static Future<void> connect() async {
    if (_connecting || ApiConfig.useMockData) return;
    _connecting = true;
    _reconnectTimer?.cancel();

    try {
      final wsUrl = ApiConfig.mqttWsUrl;
      final port = ApiConfig.mqttWsPort;
      final clientId = 'homatix_mobile_${DateTime.now().millisecondsSinceEpoch}';

      final client = createMqttClient(wsUrl, clientId, port);
      client.logging(on: false);
      client.keepAlivePeriod = 30;
      client.autoReconnect = true;
      client.onConnected = () {
        isConnected.value = true;
        debugPrint('[MqttService] Connected to $wsUrl');
      };
      client.onDisconnected = () {
        isConnected.value = false;
        debugPrint('[MqttService] Disconnected');
      };

      final connMsg = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);
      client.connectionMessage = connMsg;

      await client.connect();
      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        _client = client;
        isConnected.value = true;
        client.subscribe(topicSensors, MqttQos.atLeastOnce);
        client.subscribe(topicDevices, MqttQos.atLeastOnce);
        client.subscribe(topicEvents, MqttQos.atLeastOnce);
        client.subscribe(topicRecognition, MqttQos.atLeastOnce);

        _sub?.cancel();
        _sub = client.updates?.listen(_handleMessages);
      } else {
        client.disconnect();
        _scheduleReconnect();
      }
    } catch (e) {
      debugPrint('[MqttService] Connect error: $e');
      isConnected.value = false;
      _scheduleReconnect();
    } finally {
      _connecting = false;
    }
  }

  static void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 10), () {
      connect();
    });
  }

  static void _handleMessages(List<MqttReceivedMessage<MqttMessage?>> events) {
    for (final msg in events) {
      final recMess = msg.payload as MqttPublishMessage?;
      if (recMess == null) continue;
      final payloadStr = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      try {
        final decoded = jsonDecode(payloadStr);
        if (decoded is! Map<String, dynamic>) continue;

        switch (msg.topic) {
          case topicSensors:
            final reading = SensorReading.fromJson(decoded);
            SyncManager.applyRealtimeSensors(reading);
            break;
          case topicDevices:
            final status = DeviceStatus.fromJson(decoded);
            SyncManager.applyRealtimeDeviceStatus(status);
            break;
          case topicEvents:
            final event = EventLog.fromJson(decoded);
            final isFrAlert = event.title.contains('Spoofing') ||
                event.title.contains('Pemalsuan Wajah') ||
                event.title.contains('Wajah Tidak Dikenal');
            final isDoorConfirm = event.category == 'door' &&
                (event.title.contains('Terbuka') ||
                    event.title.contains('Tertutup'));
            final isMotion = event.category == 'motion';
            final isRain = event.category == 'weather' ||
                event.title.contains('Hujan');
            if (!isFrAlert &&
                (event.severity == EventSeverity.danger ||
                    event.severity == EventSeverity.warning ||
                    isDoorConfirm ||
                    isMotion)) {
              final title = isDoorConfirm
                  ? (event.title.contains('Terbuka')
                      ? 'Pintu Terbuka'
                      : 'Pintu Tertutup')
                  : (isMotion ? 'Ada Orang di Teras' : event.title);
              final message = (isDoorConfirm || isMotion || isRain)
                  ? ''
                  : event.description;
              AlertManager.show(
                DynamicAlert(
                  id: event.id,
                  title: title,
                  message: message,
                  icon: isRain
                      ? Icons.water_drop_rounded
                      : (isMotion
                          ? Icons.directions_walk_rounded
                          : (event.severity == EventSeverity.danger
                              ? Icons.warning_amber_rounded
                              : (isDoorConfirm
                                  ? Icons.sensor_door_outlined
                                  : Icons.notifications_active_rounded))),
                  priority: event.severity == EventSeverity.danger
                      ? AlertPriority.danger
                      : (event.severity == EventSeverity.warning
                          ? AlertPriority.warning
                          : AlertPriority.info),
                ),
              );
            }
            break;
          case topicRecognition:
            final attempt = AccessAttempt.fromJson(decoded);
            latestRecognition.value = attempt;
            if (!attempt.isAuthorized) {
              AlertManager.show(
                DynamicAlert(
                  id: attempt.id,
                  title: attempt.isSpoofAttack
                      ? 'Pemalsuan Wajah'
                      : 'Wajah Tidak Dikenal',
                  message: '',
                  icon: attempt.isSpoofAttack
                      ? Icons.gpp_bad_rounded
                      : Icons.person_off_rounded,
                  priority: attempt.isSpoofAttack
                      ? AlertPriority.danger
                      : AlertPriority.warning,
                  imageUrl: attempt.fullSnapshotUrl,
                ),
                autoCloseDuration: const Duration(seconds: 6),
              );
            }
            break;
        }
      } catch (e) {
        debugPrint('[MqttService] Parse error on ${msg.topic}: $e');
      }
    }
  }

  static void disconnect() {
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _sub = null;
    try {
      _client?.disconnect();
    } catch (_) {}
    _client = null;
    isConnected.value = false;
  }
}

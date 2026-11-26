import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

MqttClient createMqttClient(String wsUrl, String clientId, int port) {
  final client = MqttBrowserClient.withPort(wsUrl, clientId, port);
  client.websocketProtocols = MqttClientConstants.protocolsSingleDefault;
  return client;
}

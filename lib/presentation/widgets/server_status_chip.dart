import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/server_connection_manager.dart';
import '../screens/profile/device_settings_screen.dart';
import 'neu_box.dart';

class ServerStatusChip extends StatelessWidget {
  final bool compact;

  const ServerStatusChip({
    super.key,
    this.compact = false,
  });

  String _cleanHost(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.isNotEmpty ? '${uri.host}:${uri.port}' : url;
    } catch (_) {
      return url.replaceFirst('http://', '').replaceFirst('https://', '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ServerConnectionState>(
      valueListenable: ServerConnectionManager.status,
      builder: (context, connState, _) {
        return ValueListenableBuilder<String>(
          valueListenable: ServerConnectionManager.currentBaseUrl,
          builder: (context, baseUrl, _) {
            Color dotColor;
            String text;
            Color textColor = AppColors.textSecondary;
            bool isAlert = false;

            switch (connState) {
              case ServerConnectionState.connected:
                dotColor = AppColors.normal;
                text = compact ? 'Online' : 'Server: ${_cleanHost(baseUrl)}';
                break;
              case ServerConnectionState.disconnected:
                dotColor = AppColors.danger;
                textColor = AppColors.danger;
                text = compact ? 'Terputus' : 'Server Terputus • Ganti IP';
                isAlert = true;
                break;
              case ServerConnectionState.mockMode:
                dotColor = AppColors.warning;
                text = compact ? 'Mock' : 'Mode Mock (Demo)';
                break;
              case ServerConnectionState.checking:
                dotColor = AppColors.textMuted;
                text = compact ? 'Cek...' : 'Memeriksa Server...';
                break;
            }

            return GestureDetector(
              onTap: () {
                Navigator.of(context)
                    .push(
                  MaterialPageRoute(
                    builder: (_) => const DeviceSettingsScreen(),
                  ),
                )
                    .then((_) {
                  ServerConnectionManager.checkConnection();
                });
              },
              child: NeuBox(
                isPressed: isAlert,
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 9 : 12,
                  vertical: compact ? 5 : 6,
                ),
                borderRadius: BorderRadius.circular(16),
                glowColor: isAlert ? AppColors.danger.withAlpha(50) : null,
                glowRadius: isAlert ? 6 : 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                        boxShadow: [
                          BoxShadow(
                            color: dotColor.withAlpha(150),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: compact ? 11 : 11.5,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (isAlert) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.settings,
                        size: 11,
                        color: AppColors.danger,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

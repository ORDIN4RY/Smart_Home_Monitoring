import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/config/api_config.dart';
import '../../data/services/sync_manager.dart';
import '../screens/profile/device_settings_screen.dart';
import 'neu_box.dart';

class SyncStatusIndicator extends StatefulWidget {
  const SyncStatusIndicator({super.key});

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    SyncManager.syncStatus.addListener(_onStatusChanged);
    _onStatusChanged();
  }

  @override
  void dispose() {
    SyncManager.syncStatus.removeListener(_onStatusChanged);
    _spinController.dispose();
    super.dispose();
  }

  void _onStatusChanged() {
    if (SyncManager.syncStatus.value == SyncStatus.syncing) {
      if (!_spinController.isAnimating) {
        _spinController.repeat();
      }
    } else {
      if (_spinController.isAnimating) {
        _spinController.stop();
        _spinController.reset();
      }
    }
  }

  void _showSyncDetailsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _SyncDetailsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SyncStatus>(
      valueListenable: SyncManager.syncStatus,
      builder: (context, status, _) {
        Color dotColor;
        String label;
        bool isSpinning = false;
        bool isAlert = false;

        switch (status) {
          case SyncStatus.syncing:
            dotColor = AppColors.activeBlue;
            label = 'Syncing...';
            isSpinning = true;
            break;
          case SyncStatus.synced:
            dotColor = AppColors.normal;
            label = 'Online';
            break;
          case SyncStatus.offline:
            dotColor = AppColors.danger;
            label = 'Offline';
            isAlert = true;
            break;
          case SyncStatus.mock:
            dotColor = AppColors.warning;
            label = 'Mock';
            break;
          case SyncStatus.error:
            dotColor = AppColors.danger;
            label = 'Error';
            isAlert = true;
            break;
        }

        return GestureDetector(
          onTap: () => _showSyncDetailsModal(context),
          behavior: HitTestBehavior.opaque,
          child: NeuBox(
            isPressed: isAlert,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            borderRadius: BorderRadius.circular(16),
            glowColor: isAlert ? AppColors.danger.withAlpha(40) : null,
            glowRadius: isAlert ? 6 : 0,
            child: SizedBox(
              height: 20,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (isSpinning)
                    RotationTransition(
                      turns: _spinController,
                      child: const Icon(
                        Icons.sync,
                        size: 13,
                        color: AppColors.activeBlue,
                      ),
                    )
                  else
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: dotColor.withAlpha(140),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: dotColor,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SyncDetailsSheet extends StatefulWidget {
  const _SyncDetailsSheet();

  @override
  State<_SyncDetailsSheet> createState() => _SyncDetailsSheetState();
}

class _SyncDetailsSheetState extends State<_SyncDetailsSheet> {
  bool _isManualSyncing = false;

  String _formatTime(DateTime? dt) {
    if (dt == null) return 'Belum pernah disinkronkan';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 10) return 'Baru saja';
    if (diff.inSeconds < 60) return '${diff.inSeconds} detik lalu';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')} WIB';
  }

  Future<void> _triggerSync() async {
    setState(() => _isManualSyncing = true);
    await SyncManager.syncAll(silent: false);
    if (mounted) {
      setState(() => _isManualSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = SyncManager.syncStatus.value;
    final lastSync = SyncManager.lastSyncTime.value;
    final pendingCount = SyncManager.pendingChangesCount.value;

    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case SyncStatus.synced:
        statusText = 'Terhubung & Sinkron';
        statusColor = AppColors.normal;
        statusIcon = Icons.check_circle_outline;
        break;
      case SyncStatus.syncing:
        statusText = 'Sedang Menyinkronkan...';
        statusColor = AppColors.activeBlue;
        statusIcon = Icons.sync;
        break;
      case SyncStatus.offline:
        statusText = 'Terputus dari Server (Offline)';
        statusColor = AppColors.danger;
        statusIcon = Icons.cloud_off_outlined;
        break;
      case SyncStatus.mock:
        statusText = 'Mode Simulasi (Mock Data)';
        statusColor = AppColors.warning;
        statusIcon = Icons.science_outlined;
        break;
      case SyncStatus.error:
        statusText = 'Kesalahan Koneksi';
        statusColor = AppColors.danger;
        statusIcon = Icons.error_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.neuBase,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withAlpha(60),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Title
          const Row(
            children: [
              Icon(Icons.sync_alt, size: 22, color: AppColors.textPrimary),
              SizedBox(width: 10),
              Text(
                'Status Sinkronisasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status Plate NeuBox
          NeuBox(
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Host: ${ApiConfig.baseUrl}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFD5DFEC)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Waktu Sinkronisasi Terakhir:',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Text(
                      _formatTime(lastSync),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Perubahan Lokal Tertunda:',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Text(
                      pendingCount > 0 ? '$pendingCount perubahan' : 'Tersinkron',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: pendingCount > 0 ? AppColors.warning : AppColors.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action 1: Sinkronkan Sekarang
          GestureDetector(
            onTap: _isManualSyncing ? null : _triggerSync,
            child: NeuBox(
              padding: const EdgeInsets.symmetric(vertical: 14),
              borderRadius: BorderRadius.circular(18),
              glowColor: AppColors.activeBlue.withAlpha(40),
              glowRadius: 6,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isManualSyncing)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textPrimary,
                        ),
                      )
                    else
                      const Icon(Icons.refresh, size: 18, color: AppColors.textPrimary),
                    const SizedBox(width: 8),
                    Text(
                      _isManualSyncing ? 'Menyinkronkan...' : 'Sinkronkan Sekarang',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Action 2: Konfigurasi Server
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DeviceSettingsScreen()),
              );
            },
            child: NeuBox(
              isPressed: true,
              padding: const EdgeInsets.symmetric(vertical: 13),
              borderRadius: BorderRadius.circular(18),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.settings_outlined, size: 17, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Text(
                      'Ubah Konfigurasi Server / IP',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

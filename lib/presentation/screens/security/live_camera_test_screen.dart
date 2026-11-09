import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/face_model.dart';
import '../../../data/services/home_service.dart';
import '../../widgets/neu_box.dart';

class LiveCameraTestScreen extends StatefulWidget {
  const LiveCameraTestScreen({super.key});

  @override
  State<LiveCameraTestScreen> createState() => _LiveCameraTestScreenState();
}

class _LiveCameraTestScreenState extends State<LiveCameraTestScreen> {
  CameraController? _cam;
  List<CameraDescription> _cameras = [];
  int _camIdx = 0;
  bool _ready = false;
  bool _busy = false;
  String? _error;
  AccessAttempt? _result;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _cam?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _error = 'Tidak ada kamera.');
        return;
      }
      final front = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
      _camIdx = front != -1 ? front : 0;
      await _startCam(_cameras[_camIdx]);
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  Future<void> _startCam(CameraDescription desc) async {
    await _cam?.dispose();
    final c = CameraController(desc, ResolutionPreset.medium, enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);
    try {
      await c.initialize();
      if (mounted) setState(() { _cam = c; _ready = true; _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _flipCam() async {
    if (_cameras.length < 2) return;
    setState(() => _ready = false);
    _camIdx = (_camIdx + 1) % _cameras.length;
    await _startCam(_cameras[_camIdx]);
  }

  Future<void> _verify() async {
    if (_busy || _cam == null || !_cam!.value.isInitialized) return;
    setState(() => _busy = true);
    try {
      final pic = await _cam!.takePicture();
      final res = await HomeService.testRecognizeRealtime(pic);
      if (mounted) setState(() => _result = res);
    } catch (e) {
      if (mounted) {
        setState(() => _result = AccessAttempt(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          matchedName: null,
          isLivenessPassed: false,
          livenessScore: 0,
          isAuthorized: false,
          message: '$e',
          timestamp: DateTime.now(),
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neuBase,
      appBar: AppBar(
        title: const Text('Verifikasi Wajah'),
        actions: [
          if (_cameras.length > 1)
            IconButton(icon: const Icon(Icons.flip_camera_ios_outlined), onPressed: _flipCam),
        ],
      ),
      body: _error != null
          ? Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_off_outlined, size: 48, color: AppColors.danger),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 16),
                NeuBox(onTap: _initCamera, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ))
          : !_ready || _cam == null
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : SafeArea(
                  child: Column(
                    children: [
                      // ── Kamera (selalu 30 FPS mulus) ──
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: NeuBox(
                            padding: const EdgeInsets.all(4),
                            borderRadius: BorderRadius.circular(20),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CameraPreview(_cam!),
                            ),
                          ),
                        ),
                      ),

                      // ── Tombol Verifikasi ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: NeuBox(
                            onTap: _busy ? null : _verify,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            borderRadius: BorderRadius.circular(18),
                            glowColor: AppColors.primary.withAlpha(40),
                            glowRadius: 8,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_busy)
                                  const SizedBox(width: 18, height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                                else
                                  const Icon(Icons.face_retouching_natural, color: AppColors.primary, size: 22),
                                const SizedBox(width: 10),
                                Text(
                                  _busy ? 'Memverifikasi...' : 'Verifikasi Wajah',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ── Hasil Verifikasi ──
                      if (_result != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: _buildResultCard(_result!),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildResultCard(AccessAttempt r) {
    final isSpoof = r.isSpoofAttack;
    final granted = r.granted;
    final color = isSpoof ? AppColors.danger : (granted ? AppColors.normal : AppColors.warning);
    final icon = isSpoof ? Icons.block : (granted ? Icons.check_circle : Icons.cancel_outlined);
    final status = isSpoof ? 'SPOOF' : (granted ? 'DIIZINKAN' : 'DITOLAK');

    return NeuBox(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  r.matchedName ?? 'Tidak Dikenal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withAlpha(80))),
                child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Metrik singkat
          _metricRow('Kemiripan', r.similarityScore != null ? '${(r.similarityScore! * 100).toStringAsFixed(1)}%' : '-'),
          _metricRow('Liveness', '${(r.livenessScore * 100).toStringAsFixed(0)}% ${isSpoof ? "FAKE" : "REAL"}'),
          if (r.latencyMs != null) _metricRow('Latency', '${r.latencyMs} ms'),
          if (r.message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(r.message, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ),
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

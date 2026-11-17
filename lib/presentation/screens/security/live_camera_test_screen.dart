import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/face_model.dart';
import '../../../data/services/home_service.dart';
import '../../widgets/neu_box.dart';

enum CameraTestMode {
  ai, // Sistem Cerdas (Deep Learning Pretrained SFace + MiniFASNet)
  cv, // Computer Vision Klasik (Haar Cascade + Ekstraksi LBPH)
}

class LiveCameraTestScreen extends StatefulWidget {
  final CameraTestMode initialMode;

  const LiveCameraTestScreen({
    super.key,
    this.initialMode = CameraTestMode.ai,
  });

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
  late CameraTestMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
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
      final modeStr = _mode == CameraTestMode.ai ? 'ai' : 'cv';
      final res = await HomeService.testRecognizeRealtime(pic, mode: modeStr);
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
          mode: _mode == CameraTestMode.ai ? 'ai' : 'cv',
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _buildModeSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: NeuBox(
        isPressed: true,
        padding: const EdgeInsets.all(4),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Expanded(
              child: _modeTabButton(
                '🧠 Sistem Cerdas',
                'Deep Learning (AI)',
                CameraTestMode.ai,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _modeTabButton(
                '👁️ Computer Vision',
                'Ekstraksi LBPH',
                CameraTestMode.cv,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeTabButton(String title, String subtitle, CameraTestMode mode) {
    final isSelected = _mode == mode;
    return GestureDetector(
      onTap: () {
        if (_mode != mode) {
          setState(() {
            _mode = mode;
            _result = null;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.neuBase,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppColors.neuElevation(distance: 2, blur: 5),
              )
            : null,
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? AppColors.activeBlue : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neuBase,
      appBar: AppBar(
        title: Text(
          _mode == CameraTestMode.ai ? 'Uji Sistem Cerdas (AI)' : 'Uji Computer Vision (LBPH)',
        ),
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
                      // ── Tab Switcher: Sistem Cerdas vs Computer Vision ──
                      _buildModeSelector(),

                      // ── Kamera Preview (30 FPS) ──
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
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
                                  Icon(
                                    _mode == CameraTestMode.ai
                                        ? Icons.auto_awesome
                                        : Icons.visibility,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                const SizedBox(width: 10),
                                Text(
                                  _busy
                                      ? (_mode == CameraTestMode.ai ? 'Menganalisis AI (SFace)...' : 'Mengekstrak Fitur LBPH...')
                                      : (_mode == CameraTestMode.ai ? 'Verifikasi Sistem Cerdas (AI)' : 'Ekstraksi & Uji CV (LBPH)'),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ── Hasil Verifikasi ──
                      if (_result != null)
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: _buildResultCard(_result!),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildResultCard(AccessAttempt r) {
    final isCv = _mode == CameraTestMode.cv || r.isCvMode;
    final isSpoof = isCv ? false : r.isSpoofAttack;
    final granted = r.granted;
    final color = isSpoof ? AppColors.danger : (granted ? AppColors.normal : AppColors.warning);
    final icon = isSpoof ? Icons.block : (granted ? Icons.check_circle : Icons.cancel_outlined);
    final status = isSpoof ? 'SPOOF (AI)' : (granted ? 'DIIZINKAN' : 'DITOLAK');

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.matchedName ?? (isSpoof ? 'Wajah Palsu Terdeteksi' : 'Tidak Dikenal'),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                    ),
                    Text(
                      isCv ? 'Mode Computer Vision (Non-Pretrained)' : 'Mode Sistem Cerdas (Pretrained)',
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
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

          if (isCv) ...[
            // Metrik khusus Computer Vision (Ekstraksi LBPH)
            _metricRow('Metode', r.method ?? 'Haar + Ekstraksi LBPH (Non-Pretrained)'),
            _metricRow('Jarak Chi-Square', r.distance != null ? '${r.distance!.toStringAsFixed(2)} (Ambang <= 34.0)' : '-'),
            _metricRow('Kesesuaian Tekstur', r.similarityScore != null ? '${(r.similarityScore! * 100).toStringAsFixed(1)}%' : '-'),
            _metricRow('Representasi Fitur', 'Grid Spasial 8x8 (16384-D LBPH)'),
            if (r.latencyMs != null) _metricRow('Waktu Ekstraksi', '${r.latencyMs} ms'),

            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.neuBase,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                '💡 Karakteristik CV: Pengolahan murni berbasis citra tanpa model neural network. Deteksi ROI, konversi grayscale, ekualisasi histogram, dan pencocokan histogram tekstur LBPH.',
                style: TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
              ),
            ),

            if (r.pipelinePreviews != null && r.pipelinePreviews!.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                '🖼️ Visualisasi Citra Pipeline CV:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: r.pipelinePreviews!.map((p) {
                    final b64 = p['image'] ?? '';
                    if (b64.isEmpty) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.neuBase,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.memory(
                              base64Decode(b64),
                              width: 62,
                              height: 62,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 30),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p['label'] ?? '',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ] else ...[
            // Metrik Sistem Cerdas (Deep Learning: SFace + MiniFASNet)
            _metricRow('Model Pengenal', 'SFace ONNX (128-D L2 Embedding)'),
            _metricRow('Kemiripan Cosine', r.similarityScore != null ? '${(r.similarityScore! * 100).toStringAsFixed(1)}%' : '-'),
            _metricRow('Liveness Anti-Spoof', '${(r.livenessScore * 100).toStringAsFixed(0)}% ${isSpoof ? "FAKE" : "REAL"}'),
            if (r.latencyMs != null) _metricRow('Latency Inference', '${r.latencyMs} ms'),
          ],

          if (r.message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
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

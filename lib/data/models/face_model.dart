class RegisteredFace {
  final String id;
  final String name;
  final String role;
  final DateTime registeredAt;
  final int jumlahFrame;

  const RegisteredFace({
    required this.id,
    required this.name,
    required this.role,
    required this.registeredAt,
    this.jumlahFrame = 1,
  });

  /// Parse dari response Flask: GET /api/faces -> {"wajah": [...]}
  /// Setiap item: {"nama": "Faris", "jumlah_frame": 5, "diperbarui": "2026-11-05T10:00:00"}
  factory RegisteredFace.fromJson(Map<String, dynamic> json) {
    // Mendukung field Flask ("nama", "diperbarui") maupun field lama ("name", "registered_at")
    final nama = json['nama'] ?? json['name'] ?? '';
    final diperbarui = json['diperbarui'] ?? json['registered_at'];
    return RegisteredFace(
      id: nama, // Flask tidak pakai UUID — nama adalah identifier unik
      name: nama,
      role: json['role'] ?? 'Penghuni',
      registeredAt: diperbarui != null
          ? DateTime.tryParse(diperbarui.toString()) ?? DateTime.now()
          : DateTime.now(),
      jumlahFrame: json['jumlah_frame'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'registered_at': registeredAt.toIso8601String(),
        'jumlah_frame': jumlahFrame,
      };
}

/// Hasil recognition dari Flask: GET /api/status atau POST /api/recognize
class AccessAttempt {
  final String id;
  final String? matchedName;
  final bool isLivenessPassed; // MiniFASNet liveness check
  final double livenessScore;  // 0.0 – 1.0
  final bool isAuthorized;     // granted = true jika wajah dikenali & REAL
  final String message;        // catatan dari backend
  final DateTime timestamp;
  final double? similarityScore; // Skor cosine similarity (0.0 – 1.0)
  final double? threshold;       // Threshold backend (default 0.50)
  final int? latencyMs;          // Response latency dalam milidetik
  final Map<String, dynamic>? bbox; // Koordinat bounding box YuNet: {x, y, w, h, frame_w, frame_h}

  const AccessAttempt({
    required this.id,
    this.matchedName,
    required this.isLivenessPassed,
    required this.livenessScore,
    required this.isAuthorized,
    required this.message,
    required this.timestamp,
    this.similarityScore,
    this.threshold,
    this.latencyMs,
    this.bbox,
  });

  bool get isSpoofAttack => !isLivenessPassed;

  // Alias getter untuk kemudahan di UI
  bool get granted => isAuthorized;
  String? get liveness => isLivenessPassed ? 'REAL' : 'FAKE';
  double? get livenessSkor => livenessScore;
  double? get skor => similarityScore;
  String? get catatan => message.isNotEmpty ? message : null;
  String get similarityPercent =>
      similarityScore != null ? '${(similarityScore! * 100).toStringAsFixed(1)}%' : '-';
  String get livenessPercent => '${(livenessScore * 100).toStringAsFixed(1)}%';

  // Bounding box YuNet getters
  int? get bboxX => bbox?['x'] as int?;
  int? get bboxY => bbox?['y'] as int?;
  int? get bboxW => bbox?['w'] as int?;
  int? get bboxH => bbox?['h'] as int?;
  int? get frameW => bbox?['frame_w'] as int?;
  int? get frameH => bbox?['frame_h'] as int?;
  bool get hasBbox =>
      bboxX != null && bboxY != null && bboxW != null && bboxH != null && (frameW ?? 0) > 0 && (frameH ?? 0) > 0;

  /// Parse dari response Flask /api/status atau /api/recognize
  /// Field Flask: "wajah", "granted", "liveness", "liveness_skor", "skor", "threshold", "catatan", "waktu", "bbox"
  factory AccessAttempt.fromJson(Map<String, dynamic> json, {int? latency}) {
    // Dukung field Flask maupun field lama untuk kompatibilitas
    final liveness = json['liveness'] ?? json['is_liveness_passed'];
    final granted  = json['granted']  ?? json['is_authorized'] ?? false;
    final score    = json['liveness_skor'] ?? json['liveness_score'] ?? 1.0;
    final matchScore = json['skor'] ?? json['similarity_score'] ?? json['score'];
    final thresh   = json['threshold'];
    final name     = json['wajah'] ?? json['matched_name'];
    final note     = json['catatan'] ?? json['message'] ?? json['error'] ?? '';
    final ts       = json['waktu'] ?? json['timestamp'];
    final bboxMap  = json['bbox'] is Map ? Map<String, dynamic>.from(json['bbox']) : null;

    return AccessAttempt(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      matchedName: name?.toString(),
      isLivenessPassed: liveness == true,
      livenessScore: (score as num?)?.toDouble() ?? 1.0,
      isAuthorized: granted == true,
      message: note.toString(),
      timestamp: ts != null
          ? DateTime.tryParse(ts.toString()) ?? DateTime.now()
          : DateTime.now(),
      similarityScore: (matchScore as num?)?.toDouble(),
      threshold: (thresh as num?)?.toDouble() ?? 0.50,
      latencyMs: latency,
      bbox: bboxMap,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'matched_name': matchedName,
        'is_liveness_passed': isLivenessPassed,
        'liveness_score': livenessScore,
        'is_authorized': isAuthorized,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'similarity_score': similarityScore,
        'threshold': threshold,
        'latency_ms': latencyMs,
        'bbox': bbox,
      };
}

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/face_model.dart';
import '../../../data/services/home_service.dart';
import '../../widgets/neu_box.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/hazard_banner.dart';
import 'live_camera_test_screen.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  List<RegisteredFace> _faces = [];
  List<AccessAttempt> _attempts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final faces = await HomeService.fetchRegisteredFaces();
    final attempts = await HomeService.fetchAccessAttempts();
    if (mounted) {
      setState(() {
        _faces = faces;
        _attempts = attempts;
        _isLoading = false;
      });
    }
  }

  void _showRegisterFaceDialog() {
    final nameCtrl = TextEditingController();
    String selectedRole = 'Keluarga';
    final formKey = GlobalKey<FormState>();
    String? selectedImagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.neuBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daftarkan Wajah Baru',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ambil foto dari kamera atau galeri untuk mendaftarkan akses.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),

                    // ── Tombol Pilih Foto ─────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: NeuBox(
                            onTap: () async {
                              final picker = ImagePicker();
                              final picked = await picker.pickImage(
                                source: ImageSource.camera,
                                imageQuality: 85,
                              );
                              if (picked != null) {
                                setModalState(() => selectedImagePath = picked.path);
                              }
                            },
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            borderRadius: BorderRadius.circular(14),
                            child: const Column(
                              children: [
                                Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 22),
                                SizedBox(height: 4),
                                Text('Kamera', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: NeuBox(
                            onTap: () async {
                              final picker = ImagePicker();
                              final picked = await picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 85,
                              );
                              if (picked != null) {
                                setModalState(() => selectedImagePath = picked.path);
                              }
                            },
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            borderRadius: BorderRadius.circular(14),
                            child: const Column(
                              children: [
                                Icon(Icons.photo_library_outlined, color: AppColors.primary, size: 22),
                                SizedBox(height: 4),
                                Text('Galeri', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ── Indikator foto dipilih ────────────────────────
                    if (selectedImagePath != null) ...[
                      const SizedBox(height: 10),
                      NeuBox(
                        isPressed: true,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.normal, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Foto dipilih: ${selectedImagePath!.split('/').last}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 10),
                      NeuBox(
                        isPressed: true,
                        height: 60,
                        borderRadius: BorderRadius.circular(14),
                        child: const Center(
                          child: Text(
                            'Belum ada foto dipilih',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // ── Input Nama ────────────────────────────────────
                    NeuBox(
                      isPressed: true,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      borderRadius: BorderRadius.circular(16),
                      child: TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Nama Lengkap',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          icon: Icon(Icons.person_outline, color: AppColors.textSecondary, size: 20),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Masukkan nama' : null,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Dropdown Role ─────────────────────────────────
                    NeuBox(
                      isPressed: true,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      borderRadius: BorderRadius.circular(16),
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedRole,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          icon: Icon(Icons.badge_outlined, color: AppColors.textSecondary, size: 20),
                        ),
                        dropdownColor: AppColors.neuBase,
                        items: const [
                          DropdownMenuItem(value: 'Pemilik', child: Text('Pemilik Rumah')),
                          DropdownMenuItem(value: 'Keluarga', child: Text('Keluarga Inti')),
                          DropdownMenuItem(value: 'Asisten', child: Text('Asisten / Staf')),
                          DropdownMenuItem(value: 'Tamu Tetap', child: Text('Tamu Tetap')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedRole = val);
                        },
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ── Tombol Simpan ─────────────────────────────────
                    NeuBox(
                      onTap: () async {
                        if (!formKey.currentState!.validate()) return;
                        if (selectedImagePath == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pilih foto terlebih dahulu.'),
                              backgroundColor: AppColors.warning,
                            ),
                          );
                          return;
                        }
                        final name = nameCtrl.text.trim();
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.of(ctx).pop();

                        setState(() => _isLoading = true);
                        try {
                          await HomeService.registerNewFace(
                            name,
                            selectedRole,
                            filePath: selectedImagePath,
                          );
                          await _loadData();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Wajah "$name" berhasil didaftarkan!'),
                              backgroundColor: AppColors.normal,
                            ),
                          );
                        } catch (e) {
                          setState(() => _isLoading = false);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Gagal: $e'),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                        }
                      },
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      borderRadius: BorderRadius.circular(16),
                      glowColor: AppColors.primary.withAlpha(50),
                      glowRadius: 10,
                      child: const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.save_outlined, color: AppColors.primary, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Simpan Wajah',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Buka dialog kenali wajah — pilih foto lalu kirim ke Flask /api/recognize
  void _showRecognizeDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.neuBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Kenali Wajah',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Text(
                'Pilih foto wajah untuk dikenali oleh backend.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: NeuBox(
                      onTap: () => _pickAndRecognize(ctx, ImageSource.camera),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      borderRadius: BorderRadius.circular(14),
                      child: const Column(
                        children: [
                          Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 24),
                          SizedBox(height: 4),
                          Text('Kamera', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NeuBox(
                      onTap: () => _pickAndRecognize(ctx, ImageSource.gallery),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      borderRadius: BorderRadius.circular(14),
                      child: const Column(
                        children: [
                          Icon(Icons.photo_library_outlined, color: AppColors.primary, size: 24),
                          SizedBox(height: 4),
                          Text('Galeri', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndRecognize(BuildContext sheetCtx, ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    if (!mounted) return;
    // ignore: use_build_context_synchronously
    Navigator.of(sheetCtx).pop();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isLoading = true);
    try {
      final result = await HomeService.recognizeFace(picked.path);
      await _loadData();
      if (!mounted) return;
      _showRecognizeResult(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal mengenali: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  void _showRecognizeResult(AccessAttempt result) {
    final granted = result.granted;
    final name = result.matchedName ?? 'Tidak Dikenal';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.neuBase,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Icon(
              granted ? Icons.check_circle : Icons.cancel,
              color: granted ? AppColors.normal : AppColors.danger,
            ),
            const SizedBox(width: 8),
            Text(
              granted ? 'Akses Diberikan' : 'Akses Ditolak',
              style: TextStyle(
                color: granted ? AppColors.normal : AppColors.danger,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Wajah: $name',
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            if (result.liveness != null)
              Text(
                'Liveness: ${result.liveness} (skor: ${result.livenessSkor?.toStringAsFixed(2) ?? "-"})',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            if (result.catatan != null) ...[
              const SizedBox(height: 4),
              Text(result.catatan!, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFace(RegisteredFace face) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.neuBase,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Hapus Wajah', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Apakah Anda yakin ingin menghapus data akses "${face.name}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() => _isLoading = true);
              await HomeService.deleteFace(face.id);
              await _loadData();
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recentSpoof = _attempts.cast<AccessAttempt?>().firstWhere(
          (a) => a != null && a.isSpoofAttack,
          orElse: () => null,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keamanan & Akses Pintu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            tooltip: 'Uji Kamera Real-Time',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LiveCameraTestScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.face_retouching_natural),
            tooltip: 'Kenali Wajah',
            onPressed: _showRecognizeDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              backgroundColor: AppColors.neuBase,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (recentSpoof != null)
                      const HazardBanner(
                        title: '🚨 PERINGATAN: WAJAH PALSU TERDETEKSI!',
                        message:
                            'Terdeteksi upaya pembobolan pintu menggunakan foto/layar digital. Pintu otomatis tetap terkunci aman demi keselamatan rumah Anda.',
                        icon: Icons.shield_outlined,
                        isDanger: true,
                      ),

                    // Neumorphic Security Shield Plate
                    NeuBox(
                      padding: const EdgeInsets.all(18),
                      borderRadius: BorderRadius.circular(22),
                      child: Row(
                        children: [
                          NeuBox(
                            isPressed: true,
                            shape: BoxShape.circle,
                            padding: const EdgeInsets.all(12),
                            glowColor: AppColors.primary.withAlpha(40),
                            glowRadius: 6,
                            child: const Icon(Icons.security, color: AppColors.primary, size: 26),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Proteksi Pintu Pintar',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    StatusBadge(label: 'Terlindungi', type: BadgeType.normal),
                                  ],
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Pintu hanya akan terbuka untuk wajah orang asli yang sudah terdaftar. Foto atau layar akan langsung ditolak.',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Live Camera Test Banner Plate
                    NeuBox(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LiveCameraTestScreen()),
                        );
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      borderRadius: BorderRadius.circular(20),
                      glowColor: AppColors.activeBlue.withAlpha(50),
                      glowRadius: 10,
                      child: Row(
                        children: [
                          NeuBox(
                            isPressed: true,
                            shape: BoxShape.circle,
                            padding: const EdgeInsets.all(10),
                            glowColor: AppColors.activeBlue.withAlpha(40),
                            glowRadius: 6,
                            child: const Icon(
                              Icons.videocam_outlined,
                              color: AppColors.activeBlue,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Uji Kamera Real-Time',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    StatusBadge(label: 'LIVE SCAN', type: BadgeType.active),
                                  ],
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Uji akurasi pencocokan wajah & liveness langsung dari kamera HP.',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Section: Wajah Terdaftar + Add Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Wajah Terdaftar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              '${_faces.length} orang memiliki izin akses',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        NeuBox(
                          onTap: _showRegisterFaceDialog,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          borderRadius: BorderRadius.circular(14),
                          glowColor: AppColors.primary.withAlpha(40),
                          glowRadius: 6,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_add_outlined, size: 16, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text(
                                'Daftar Wajah',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Registered Faces List (NeuBox cards)
                    if (_faces.isEmpty)
                      NeuBox(
                        isPressed: true,
                        padding: const EdgeInsets.all(24),
                        borderRadius: BorderRadius.circular(18),
                        child: const Center(
                          child: Text(
                            'Belum ada wajah terdaftar. Tekan "Daftar Wajah" untuk menambahkan.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _faces.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final f = _faces[i];
                          return NeuBox(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            borderRadius: BorderRadius.circular(18),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: NeuBox(
                                isPressed: true,
                                shape: BoxShape.circle,
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  f.name.isNotEmpty ? f.name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              title: Text(
                                f.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Text(
                                '${f.role} • Terdaftar ${AppFormatters.relativeTime(f.registeredAt)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary, size: 20),
                                onPressed: () => _confirmDeleteFace(f),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 24),

                    // Section: Riwayat Akses Pintu
                    const Text(
                      'Riwayat Akses Pintu Masuk',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _attempts.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, idx) {
                        final att = _attempts[idx];
                        final isAttack = att.isSpoofAttack;

                        return NeuBox(
                          padding: const EdgeInsets.all(14),
                          borderRadius: BorderRadius.circular(18),
                          glowColor: isAttack ? AppColors.danger.withAlpha(40) : null,
                          glowRadius: isAttack ? 10 : 0,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              NeuBox(
                                isPressed: true,
                                shape: BoxShape.circle,
                                padding: const EdgeInsets.all(8),
                                glowColor: (isAttack ? AppColors.danger : AppColors.normal).withAlpha(40),
                                glowRadius: 4,
                                child: Icon(
                                  isAttack ? Icons.block : Icons.check_circle_outline,
                                  color: isAttack ? AppColors.danger : AppColors.normal,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          att.matchedName ?? 'Orang Tidak Dikenal',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isAttack ? AppColors.danger : AppColors.textPrimary,
                                          ),
                                        ),
                                        StatusBadge(
                                          label: isAttack ? 'DITOLAK' : 'DIIZINKAN',
                                          type: isAttack ? BadgeType.danger : BadgeType.normal,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isAttack
                                          ? 'Upaya akses dengan foto/layar HP digagalkan.'
                                          : 'Wajah asli terverifikasi. Pintu terbuka.',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      AppFormatters.formatTimestamp(att.timestamp),
                                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}

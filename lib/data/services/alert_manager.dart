import 'dart:async';
import 'package:flutter/material.dart';

enum AlertPriority { danger, warning, info }

class DynamicAlert {
  final String id;
  final String title;
  final String message;
  final IconData icon;
  final AlertPriority priority;
  final VoidCallback? onTap;

  const DynamicAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.icon,
    this.priority = AlertPriority.warning,
    this.onTap,
  });
}

class AlertManager {
  static final ValueNotifier<DynamicAlert?> currentAlert = ValueNotifier<DynamicAlert?>(null);
  static final Set<String> dismissedAlertIds = {};
  static Timer? _autoCloseTimer;

  static void show(DynamicAlert alert, {Duration autoCloseDuration = const Duration(milliseconds: 4500)}) {
    // Jangan tampilkan jika sudah ditutup/di-dismiss sebelumnya
    if (dismissedAlertIds.contains(alert.id)) {
      return;
    }

    // Hindari update jika isi alert sama persis dan sedang aktif
    if (currentAlert.value?.id == alert.id &&
        currentAlert.value?.message == alert.message) {
      return;
    }

    _autoCloseTimer?.cancel();
    currentAlert.value = alert;

    // Otomatis tutup setelah beberapa detik agar tidak membebani layar
    _autoCloseTimer = Timer(autoCloseDuration, () {
      clear(markDismissed: false);
    });
  }

  static void clear({bool markDismissed = true}) {
    _autoCloseTimer?.cancel();
    if (currentAlert.value != null) {
      if (markDismissed) {
        dismissedAlertIds.add(currentAlert.value!.id);
      }
      currentAlert.value = null;
    }
  }

  static void dismiss(String id) {
    dismissedAlertIds.add(id);
    if (currentAlert.value?.id == id) {
      clear(markDismissed: true);
    }
  }

  static bool isDismissed(String id) {
    return dismissedAlertIds.contains(id);
  }

  static void resetDismissed(String id) {
    dismissedAlertIds.remove(id);
  }

  static void clearAllDismissed() {
    dismissedAlertIds.clear();
  }
}

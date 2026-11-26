import 'dart:async';
import 'package:flutter/material.dart';

enum AlertPriority { danger, warning, info }

class DynamicAlert {
  final String id;
  final String title;
  final String message;
  final IconData icon;
  final AlertPriority priority;
  final String? imageUrl;
  final VoidCallback? onTap;

  const DynamicAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.icon,
    this.priority = AlertPriority.warning,
    this.imageUrl,
    this.onTap,
  });
}

class AlertManager {
  static final ValueNotifier<DynamicAlert?> currentAlert =
      ValueNotifier<DynamicAlert?>(null);
  static final ValueNotifier<List<DynamicAlert>> activeAlerts =
      ValueNotifier<List<DynamicAlert>>([]);
  static final Set<String> dismissedAlertIds = {};
  static final Map<String, Timer> _autoCloseTimers = {};

  static void show(
    DynamicAlert alert, {
    Duration autoCloseDuration = const Duration(milliseconds: 5000),
  }) {
    if (dismissedAlertIds.contains(alert.id)) {
      return;
    }

    final currentList = List<DynamicAlert>.from(activeAlerts.value);
    final existingIdx = currentList.indexWhere((a) => a.id == alert.id);
    if (existingIdx >= 0) {
      if (currentList[existingIdx].message == alert.message &&
          currentList[existingIdx].title == alert.title &&
          currentList[existingIdx].imageUrl == alert.imageUrl) {
        return;
      }
      currentList[existingIdx] = alert;
    } else {
      if (currentList.length >= 4) {
        final dropped = currentList.removeAt(0);
        _autoCloseTimers.remove(dropped.id)?.cancel();
      }
      currentList.add(alert);
    }

    _autoCloseTimers.remove(alert.id)?.cancel();
    _autoCloseTimers[alert.id] = Timer(autoCloseDuration, () {
      dismiss(alert.id, markDismissed: false);
    });

    activeAlerts.value = currentList;
    currentAlert.value = currentList.isNotEmpty ? currentList.first : null;
  }

  static void clear({bool markDismissed = true}) {
    for (final t in _autoCloseTimers.values) {
      t.cancel();
    }
    _autoCloseTimers.clear();
    if (activeAlerts.value.isNotEmpty) {
      if (markDismissed) {
        for (final a in activeAlerts.value) {
          dismissedAlertIds.add(a.id);
        }
      }
      activeAlerts.value = [];
      currentAlert.value = null;
    }
  }

  static void dismiss(String id, {bool markDismissed = true}) {
    _autoCloseTimers.remove(id)?.cancel();
    if (markDismissed) {
      dismissedAlertIds.add(id);
    }
    final currentList = List<DynamicAlert>.from(activeAlerts.value)
      ..removeWhere((a) => a.id == id);
    activeAlerts.value = currentList;
    currentAlert.value = currentList.isNotEmpty ? currentList.first : null;
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

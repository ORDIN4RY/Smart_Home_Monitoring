import 'package:flutter/material.dart';

/// Gate widget yang menunda inisialisasi dan rendering [child] sampai [shouldLoad] bernilai true.
/// Begitu gerbang terbuka (tab dikunjungi untuk pertama kali), child akan terus dijaga tetap hidup
/// di memori menggunakan [AutomaticKeepAliveClientMixin] sehingga background polling, state real-time,
/// dan posisi scroll tidak pernah hilang atau di-dispose saat berpindah tab.
class LazyKeepAliveGate extends StatefulWidget {
  final bool shouldLoad;
  final Widget child;

  const LazyKeepAliveGate({
    super.key,
    required this.shouldLoad,
    required this.child,
  });

  @override
  State<LazyKeepAliveGate> createState() => _LazyKeepAliveGateState();
}

class _LazyKeepAliveGateState extends State<LazyKeepAliveGate>
    with AutomaticKeepAliveClientMixin {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.shouldLoad) {
      _isInitialized = true;
    }
  }

  @override
  void didUpdateWidget(covariant LazyKeepAliveGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldLoad && !_isInitialized) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  bool get wantKeepAlive => _isInitialized;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_isInitialized) {
      return const SizedBox.shrink();
    }
    return widget.child;
  }
}

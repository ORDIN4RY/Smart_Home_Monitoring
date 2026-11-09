import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/event_log.dart';
import '../../../data/models/sensor_reading.dart';
import '../../../data/services/home_service.dart';
import '../../widgets/neu_box.dart';
import '../../widgets/status_badge.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<EventLog> _events = [];
  List<SensorReading> _sensorHistory = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistoryData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistoryData() async {
    setState(() => _isLoading = true);
    final events = await HomeService.fetchEventLogs();
    final history = await HomeService.fetchSensorHistory();
    if (mounted) {
      setState(() {
        _events = events;
        _sensorHistory = history;
        _isLoading = false;
      });
    }
  }

  List<EventLog> get _filteredEvents {
    if (_selectedCategory == 'all') return _events;
    if (_selectedCategory == 'security') {
      return _events.where((e) => e.category == 'gas' || e.category == 'flame').toList();
    }
    if (_selectedCategory == 'door') {
      return _events.where((e) => e.category == 'door' || e.category == 'motion').toList();
    }
    return _events;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histori & Aktivitas'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: NeuBox(
              isPressed: true,
              padding: const EdgeInsets.all(4),
              borderRadius: BorderRadius.circular(16),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.neuBase,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppColors.neuElevation(distance: 2, blur: 5),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: 'Event Keamanan'),
                  Tab(text: 'Log Sensor'),
                ],
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistoryData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildEventList(),
                _buildSensorHistoryList(),
              ],
            ),
    );
  }

  Widget _buildEventList() {
    return Column(
      children: [
        // Category Filter Chips (Tactile NeuBox Chips)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              _neuFilterChip('Semua Event', 'all'),
              const SizedBox(width: 10),
              _neuFilterChip('Gas & Api (Bahaya)', 'security'),
              const SizedBox(width: 10),
              _neuFilterChip('Akses Pintu & PIR', 'door'),
            ],
          ),
        ),
        Expanded(
          child: _filteredEvents.isEmpty
              ? const Center(
                  child: Text(
                    'Tidak ada event pada kategori ini',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  itemCount: _filteredEvents.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final evt = _filteredEvents[index];
                    return _buildEventTile(evt);
                  },
                ),
        ),
      ],
    );
  }

  Widget _neuFilterChip(String label, String value) {
    final isSelected = _selectedCategory == value;

    return NeuBox(
      onTap: () => setState(() => _selectedCategory = value),
      isPressed: isSelected,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      borderRadius: BorderRadius.circular(14),
      glowColor: isSelected ? AppColors.primary.withAlpha(50) : null,
      glowRadius: isSelected ? 8 : 0,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildEventTile(EventLog evt) {
    IconData icon;
    Color iconColor;

    switch (evt.category) {
      case 'gas':
        icon = Icons.gas_meter_outlined;
        iconColor = AppColors.danger;
        break;
      case 'flame':
        icon = Icons.local_fire_department_outlined;
        iconColor = AppColors.danger;
        break;
      case 'door':
        icon = Icons.door_sliding_outlined;
        iconColor = AppColors.primary;
        break;
      case 'motion':
        icon = Icons.motion_photos_on_outlined;
        iconColor = AppColors.warning;
        break;
      default:
        icon = Icons.info_outline;
        iconColor = AppColors.textSecondary;
    }

    BadgeType badgeType = BadgeType.normal;
    if (evt.severity == EventSeverity.danger) {
      badgeType = BadgeType.danger;
    } else if (evt.severity == EventSeverity.warning) {
      badgeType = BadgeType.warning;
    }

    return NeuBox(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(18),
      glowColor: evt.severity == EventSeverity.danger ? AppColors.danger.withAlpha(30) : null,
      glowRadius: evt.severity == EventSeverity.danger ? 8 : 0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeuBox(
            isPressed: true,
            shape: BoxShape.circle,
            padding: const EdgeInsets.all(10),
            glowColor: iconColor.withAlpha(40),
            glowRadius: 6,
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        evt.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    StatusBadge(
                      label: evt.severity.name.toUpperCase(),
                      type: badgeType,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  evt.description,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  AppFormatters.formatTimestamp(evt.timestamp),
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorHistoryList() {
    if (_sensorHistory.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada histori data sensor',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      itemCount: _sensorHistory.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _sensorHistory[index];
        return NeuBox(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          borderRadius: BorderRadius.circular(18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppFormatters.formatTimeOnly(item.timestamp),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    AppFormatters.relativeTime(item.timestamp),
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
              Row(
                children: [
                  _metricCol('Suhu', '${item.temperature.toStringAsFixed(1)}°C'),
                  const SizedBox(width: 16),
                  _metricCol('Lembap', '${item.humidity.toStringAsFixed(0)}%'),
                  const SizedBox(width: 16),
                  _metricCol('Gas', '${item.gasPpm.toStringAsFixed(0)} PPM'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _metricCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}

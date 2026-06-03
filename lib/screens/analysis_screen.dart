import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import '../services/sensor_service.dart';
import '../services/refresh_notifier.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  int _selected = 0;
  SensorReading? _latest;
  List<SensorAvg> _chartData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    refreshNotifier.addListener(_onGlobalRefresh);
  }

  void _onGlobalRefresh() => _loadData();

  @override
  void dispose() {
    refreshNotifier.removeListener(_onGlobalRefresh);
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final latest = await SensorService.getLatest();
    final chart = await _fetchChartData();
    setState(() {
      _latest = latest;
      _chartData = chart;
      _isLoading = false;
    });
  }

  Future<List<SensorAvg>> _fetchChartData() async {
    if (_selected == 0) return SensorService.getHourlyToday();
    if (_selected == 1) return SensorService.getDailyThisWeek();
    return SensorService.getDailyThisMonth();
  }

  Future<void> _onTabChanged(int i) async {
    setState(() {
      _selected = i;
      _isLoading = true;
    });
    final chart = await _fetchChartData();
    setState(() {
      _chartData = chart;
      _isLoading = false;
    });
  }

  Map<String, double> _calcDistribution() {
    if (_latest == null) return {'Normal': 60, 'Warning': 30, 'Danger': 10};
    final sensors = {
      'nh3': _latest!.nh3, 'h2s': _latest!.h2s, 'ch4': _latest!.ch4,
      'co2': _latest!.co2, 'voc': _latest!.voc, 'c2h5oh': _latest!.c2h5oh,
      'co': _latest!.co, 'acetone': _latest!.acetone, 'h2': _latest!.h2,
    };
    int normal = 0, warning = 0, danger = 0;
    for (final e in sensors.entries) {
      final s = SensorService.getStatus(e.key, e.value);
      if (s == 'Danger') danger++;
      else if (s == 'Warning') warning++;
      else normal++;
    }
    final total = sensors.length.toDouble();
    return {
      'Normal': normal / total * 100,
      'Warning': warning / total * 100,
      'Danger': danger / total * 100,
    };
  }

  List<double> _calcRadarValues() {
    if (_latest == null) return [0.7, 0.6, 0.65, 0.55, 0.5, 0.6, 0.4, 0.45, 0.5];
    double norm(String key, double? val) {
      if (val == null) return 0.0;
      final thresholds = {
        'nh3': 25.0, 'h2s': 10.0, 'ch4': 100.0,
        'co2': 5000.0, 'voc': 1.0, 'c2h5oh': 50.0,
        'co': 50.0, 'acetone': 500.0, 'h2': 100.0,
      };
      final max = thresholds[key] ?? 100.0;
      return (val / max).clamp(0.0, 1.0);
    }
    return [
      norm('nh3', _latest!.nh3),
      norm('h2s', _latest!.h2s),
      norm('ch4', _latest!.ch4),
      norm('c2h5oh', _latest!.c2h5oh),
      norm('voc', _latest!.voc),
      norm('co2', _latest!.co2),
      norm('co', _latest!.co),
      norm('acetone', _latest!.acetone),
      norm('h2', _latest!.h2),
    ];
  }

  List<double> _calcHeatmapValues() {
    if (_chartData.isEmpty) {
      return List.generate(72, (i) => (i % 5) / 4.0);
    }
    final vals = _chartData.map((e) => e.nh3 ?? 0.0).toList();
    final maxVal = vals.reduce(math.max);
    if (maxVal == 0) return List.filled(vals.length, 0.0);
    final result = vals.map((v) => v / maxVal).toList();
    while (result.length < 72) result.add(0.0);
    return result.take(72).toList();
  }

  List<FlSpot> _calcTrendSpots() {
    if (_chartData.isEmpty) {
      if (_selected == 0) {
        return const [
          FlSpot(0, 15), FlSpot(4, 35), FlSpot(8, 25),
          FlSpot(12, 60), FlSpot(16, 45), FlSpot(20, 65),
        ];
      } else if (_selected == 1) {
        return const [
          FlSpot(1, 100), FlSpot(2, 140), FlSpot(3, 130),
          FlSpot(4, 80), FlSpot(5, 60), FlSpot(6, 90),
        ];
      } else {
        return const [
          FlSpot(1, 160), FlSpot(2, 270), FlSpot(3, 200), FlSpot(4, 230),
        ];
      }
    }
    return _chartData.asMap().entries.map((e) {
      final idx = e.key;
      final avg = e.value;
      final y = avg.nh3 ?? avg.h2s ?? avg.ch4 ?? avg.co2 ?? 0.0;
      double x;
      if (_selected == 0) {
        x = avg.time.hour.toDouble();
      } else {
        x = (idx + 1).toDouble();
      }
      return FlSpot(x, y);
    }).toList();
  }

  List<String> _trendLabels() {
    if (_selected == 0) return ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00'];
    if (_selected == 1) {
      if (_chartData.isNotEmpty) {
        return _chartData.map((e) {
          const days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
          return days[e.time.weekday % 7];
        }).toList();
      }
      return ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    }
    if (_chartData.isNotEmpty) {
      return _chartData.map((e) => 'M${_chartData.indexOf(e) + 1}').toList();
    }
    return ['M1', 'M2', 'M3', 'M4'];
  }

  double _systemUptime() {
    if (_latest == null) return 0;
    final sensors = [
      _latest!.nh3, _latest!.h2s, _latest!.ch4, _latest!.co2,
      _latest!.voc, _latest!.c2h5oh, _latest!.co, _latest!.acetone, _latest!.h2,
    ];
    final online = sensors.where((v) => v != null).length;
    return online / sensors.length * 100;
  }

  String _buildSummary() {
    if (_latest == null) {
      return 'Belum ada data sensor yang masuk. Pastikan perangkat terhubung dan mengirim data ke broker MQTT.';
    }
    final highSensors = <String>[];
    final warnSensors = <String>[];
    void check(String name, String key, double? val) {
      final s = SensorService.getStatus(key, val);
      if (s == 'Danger') highSensors.add('$name (${val?.toStringAsFixed(1)})');
      if (s == 'Warning') warnSensors.add('$name (${val?.toStringAsFixed(1)})');
    }
    check('NH3', 'nh3', _latest!.nh3);
    check('H2S', 'h2s', _latest!.h2s);
    check('CH4', 'ch4', _latest!.ch4);
    check('CO2', 'co2', _latest!.co2);
    check('VOC', 'voc', _latest!.voc);
    check('C2H5OH', 'c2h5oh', _latest!.c2h5oh);
    check('CO', 'co', _latest!.co);
    check('Acetone', 'acetone', _latest!.acetone);
    check('H2', 'h2', _latest!.h2);
    final buf = StringBuffer();
    if (highSensors.isEmpty && warnSensors.isEmpty) {
      buf.write('Semua sensor dalam kondisi Normal. Tidak ada gas berbahaya yang terdeteksi saat ini.');
    } else {
      if (highSensors.isNotEmpty) buf.write('⚠️ BAHAYA: ${highSensors.join(', ')}. ');
      if (warnSensors.isNotEmpty) buf.write('⚡ WARNING: ${warnSensors.join(', ')}. ');
      buf.write('Segera periksa kondisi makanan dan ventilasi ruangan.');
    }
    return buf.toString();
  }

  String _fmt(double? v, {int decimals = 2}) =>
      v != null ? v.toStringAsFixed(decimals) : '-';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final distribution = _calcDistribution();
    final radarValues = _calcRadarValues();
    final heatmapValues = _calcHeatmapValues();
    final trendSpots = _calcTrendSpots();
    final trendLabels = _trendLabels();
    final uptime = _systemUptime();

    return Scaffold(
      backgroundColor: cs.surface,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          // ─── App Bar (sama pola dengan Home, Tray, Profile) ──────────
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: cs.primaryContainer,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analitik Sensor',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    'Deep Analytics Berbasis Data',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1565C0), Color(0xFF64B5F6)],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: _loadData,
                icon: Icon(Icons.refresh_rounded, color: cs.onPrimary),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ],
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: cs.primary))
            : CustomScrollView(
          slivers: [
            // ─── Tab Filter ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip(context, 0, 'Hari Ini'),
                      const SizedBox(width: 8),
                      _filterChip(context, 1, 'Minggu'),
                      const SizedBox(width: 8),
                      _filterChip(context, 2, 'Bulan'),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ─── Status Sistem Card ──────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 0,
                  color: cs.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Icon(Icons.monitor_heart_outlined,
                          color: cs.primary, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Status Sistem',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: cs.onSurface)),
                              const SizedBox(height: 2),
                              Text(
                                  '${_latest == null ? 0 : 9} sensor online',
                                  style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 12)),
                            ]),
                      ),
                      Text(
                        '${uptime.toStringAsFixed(0)}%',
                        style: TextStyle(
                            color: cs.primary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800),
                      ),
                    ]),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ─── Heatmap Card ─────────────────────────────────────
            SliverToBoxAdapter(
              child: _AnalyticsCard(
                title: _selected == 0
                    ? 'Heatmap Aktivitas Gas (24 Jam)'
                    : _selected == 1
                    ? 'Heatmap Aktivitas Gas (7 Hari)'
                    : 'Heatmap Aktivitas Gas (30 Hari)',
                icon: Icons.grid_view_rounded,
                cs: cs,
                height: 200,
                child: _HeatmapWidget(values: heatmapValues, cs: cs),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ─── Donut Card ───────────────────────────────────────
            SliverToBoxAdapter(
              child: _AnalyticsCard(
                title: 'Distribusi Status Sensor',
                icon: Icons.donut_large_rounded,
                cs: cs,
                height: 260,
                child: _DonutWidget(distribution: distribution, cs: cs),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ─── Radar Card ───────────────────────────────────────
            SliverToBoxAdapter(
              child: _AnalyticsCard(
                title: 'Radar Profil Gas',
                icon: Icons.radar_rounded,
                cs: cs,
                height: 240,
                child: _RadarWidget(values: radarValues, cs: cs),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ─── Trend Chart Card ─────────────────────────────────
            SliverToBoxAdapter(
              child: _AnalyticsCard(
                title: _selected == 0
                    ? 'Trend 24 Jam'
                    : _selected == 1
                    ? 'Trend 7 Hari'
                    : 'Trend 30 Hari',
                icon: Icons.show_chart_rounded,
                cs: cs,
                height: 240,
                child: _TrendChart(
                  mode: _selected,
                  spots: trendSpots,
                  labels: trendLabels,
                  cs: cs,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ─── All Sensors Card ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 0,
                  color: cs.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.sensors_rounded,
                                color: cs.primary),
                            const SizedBox(width: 8),
                            Text('Semua Sensor',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: cs.onSurface)),
                          ]),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics:
                            const NeverScrollableScrollPhysics(),
                            gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1.4,
                            ),
                            itemCount: 9,
                            itemBuilder: (_, i) {
                              final entries = [
                                ('NH3', 'nh3', _latest?.nh3, 'MQ-137', 'ppm'),
                                ('H2S', 'h2s', _latest?.h2s, 'MQ-136', 'ppm'),
                                ('CH4', 'ch4', _latest?.ch4, 'MQ-4', 'ppm'),
                                ('CO2', 'co2', _latest?.co2, 'MQ-135', 'ppm'),
                                ('VOC', 'voc', _latest?.voc, 'MQ-135', 'mg/m³'),
                                ('C2H5OH', 'c2h5oh', _latest?.c2h5oh, 'MQ-3', 'ppm'),
                                ('CO', 'co', _latest?.co, 'MQ-7', 'ppm'),
                                ('Acetone', 'acetone', _latest?.acetone, 'MQ-138', 'ppm'),
                                ('H2', 'h2', _latest?.h2, 'MQ-8', 'ppm'),
                              ];
                              final (title, key, val, sensor, unit) =
                              entries[i];
                              final status = SensorService.getStatus(key, val);
                              final isDanger = status == 'Danger';
                              final isWarning = status == 'Warning';
                              final tileColor = isDanger
                                  ? cs.errorContainer
                                  : isWarning
                                  ? const Color(0xFFFFF8E1)
                                  : cs.surfaceContainerHighest;
                              final dotColor = isDanger
                                  ? cs.error
                                  : isWarning
                                  ? Colors.orange
                                  : cs.primary;
                              return Card(
                                elevation: 0,
                                color: tileColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(14)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Text(title,
                                              style: TextStyle(
                                                  fontWeight:
                                                  FontWeight.w600,
                                                  color: cs.onSurface,
                                                  fontSize: 13)),
                                          const Spacer(),
                                          Icon(Icons.circle,
                                              size: 8,
                                              color: dotColor),
                                        ]),
                                        const SizedBox(height: 6),
                                        Row(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                  _fmt(val,
                                                      decimals: 1),
                                                  style: TextStyle(
                                                      fontWeight:
                                                      FontWeight
                                                          .w800,
                                                      fontSize: 20,
                                                      color:
                                                      cs.onSurface)),
                                              const SizedBox(width: 3),
                                              Padding(
                                                padding:
                                                const EdgeInsets.only(
                                                    bottom: 2),
                                                child: Text(unit,
                                                    style: TextStyle(
                                                        fontSize: 10,
                                                        color: cs
                                                            .onSurfaceVariant)),
                                              ),
                                            ]),
                                        Text('$sensor • $status',
                                            style: TextStyle(
                                                color:
                                                cs.onSurfaceVariant,
                                                fontSize: 11)),
                                      ]),
                                ),
                              );
                            },
                          ),
                        ]),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ─── AI Summary Card ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 0,
                  color: cs.secondaryContainer,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.smart_toy_outlined,
                                color: cs.onSecondaryContainer),
                            const SizedBox(width: 8),
                            Text('Summary',
                                style: TextStyle(
                                    color: cs.onSecondaryContainer,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                          ]),
                          const SizedBox(height: 10),
                          Text(
                            _buildSummary(),
                            style: TextStyle(
                                color: cs.onSecondaryContainer,
                                height: 1.5),
                          ),
                          const SizedBox(height: 14),
                          GridView.count(
                            shrinkWrap: true,
                            physics:
                            const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            childAspectRatio: 2.2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            children: [
                              _SummaryStatTile(
                                  value: _latest == null ? '0' : '9',
                                  label: 'Sensor Online',
                                  cs: cs),
                              _SummaryStatTile(
                                  value:
                                  '${(distribution['Danger'] ?? 0).toStringAsFixed(0)}%',
                                  label: 'Bahaya',
                                  cs: cs),
                              _SummaryStatTile(
                                  value:
                                  '${(distribution['Warning'] ?? 0).toStringAsFixed(0)}%',
                                  label: 'Warning',
                                  cs: cs),
                              _SummaryStatTile(
                                  value:
                                  '${(distribution['Normal'] ?? 0).toStringAsFixed(0)}%',
                                  label: 'Normal',
                                  cs: cs),
                            ],
                          ),
                        ]),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(BuildContext context, int index, String label) {
    final cs = Theme.of(context).colorScheme;
    final selected = _selected == index;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _onTabChanged(index),
      selectedColor: cs.primaryContainer,
      checkmarkColor: cs.primary,
      labelStyle: TextStyle(
        color: selected ? cs.primary : cs.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
      ),
    );
  }
}

// ─── Analytics Card (M3 style) ────────────────────────────────────────────────

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
    required this.title,
    required this.icon,
    required this.cs,
    required this.child,
    this.height = 200,
  });
  final String title;
  final IconData icon;
  final ColorScheme cs;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: cs.onSurface,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            SizedBox(height: height, child: child),
          ]),
        ),
      ),
    );
  }
}

// ─── Summary Stat Tile ────────────────────────────────────────────────────────

class _SummaryStatTile extends StatelessWidget {
  const _SummaryStatTile(
      {required this.value, required this.label, required this.cs});
  final String value, label;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.secondary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: TextStyle(
                color: cs.onSecondaryContainer,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        const SizedBox(height: 2),
        Text(label,
            style:
            TextStyle(color: cs.onSecondaryContainer.withOpacity(0.7), fontSize: 12)),
      ]),
    );
  }
}

// ─── Heatmap ──────────────────────────────────────────────────────────────────

class _HeatmapWidget extends StatelessWidget {
  const _HeatmapWidget({required this.values, required this.cs});
  final List<double> values;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 12, mainAxisSpacing: 4, crossAxisSpacing: 4),
      itemCount: values.length,
      itemBuilder: (_, i) {
        final v = values[i].clamp(0.0, 1.0);
        final color = Color.lerp(
          cs.primaryContainer,
          cs.primary,
          v,
        )!;
        return Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }
}

// ─── Donut ────────────────────────────────────────────────────────────────────

class _DonutWidget extends StatelessWidget {
  const _DonutWidget({required this.distribution, required this.cs});
  final Map<String, double> distribution;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: CustomPaint(
            painter: _DonutPainter(
              normal: distribution['Normal'] ?? 60,
              warning: distribution['Warning'] ?? 30,
              danger: distribution['Danger'] ?? 10,
              normalColor: cs.tertiary,
              warningColor: Colors.orange,
              dangerColor: cs.error,
              bgColor: cs.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            _Legend(
                color: cs.tertiary,
                label: 'Aman (${(distribution['Normal'] ?? 0).toStringAsFixed(0)}%)',
                cs: cs),
            _Legend(
                color: Colors.orange,
                label: 'Warning (${(distribution['Warning'] ?? 0).toStringAsFixed(0)}%)',
                cs: cs),
            _Legend(
                color: cs.error,
                label: 'Bahaya (${(distribution['Danger'] ?? 0).toStringAsFixed(0)}%)',
                cs: cs),
          ],
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.normal,
    required this.warning,
    required this.danger,
    required this.normalColor,
    required this.warningColor,
    required this.dangerColor,
    required this.bgColor,
  });
  final double normal, warning, danger;
  final Color normalColor, warningColor, dangerColor, bgColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 6;
    const stroke = 16.0;

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = bgColor;
    canvas.drawCircle(center, radius, bg);

    void drawArc(double start, double sweep, Color color) {
      if (sweep <= 0) return;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke
        ..color = color;
      canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius), start, sweep, false, p);
    }

    final total = normal + warning + danger;
    if (total == 0) return;

    final greenSweep  = normal  / total * math.pi * 2;
    final yellowSweep = warning / total * math.pi * 2;
    final redSweep    = danger  / total * math.pi * 2;

    double start = -math.pi / 2;
    drawArc(start, greenSweep, normalColor);
    start += greenSweep + 0.05;
    drawArc(start, yellowSweep, warningColor);
    start += yellowSweep + 0.05;
    drawArc(start, redSweep, dangerColor);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.normal != normal || old.warning != warning || old.danger != danger;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, required this.cs});
  final Color color;
  final String label;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(color: cs.onSurface, fontSize: 13)),
    ]);
  }
}

// ─── Radar ────────────────────────────────────────────────────────────────────

class _RadarWidget extends StatelessWidget {
  const _RadarWidget({required this.values, required this.cs});
  final List<double> values;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    const labels = ['NH3', 'H2S', 'CH4', 'C2H5OH', 'VOC', 'CO2', 'CO', 'Acetone', 'H2'];
    final safeValues =
    List<double>.generate(9, (i) => i < values.length ? values[i] : 0.0);

    return RadarChart(
      RadarChartData(
        radarShape: RadarShape.polygon,
        tickCount: 3,
        ticksTextStyle:
        TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
        gridBorderData:
        BorderSide(color: cs.outlineVariant),
        titlePositionPercentageOffset: 0.15,
        getTitle: (index, angle) =>
            RadarChartTitle(text: labels[index]),
        dataSets: [
          RadarDataSet(
            fillColor: cs.primary.withOpacity(0.2),
            borderColor: cs.primary,
            entryRadius: 2,
            borderWidth: 2,
            dataEntries:
            safeValues.map((v) => RadarEntry(value: v)).toList(),
          ),
        ],
      ),
      swapAnimationDuration: const Duration(milliseconds: 250),
    );
  }
}

// ─── Trend Chart ──────────────────────────────────────────────────────────────

class _TrendChart extends StatelessWidget {
  const _TrendChart({
    required this.mode,
    required this.spots,
    required this.labels,
    required this.cs,
  });
  final int mode;
  final List<FlSpot> spots;
  final List<String> labels;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) {
      return Center(
          child: Text('Belum ada data',
              style: TextStyle(color: cs.onSurfaceVariant)));
    }

    final xs = spots.map((s) => s.x).toList();
    final ys = spots.map((s) => s.y).toList();
    final minX = xs.reduce(math.min);
    final maxX = xs.reduce(math.max);
    final maxY = ys.reduce(math.max);
    final interval = mode == 0 ? 4.0 : 1.0;

    return LineChart(
      LineChartData(
        minY: 0,
        minX: minX,
        maxX: maxX,
        maxY: maxY * 1.2,
        gridData: FlGridData(
          show: true,
          horizontalInterval: maxY > 0 ? maxY / 4 : 25,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: cs.outlineVariant, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: Text(
              mode == 2 ? 'Total Insiden' : 'Konsentrasi (ppm)',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
            axisNameSize: 22,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(0),
                style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              getTitlesWidget: (value, meta) {
                final idx =
                xs.indexWhere((x) => (x - value).abs() < 0.5);
                if (idx == -1 || idx >= labels.length) {
                  return const SizedBox.shrink();
                }
                return Text(labels[idx],
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant));
              },
            ),
          ),
          topTitles:
          AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
          AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
                colors: [cs.primary, cs.tertiary]),
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                    radius: 3,
                    color: cs.primary,
                    strokeWidth: 0,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  cs.primary.withOpacity(0.15),
                  cs.primary.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
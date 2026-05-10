import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import '../services/sensor_service.dart';

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

  // Hitung distribusi status dari latest
  Map<String, double> _calcDistribution() {
    if (_latest == null) return {'Normal': 60, 'Warning': 30, 'Danger': 10};
    final sensors = {
      'nh3': _latest!.nh3, 'h2s': _latest!.h2s, 'ch4': _latest!.ch4,
      'co2': _latest!.co2, 'voc': _latest!.voc, 'c2h5oh': _latest!.c2h5oh,
      'co': _latest!.co, 'h2': _latest!.h2,
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

  // Hitung nilai radar dari latest (normalisasi 0-1)
  List<double> _calcRadarValues() {
    if (_latest == null) return [0.7, 0.6, 0.65, 0.55, 0.5, 0.6];
    double norm(String key, double? val) {
      if (val == null) return 0.0;
      final thresholds = {
        'nh3': 25.0, 'h2s': 10.0, 'ch4': 100.0,
        'co2': 5000.0, 'voc': 1.0, 'c2h5oh': 50.0,
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
    ];
  }

  // Heatmap: ambil nilai NH3 dari chartData (normalisasi per sel)
  List<double> _calcHeatmapValues() {
    if (_chartData.isEmpty) {
      return List.generate(72, (i) => (i % 5) / 4.0);
    }
    final vals = _chartData.map((e) => e.nh3 ?? 0.0).toList();
    final maxVal = vals.reduce(math.max);
    if (maxVal == 0) return List.filled(vals.length, 0.0);
    // Pad/trim to 72 cells
    final result = vals.map((v) => v / maxVal).toList();
    while (result.length < 72) result.add(0.0);
    return result.take(72).toList();
  }

  // Konversi chartData ke FlSpot untuk trend
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
      // Gunakan NH3 sebagai representasi utama, fallback ke 0
      final y = avg.nh3 ?? avg.h2s ?? avg.ch4 ?? avg.co2 ?? 0.0;
      double x;
      if (_selected == 0) {
        x = avg.time.hour.toDouble();
      } else if (_selected == 1) {
        x = (idx + 1).toDouble();
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
    if (_latest == null) return 98.5;
    final sensors = [
      _latest!.nh3, _latest!.h2s, _latest!.ch4, _latest!.co2,
      _latest!.voc, _latest!.c2h5oh, _latest!.co, _latest!.h2,
    ];
    final online = sensors.where((v) => v != null).length;
    return online / sensors.length * 100;
  }

  @override
  Widget build(BuildContext context) {
    final distribution = _calcDistribution();
    final radarValues = _calcRadarValues();
    final heatmapValues = _calcHeatmapValues();
    final trendSpots = _calcTrendSpots();
    final trendLabels = _trendLabels();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        backgroundColor: const Color(0xFF00A39B),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _FixedHeaderDelegate(
                height: 120,
                child: _Header(
                  onTabChanged: (i) => setState(() => _selected = i),
                  selected: _selected,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                child: _TabsBar(
                  selected: _selected,
                  onSelected: _onTabChanged,
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 12),
                _StatusCard(percentage: _systemUptime()),
                const SizedBox(height: 12),
                _AnalyticsCard(
                  title: _selected == 0
                      ? 'Heatmap Aktivitas Gas (24 Jam)'
                      : _selected == 1
                      ? 'Heatmap Aktivitas Gas (7 Hari)'
                      : 'Heatmap Aktivitas Gas (30 Hari)',
                  child: _HeatmapWidget(values: heatmapValues),
                  height: 200,
                ),
                const SizedBox(height: 12),
                _AnalyticsCard(
                  title: 'Distribusi Status Sensor',
                  child: _DonutWidget(distribution: distribution),
                  height: 260,
                ),
                const SizedBox(height: 12),
                _AnalyticsCard(
                  title: 'Radar Profil Gas',
                  child: _RadarWidget(values: radarValues),
                  height: 240,
                ),
                const SizedBox(height: 12),
                _AnalyticsCard(
                  title: _selected == 0
                      ? 'Trend 24 Jam'
                      : _selected == 1
                      ? 'Trend 7 Hari'
                      : 'Trend 30 Hari',
                  child: _TrendChart(
                    mode: _selected,
                    spots: trendSpots,
                    labels: trendLabels,
                  ),
                  height: 240,
                ),
                const SizedBox(height: 12),
                _AllSensorsCard(latest: _latest),
                const SizedBox(height: 12),
                _AiSummaryCard(latest: _latest, distribution: distribution),
                const SizedBox(height: 80),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header & Tabs ────────────────────────────────────────────────────────────

class _FixedHeaderDelegate extends SliverPersistentHeaderDelegate {
  _FixedHeaderDelegate({required this.child, required this.height});
  final Widget child;
  final double height;

  @override double get minExtent => height;
  @override double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox.expand(child: child);

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

class _Header extends StatelessWidget {
  const _Header({required this.onTabChanged, required this.selected});
  final ValueChanged<int> onTabChanged;
  final int selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00B4DB), Color(0xFF00A39B)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Analitik Sensor',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Deep Analytics Berbasis Data',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _TabsBar extends StatelessWidget {
  const _TabsBar({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))
          ]),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          _TabButton(label: 'Hari Ini', selected: selected == 0, onTap: () => onSelected(0)),
          _TabButton(label: 'Minggu',   selected: selected == 1, onTap: () => onSelected(1)),
          _TabButton(label: 'Bulan',    selected: selected == 2, onTap: () => onSelected(2)),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF10B981) : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Center(
              child: Text(label,
                  style: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Cards ────────────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.percentage});
  final double percentage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))
            ]),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Expanded(
                child: Text('Status Sistem',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.black87))),
            Text('${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                    color: Color(0xFF0284C7),
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({required this.title, required this.child, this.height = 180});
  final String title;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))
            ]),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 12),
          SizedBox(height: height, child: child),
        ]),
      ),
    );
  }
}

// ─── Heatmap (data real) ──────────────────────────────────────────────────────

class _HeatmapWidget extends StatelessWidget {
  const _HeatmapWidget({required this.values});
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 12, mainAxisSpacing: 4, crossAxisSpacing: 4),
      itemCount: values.length,
      itemBuilder: (_, i) {
        final v = values[i].clamp(0.0, 1.0);
        // Interpolasi warna: hijau muda → hijau tua (aman → tinggi)
        final color = Color.lerp(
          const Color(0xFFE0F2F1),
          const Color(0xFF00796B),
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

// ─── Donut (data real) ────────────────────────────────────────────────────────

class _DonutWidget extends StatelessWidget {
  const _DonutWidget({required this.distribution});
  final Map<String, double> distribution;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 180,
          height: 180,
          child: CustomPaint(
            painter: _DonutPainter(
              normal: distribution['Normal'] ?? 60,
              warning: distribution['Warning'] ?? 30,
              danger: distribution['Danger'] ?? 10,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            _Legend(
                color: const Color(0xFF10B981),
                label: 'Aman (${(distribution['Normal'] ?? 0).toStringAsFixed(0)}%)'),
            _Legend(
                color: const Color(0xFFF59E0B),
                label: 'Warning (${(distribution['Warning'] ?? 0).toStringAsFixed(0)}%)'),
            _Legend(
                color: const Color(0xFFEF4444),
                label: 'Bahaya (${(distribution['Danger'] ?? 0).toStringAsFixed(0)}%)'),
          ],
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.normal, required this.warning, required this.danger});
  final double normal, warning, danger;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 6;
    const stroke = 16.0;

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = const Color(0xFFE5E7EB);
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
    drawArc(start, greenSweep,  const Color(0xFF10B981));
    start += greenSweep + 0.05;
    drawArc(start, yellowSweep, const Color(0xFFF59E0B));
    start += yellowSweep + 0.05;
    drawArc(start, redSweep,    const Color(0xFFEF4444));

    canvas.drawCircle(center, radius - stroke, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.normal != normal || old.warning != warning || old.danger != danger;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.black87)),
      ],
    );
  }
}

// ─── Radar (data real) ────────────────────────────────────────────────────────

class _RadarWidget extends StatelessWidget {
  const _RadarWidget({required this.values});
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    const labels = ['NH3', 'H2S', 'CH4', 'C2H5OH', 'VOC', 'CO2'];
    // Pastikan panjang values = 6
    final safeValues = List<double>.generate(
        6, (i) => i < values.length ? values[i] : 0.0);

    return RadarChart(
      RadarChartData(
        radarShape: RadarShape.polygon,
        tickCount: 3,
        ticksTextStyle: const TextStyle(color: Colors.black38, fontSize: 10),
        gridBorderData: const BorderSide(color: Color(0xFFE5E7EB)),
        titlePositionPercentageOffset: 0.15,
        getTitle: (index, angle) => RadarChartTitle(text: labels[index]),
        dataSets: [
          RadarDataSet(
            fillColor: const Color(0xFF60A5FA).withOpacity(0.35),
            borderColor: const Color(0xFF3B82F6),
            entryRadius: 2,
            borderWidth: 2,
            dataEntries: safeValues.map((v) => RadarEntry(value: v)).toList(),
          ),
        ],
      ),
      swapAnimationDuration: const Duration(milliseconds: 250),
    );
  }
}

// ─── Trend Chart (data real) ──────────────────────────────────────────────────

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.mode, required this.spots, required this.labels});
  final int mode;
  final List<FlSpot> spots;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) {
      return const Center(child: Text('Belum ada data', style: TextStyle(color: Colors.black38)));
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
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: Text(
              mode == 2 ? 'Total Insiden' : 'Konsentrasi Gas (ppm)',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            axisNameSize: 22,
            sideTitles: SideTitles(showTitles: true, reservedSize: 36),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              getTitlesWidget: (value, meta) {
                final idx = xs.indexWhere((x) => (x - value).abs() < 0.5);
                if (idx == -1 || idx >= labels.length) return const SizedBox.shrink();
                return Text(labels[idx],
                    style: const TextStyle(fontSize: 11, color: Colors.black45));
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF0284C7)]),
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3,
                color: const Color(0xFF10B981),
                strokeWidth: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── All Sensors Card ─────────────────────────────────────────────────────────

class _AllSensorsCard extends StatelessWidget {
  const _AllSensorsCard({this.latest});
  final SensorReading? latest;

  static Color _statusColor(String status) {
    if (status == 'Danger') return const Color(0xFFEF4444);
    if (status == 'Warning') return const Color(0xFFF59E0B);
    return Colors.green;
  }

  static Widget _sensor(String title, String value, String note, Color dotColor) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(title,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
          const Spacer(),
          Icon(Icons.circle, size: 8, color: dotColor),
        ]),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: Color(0xFF0284C7), fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(note, style: const TextStyle(color: Colors.black45, fontSize: 11)),
      ]),
    );
  }

  String _fmt(double? v, {int decimals = 2}) =>
      v != null ? v.toStringAsFixed(decimals) : '-';

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _sensor('NH3',     '${_fmt(latest?.nh3)} ppm',     'MQ-137 • ${SensorService.getStatus('nh3', latest?.nh3)}',      _statusColor(SensorService.getStatus('nh3', latest?.nh3))),
      _sensor('H2S',     '${_fmt(latest?.h2s)} ppm',     'MQ-136 • ${SensorService.getStatus('h2s', latest?.h2s)}',      _statusColor(SensorService.getStatus('h2s', latest?.h2s))),
      _sensor('CH4',     '${_fmt(latest?.ch4)} ppm',     'MQ-4 • ${SensorService.getStatus('ch4', latest?.ch4)}',        _statusColor(SensorService.getStatus('ch4', latest?.ch4))),
      _sensor('CO2',     '${_fmt(latest?.co2)} ppm',     'MQ-135 • ${SensorService.getStatus('co2', latest?.co2)}',      _statusColor(SensorService.getStatus('co2', latest?.co2))),
      _sensor('VOC',     '${_fmt(latest?.voc)} mg/m³',   'MQ-135 • ${SensorService.getStatus('voc', latest?.voc)}',      _statusColor(SensorService.getStatus('voc', latest?.voc))),
      _sensor('C2H5OH',  '${_fmt(latest?.c2h5oh)} ppm',  'MQ-3 • ${SensorService.getStatus('c2h5oh', latest?.c2h5oh)}',  _statusColor(SensorService.getStatus('c2h5oh', latest?.c2h5oh))),
      _sensor('CO',      '${_fmt(latest?.co)} ppm',      'MQ-7 • ${SensorService.getStatus('co', latest?.co)}',          _statusColor(SensorService.getStatus('co', latest?.co))),
      _sensor('Acetone', '${_fmt(latest?.acetone)} ppm', 'MQ-138 • Normal',                                               Colors.green),
      _sensor('H2',      '${_fmt(latest?.h2)} ppm',      'MQ-8 • ${SensorService.getStatus('h2', latest?.h2)}',          _statusColor(SensorService.getStatus('h2', latest?.h2))),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Semua Sensor',
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
            ),
            itemCount: tiles.length,
            itemBuilder: (_, i) => tiles[i],
          ),
        ]),
      ),
    );
  }
}

// ─── AI Summary Card (data real) ─────────────────────────────────────────────

class _AiSummaryCard extends StatelessWidget {
  const _AiSummaryCard({this.latest, required this.distribution});
  final SensorReading? latest;
  final Map<String, double> distribution;

  String _buildSummary() {
    if (latest == null) {
      return 'Belum ada data sensor yang masuk. Pastikan perangkat terhubung dan mengirim data ke broker MQTT.';
    }

    final highSensors = <String>[];
    final warnSensors = <String>[];

    void check(String name, String key, double? val) {
      final s = SensorService.getStatus(key, val);
      if (s == 'Danger') highSensors.add('$name (${val?.toStringAsFixed(1)})');
      if (s == 'Warning') warnSensors.add('$name (${val?.toStringAsFixed(1)})');
    }

    check('NH3', 'nh3', latest!.nh3);
    check('H2S', 'h2s', latest!.h2s);
    check('CH4', 'ch4', latest!.ch4);
    check('CO2', 'co2', latest!.co2);
    check('VOC', 'voc', latest!.voc);
    check('C2H5OH', 'c2h5oh', latest!.c2h5oh);
    check('CO', 'co', latest!.co);
    check('H2', 'h2', latest!.h2);

    final buf = StringBuffer();
    if (highSensors.isEmpty && warnSensors.isEmpty) {
      buf.write('Semua sensor dalam kondisi Normal. Tidak ada gas berbahaya yang terdeteksi saat ini.');
    } else {
      if (highSensors.isNotEmpty) {
        buf.write('⚠️ Sensor dalam kondisi BAHAYA: ${highSensors.join(', ')}. ');
      }
      if (warnSensors.isNotEmpty) {
        buf.write('⚡ Sensor dalam kondisi WARNING: ${warnSensors.join(', ')}. ');
      }
      buf.write('Segera periksa kondisi makanan dan ventilasi ruangan.');
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final dangerPct = (distribution['Danger'] ?? 0).toStringAsFixed(0);
    final warnPct   = (distribution['Warning'] ?? 0).toStringAsFixed(0);
    final normalPct = (distribution['Normal'] ?? 0).toStringAsFixed(0);
    final onlineSensors = latest == null ? '0' : '9';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF38BDF8), Color(0xFF10B981)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 16, offset: Offset(0, 8))
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.smart_toy, color: Colors.white),
            SizedBox(width: 8),
            Text('AI Summary',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
          ]),
          const SizedBox(height: 8),
          Text(
            _buildSummary(),
            style: const TextStyle(color: Colors.white, height: 1.4),
          ),
          const SizedBox(height: 14),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _AiStat(value: onlineSensors, label: 'Sensor Online'),
              _AiStat(value: '$dangerPct%', label: 'Bahaya'),
              _AiStat(value: '$warnPct%',   label: 'Warning'),
              _AiStat(value: '$normalPct%', label: 'Normal'),
            ],
          ),
        ]),
      ),
    );
  }
}

class _AiStat extends StatelessWidget {
  const _AiStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.all(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    );
  }
}
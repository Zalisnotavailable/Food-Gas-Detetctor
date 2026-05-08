import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  int _selected = 0; // 0: Hari Ini, 1: Minggu, 2: Bulan

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _FixedHeaderDelegate(
              height: 120,
              child: _Header(onTabChanged: (i) => setState(() => _selected = i), selected: _selected),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              child: _TabsBar(
                selected: _selected,
                onSelected: (i) => setState(() => _selected = i),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 12),
              _StatusCard(percentage: _selected == 0 ? 98.5 : _selected == 1 ? 96.2 : 95.1),
              const SizedBox(height: 12),
              _AnalyticsCard(
                title: _selected == 0
                    ? 'Heatmap Aktivitas Gas (24 Jam)'
                    : _selected == 1
                        ? 'Heatmap Aktivitas Gas (7 Hari)'
                        : 'Heatmap Aktivitas Gas (30 Hari)',
                child: const _HeatmapPlaceholder(),
                height: 260,
              ),
              const SizedBox(height: 12),
              _AnalyticsCard(title: 'Distribusi Status Sensor', child: const _DonutPlaceholder(), height: 260),
              const SizedBox(height: 12),
              _AnalyticsCard(title: 'Radar Profil Gas', child: const _RadarPlaceholder(), height: 240),
              const SizedBox(height: 12),
              _AnalyticsCard(
                title: _selected == 0
                    ? 'Trend 24 Jam'
                    : _selected == 1
                        ? 'Trend 7 Hari'
                        : 'Trend 30 Hari',
                child: _TrendChart(mode: _selected),
                height: 240,
              ),
              const SizedBox(height: 12),
              const _AllSensorsCard(),
              const SizedBox(height: 12),
              const _AiSummaryCard(),
              const SizedBox(height: 80),
            ]),
          ),
        ],
        ),
      ),
    );
  }
}

class _FixedHeaderDelegate extends SliverPersistentHeaderDelegate {
  _FixedHeaderDelegate({required this.child, required this.height});
  final Widget child;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Deep Analytics Berbasis Data', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.selected, required this.onSelected, required this.labels});
  final int selected;
  final ValueChanged<int> onSelected;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(labels.length, (i) {
          final bool isSel = i == selected;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFF10B981) : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextButton(
                onPressed: () => onSelected(i),
                child: Text(
                  labels[i],
                  style: TextStyle(color: isSel ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          );
        }),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [
        BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))
      ]),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          _TabButton(label: 'Hari Ini', selected: selected == 0, onTap: () => onSelected(0)),
          _TabButton(label: 'Minggu', selected: selected == 1, onTap: () => onSelected(1)),
          _TabButton(label: 'Bulan', selected: selected == 2, onTap: () => onSelected(2)),
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
              child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.percentage});
  final double percentage;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))
        ]),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Expanded(child: Text('Status Sistem', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87 ))),
            Text('${percentage.toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF0284C7), fontSize: 20, fontWeight: FontWeight.w800)),
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
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))
        ]),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 12),
          SizedBox(height: height, child: child),
        ]),
      ),
    );
  }
}

class _HeatmapPlaceholder extends StatelessWidget {
  const _HeatmapPlaceholder();
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 12, mainAxisSpacing: 4, crossAxisSpacing: 4),
      itemCount: 12 * 6,
      itemBuilder: (_, i) {
        final shades = [0xFFE0F2F1, 0xFFB2DFDB, 0xFF80CBC4, 0xFF4DB6AC, 0xFF26A69A];
        return Container(
          decoration: BoxDecoration(
            color: Color(shades[i % shades.length]),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }
}

class _DonutPlaceholder extends StatelessWidget {
  const _DonutPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 180,
          height: 180,
          child: CustomPaint(painter: _DonutPainter()),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: const [
            _Legend(color: Color(0xFF10B981), label: 'Aman (60%)'),
            _Legend(color: Color(0xFFF59E0B), label: 'Warning (30%)'),
            _Legend(color: Color(0xFFEF4444), label: 'Bahaya (10%)'),
          ],
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 6;
    final stroke = 16.0;

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = const Color(0xFFE5E7EB);
    canvas.drawCircle(center, radius, bg);

    void drawArc(double start, double sweep, Color color) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke
        ..color = color;
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, start, sweep, false, p);
    }

    const total = 100.0;
    final green = 60.0 / total * math.pi * 2;
    final yellow = 30.0 / total * math.pi * 2;
    final red = 10.0 / total * math.pi * 2;
    double start = -math.pi / 2;
    drawArc(start, green, const Color(0xFF10B981));
    start += green + 0.05;
    drawArc(start, yellow, const Color(0xFFF59E0B));
    start += yellow + 0.05;
    drawArc(start, red, const Color(0xFFEF4444));

    final inner = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius - stroke, inner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.black87)),
      ],
    );
  }
}

class _RadarPlaceholder extends StatelessWidget {
  const _RadarPlaceholder();
  @override
  Widget build(BuildContext context) {
    const labels = ['NH3', 'H2S', 'CH4', 'C2H5OH', 'VOC', 'CO2'];
    const values = [0.7, 0.6, 0.65, 0.55, 0.5, 0.6];
    return RadarChart(
      RadarChartData(
        radarShape: RadarShape.polygon,
        tickCount: 3,
        ticksTextStyle: const TextStyle(color: Colors.black38, fontSize: 10),
        gridBorderData: BorderSide(color: const Color(0xFFE5E7EB)),
        titlePositionPercentageOffset: 0.15,
        getTitle: (index, angle) => RadarChartTitle(text: labels[index]),
        dataSets: [
          RadarDataSet(
            fillColor: const Color(0xFF60A5FA).withOpacity(0.35),
            borderColor: const Color(0xFF3B82F6),
            entryRadius: 2,
            borderWidth: 2,
            dataEntries: values.map((v) => RadarEntry(value: v)).toList(),
          ),
        ],
      ),
      swapAnimationDuration: const Duration(milliseconds: 250),
    );
  }
}

class _LineChartPlaceholder extends StatelessWidget {
  const _LineChartPlaceholder();
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _LinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()..color = const Color(0xFFDBEAFE)..strokeWidth = 1;
    for (int i = 1; i < 4; i++) {
      final dy = size.height * i / 4;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paintGrid);
    }

    final path = Path();
    final paintLine = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final points = [
      Offset(0, size.height * .75),
      Offset(size.width * .2, size.height * .5),
      Offset(size.width * .4, size.height * .6),
      Offset(size.width * .6, size.height * .3),
      Offset(size.width * .8, size.height * .45),
      Offset(size.width * 1.0, size.height * .35),
    ];
    path.addPolygon(points, false);
    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.mode});
  final int mode; // 0 day, 1 week, 2 month

  List<FlSpot> _data() {
    if (mode == 0) {
      return const [
        FlSpot(0, 15),
        FlSpot(4, 35),
        FlSpot(8, 25),
        FlSpot(12, 60),
        FlSpot(16, 45),
        FlSpot(20, 65),
      ];
    } else if (mode == 1) {
      return const [
        FlSpot(1, 100), // Sen
        FlSpot(2, 140), // Sel
        FlSpot(3, 130), // Rab
        FlSpot(4, 80),  // Kam
        FlSpot(5, 60),  // Jum
        FlSpot(6, 90),  // Sab
      ];
    } else {
      return const [
        FlSpot(1, 160), // M1
        FlSpot(2, 270), // M2
        FlSpot(3, 200), // M3
        FlSpot(4, 230), // M4
      ];
    }
  }

  List<String> _labels() {
    if (mode == 0) {
      return const ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00'];
    } else if (mode == 1) {
      return const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    } else {
      return const ['M1', 'M2', 'M3', 'M4'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data();
    final labels = _labels();
    final double interval = mode == 0 ? 4 : 1;
    return LineChart(
      LineChartData(
        minY: 0,
        minX: mode == 2 ? 1 : 0,
        maxX: mode == 0 ? 20 : (mode == 1 ? 6 : 4),
        gridData: FlGridData(show: true, horizontalInterval: mode == 0 ? 25 : (mode == 1 ? 25 : 100), drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: Text(
              mode == 2
                  ? 'Total Insiden'
                  : (mode == 1 ? 'Rata-rata Gas (ppm)' : 'Konsentrasi Gas (ppm)'),
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
                // Round to nearest step and map to labels list
                double rounded = (value / interval).roundToDouble() * interval;
                List<double> xs;
                if (mode == 0) {
                  xs = const [0, 4, 8, 12, 16, 20];
                } else if (mode == 1) {
                  xs = const [1, 2, 3, 4, 5, 6];
                } else {
                  xs = const [1, 2, 3, 4];
                }
                final idx = xs.indexWhere((x) => (x - rounded).abs() < 0.01);
                return idx == -1 ? const SizedBox.shrink() : Text(labels[idx], style: const TextStyle(fontSize: 11, color: Colors.black45));
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data,
            isCurved: true,
            gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF0284C7)]),
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

class _AllSensorsCard extends StatelessWidget {
  const _AllSensorsCard();
  @override
  Widget build(BuildContext context) {
    final tiles = [
      _sensor('NH3', '8.2 ppm', 'MQ-137 • Normal', Colors.green),
      _sensor('H2S', '6.5 ppm', 'MQ-136 • Warning', const Color(0xFFF59E0B)),
      _sensor('CH4', '32.1 ppm', 'MQ-4 • Normal', Colors.green),
      _sensor('CO2', '450 ppm', 'MQ-135 • Normal', Colors.green),
      _sensor('VOC', '0.8 mg/m³', 'MQ-135 • Danger', const Color(0xFFEF4444)),
      _sensor('C2H5OH', '12.3 ppm', 'MQ-3 • Normal', Colors.green),
      _sensor('CO', '5.2 ppm', 'MQ-7 • Normal', Colors.green),
      _sensor('Acetone', '0.3 ppm', 'MQ-138 • Normal', Colors.green),
      _sensor('H2', '15.8 ppm', 'MQ-8 • Warning', const Color(0xFFF59E0B)),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))
        ]),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Semua Sensor', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87)),
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

  static Widget _sensor(String title, String value, String note, Color dotColor) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(title, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
          const Spacer(),
          Icon(Icons.circle, size: 8, color: dotColor),
        ]),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Color(0xFF0284C7), fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(note, style: const TextStyle(color: Colors.black45, fontSize: 11)),
      ]),
    );
  }
}

class _AiSummaryCard extends StatelessWidget {
  const _AiSummaryCard();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF38BDF8), Color(0xFF10B981)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 16, offset: Offset(0, 8))],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: const [
            Icon(Icons.smart_toy, color: Colors.white),
            SizedBox(width: 8),
            Text('AI Summary Hari Ini', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          ]),
          const SizedBox(height: 8),
          const Text(
            'Berdasarkan analisis 35 tray yang diuji hari ini, terdeteksi pola peningkatan gas VOC dan H2S pada jam 10-12 pagi. Korelasi antara VOC dan H2S menunjukkan kemungkinan kontaminasi bakteri anaerob. Risiko keracunan tertinggi pada menu ayam goreng (78%) dan sayur bening (65%).',
            style: TextStyle(color: Colors.white, height: 1.4),
          ),
          const SizedBox(height: 14),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: const [
              _AiStat(value: '35', label: 'Total Tray'),
              _AiStat(value: '78%', label: 'Risiko Tertinggi'),
              _AiStat(value: '10-12', label: 'Jam Kritis'),
              _AiStat(value: '65%', label: 'Akurasi AI'),
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
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.all(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    );
  }
}



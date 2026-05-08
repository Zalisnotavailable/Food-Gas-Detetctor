import 'package:flutter/material.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _FixedHeaderDelegate(height: 220, child: const _Header()),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _ScanPanel(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              childAspectRatio: 1.6,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: const [
                _SensorTile(label: 'NH3'),
                _SensorTile(label: 'H2S'),
                _SensorTile(label: 'CH4'),
                _SensorTile(label: 'CO2'),
                _SensorTile(label: 'VOC', unit: 'mg/m³'),
                _SensorTile(label: 'C2H5OH'),
                _SensorTile(label: 'CO'),
                _SensorTile(label: 'ACETONE'),
                _SensorTile(label: 'H2'),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF10B981),
        onPressed: () {},
        child: const Icon(Icons.refresh, color: Colors.white),
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
  const _Header();
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
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Scan Tray',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Deteksi Real-time 9 Gas', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: const [
                Expanded(
                  child: _HeaderInfo(label: 'Lokasi', value: 'SDN 01 Jakarta'),
                ),
                Expanded(
                  child: _HeaderInfo(label: 'Operator', value: 'Dr. Sarah, S.Gz'),
                ),
                Expanded(
                  child: _HeaderInfo(label: 'Status', value: 'Ready to Scan'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderInfo extends StatelessWidget {
  const _HeaderInfo({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ScanPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [
        BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 10))
      ]),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF06B6D4), style: BorderStyle.solid, width: 2, strokeAlign: BorderSide.strokeAlignOutside),
              ),
              child: const Center(
                child: Icon(Icons.photo_camera_outlined, size: 48, color: Colors.black26),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF10B981)]),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [BoxShadow(color: Color(0x2206B6D4), blurRadius: 20, offset: Offset(0, 10))],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () {},
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  child: Text('Pindai Tray Sekarang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorTile extends StatelessWidget {
  const _SensorTile({required this.label, this.unit = 'ppm'});
  final String label;
  final String unit;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [
        BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))
      ]),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Spacer(),
          Icon(Icons.circle, size: 8, color: Color(0xFF10B981)),
        ]),
        Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('--', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(unit, style: const TextStyle(color: Colors.black54, fontSize: 11)),
      ]),
    );
  }
}



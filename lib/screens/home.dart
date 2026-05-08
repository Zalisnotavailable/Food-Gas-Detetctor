import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              height: 300,
              child: _HeaderCard(),
            ),
          ),
          SliverToBoxAdapter(child: _StatusRow()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              childAspectRatio: 1.75,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: const [
                _GasTile(title: 'NH3', value: '9.6', unit: 'ppm'),
                _GasTile(title: 'H2S', value: '5.1', unit: 'ppm', tint: Color(0xFFFFE2B5)),
                _GasTile(title: 'CH4', value: '34.7', unit: 'ppm'),
                _GasTile(title: 'CO2', value: '447.5', unit: 'ppm'),
                _GasTile(title: 'VOC', value: '0.0', unit: 'mg/m³', danger: true, tint: Color(0xFFFFD7D7)),
                _GasTile(title: 'C2H5OH', value: '12.9', unit: 'ppm'),
                _GasTile(title: 'CO', value: '9.2', unit: 'ppm'),
                _GasTile(title: 'ACETONE', value: '0.2', unit: 'ppm'),
                _GasTile(title: 'H2', value: '16.3', unit: 'ppm'),
              ],
            ),
          ),
          SliverToBoxAdapter(child: _AlertBanner()),
          SliverToBoxAdapter(child: _RecommendationCard()),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          const SliverToBoxAdapter(child: SizedBox(height: 72)),
        ],
        ),
      ),
      floatingActionButton: _RefreshFab(onPressed: () {}),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _HeaderCard extends StatelessWidget {
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
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FoodGuard Pro',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Deteksi 9 Gas Makanan Basi',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _InfoRow(label: 'Lokasi:', value: 'SDN 01 Jakarta'),
                _InfoRow(label: 'Operator:', value: 'Dr. Sarah, S.Gz'),
                _InfoRow(label: 'Tanggal:', value: '15 Nov 2024, 09:30 WIB'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: _StatusPill(label: 'ESP32 Online', color: Color(0xFF2ecc71))),
              SizedBox(width: 12),
              Expanded(child: _StatusPill(label: 'MQTT: Connected', color: Color(0xFF2ecc71))),
            ],
          ),
        ],
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

class _StatusRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 12);
  }
}

class _GasTile extends StatelessWidget {
  const _GasTile({
    required this.title,
    required this.value,
    required this.unit,
    this.danger = false,
    this.tint,
  });

  final String title;
  final String value;
  final String unit;
  final bool danger;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final cardColor = tint ?? Colors.white;
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
              const Spacer(),
              Icon(Icons.circle, size: 8, color: danger ? Colors.redAccent : Colors.tealAccent.shade100),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      color: Colors.black,
                    ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11, color: Colors.black54),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF00A0D2),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('3 Gas Melewati Batas Aman!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'VOC, H2S, dan H2 tinggi. Risiko keracunan 78%. Segera lakukan uji lab!',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Card(
        color: Colors.white,
        elevation: 2, // Menambahkan elevasi untuk memberikan efek bayangan
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Membulatkan sudut
        ),
        child: Container(
          padding: const EdgeInsets.all(16), // Padding dalam kartu
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.teal.shade600,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'AI',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Rekomendasi Deep Learning',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black),
                      ),
                      Text(
                        'LSTM + DRL Analysis',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _Bullet(index: 1, text: 'Uji Salmonella & E.coli (probabilitas 65%)'),
              const _Bullet(index: 2, text: 'Simpan sampel di -20°C sebelum lab'),
              const _Bullet(index: 3, text: 'Cek batch produksi dan cold chain'),
            ],
          ),
        ),
      ),
    );
  }
}



class _Bullet extends StatelessWidget {
  const _Bullet({required this.index, required this.text});
  final int index;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(Icons.circle, size: 10, color: color),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Colors.white)),
          ]),
        ],
      ),
    );
  }
}

class _RefreshFab extends StatelessWidget {
  const _RefreshFab({required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: const Color(0xFF00A39B),
      child: const Icon(Icons.refresh, color: Colors.white),
    );
  }
}



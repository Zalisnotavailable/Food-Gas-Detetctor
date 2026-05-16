import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/sensor_service.dart';
import '../services/refresh_notifier.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SensorReading? _latest;
  bool _isLoading = true;
  DateTime? _lastUpdate;
  String _lokasi = 'Memuat lokasi...'; // ← TAMBAHAN

  @override
  void initState() {
    super.initState();
    _loadData();
    _getLocation(); // ← TAMBAHAN
  }

  // ← TAMBAHAN: fungsi ambil lokasi GPS
  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _lokasi = 'GPS tidak aktif');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _lokasi = 'Izin lokasi ditolak');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _lokasi = 'Izin lokasi ditolak permanen');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _lokasi = '${place.subLocality ?? place.locality ?? 'Tidak diketahui'}, '
              '${place.subAdministrativeArea ?? place.administrativeArea ?? ''}';
        });
      }
    } catch (e) {
      setState(() => _lokasi = 'Gagal ambil lokasi');
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await SensorService.getLatest();
    setState(() {
      _latest = data;
      _lastUpdate = DateTime.now();
      _isLoading = false;
    });
  }

  List<String> _getDangerSensors() {
    if (_latest == null) return [];
    final sensors = {
      'NH3': _latest!.nh3, 'H2S': _latest!.h2s, 'CH4': _latest!.ch4,
      'CO2': _latest!.co2, 'VOC': _latest!.voc, 'C2H5OH': _latest!.c2h5oh,
      'CO': _latest!.co, 'H2': _latest!.h2,
    };
    return sensors.entries
        .where((e) => SensorService.getStatus(e.key.toLowerCase(), e.value) == 'Danger')
        .map((e) => e.key)
        .toList();
  }

  List<String> _getWarningSensors() {
    if (_latest == null) return [];
    final sensors = {
      'NH3': _latest!.nh3, 'H2S': _latest!.h2s, 'CH4': _latest!.ch4,
      'CO2': _latest!.co2, 'VOC': _latest!.voc, 'C2H5OH': _latest!.c2h5oh,
      'CO': _latest!.co, 'H2': _latest!.h2,
    };
    return sensors.entries
        .where((e) => SensorService.getStatus(e.key.toLowerCase(), e.value) == 'Warning')
        .map((e) => e.key)
        .toList();
  }

  Color _tileColor(String key, double? val) {
    final status = SensorService.getStatus(key.toLowerCase(), val);
    if (status == 'Danger') return const Color(0xFFFFD7D7);
    if (status == 'Warning') return const Color(0xFFFFE2B5);
    return Colors.white;
  }

  bool _isDanger(String key, double? val) =>
      SensorService.getStatus(key.toLowerCase(), val) == 'Danger';

  String _fmt(double? v, {int d = 1}) => v != null ? v.toStringAsFixed(d) : '-';

  String _formatTime(DateTime? t) {
    if (t == null) return '-';
    return '${t.day.toString().padLeft(2, '0')} '
        '${_monthName(t.month)} ${t.year}, '
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} WIB';
  }

  String _monthName(int m) {
    const names = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return names[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    final dangerSensors  = _getDangerSensors();
    final warningSensors = _getWarningSensors();
    final allAlert       = [...dangerSensors, ...warningSensors];
    final isOnline       = _latest != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A39B)))
            : CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _FixedHeaderDelegate(
                height: 240,
                child: _HeaderCard(
                  isOnline: isOnline,
                  lastUpdate: _formatTime(_latest?.timestamp),
                  lokasi: _lokasi, // ← TAMBAHAN
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                childAspectRatio: 1.75,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _GasTile(title: 'NH3',     value: _fmt(_latest?.nh3),     unit: 'ppm',    tint: _tileColor('NH3', _latest?.nh3),     danger: _isDanger('NH3', _latest?.nh3)),
                  _GasTile(title: 'H2S',     value: _fmt(_latest?.h2s),     unit: 'ppm',    tint: _tileColor('H2S', _latest?.h2s),     danger: _isDanger('H2S', _latest?.h2s)),
                  _GasTile(title: 'CH4',     value: _fmt(_latest?.ch4),     unit: 'ppm',    tint: _tileColor('CH4', _latest?.ch4),     danger: _isDanger('CH4', _latest?.ch4)),
                  _GasTile(title: 'CO2',     value: _fmt(_latest?.co2),     unit: 'ppm',    tint: _tileColor('CO2', _latest?.co2),     danger: _isDanger('CO2', _latest?.co2)),
                  _GasTile(title: 'VOC',     value: _fmt(_latest?.voc, d: 2), unit: 'mg/m³', tint: _tileColor('VOC', _latest?.voc),   danger: _isDanger('VOC', _latest?.voc)),
                  _GasTile(title: 'C2H5OH',  value: _fmt(_latest?.c2h5oh),  unit: 'ppm',    tint: _tileColor('C2H5OH', _latest?.c2h5oh), danger: _isDanger('C2H5OH', _latest?.c2h5oh)),
                  _GasTile(title: 'CO',      value: _fmt(_latest?.co),      unit: 'ppm',    tint: _tileColor('CO', _latest?.co),       danger: _isDanger('CO', _latest?.co)),
                  _GasTile(title: 'ACETONE', value: _fmt(_latest?.acetone, d: 2), unit: 'ppm', tint: Colors.white, danger: false),
                  _GasTile(title: 'H2',      value: _fmt(_latest?.h2),      unit: 'ppm',    tint: _tileColor('H2', _latest?.h2),       danger: _isDanger('H2', _latest?.h2)),
                ],
              ),
            ),
            if (allAlert.isNotEmpty)
              SliverToBoxAdapter(
                child: _AlertBanner(
                  dangerSensors: dangerSensors,
                  warningSensors: warningSensors,
                ),
              ),
            SliverToBoxAdapter(
              child: _RecommendationCard(
                dangerSensors: dangerSensors,
                warningSensors: warningSensors,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 72)),
          ],
        ),
      ),
      floatingActionButton: _RefreshFab(onPressed: () {
        _loadData();                  // refresh home
        refreshNotifier.refreshAll(); // refresh semua page lain
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.isOnline,
    required this.lastUpdate,
    required this.lokasi, // ← TAMBAHAN
  });
  final bool isOnline;
  final String lastUpdate;
  final String lokasi; // ← TAMBAHAN

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
          Text('WITFood',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Deteksi 9 Gas Makanan Basi',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70)),
          const SizedBox(height: 12),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: 'Lokasi:', value: lokasi), // ← DIUBAH
                _InfoRow(label: 'Update:', value: lastUpdate),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatusPill(
                label: isOnline ? 'ESP32 Online' : 'ESP32 Offline',
                color: isOnline ? const Color(0xFF2ecc71) : Colors.redAccent,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatusPill(
                label: isOnline ? 'MQTT: Connected' : 'MQTT: Disconnected',
                color: isOnline ? const Color(0xFF2ecc71) : Colors.redAccent,
              )),
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

  @override double get minExtent => height;
  @override double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox.expand(child: child);

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

// ─── Gas Tile ─────────────────────────────────────────────────────────────────

class _GasTile extends StatelessWidget {
  const _GasTile({
    required this.title,
    required this.value,
    required this.unit,
    this.danger = false,
    this.tint,
  });
  final String title, value, unit;
  final bool danger;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tint ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: Colors.black87)),
            const Spacer(),
            Icon(Icons.circle,
                size: 8,
                color: danger ? Colors.redAccent : Colors.tealAccent.shade100),
          ]),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      color: Colors.black)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(unit,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: 11, color: Colors.black54)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Alert Banner (dinamis) ───────────────────────────────────────────────────

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.dangerSensors, required this.warningSensors});
  final List<String> dangerSensors;
  final List<String> warningSensors;

  @override
  Widget build(BuildContext context) {
    final allAlert = [...dangerSensors, ...warningSensors];
    final isDanger = dangerSensors.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      child: Container(
        decoration: BoxDecoration(
          color: isDanger ? const Color(0xFFDC2626) : const Color(0xFFF59E0B),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${allAlert.length} Gas Melewati Batas Aman!',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            '${allAlert.join(', ')} tinggi. Segera periksa kondisi makanan!',
            style: const TextStyle(color: Colors.white),
          ),
        ]),
      ),
    );
  }
}

// ─── Recommendation Card (dinamis) ───────────────────────────────────────────

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.dangerSensors,
    required this.warningSensors,
  });
  final List<String> dangerSensors;
  final List<String> warningSensors;

  List<String> _buildRecommendations() {
    if (dangerSensors.isEmpty && warningSensors.isEmpty) {
      return [
        'Semua gas dalam batas aman. Lanjutkan pemantauan rutin.',
        'Catat hasil pengukuran untuk laporan harian.',
        'Pastikan sensor dikalibrasi setiap 30 hari.',
      ];
    }

    final recs = <String>[];

    if (dangerSensors.contains('H2S') || dangerSensors.contains('NH3')) {
      recs.add('Uji Salmonella & E.coli segera (probabilitas kontaminasi tinggi)');
    }
    if (dangerSensors.contains('VOC') || dangerSensors.contains('CH4')) {
      recs.add('Simpan sampel di -20°C sebelum dikirim ke laboratorium');
    }
    if (dangerSensors.contains('CO2') || dangerSensors.contains('CO')) {
      recs.add('Periksa ventilasi ruangan dan sumber CO2/CO');
    }
    if (warningSensors.isNotEmpty) {
      recs.add('Monitor sensor ${warningSensors.join(', ')} — mendekati batas bahaya');
    }
    if (dangerSensors.isNotEmpty) {
      recs.add('Cek batch produksi dan cold chain distribusi makanan');
    }

    // Pastikan minimal 3 rekomendasi
    if (recs.length < 3) {
      recs.add('Dokumentasikan insiden dan laporkan ke supervisor');
    }

    return recs.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final recs = _buildRecommendations();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: Colors.teal.shade600,
                    borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: const Text('💡',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Rekomendasi Tindakan',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.black)),
                Text('Berdasarkan Kesimpulan Sementara',
                    style: TextStyle(color: Colors.black54, fontSize: 12)),
              ]),
            ]),
            const SizedBox(height: 12),
            ...recs.asMap().entries.map(
                  (e) => _Bullet(index: e.key + 1, text: e.value),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

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
      child: Row(children: [
        Container(
          width: 24, height: 24,
          decoration: const BoxDecoration(
              color: Color(0xFF0EA5E9), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text('$index',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: Colors.white)),
        ),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.black87))),
      ]),
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
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right),
        ),
      ]),
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
      child: Row(children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Colors.white)),
      ]),
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
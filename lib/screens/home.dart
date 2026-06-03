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
  String _lokasi = 'Memuat lokasi...';

  @override
  void initState() {
    super.initState();
    _loadData();
    _getLocation();
    refreshNotifier.addListener(_onGlobalRefresh);
  }

  void _onGlobalRefresh() => _loadData();

  @override
  void dispose() {
    refreshNotifier.removeListener(_onGlobalRefresh);
    super.dispose();
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { setState(() => _lokasi = 'GPS tidak aktif'); return; }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) { setState(() => _lokasi = 'Izin ditolak'); return; }
      }
      if (permission == LocationPermission.deniedForever) { setState(() => _lokasi = 'Izin ditolak permanen'); return; }
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks[0];
        setState(() => _lokasi = '${p.subLocality ?? p.locality ?? 'Tidak diketahui'}, ${p.subAdministrativeArea ?? p.administrativeArea ?? ''}');
      }
    } catch (_) { setState(() => _lokasi = 'Gagal ambil lokasi'); }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await SensorService.getLatest();
    setState(() { _latest = data; _isLoading = false; });
  }

  List<String> _getDangerSensors() {
    if (_latest == null) return [];
    final s = {'NH3': _latest!.nh3, 'H2S': _latest!.h2s, 'CH4': _latest!.ch4, 'CO2': _latest!.co2, 'VOC': _latest!.voc, 'C2H5OH': _latest!.c2h5oh, 'CO': _latest!.co, 'Acetone': _latest!.acetone, 'H2': _latest!.h2};
    return s.entries.where((e) => SensorService.getStatus(e.key.toLowerCase(), e.value) == 'Danger').map((e) => e.key).toList();
  }

  List<String> _getWarningSensors() {
    if (_latest == null) return [];
    final s = {'NH3': _latest!.nh3, 'H2S': _latest!.h2s, 'CH4': _latest!.ch4, 'CO2': _latest!.co2, 'VOC': _latest!.voc, 'C2H5OH': _latest!.c2h5oh, 'CO': _latest!.co, 'Acetone': _latest!.acetone, 'H2': _latest!.h2};
    return s.entries.where((e) => SensorService.getStatus(e.key.toLowerCase(), e.value) == 'Warning').map((e) => e.key).toList();
  }

  Color _tileColor(BuildContext ctx, String key, double? val) {
    final cs = Theme.of(ctx).colorScheme;
    final status = SensorService.getStatus(key.toLowerCase(), val);
    if (status == 'Danger') return cs.errorContainer;
    if (status == 'Warning') return const Color(0xFFFFF3E0);
    return cs.surfaceContainerLow;
  }

  bool _isDanger(String key, double? val) => SensorService.getStatus(key.toLowerCase(), val) == 'Danger';
  String _fmt(double? v, {int d = 1}) => v != null ? v.toStringAsFixed(d) : '-';

  String _formatTime(DateTime? t) {
    if (t == null) return '-';
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return '${t.day.toString().padLeft(2,'0')} ${months[t.month-1]} ${t.year}, ${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')} WIB';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dangerSensors  = _getDangerSensors();
    final warningSensors = _getWarningSensors();
    final allAlert = [...dangerSensors, ...warningSensors];
    final isOnline = _latest != null;

    return Scaffold(
      backgroundColor: cs.surface,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : CustomScrollView(
        slivers: [
          // ─── App Bar ────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            stretch: true,
            backgroundColor: cs.primaryContainer,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WITFood',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20)),
                  Text('Deteksi 9 Gas Makanan',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11)),
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 60, 16, 72),
                  child: Row(children: [
                    Expanded(
                      child: _InfoChip(
                        icon: Icons.location_on_outlined,
                        label: _lokasi,
                        cs: cs,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: isOnline ? Icons.wifi : Icons.wifi_off,
                      label: isOnline ? 'Online' : 'Offline',
                      cs: cs,
                    ),
                  ]),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () { _loadData(); refreshNotifier.refreshAll(); },
                icon: Icon(Icons.refresh_rounded, color: cs.onPrimary),
                tooltip: 'Refresh',
              ),
            ],
          ),

          // ─── Update time ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'Update terakhir: ${_formatTime(_latest?.timestamp)}',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
            ),
          ),

          // ─── Alert Banner ────────────────────────────────────────────
          if (allAlert.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Card(
                  color: dangerSensors.isNotEmpty ? cs.errorContainer : const Color(0xFFFFF3E0),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Icon(Icons.warning_amber_rounded,
                          color: dangerSensors.isNotEmpty ? cs.error : Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${allAlert.length} Gas Melewati Batas!',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: dangerSensors.isNotEmpty ? cs.onErrorContainer : Colors.orange.shade900)),
                            Text(allAlert.join(', '),
                                style: TextStyle(
                                    color: dangerSensors.isNotEmpty ? cs.onErrorContainer : Colors.orange.shade800,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),

          // ─── Gas Grid ────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              childAspectRatio: 1.7,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _GasTile(title: 'NH3',     value: _fmt(_latest?.nh3),        unit: 'ppm',   color: _tileColor(context, 'NH3',     _latest?.nh3),     danger: _isDanger('NH3',     _latest?.nh3),     cs: cs),
                _GasTile(title: 'H2S',     value: _fmt(_latest?.h2s),        unit: 'ppm',   color: _tileColor(context, 'H2S',     _latest?.h2s),     danger: _isDanger('H2S',     _latest?.h2s),     cs: cs),
                _GasTile(title: 'CH4',     value: _fmt(_latest?.ch4),        unit: 'ppm',   color: _tileColor(context, 'CH4',     _latest?.ch4),     danger: _isDanger('CH4',     _latest?.ch4),     cs: cs),
                _GasTile(title: 'CO2',     value: _fmt(_latest?.co2),        unit: 'ppm',   color: _tileColor(context, 'CO2',     _latest?.co2),     danger: _isDanger('CO2',     _latest?.co2),     cs: cs),
                _GasTile(title: 'VOC',     value: _fmt(_latest?.voc, d: 2),  unit: 'mg/m³', color: _tileColor(context, 'VOC',     _latest?.voc),     danger: _isDanger('VOC',     _latest?.voc),     cs: cs),
                _GasTile(title: 'C2H5OH',  value: _fmt(_latest?.c2h5oh),     unit: 'ppm',   color: _tileColor(context, 'C2H5OH',  _latest?.c2h5oh),  danger: _isDanger('C2H5OH',  _latest?.c2h5oh),  cs: cs),
                _GasTile(title: 'CO',      value: _fmt(_latest?.co),         unit: 'ppm',   color: _tileColor(context, 'CO',      _latest?.co),      danger: _isDanger('CO',      _latest?.co),      cs: cs),
                _GasTile(title: 'Acetone', value: _fmt(_latest?.acetone, d: 2), unit: 'ppm',   color: _tileColor(context, 'Acetone',      _latest?.acetone),      danger: _isDanger('Acetone',      _latest?.acetone),      cs: cs),
                _GasTile(title: 'H2',      value: _fmt(_latest?.h2),         unit: 'ppm',   color: _tileColor(context, 'H2',      _latest?.h2),      danger: _isDanger('H2',      _latest?.h2),      cs: cs),
              ],
            ),
          ),

          // ─── Rekomendasi ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _RecommendationCard(
                  dangerSensors: dangerSensors, warningSensors: warningSensors),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, required this.cs});
  final IconData icon;
  final String label;
  final ColorScheme cs;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.onPrimary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.onPrimary.withOpacity(0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: cs.onPrimary),
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: TextStyle(color: cs.onPrimary, fontSize: 12), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

class _GasTile extends StatelessWidget {
  const _GasTile({required this.title, required this.value, required this.unit, required this.color, required this.danger, required this.cs});
  final String title, value, unit;
  final Color color;
  final bool danger;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface, fontSize: 13)),
            const Spacer(),
            Icon(Icons.circle, size: 8, color: danger ? cs.error : cs.primary),
          ]),
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: cs.onSurface)),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(unit, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.dangerSensors, required this.warningSensors});
  final List<String> dangerSensors, warningSensors;

  List<String> _recs() {
    if (dangerSensors.isEmpty && warningSensors.isEmpty) {
      return ['Semua gas dalam batas aman. Lanjutkan pemantauan rutin.', 'Catat hasil pengukuran untuk laporan harian.', 'Pastikan sensor dikalibrasi setiap 30 hari.'];
    }
    final r = <String>[];
    if (dangerSensors.contains('H2S') || dangerSensors.contains('NH3')) r.add('Uji Salmonella & E.coli segera');
    if (dangerSensors.contains('VOC') || dangerSensors.contains('CH4')) r.add('Simpan sampel di -20°C sebelum ke lab');
    if (dangerSensors.contains('CO2') || dangerSensors.contains('CO'))  r.add('Periksa ventilasi ruangan');
    if (warningSensors.isNotEmpty) r.add('Monitor ${warningSensors.join(', ')} — mendekati batas bahaya');
    if (dangerSensors.isNotEmpty)  r.add('Cek batch produksi dan cold chain');
    if (r.length < 3) r.add('Dokumentasikan insiden ke supervisor');
    return r.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.lightbulb_outline_rounded, color: cs.onSecondaryContainer),
            const SizedBox(width: 8),
            Text('Rekomendasi Tindakan',
                style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSecondaryContainer, fontSize: 15)),
          ]),
          const SizedBox(height: 12),
          ..._recs().asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(radius: 12, backgroundColor: cs.secondary,
                  child: Text('${e.key+1}', style: TextStyle(color: cs.onSecondary, fontSize: 11, fontWeight: FontWeight.w700))),
              const SizedBox(width: 10),
              Expanded(child: Text(e.value, style: TextStyle(color: cs.onSecondaryContainer))),
            ]),
          )),
        ]),
      ),
    );
  }
}
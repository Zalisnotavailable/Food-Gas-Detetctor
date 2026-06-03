import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/refresh_notifier.dart';
import '../services/tray_pdf_service.dart';

// ─── Model ────────────────────────────────────────────────────────────────────
enum _TrayStatus { safe, warning, danger }

class _TrayItem {
  final String id;
  final DateTime datetime;
  final _TrayStatus status;
  final Map<String, double?> gasValues;

  _TrayItem({required this.id, required this.datetime, required this.status, required this.gasValues});

  factory _TrayItem.fromMap(Map<String, dynamic> map) {
    _TrayStatus status = _TrayStatus.safe;
    final voc = (map['voc'] as num?)?.toDouble();
    final h2s = (map['h2s'] as num?)?.toDouble();
    final nh3 = (map['nh3'] as num?)?.toDouble();
    final co  = (map['co']  as num?)?.toDouble();
    if ((voc != null && voc >= 1.0) || (h2s != null && h2s >= 10.0) || (nh3 != null && nh3 >= 25.0) || (co != null && co >= 35.0)) {
      status = _TrayStatus.danger;
    } else if ((voc != null && voc >= 0.5) || (h2s != null && h2s >= 5.0) || (nh3 != null && nh3 >= 10.0) || (co != null && co >= 9.0)) {
      status = _TrayStatus.warning;
    }
    return _TrayItem(
      id: map['id']?.toString() ?? '-',
      datetime: DateTime.parse(map['timestamp']).toLocal(),
      status: status,
      gasValues: {
        'NH3': (map['nh3'] as num?)?.toDouble(), 'H2S': (map['h2s'] as num?)?.toDouble(),
        'CH4': (map['ch4'] as num?)?.toDouble(), 'CO2': (map['co2'] as num?)?.toDouble(),
        'VOC': (map['voc'] as num?)?.toDouble(), 'C2H5OH':  (map['c2h5oh']  as num?)?.toDouble(),
        'CO':  (map['co']  as num?)?.toDouble(), 'ACETONE':  (map['acetone']  as num?)?.toDouble(),
        'H2':  (map['h2']  as num?)?.toDouble(),
      },
    );
  }

  String get formattedDate {
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agt','Sep','Okt','Nov','Des'];
    return '${datetime.day} ${months[datetime.month-1]} ${datetime.year}, ${datetime.hour.toString().padLeft(2,'0')}:${datetime.minute.toString().padLeft(2,'0')} WIB';
  }

  String get trayId => 'TRAY-${datetime.year}-${id.padLeft(3,'0')}';
}

// ─── Page ─────────────────────────────────────────────────────────────────────
class TrayPage extends StatefulWidget {
  const TrayPage({super.key});
  @override
  State<TrayPage> createState() => _TrayPageState();
}

class _TrayPageState extends State<TrayPage> {
  int _tab = 0;
  int _page = 1;
  bool _isLoading = true;
  String? _error;
  List<_TrayItem> _all = [];
  static const int _perPage = 10;

  @override
  void initState() {
    super.initState();
    _load();
    refreshNotifier.addListener(_onRefresh);
  }

  void _onRefresh() => _load();

  @override
  void dispose() {
    refreshNotifier.removeListener(_onRefresh);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await Supabase.instance.client
          .from('sensor_readings').select()
          .order('timestamp', ascending: false).limit(200);
      setState(() { _all = (res as List).map((e) => _TrayItem.fromMap(e)).toList(); _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  List<_TrayItem> get _filtered {
    switch (_tab) {
      case 1: return _all.where((e) => e.status == _TrayStatus.safe).toList();
      case 2: return _all.where((e) => e.status == _TrayStatus.warning).toList();
      case 3: return _all.where((e) => e.status == _TrayStatus.danger).toList();
      default: return _all;
    }
  }

  int get _pageCount => (_filtered.length / _perPage).ceil().clamp(1, 999);

  List<_TrayItem> get _pageItems {
    final start = (_page - 1) * _perPage;
    final end = (start + _perPage).clamp(0, _filtered.length);
    return _filtered.sublist(start.clamp(0, _filtered.length), end);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Manajemen Tray',
                      style: const TextStyle(
                          color: Colors.white, // ← putih
                          fontWeight: FontWeight.w800,
                          fontSize: 18)),
                  Text('${_all.length} Data Tersimpan',
                      style: const TextStyle(
                          color: Colors.white70, // ← putih transparan
                          fontSize: 11)),
                ],
              ),
              background: Container( // ← tambahkan gradient di sini
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1565C0), Color(0xFF64B5F6)],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(onPressed: _load, icon: Icon(Icons.refresh_rounded, color: cs.onPrimaryContainer)),
            ],
          ),
        ],
        body: Column(
          children: [
            // ─── Filter Tabs ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip(context, 0, 'Semua', _all.length),
                    const SizedBox(width: 8),
                    _filterChip(context, 1, 'Aman', _all.where((e) => e.status == _TrayStatus.safe).length),
                    const SizedBox(width: 8),
                    _filterChip(context, 2, 'Warning', _all.where((e) => e.status == _TrayStatus.warning).length),
                    const SizedBox(width: 8),
                    _filterChip(context, 3, 'Bahaya', _all.where((e) => e.status == _TrayStatus.danger).length),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ─── Content ───────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: cs.primary))
                  : _error != null
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.error_outline, color: cs.error, size: 48),
                const SizedBox(height: 12),
                Text('Gagal memuat data'),
                const SizedBox(height: 8),
                FilledButton(onPressed: _load, child: const Text('Coba Lagi')),
              ]))
                  : _filtered.isEmpty
                  ? Center(child: Text('Tidak ada data', style: TextStyle(color: cs.onSurfaceVariant)))
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                itemCount: _pageItems.length + 1,
                itemBuilder: (ctx, i) {
                  if (i == _pageItems.length) {
                    return _pageCount > 1
                        ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: _Pagination(pageCount: _pageCount, current: _page, onSelect: (p) => setState(() => _page = p)),
                    )
                        : const SizedBox(height: 80);
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TrayCard(item: _pageItems[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(BuildContext context, int index, String label, int count) {
    final cs = Theme.of(context).colorScheme;
    final selected = _tab == index;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: selected,
      onSelected: (_) => setState(() { _tab = index; _page = 1; }),
      selectedColor: cs.primaryContainer,
      checkmarkColor: cs.primary,
      labelStyle: TextStyle(
        color: selected ? cs.primary : cs.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
      ),
    );
  }
}

// ─── Tray Card ────────────────────────────────────────────────────────────────
class _TrayCard extends StatelessWidget {
  const _TrayCard({required this.item});
  final _TrayItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.trayId, style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSurface, fontSize: 15)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.access_time_rounded, size: 13, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(item.formattedDate, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                ]),
                const SizedBox(height: 8),
                _StatusChip(status: item.status),
              ]),
            ),
            const SizedBox(width: 8),
            Column(children: [
              FilledButton.tonal(
                onPressed: () => _showDetail(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(64, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Detail', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(height: 6),
              FilledButton(
                onPressed: () async {
                  try {
                    await TrayPdfService.generateAndShare(
                      trayId: item.trayId, datetime: item.formattedDate,
                      status: item.status == _TrayStatus.danger ? 'Bahaya' : item.status == _TrayStatus.warning ? 'Warning' : 'Aman',
                      gasValues: item.gasValues,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Theme.of(context).colorScheme.error));
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(64, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('PDF', style: TextStyle(fontSize: 12)),
              ),
            ]),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: item.gasValues.entries.where((e) => e.value != null)
                .map((e) => _GasChip(label: e.key, value: e.value!)).toList(),
          ),
        ]),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(item.trayId, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: cs.onSurface)),
            const SizedBox(height: 4),
            Text(item.formattedDate, style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 12),
            _StatusChip(status: item.status),
            const SizedBox(height: 20),
            Text('Detail Gas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: cs.onSurface)),
            const SizedBox(height: 12),
            ...item.gasValues.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Expanded(child: Text(e.key, style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface))),
                Text(e.value != null ? '${e.value!.toStringAsFixed(2)} ppm' : '-',
                    style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700)),
              ]),
            )),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final _TrayStatus status;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final config = {
      _TrayStatus.safe:    {'bg': cs.tertiaryContainer,  'fg': cs.onTertiaryContainer, 'text': 'Aman',    'icon': Icons.check_circle_outline},
      _TrayStatus.warning: {'bg': const Color(0xFFFFF8E1), 'fg': Colors.orange.shade900, 'text': 'Warning', 'icon': Icons.warning_amber_outlined},
      _TrayStatus.danger:  {'bg': cs.errorContainer,     'fg': cs.onErrorContainer,    'text': 'Bahaya',  'icon': Icons.dangerous_outlined},
    }[status]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: config['bg'] as Color, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(config['icon'] as IconData, size: 14, color: config['fg'] as Color),
        const SizedBox(width: 4),
        Text(config['text'] as String, style: TextStyle(color: config['fg'] as Color, fontWeight: FontWeight.w700, fontSize: 12)),
      ]),
    );
  }
}

class _GasChip extends StatelessWidget {
  const _GasChip({required this.label, required this.value});
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(8)),
      child: Text('$label: ${value.toStringAsFixed(1)}',
          style: TextStyle(fontSize: 11, color: cs.onPrimaryContainer, fontWeight: FontWeight.w600)),
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({required this.pageCount, required this.current, required this.onSelect});
  final int pageCount, current;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: current > 1 ? () => onSelect(current - 1) : null),
          ...List.generate(pageCount, (i) {
            final p = i + 1;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: p == current
                  ? FilledButton(onPressed: () => onSelect(p), style: FilledButton.styleFrom(minimumSize: const Size(40, 40), shape: const CircleBorder()), child: Text('$p'))
                  : OutlinedButton(onPressed: () => onSelect(p), style: OutlinedButton.styleFrom(minimumSize: const Size(40, 40), shape: const CircleBorder()), child: Text('$p')),
            );
          }),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: current < pageCount ? () => onSelect(current + 1) : null),
        ],
      ),
    );
  }
}
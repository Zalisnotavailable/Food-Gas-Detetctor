import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/refresh_notifier.dart';

// ─── Model ────────────────────────────────────────────────────────────────────
enum _TrayStatus { safe, warning, danger }

class _TrayItem {
  final String id;
  final DateTime datetime;
  final _TrayStatus status;
  final Map<String, double?> gasValues;

  _TrayItem({
    required this.id,
    required this.datetime,
    required this.status,
    required this.gasValues,
  });

  factory _TrayItem.fromMap(Map<String, dynamic> map) {
    // Tentukan status berdasarkan nilai gas
    _TrayStatus status = _TrayStatus.safe;

    final voc     = (map['voc'] as num?)?.toDouble();
    final h2s     = (map['h2s'] as num?)?.toDouble();
    final nh3     = (map['nh3'] as num?)?.toDouble();
    final co      = (map['co'] as num?)?.toDouble();

    // Cek danger dulu
    if ((voc != null && voc >= 1.0) ||
        (h2s != null && h2s >= 10.0) ||
        (nh3 != null && nh3 >= 25.0) ||
        (co  != null && co  >= 35.0)) {
      status = _TrayStatus.danger;
    }
    // Cek warning
    else if ((voc != null && voc >= 0.5) ||
        (h2s != null && h2s >= 5.0) ||
        (nh3 != null && nh3 >= 10.0) ||
        (co  != null && co  >= 9.0)) {
      status = _TrayStatus.warning;
    }

    return _TrayItem(
      id:       map['id']?.toString() ?? '-',
      datetime: DateTime.parse(map['timestamp']).toLocal(),
      status:   status,
      gasValues: {
        'NH3':    (map['nh3']    as num?)?.toDouble(),
        'H2S':    (map['h2s']    as num?)?.toDouble(),
        'CH4':    (map['ch4']    as num?)?.toDouble(),
        'CO2':    (map['co2']    as num?)?.toDouble(),
        'VOC':    (map['voc']    as num?)?.toDouble(),
        'CO':     (map['co']     as num?)?.toDouble(),
        'H2':     (map['h2']     as num?)?.toDouble(),
      },
    );
  }

  String get formattedDate {
    final d = datetime;
    final months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agt','Sep','Okt','Nov','Des'];
    return '${d.day} ${months[d.month - 1]} ${d.year}, '
        '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')} WIB';
  }

  String get trayId => 'TRAY-${datetime.year}-${id.toString().padLeft(3, '0')}';
}

// ─── Page ─────────────────────────────────────────────────────────────────────
class TrayPage extends StatefulWidget {
  const TrayPage({super.key});

  @override
  State<TrayPage> createState() => _TrayPageState();
}

class _TrayPageState extends State<TrayPage> {
  int selectedTab  = 0;
  int currentPage  = 1;
  bool _isLoading  = true;
  String? _error;
  static const int itemsPerPage = 10;

  List<_TrayItem> _allItems = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    refreshNotifier.addListener(_onGlobalRefresh); // ← tambah
  }

  void _onGlobalRefresh() => _loadData(); // ← tambah

  @override
  void dispose() {
    refreshNotifier.removeListener(_onGlobalRefresh); // ← tambah
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await Supabase.instance.client
          .from('sensor_readings')
          .select()
          .order('timestamp', ascending: false)
          .limit(200);

      setState(() {
        _allItems  = (res as List).map((e) => _TrayItem.fromMap(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  List<_TrayItem> get _filtered {
    switch (selectedTab) {
      case 1: return _allItems.where((e) => e.status == _TrayStatus.safe).toList();
      case 2: return _allItems.where((e) => e.status == _TrayStatus.warning).toList();
      case 3: return _allItems.where((e) => e.status == _TrayStatus.danger).toList();
      default: return _allItems;
    }
  }

  int get _pageCount => (_filtered.length / itemsPerPage).ceil().clamp(1, 999);

  List<_TrayItem> get _pageItems {
    final start = (currentPage - 1) * itemsPerPage;
    final end   = (start + itemsPerPage).clamp(0, _filtered.length);
    return _filtered.sublist(start.clamp(0, _filtered.length), end);
  }

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
                height: 130,
                child: _Header(total: _allItems.length),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: _FilterTabs(
                  counts: [
                    _allItems.length,
                    _allItems.where((e) => e.status == _TrayStatus.safe).length,
                    _allItems.where((e) => e.status == _TrayStatus.warning).length,
                    _allItems.where((e) => e.status == _TrayStatus.danger).length,
                  ],
                  selectedIndex: selectedTab,
                  onSelected: (i) => setState(() { selectedTab = i; currentPage = 1; }),
                ),
              ),
            ),

            // ─── Loading / Error / Content ───────────────────────────────────
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text('Gagal memuat data', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: _loadData, child: const Text('Coba Lagi')),
                    ],
                  ),
                ),
              )
            else if (_filtered.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text('Tidak ada data', style: TextStyle(color: Colors.black45)),
                  ),
                )
              else ...[
                  SliverList.builder(
                    itemCount: _pageItems.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                      child: _TrayCard(item: _pageItems[index]),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
                      child: _Pagination(
                        pageCount: _pageCount,
                        current: currentPage,
                        onSelect: (p) => setState(() => currentPage = p),
                      ),
                    ),
                  ),
                ],

            const SliverToBoxAdapter(child: SizedBox(height: 92)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF10B981),
        onPressed: _loadData,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.total});
  final int total;
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
      padding: const EdgeInsets.fromLTRB(25, 30, 25, 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Manajemen Tray',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('$total Data Tersimpan',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}

// ─── Filter Tabs ──────────────────────────────────────────────────────────────
class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.counts, required this.selectedIndex, required this.onSelected});
  final List<int> counts;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const labels = ['Semua', 'Aman', 'Warning', 'Bahaya'];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 8))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(4, (i) => Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 14),
            child: _FilterChip(
              label: '${labels[i]} (${counts[i]})',
              selected: selectedIndex == i,
              onTap: () => onSelected(i),
            ),
          )),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!selected) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF10B981)]),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Color(0x3306B6D4), blurRadius: 12, spreadRadius: 1, offset: Offset(0, 4))],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 10))],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Baris atas: ID + Status + Tombol ───────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.trayId,
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black, fontSize: 15)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.access_time, size: 13, color: Colors.black45),
                      const SizedBox(width: 4),
                      Text(item.formattedDate,
                          style: const TextStyle(color: Colors.black54, fontSize: 12)),
                    ]),
                    const SizedBox(height: 8),
                    _StatusPill(status: item.status),
                  ],
                ),
              ),
              Column(children: [
                _SmallButton(label: 'Detail', color: const Color(0xFF0284C7), onTap: () => _showDetail(context)),
              ]),
            ],
          ),

          // ─── Baris bawah: ringkasan gas ──────────────────────────────────
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: item.gasValues.entries
                .where((e) => e.value != null)
                .map((e) => _GasChip(label: e.key, value: e.value!))
                .toList(),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.trayId, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 4),
            Text(item.formattedDate, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            _StatusPill(status: item.status),
            const SizedBox(height: 16),
            const Text('Detail Gas:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            ...item.gasValues.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                SizedBox(width: 70, child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600))),
                Text(e.value != null ? '${e.value!.toStringAsFixed(2)} ppm' : '-',
                    style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w700)),
              ]),
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _GasChip extends StatelessWidget {
  const _GasChip({required this.label, required this.value});
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Text('$label: ${value.toStringAsFixed(1)}',
          style: const TextStyle(fontSize: 11, color: Color(0xFF0369A1), fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Pagination ───────────────────────────────────────────────────────────────
class _Pagination extends StatelessWidget {
  const _Pagination({required this.pageCount, required this.current, required this.onSelect});
  final int pageCount;
  final int current;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    if (pageCount <= 1) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PageButton(icon: Icons.chevron_left, onTap: current > 1 ? () => onSelect(current - 1) : null),
          for (int i = 1; i <= pageCount; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _PageNumber(index: i, selected: i == current, onTap: () => onSelect(i)),
            ),
          _PageButton(icon: Icons.chevron_right, onTap: current < pageCount ? () => onSelect(current + 1) : null),
        ],
      ),
    );
  }
}

class _PageNumber extends StatelessWidget {
  const _PageNumber({required this.index, required this.selected, required this.onTap});
  final int index;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF06B6D4) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6))],
        ),
        alignment: Alignment.center,
        child: Text('$index', style: TextStyle(
            color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: Colors.white, shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6))],
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: onTap == null ? Colors.black26 : const Color(0xFF111827)),
      ),
    );
  }
}

// ─── Status Pill ──────────────────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final _TrayStatus status;
  @override
  Widget build(BuildContext context) {
    final Map<_TrayStatus, Map<String, dynamic>> styles = {
      _TrayStatus.safe:    {'bg': const Color(0xFFD1FAE5), 'fg': const Color(0xFF047857), 'text': 'Aman'},
      _TrayStatus.warning: {'bg': const Color(0xFFFDE68A), 'fg': const Color(0xFF92400E), 'text': 'Warning'},
      _TrayStatus.danger:  {'bg': const Color(0xFFFECACA), 'fg': const Color(0xFFB91C1C), 'text': 'Bahaya'},
    };
    final s = styles[status]!;
    return Container(
      decoration: BoxDecoration(color: s['bg'], borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(s['text'], style: TextStyle(color: s['fg'], fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

// ─── Small Button ─────────────────────────────────────────────────────────────
class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

// ─── Fixed Header Delegate ────────────────────────────────────────────────────
class _FixedHeaderDelegate extends SliverPersistentHeaderDelegate {
  _FixedHeaderDelegate({required this.child, required this.height});
  final Widget child;
  final double height;

  @override double get minExtent => height;
  @override double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
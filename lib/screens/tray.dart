import 'package:flutter/material.dart';

class TrayPage extends StatefulWidget {
  const TrayPage({super.key});

  @override
  State<TrayPage> createState() => _TrayPageState();
}

class _TrayPageState extends State<TrayPage> {
  int selectedTab = 0; // 0: Semua, 1: Aman, 2: Warning, 3: Bahaya
  int currentPage = 1;
  static const int itemsPerPage = 3;

  final List<_TrayItem> allItems = [
    _TrayItem(
      id: 'TRAY-2024-001',
      datetime: '15 Nov 2024, 13:28 WIB',
      status: _TrayStatus.safe,
      image: 'assets/images/sample_1.jpg',
    ),
    _TrayItem(
      id: 'TRAY-2024-002',
      datetime: '15 Nov 2024, 14:50 WIB',
      status: _TrayStatus.danger,
      image: 'assets/images/sample_1.jpg',
    ),
    _TrayItem(
      id: 'TRAY-2024-003',
      datetime: '15 Nov 2024, 9:21 WIB',
      status: _TrayStatus.danger,
      image: 'assets/images/sample_1.jpg',
    ),
    _TrayItem(
      id: 'TRAY-2024-004',
      datetime: '15 Nov 2024, 9:41 WIB',
      status: _TrayStatus.danger,
      image: 'assets/images/sample_1.jpg',
    ),
    _TrayItem(
      id: 'TRAY-2024-005',
      datetime: '15 Nov 2024, 11:33 WIB',
      status: _TrayStatus.warning,
      image: 'assets/images/sample_1.jpg',
    ),
  ];

  List<_TrayItem> get _filteredAll {
    switch (selectedTab) {
      case 1:
        return allItems.where((e) => e.status == _TrayStatus.safe).toList();
      case 2:
        return allItems.where((e) => e.status == _TrayStatus.warning).toList();
      case 3:
        return allItems.where((e) => e.status == _TrayStatus.danger).toList();
      default:
        return allItems;
    }
  }

  int get pageCount =>
      (_filteredAll.length / itemsPerPage).ceil().clamp(1, 999);

  List<_TrayItem> get filteredItems {
    final start = (currentPage - 1) * itemsPerPage;
    final end = (start + itemsPerPage).clamp(0, _filteredAll.length);
    return _filteredAll.sublist(start.clamp(0, _filteredAll.length), end);
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
                child: _Header(total: allItems.length),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 15, 0),
                child: _FilterTabs(
                  counts: [
                    allItems.length,
                    allItems.where((e) => e.status == _TrayStatus.safe).length,
                    allItems.where((e) => e.status == _TrayStatus.warning).length,
                    allItems.where((e) => e.status == _TrayStatus.danger).length,
                  ],
                  selectedIndex: selectedTab,
                  onSelected: (i) => setState(() {
                    selectedTab = i;
                    currentPage = 1;
                  }),
                ),
              ),
            ),
            SliverList.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: _TrayCard(item: item),
                );
              },
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
                child: _Pagination(
                  pageCount: pageCount,
                  current: currentPage,
                  onSelect: (p) => setState(() => currentPage = p),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 92)),
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
          Text(
            'Manajemen Tray',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '$total Tray Terdeteksi Hari Ini',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.counts,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<int> counts; // [Semua, Aman, Warning, Bahaya]
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: SingleChildScrollView(  // Menambahkan scrollable
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'Semua (${counts[0]})',
              selected: selectedIndex == 0,
              onTap: () => onSelected(0),
            ),
            const SizedBox(width: 14),
            _FilterChip(
              label: 'Aman (${counts[1]})',
              selected: selectedIndex == 1,
              onTap: () => onSelected(1),
            ),
            const SizedBox(width: 14),
            _FilterChip(
              label: 'Warning (${counts[2]})',
              selected: selectedIndex == 2,
              onTap: () => onSelected(2),
            ),
            const SizedBox(width: 14),
            _FilterChip(
              label: 'Bahaya (${counts[3]})',
              selected: selectedIndex == 3,
              onTap: () => onSelected(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});
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
          child: Text(label,
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.w700)),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF06B6D4), Color(0xFF10B981)]),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
              color: Color(0x3306B6D4),
              blurRadius: 12,
              spreadRadius: 1,
              offset: Offset(0, 4)),
        ],
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
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }
}

class _TrayCard extends StatelessWidget {
  const _TrayCard({required this.item});
  final _TrayItem item;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(item.image,
                width: 68, height: 68, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.id,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: Colors.black)),
                const SizedBox(height: 4),
                Text(item.datetime,
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 12)),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _StatusPill(status: item.status),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              _SmallButton(
                label: 'Lihat',
                color: const Color(0xFF0284C7),
                onTap: () {},
              ),
              const SizedBox(height: 8),
              _SmallButton(
                label: 'PDF',
                color: const Color(0xFF10B981),
                onTap: () {},
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.pageCount,
    required this.current,
    required this.onSelect,
  });

  final int pageCount;
  final int current;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    if (pageCount <= 1) return const SizedBox.shrink();
    final List<Widget> buttons = [];
    buttons.add(_PageButton(
      icon: Icons.chevron_left,
      onTap: current > 1 ? () => onSelect(current - 1) : null,
    ));
    for (int i = 1; i <= pageCount; i++) {
      buttons.add(_PageNumber(
          index: i, selected: i == current, onTap: () => onSelect(i)));
    }
    buttons.add(_PageButton(
      icon: Icons.chevron_right,
      onTap: current < pageCount ? () => onSelect(current + 1) : null,
    ));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final w in buttons)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: w),
        ],
      ),
    );
  }
}

class _PageNumber extends StatelessWidget {
  const _PageNumber(
      {required this.index, required this.selected, required this.onTap});
  final int index;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF06B6D4) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6))
          ],
        ),
        alignment: Alignment.center,
        child: Text('$index',
            style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w800)),
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
    final bool disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6))
          ],
        ),
        alignment: Alignment.center,
        child: Icon(icon,
            color: disabled ? Colors.black26 : const Color(0xFF111827)),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton(
      {required this.label, required this.color, required this.onTap});
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
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final _TrayStatus status;
  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String text;
    switch (status) {
      case _TrayStatus.safe:
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF047857);
        text = 'Aman';
        break;
      case _TrayStatus.warning:
        bg = const Color(0xFFFDE68A);
        fg = const Color(0xFF92400E);
        text = 'Warning';
        break;
      case _TrayStatus.danger:
        bg = const Color(0xFFFECACA);
        fg = const Color(0xFFB91C1C);
        text = 'Bahaya';
        break;
    }
    return Container(
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(text,
          style:
              TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

enum _TrayStatus { safe, warning, danger }

class _TrayItem {
  _TrayItem(
      {required this.id,
      required this.datetime,
      required this.status,
      required this.image});
  final String id;
  final String datetime;
  final _TrayStatus status;
  final String image;
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
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

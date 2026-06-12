part of roro_main;

// ─── Model ────────────────────────────────────────────────────────────────────

class RehabSession {
  const RehabSession({
    required this.startTime,
    required this.endTime,
  });

  final DateTime startTime;
  final DateTime endTime;

  Duration get duration => endTime.difference(startTime);

  String get durationLabel {
    final m = duration.inMinutes;
    final s = duration.inSeconds % 60;
    if (m == 0) return '${s}s';
    if (s == 0) return '${m} min';
    return '${m} min ${s}s';
  }

  String get dateLabel {
    final d = startTime.day.toString().padLeft(2, '0');
    final mo = _monthName(startTime.month);
    final h = startTime.hour.toString().padLeft(2, '0');
    final min = startTime.minute.toString().padLeft(2, '0');
    return '$mo $d  •  $h:$min';
  }

  static String _monthName(int m) {
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return m < names.length ? names[m] : '?';
  }
}

// ─── Session calculator ───────────────────────────────────────────────────────

List<RehabSession> _calculateSessions(List<ImuHistoryEntry> history) {
  // Urutkan ascending berdasarkan timestamp
  final sorted = [...history]..sort((a, b) {
      final at = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(a.deviceMillis ?? 0);
      final bt = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(b.deviceMillis ?? 0);
      return at.compareTo(bt);
    });

  final sessions = <RehabSession>[];
  DateTime? walkStart;
  const minDuration = Duration(seconds: 30);

  for (final entry in sorted) {
    final t = entry.timestamp ??
        (entry.deviceMillis != null
            ? DateTime.fromMillisecondsSinceEpoch(entry.deviceMillis!)
            : null);
    if (t == null) continue;

    if (entry.status == ImuStatus.jalan && walkStart == null) {
      walkStart = t;
    } else if (entry.status != ImuStatus.jalan && walkStart != null) {
      final session = RehabSession(startTime: walkStart!, endTime: t);
      if (session.duration >= minDuration) {
        sessions.add(session);
      }
      walkStart = null;
    }
  }

  // Sesi yang belum ditutup — gunakan waktu sekarang sebagai penutup sementara
  if (walkStart != null) {
    final now = DateTime.now();
    final session = RehabSession(startTime: walkStart!, endTime: now);
    if (session.duration >= minDuration) {
      sessions.add(session);
    }
  }

  // Terbaru di atas
  sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
  return sessions;
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class SessionHistoryPage extends StatefulWidget {
  const SessionHistoryPage({super.key, required this.rollatorRepository});

  final RollatorRepository rollatorRepository;

  @override
  State<SessionHistoryPage> createState() => _SessionHistoryPageState();
}

class _SessionHistoryPageState extends State<SessionHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedMonth = 0;
  int _selectedDay = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RehabSession> _applyFilters(List<RehabSession> sessions) {
    return sessions.where((s) {
      if (_selectedMonth != 0 && s.startTime.month != _selectedMonth) return false;
      if (_selectedDay != 0 && s.startTime.weekday != _selectedDay) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!s.dateLabel.toLowerCase().contains(q) &&
            !s.durationLabel.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Widget _chip({
    required int code,
    required String label,
    required int selected,
    required void Function(int) onSelect,
  }) {
    final isSelected = selected == code;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => onSelect(isSelected ? 0 : code)),
      selectedColor: const Color(0xFFDC2626),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF4B5563),
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFFDC2626) : const Color(0xFFE5E7EB),
        ),
      ),
      showCheckmark: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: Text(
          'Session History',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF111827),
              ),
        ),
        backgroundColor: const Color(0xFFF6F8FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF111827)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7F9FF), Color(0xFFF2F4F8)],
          ),
        ),
        child: StreamBuilder<List<ImuHistoryEntry>>(
          stream: widget.rollatorRepository.watchImuHistory(_kSosDocumentId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allHistory = snapshot.data ?? [];
            final allSessions = _calculateSessions(allHistory);
            final filtered = _applyFilters(allSessions);

            // Kumpulkan bulan-bulan yang ada untuk filter dinamis
            final months = allSessions
                .map((s) => s.startTime.month)
                .toSet()
                .toList()
              ..sort();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) =>
                        setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Cari sesi berdasarkan tanggal...',
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: Color(0xFF6B7280)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  color: Color(0xFF6B7280)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: Color(0xFFDC2626), width: 1.5),
                      ),
                    ),
                  ),
                ),
                // Summary
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Row(
                    children: [
                      _SummaryChip(
                        icon: Icons.directions_walk_rounded,
                        label: '${allSessions.length} Sesi',
                        color: const Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 8),
                      _SummaryChip(
                        icon: Icons.timer_rounded,
                        label: _totalDurationLabel(allSessions),
                        color: const Color(0xFF059669),
                      ),
                    ],
                  ),
                ),
                if (months.isNotEmpty) ...[
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 16, top: 4, bottom: 4),
                    child: Text(
                      'FILTER BULAN',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF77829A),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        _chip(
                          code: 0,
                          label: 'Semua',
                          selected: _selectedMonth,
                          onSelect: (v) => _selectedMonth = v,
                        ),
                        for (final m in months) ...[
                          const SizedBox(width: 8),
                          _chip(
                            code: m,
                            label: RehabSession._monthName(m),
                            selected: _selectedMonth,
                            onSelect: (v) => _selectedMonth = v,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                Padding(
                  padding:
                      const EdgeInsets.only(left: 16, top: 8, bottom: 4),
                  child: Text(
                    'FILTER HARI',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF77829A),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      _chip(code: 0, label: 'Semua', selected: _selectedDay, onSelect: (v) => _selectedDay = v),
                      const SizedBox(width: 8),
                      _chip(code: 1, label: 'Sen', selected: _selectedDay, onSelect: (v) => _selectedDay = v),
                      const SizedBox(width: 8),
                      _chip(code: 2, label: 'Sel', selected: _selectedDay, onSelect: (v) => _selectedDay = v),
                      const SizedBox(width: 8),
                      _chip(code: 3, label: 'Rab', selected: _selectedDay, onSelect: (v) => _selectedDay = v),
                      const SizedBox(width: 8),
                      _chip(code: 4, label: 'Kam', selected: _selectedDay, onSelect: (v) => _selectedDay = v),
                      const SizedBox(width: 8),
                      _chip(code: 5, label: 'Jum', selected: _selectedDay, onSelect: (v) => _selectedDay = v),
                      const SizedBox(width: 8),
                      _chip(code: 6, label: 'Sab', selected: _selectedDay, onSelect: (v) => _selectedDay = v),
                      const SizedBox(width: 8),
                      _chip(code: 7, label: 'Min', selected: _selectedDay, onSelect: (v) => _selectedDay = v),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmpty(allSessions.isEmpty)
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 4, 16, 40),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return _SessionCard(
                                session: filtered[index]);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _totalDurationLabel(List<RehabSession> sessions) {
    if (sessions.isEmpty) return '0 min';
    final total = sessions.fold(
        Duration.zero, (acc, s) => acc + s.duration);
    final h = total.inHours;
    final m = total.inMinutes % 60;
    if (h > 0) return '${h}j ${m}m total';
    return '${m} min total';
  }

  Widget _buildEmpty(bool noData) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 72,
              width: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                noData
                    ? Icons.sensors_off_rounded
                    : Icons.search_off_rounded,
                size: 36,
                color: const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              noData ? 'Belum ada data sesi' : 'Sesi tidak ditemukan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              noData
                  ? 'Data akan muncul setelah rollator digunakan dan IMU mengirim riwayat.'
                  : 'Coba ubah filter atau kata kunci pencarian.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Session card ─────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final RehabSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withOpacity(0.08),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.directions_walk_rounded,
              color: Color(0xFFDC2626),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sesi Berjalan',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF111827),
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  session.dateLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              session.durationLabel,
              style: const TextStyle(
                color: Color(0xFF059669),
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary chip ─────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

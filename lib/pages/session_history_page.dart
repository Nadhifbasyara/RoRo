part of roro_main;

class RehabSession {
  final String title;
  final String duration;
  final String dateLabel;
  final DateTime dateTime;
  final String category;

  const RehabSession({
    required this.title,
    required this.duration,
    required this.dateLabel,
    required this.dateTime,
    required this.category,
  });
}

class SessionHistoryPage extends StatefulWidget {
  const SessionHistoryPage({super.key});

  @override
  State<SessionHistoryPage> createState() => _SessionHistoryPageState();
}

class _SessionHistoryPageState extends State<SessionHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedMonth = 0; // 0: All, 9: Sept, 10: Oct
  int _selectedDay = 0;   // 0: All, 1: Mon ... 7: Sun

  final List<RehabSession> _allSessions = [
    RehabSession(
      title: 'Afternoon Walk',
      duration: '15 mins',
      dateLabel: 'Oct 24 • 02:30 PM',
      dateTime: DateTime(2024, 10, 24, 14, 30),
      category: 'Walk',
    ),
    RehabSession(
      title: 'Morning Rehab',
      duration: '10 mins',
      dateLabel: 'Oct 24 • 09:15 AM',
      dateTime: DateTime(2024, 10, 24, 9, 15),
      category: 'Rehab',
    ),
    RehabSession(
      title: 'Garden Stroll',
      duration: '25 mins',
      dateLabel: 'Oct 23 • 04:45 PM',
      dateTime: DateTime(2024, 10, 23, 16, 45),
      category: 'Stroll',
    ),
    RehabSession(
      title: 'Evening Walk',
      duration: '20 mins',
      dateLabel: 'Oct 22 • 06:15 PM',
      dateTime: DateTime(2024, 10, 22, 18, 15),
      category: 'Walk',
    ),
    RehabSession(
      title: 'Lunch Walk',
      duration: '12 mins',
      dateLabel: 'Oct 22 • 12:45 PM',
      dateTime: DateTime(2024, 10, 22, 12, 45),
      category: 'Walk',
    ),
    RehabSession(
      title: 'Morning Rehab',
      duration: '15 mins',
      dateLabel: 'Oct 22 • 09:00 AM',
      dateTime: DateTime(2024, 10, 22, 9, 0),
      category: 'Rehab',
    ),
    RehabSession(
      title: 'Afternoon Stroll',
      duration: '30 mins',
      dateLabel: 'Oct 21 • 03:30 PM',
      dateTime: DateTime(2024, 10, 21, 15, 30),
      category: 'Stroll',
    ),
    RehabSession(
      title: 'Morning Walk',
      duration: '10 mins',
      dateLabel: 'Oct 20 • 08:45 AM',
      dateTime: DateTime(2024, 10, 20, 8, 45),
      category: 'Walk',
    ),
    RehabSession(
      title: 'Sunday Walk',
      duration: '40 mins',
      dateLabel: 'Oct 19 • 10:00 AM',
      dateTime: DateTime(2024, 10, 19, 10, 0),
      category: 'Walk',
    ),
    RehabSession(
      title: 'Evening Rehab',
      duration: '18 mins',
      dateLabel: 'Oct 18 • 05:00 PM',
      dateTime: DateTime(2024, 10, 18, 17, 0),
      category: 'Rehab',
    ),
    RehabSession(
      title: 'Morning Walk',
      duration: '12 mins',
      dateLabel: 'Oct 18 • 09:30 AM',
      dateTime: DateTime(2024, 10, 18, 9, 30),
      category: 'Walk',
    ),
    RehabSession(
      title: 'Afternoon Walk',
      duration: '15 mins',
      dateLabel: 'Sep 28 • 03:00 PM',
      dateTime: DateTime(2024, 9, 28, 15, 0),
      category: 'Walk',
    ),
    RehabSession(
      title: 'Morning Rehab',
      duration: '10 mins',
      dateLabel: 'Sep 27 • 09:00 AM',
      dateTime: DateTime(2024, 9, 27, 9, 0),
      category: 'Rehab',
    ),
    RehabSession(
      title: 'Garden Stroll',
      duration: '20 mins',
      dateLabel: 'Sep 25 • 04:00 PM',
      dateTime: DateTime(2024, 9, 25, 16, 0),
      category: 'Stroll',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RehabSession> get _filteredSessions {
    return _allSessions.where((session) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = session.title.toLowerCase().contains(query);
        final matchesCategory = session.category.toLowerCase().contains(query);
        if (!matchesTitle && !matchesCategory) {
          return false;
        }
      }

      if (_selectedMonth != 0 && session.dateTime.month != _selectedMonth) {
        return false;
      }

      if (_selectedDay != 0 && session.dateTime.weekday != _selectedDay) {
        return false;
      }

      return true;
    }).toList();
  }

  Widget _buildMonthChip(int monthCode, String label) {
    final isSelected = _selectedMonth == monthCode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedMonth = monthCode;
        });
      },
      selectedColor: const Color(0xFFDC2626),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF4B5563),
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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

  Widget _buildDayChip(int dayCode, String label) {
    final isSelected = _selectedDay == dayCode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedDay = dayCode;
        });
      },
      selectedColor: const Color(0xFFDC2626),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF4B5563),
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 72,
              width: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 36,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No sessions found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or search keywords.',
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF111827)),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search rehab session...',
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6B7280)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Color(0xFF6B7280)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
              child: Text(
                'FILTER BY MONTH',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF77829A),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _buildMonthChip(0, 'All Months'),
                  const SizedBox(width: 8),
                  _buildMonthChip(10, 'October'),
                  const SizedBox(width: 8),
                  _buildMonthChip(9, 'September'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
              child: Text(
                'FILTER BY DAY',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF77829A),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _buildDayChip(0, 'All Days'),
                  const SizedBox(width: 8),
                  _buildDayChip(1, 'Mon'),
                  const SizedBox(width: 8),
                  _buildDayChip(2, 'Tue'),
                  const SizedBox(width: 8),
                  _buildDayChip(3, 'Wed'),
                  const SizedBox(width: 8),
                  _buildDayChip(4, 'Thu'),
                  const SizedBox(width: 8),
                  _buildDayChip(5, 'Fri'),
                  const SizedBox(width: 8),
                  _buildDayChip(6, 'Sat'),
                  const SizedBox(width: 8),
                  _buildDayChip(7, 'Sun'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredSessions.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      key: const ValueKey('session_history_list'),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                      itemCount: _filteredSessions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final session = _filteredSessions[index];
                        return Container(
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
                          child: _SessionRow(
                            title: session.title,
                            duration: session.duration,
                            date: session.dateLabel,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

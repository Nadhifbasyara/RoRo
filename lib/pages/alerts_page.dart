part of roro_main;

// Document ID spesifik yang ditetapkan tim hardware
const _kSosDocumentId = '471grmOw38iBx5v5m9uC';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key, required this.colorScheme, required this.rollatorRepository});

  final ColorScheme colorScheme;
  final RollatorRepository rollatorRepository;

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> with WidgetsBindingObserver {
  StreamSubscription<bool>? _sosSub;
  bool _sosActive = false;
  DateTime? _sosTriggeredAt;
  bool _sosDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startSosListener();
  }

  void _startSosListener() {
    // Selalu listen dari document ID spesifik
    _sosSub = widget.rollatorRepository.watchSos(_kSosDocumentId).listen((isActive) {
      if (!mounted) return;
      setState(() {
        _sosActive = isActive;
        if (isActive) _sosTriggeredAt = DateTime.now();
      });
      if (isActive && !_sosDialogShown) {
        _sosDialogShown = true;
        _triggerSosAlert();
      }
      if (!isActive) {
        _sosDialogShown = false;
        Vibration.cancel();
      }
    });
  }

  void _triggerSosAlert() {
    // Getaran panjang berulang
    Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500], repeat: 2);
    // Langsung buka WhatsApp call otomatis
    _callFamily(auto: true);
    // Tampilkan dialog
    _showSosDialog();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sosSub?.cancel();
    Vibration.cancel();
    super.dispose();
  }

  void _showSosDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (ctx) => _SosAlertDialog(
        triggeredAt: _sosTriggeredAt,
        onCallFamily: () {
          Navigator.of(ctx).pop();
          _callFamily();
        },
        onDismiss: () {
          Navigator.of(ctx).pop();
          Vibration.cancel();
        },
      ),
    );
  }

  Future<void> _clearSos() async {
    await widget.rollatorRepository.clearSos(_kSosDocumentId);
    Vibration.cancel();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SOS telah dihentikan.')),
      );
    }
  }

  Future<void> _callFamily({bool auto = false}) async {
    final contact = await EmergencyContactStore.load();

    if (contact == null || contact.phone.isEmpty) {
      if (!mounted) return;
      // Kalau dipanggil otomatis saat SOS, jangan tampilkan dialog —
      // user sudah lihat di SOS screen. Hanya tampilkan kalau manual.
      if (!auto) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Kontak Darurat Belum Diatur'),
            content: const Text(
              'Silakan tambahkan nomor kontak darurat di halaman Profile terlebih dahulu.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Normalisasi nomor ke format internasional untuk wa.me
    // 08xxx → 628xxx, +628xxx → 628xxx, 628xxx → tetap
    String normalized = contact.phone.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (normalized.startsWith('0')) {
      normalized = '62${normalized.substring(1)}';
    } else if (normalized.startsWith('+')) {
      normalized = normalized.substring(1);
    }

    // wa.me/<nomor> — membuka WhatsApp dan langsung ke chat/call
    final uri = Uri.parse('https://wa.me/$normalized');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      // Fallback ke dialer biasa jika WhatsApp tidak terinstall
      final telUri = Uri(scheme: 'tel', path: contact.phone);
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat menghubungi ${contact.phone}')),
        );
      }
    }
  }

  void _openSosHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SosHistoryPage(rollatorRepository: widget.rollatorRepository),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _sosActive
              ? [const Color(0xFFEF4444), const Color(0xFFB91C1C)]
              : [const Color(0xFFF7F9FF), const Color(0xFFF2F4F8)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: _sosActive ? _buildSosActiveView() : _buildNormalView(),
      ),
    );
  }

  // ─── SOS AKTIF: full-screen darurat ───────────────────────────────────────

  Widget _buildSosActiveView() {
    final timeStr = _sosTriggeredAt != null
        ? '${_sosTriggeredAt!.hour.toString().padLeft(2, '0')}:${_sosTriggeredAt!.minute.toString().padLeft(2, '0')}:${_sosTriggeredAt!.second.toString().padLeft(2, '0')}'
        : '--:--:--';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _TopBar(colorScheme: const ColorScheme.dark()),
          const SizedBox(height: 32),
          // Pulsing SOS icon
          Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white54, width: 3),
            ),
            child: const Icon(Icons.sos_rounded, color: Colors.white, size: 72),
          ),
          const SizedBox(height: 28),
          const Text(
            'SOS DARURAT AKTIF',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tombol SOS ditekan pada $timeStr',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pengguna membutuhkan bantuan segera.\nPerangkat RoRo mengirimkan sinyal darurat.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _callFamily(),
              icon: const Icon(Icons.call, size: 22),
              label: const Text('HUBUNGI KELUARGA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFDC2626),
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _clearSos,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
              label: const Text('KONDISI AMAN — HENTIKAN SOS', style: TextStyle(fontWeight: FontWeight.w900)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white60, width: 1.5),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 32),
          InkWell(
            onTap: _openSosHistory,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_rounded, color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Text('Lihat Riwayat SOS', style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── NORMAL: kondisi aman ─────────────────────────────────────────────────

  Widget _buildNormalView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopBar(colorScheme: widget.colorScheme),
          const SizedBox(height: 18),
          // Status aman
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF6EE7B7)),
            ),
            child: Row(
              children: [
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'KONDISI AMAN',
                        style: TextStyle(
                          color: Color(0xFF065F46),
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tidak ada aktivitas SOS terdeteksi saat ini.',
                        style: TextStyle(color: const Color(0xFF059669).withOpacity(0.8), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Tombol lihat riwayat
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openSosHistory,
              icon: const Icon(Icons.history_rounded),
              label: const Text('Lihat Riwayat SOS', style: TextStyle(fontWeight: FontWeight.w800)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1D4ED8),
                side: const BorderSide(color: Color(0xFF1D4ED8)),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Critical Alerts', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'ALL CLEAR',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CriticalAlertTile(onCheck: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Checking on patient...')),
            );
          }),
          const SizedBox(height: 22),
          Text('Safety Notifications', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          const _SafetyToggle(title: 'Push Alerts', subtitle: 'Immediate mobile notifications', initialValue: true),
          const SizedBox(height: 10),
          const _SafetyToggle(title: 'Critical Sounds', subtitle: 'Override silent mode for SOS', initialValue: true),
          const SizedBox(height: 10),
          const _SafetyToggle(title: 'Family Sync', subtitle: 'Alert emergency contacts', initialValue: false),
        ],
      ),
    );
  }
}

// ─── SOS Alert Dialog ─────────────────────────────────────────────────────────

class _SosAlertDialog extends StatelessWidget {
  const _SosAlertDialog({required this.onCallFamily, required this.onDismiss, this.triggeredAt});

  final VoidCallback onCallFamily;
  final VoidCallback onDismiss;
  final DateTime? triggeredAt;

  @override
  Widget build(BuildContext context) {
    final timeStr = triggeredAt != null
        ? '${triggeredAt!.hour.toString().padLeft(2, '0')}:${triggeredAt!.minute.toString().padLeft(2, '0')}:${triggeredAt!.second.toString().padLeft(2, '0')}'
        : null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEF4444), Color(0xFF991B1B)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 32, offset: const Offset(0, 16)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.sos_rounded, color: Colors.white, size: 42),
            ),
            const SizedBox(height: 16),
            const Text(
              'SOS DARURAT AKTIF',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, height: 1.2),
            ),
            if (timeStr != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Pukul $timeStr',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Pengguna membutuhkan bantuan segera.\nPerangkat RoRo mengirimkan sinyal darurat.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onCallFamily,
                icon: const Icon(Icons.call, size: 20),
                label: const Text('HUBUNGI KELUARGA', style: TextStyle(fontWeight: FontWeight.w900)),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFDC2626),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onDismiss,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('TUTUP', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SOS History Page ─────────────────────────────────────────────────────────

class _SosHistoryPage extends StatelessWidget {
  const _SosHistoryPage({required this.rollatorRepository});

  final RollatorRepository rollatorRepository;

  String _formatTimestamp(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final mon = dt.month.toString().padLeft(2, '0');
    return '[$h:$m:$s] — $day/$mon/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FF),
      appBar: AppBar(
        title: const Text('Riwayat SOS', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: StreamBuilder<List<SosHistoryEntry>>(
        stream: rollatorRepository.watchSosHistory(_kSosDocumentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data ?? [];

          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat SOS',
                    style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isActive = entry.sos;
              final timeStr = entry.timestamp != null
                  ? _formatTimestamp(entry.timestamp!)
                  : 'Waktu tidak tersedia';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFFFF5F5) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFFEF4444).withOpacity(0.35)
                        : const Color(0xFFE5E7EB),
                  ),
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
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFEF4444).withOpacity(0.1)
                            : const Color(0xFF10B981).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isActive ? Icons.sos_rounded : Icons.check_circle_rounded,
                        color: isActive ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isActive ? 'SOS AKTIF' : 'SOS NONAKTIF',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: isActive ? const Color(0xFFDC2626) : const Color(0xFF059669),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            timeStr,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Supporting widgets ───────────────────────────────────────────────────────

class _CriticalAlertTile extends StatelessWidget {
  const _CriticalAlertTile({required this.onCheck});

  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(color: const Color(0xFFFCECEA), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.elderly, color: Color(0xFFEF4444)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fall Detected', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text('IMU sensors triggered a high-impact event.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onCheck,
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1550D4)),
              child: const Text('Check on Patient'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyToggle extends StatefulWidget {
  const _SafetyToggle({required this.title, required this.subtitle, required this.initialValue});

  final String title;
  final String subtitle;
  final bool initialValue;

  @override
  State<_SafetyToggle> createState() => _SafetyToggleState();
}

class _SafetyToggleState extends State<_SafetyToggle> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(color: const Color(0xFFF8FAFF), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1550D4)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(widget.subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280))),
              ],
            ),
          ),
          Switch.adaptive(value: _value, onChanged: (v) => setState(() => _value = v), activeColor: const Color(0xFF1550D4)),
        ],
      ),
    );
  }
}

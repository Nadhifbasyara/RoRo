part of roro_main;

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key, required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF7F9FF), Color(0xFFF2F4F8)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(colorScheme: colorScheme),
              const SizedBox(height: 18),
              _EmergencySosCard(onCall: () => _callEmergency(context), onStop: () => _stopSos(context)),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Critical Alerts', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('ACTIVE NOW', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xFFD14343), fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _CriticalAlertTile(onCheck: () => _checkOnPatient(context)),
              const SizedBox(height: 18),
              Text('Emergency Event Log', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              _EventLogItem(timeLabel: '10:15 AM', title: 'Fall detected', subtitle: 'Hallway sensor triggered high impact'),
              const SizedBox(height: 10),
              _EventLogItem(timeLabel: '09:30 PM', title: 'SOS Button pressed', subtitle: 'Manual activation by user'),
              const SizedBox(height: 10),
              _EventLogItem(timeLabel: 'Yesterday', title: 'Low Battery Warning', subtitle: 'Device reached 15% charge'),
              const SizedBox(height: 22),
              Text('Safety Notifications', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              _SafetyToggle(title: 'Push Alerts', subtitle: 'Immediate mobile notifications', initialValue: true),
              const SizedBox(height: 10),
              _SafetyToggle(title: 'Critical Sounds', subtitle: 'Override silent mode for SOS', initialValue: true),
              const SizedBox(height: 10),
              _SafetyToggle(title: 'Family Sync', subtitle: 'Alert emergency contacts', initialValue: false),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  static void _callEmergency(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Call Emergency'),
        content: const Text('Dialing emergency services...'),
        actions: [
          FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  static void _stopSos(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop SOS'),
        content: const Text('SOS has been stopped.'),
        actions: [
          FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  static void _checkOnPatient(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checking on patient...')));
  }
}

class _EmergencySosCard extends StatelessWidget {
  const _EmergencySosCard({required this.onCall, required this.onStop});

  final VoidCallback onCall;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFB91C1C)]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text('EMERGENCY\nSOS', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Physical SOS button was pressed on the RoRo device.\nHelp is requested immediately.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.95))),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCall,
            icon: const Icon(Icons.call, color: Color(0xFF7C3AED)),
            label: const Text('CALL 911'),
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF7C3AED), minimumSize: const Size.fromHeight(48)),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onStop,
            style: OutlinedButton.styleFrom(backgroundColor: const Color(0xFFFFF1F1), foregroundColor: const Color(0xFF7C3AED), minimumSize: const Size.fromHeight(48)),
            child: const Text('STOP SOS'),
          ),
        ],
      ),
    );
  }
}

class _CriticalAlertTile extends StatelessWidget {
  const _CriticalAlertTile({required this.onCheck});

  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 18, offset: const Offset(0, 10))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(height: 46, width: 46, decoration: BoxDecoration(color: const Color(0xFFFCECEA), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.elderly, color: Color(0xFFEF4444))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Fall Detected', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text('IMU sensors triggered a high-impact event at 10:15 AM. Device is stationary.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280))),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: onCheck, style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1550D4)), child: const Text('Check on Patient'))),
        ],
      ),
    );
  }
}

class _EventLogItem extends StatelessWidget {
  const _EventLogItem({required this.timeLabel, required this.title, required this.subtitle});

  final String timeLabel;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 6))]),
      child: Row(
        children: [
          Column(
            children: [
              Text(timeLabel, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xFF6B7280))),
              const SizedBox(height: 6),
              Container(height: 10, width: 10, decoration: BoxDecoration(color: const Color(0xFFEF4444), shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 6), Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280)))])),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFC5CCD8)),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 6))]),
      child: Row(
        children: [
          Container(height: 44, width: 44, decoration: BoxDecoration(color: const Color(0xFFF8FAFF), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1550D4))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 6), Text(widget.subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280)))])),
          Switch.adaptive(value: _value, onChanged: (v) => setState(() => _value = v), activeColor: const Color(0xFF1550D4)),
        ],
      ),
    );
  }
}

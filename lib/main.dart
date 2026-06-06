library roro_main;

import 'dart:math';
import 'dart:typed_data';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'data/distance_repository.dart';
import 'data/rollator_firmware_client.dart';
import 'data/rollator_repository.dart';
import 'data/rollator_session_store.dart';
import 'firebase_options.dart';
import 'package:vibration/vibration.dart';

part 'pages/dashboard_page.dart';
part 'pages/firmware_provisioning_page.dart';
part 'pages/login_page.dart';
part 'pages/tracker_page.dart';
part 'pages/profile_page.dart';
part 'pages/alerts_page.dart';
part 'pages/session_history_page.dart';
part 'pages/education_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MyApp(
      distanceRepository: FirebaseDistanceRepository(),
      rollatorRepository: FirebaseRollatorRepository(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.distanceRepository, this.rollatorRepository});

  final DistanceRepository? distanceRepository;
  final RollatorRepository? rollatorRepository;

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0F4FDB),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF6F8FC),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RoRo Dashboard',
      theme: baseTheme.copyWith(
        textTheme: GoogleFonts.manropeTextTheme(baseTheme.textTheme),
      ),
      home: SessionGate(
        distanceRepository:
            distanceRepository ?? const DemoDistanceRepository(),
        rollatorRepository:
            rollatorRepository ?? const DemoRollatorRepository(),
      ),
    );
  }
}

class SessionGate extends StatefulWidget {
  const SessionGate({
    super.key,
    required this.distanceRepository,
    required this.rollatorRepository,
  });

  final DistanceRepository distanceRepository;
  final RollatorRepository rollatorRepository;

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late final Future<bool> _hasSessionFuture = _loadSession();

  Future<bool> _loadSession() async {
    return RollatorSessionStore.hasActiveSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasSessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final shouldOpenDashboard = snapshot.data == true;
        if (shouldOpenDashboard) {
          return DashboardPage(
            distanceRepository: widget.distanceRepository,
            rollatorRepository: widget.rollatorRepository,
          );
        }

        return LoginPage(
          distanceRepository: widget.distanceRepository,
          rollatorRepository: widget.rollatorRepository,
        );
      },
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.distanceRepository,
    required this.rollatorRepository,
  });

  final DistanceRepository distanceRepository;
  final RollatorRepository rollatorRepository;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  void _handleTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final pages = [
      DashboardHome(
        distanceRepository: widget.distanceRepository,
        colorScheme: colorScheme,
      ),
      TrackerPage(
        distanceRepository: widget.distanceRepository,
        colorScheme: colorScheme,
      ),
      AlertsPage(colorScheme: colorScheme, rollatorRepository: widget.rollatorRepository),
      EducationPage(colorScheme: colorScheme),
      ProfilePage(
        colorScheme: colorScheme,
        rollatorRepository: widget.rollatorRepository,
        onSignOut: () async {
          final navigator = Navigator.of(context);
          final activeRollatorCode =
              await RollatorSessionStore.loadRollatorCode();
          if (activeRollatorCode != null) {
            try {
              await widget.rollatorRepository.unlinkCurrentUserFromRollator(
                activeRollatorCode,
              );
            } catch (_) {
              // Keep sign-out resilient even if unlink fails.
            }
          }
          await RollatorSessionStore.clear();
          await FirebaseAuth.instance.signOut();
          if (!mounted) {
            return;
          }
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => LoginPage(
                distanceRepository: widget.distanceRepository,
                rollatorRepository: widget.rollatorRepository,
              ),
            ),
            (_) => false,
          );
        },
        onReconfigureWifi: () async {
          final messenger = ScaffoldMessenger.of(context);
          final navigator = Navigator.of(context);
          final activeRollatorCode =
              await RollatorSessionStore.loadRollatorCode();
          if (!mounted) {
            return;
          }

          if (activeRollatorCode == null) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text(
                  'Tidak ada rollator aktif. Scan QR dulu dari halaman login.',
                ),
              ),
            );
            return;
          }

          navigator.push(
            MaterialPageRoute(
              builder: (_) => FirmwareProvisioningPage(
                rollatorRepository: widget.rollatorRepository,
                initialRollatorCode: activeRollatorCode,
              ),
            ),
          );
        },
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: _selectedIndex,
        onTabSelected: _handleTabSelected,
      ),
    );
  }
}

class _DistanceMetricCard extends StatelessWidget {
  const _DistanceMetricCard({required this.distanceRepository});

  final DistanceRepository distanceRepository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: distanceRepository.watchDistanceTodayMeters(),
      initialData: 1240,
      builder: (context, snapshot) {
        final meters = snapshot.data ?? 0;
        return _MetricCard(
          icon: Icons.route_rounded,
          accent: const Color(0xFF1E5BFF),
          title: 'DISTANCE TODAY',
          value: _formatThousands(meters),
          suffix: 'Meters',
        );
      },
    );
  }
}

class _WalkingTimeMetricCard extends StatelessWidget {
  const _WalkingTimeMetricCard({required this.distanceRepository});

  final DistanceRepository distanceRepository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: distanceRepository.watchWalkingTimeMinutes(),
      initialData: 42,
      builder: (context, snapshot) {
        final minutes = snapshot.data ?? 0;
        return _MetricCard(
          icon: Icons.timer_rounded,
          accent: const Color(0xFF3B82F6),
          title: 'WALKING TIME',
          value: _formatThousands(minutes),
          suffix: 'Minutes',
        );
      },
    );
  }
}

class _FireStreakCard extends StatelessWidget {
  const _FireStreakCard({required this.distanceRepository});

  final DistanceRepository distanceRepository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: distanceRepository.watchHasWalkedToday(),
      initialData: true,
      builder: (context, walkedSnapshot) {
        final hasWalkedToday = walkedSnapshot.data ?? false;
        return StreamBuilder<int>(
          stream: distanceRepository.watchWalkStreakDays(),
          initialData: hasWalkedToday ? 1 : 0,
          builder: (context, streakSnapshot) {
            final streakDays = streakSnapshot.data ?? 0;
            final background = hasWalkedToday
                ? const [Color(0xFFEF4444), Color(0xFFF97316)]
                : const [Color(0xFF9CA3AF), Color(0xFF6B7280)];
            final title = hasWalkedToday
                ? 'Streak Aman Hari Ini'
                : 'Streak Hampir Putus';
            final subtitle = hasWalkedToday
                ? 'Pasien sudah jalan, streak tetap lanjut.'
                : 'Belum ada jalan hari ini, ayo jaga streak.';
            final buttonLabel = hasWalkedToday
                ? 'Sudah Ditandai'
                : 'Saya Sudah Jalan';

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: background,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: background.first.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1600),
                    tween: Tween(begin: 0.92, end: 1.08),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FIRE STREAK',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Colors.white.withOpacity(0.95),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$streakDays Hari',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withOpacity(0.92),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 36,
                          child: FilledButton.icon(
                            onPressed: hasWalkedToday
                                ? null
                                : () async {
                                    try {
                                      await distanceRepository
                                          .markWalkedToday();
                                      if (!context.mounted) {
                                        return;
                                      }
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Mantap, jalan hari ini sudah ditandai.',
                                          ),
                                        ),
                                      );
                                    } catch (_) {
                                      if (!context.mounted) {
                                        return;
                                      }
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Gagal menandai jalan hari ini. Coba lagi.',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: hasWalkedToday
                                  ? const Color(0xFF6B7280)
                                  : const Color(0xFFDC2626),
                              disabledBackgroundColor: Colors.white.withOpacity(
                                0.85,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            icon: Icon(
                              hasWalkedToday
                                  ? Icons.check_circle_rounded
                                  : Icons.touch_app_rounded,
                              size: 18,
                            ),
                            label: Text(buttonLabel),
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
    );
  }
}

String _formatThousands(int value) {
  return value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Row(
          children: [
            Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.spa_rounded,
                color: colorScheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'RoRo',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 58,
                width: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFF151A28),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.monitor_heart_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  height: 16,
                  width: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF17B26A),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Albert's RoRo",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.memory_rounded,
                      color: colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ESP32: Online',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF4B5563),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return const _ActionButton(
      label: 'Emergency SOS',
      icon: Icons.warning_amber_rounded,
      background: Color(0xFFDC2626),
      foreground: Colors.white,
      borderColor: Color(0xFFDC2626),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.borderColor,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (background != Colors.white)
            BoxShadow(
              color: const Color(0xFF1550D4).withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foreground, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.value,
    required this.suffix,
    this.badgeText,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String value;
  final String suffix;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9FBF3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badgeText!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF17B26A),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFF4B5563),
              letterSpacing: 1.4,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Text(
                  suffix,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OperatingModeCard extends StatelessWidget {
  const _OperatingModeCard({required this.distanceRepository});

  final DistanceRepository distanceRepository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: distanceRepository.watchOperatingMode(),
      initialData: 'assist',
      builder: (context, snapshot) {
        final selectedMode = _normalizeOperatingMode(snapshot.data);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.settings_input_component_rounded,
                    color: const Color(0xFF1550D4),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Current Operating Mode',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _ModePill(
                title: 'Assist (Uphill)',
                icon: Icons.north_east_rounded,
                selected: selectedMode == 'assist',
              ),
              const SizedBox(height: 10),
              _ModePill(
                title: 'Brake (Downhill)',
                icon: Icons.south_east_rounded,
                selected: selectedMode == 'brake',
              ),
              const SizedBox(height: 10),
              _ModePill(
                title: 'Idle (Flat)',
                icon: Icons.pause_rounded,
                selected: selectedMode == 'idle',
              ),
            ],
          ),
        );
      },
    );
  }
}

String _normalizeOperatingMode(String? value) {
  switch (value?.trim().toLowerCase()) {
    case 'assist':
    case 'brake':
    case 'idle':
      return value!.trim().toLowerCase();
    default:
      return 'assist';
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({
    required this.title,
    required this.icon,
    this.selected = false,
  });

  final String title;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? const Color(0xFFDCE5FF)
        : const Color(0xFFF3F5F8);
    final textColor = selected
        ? const Color(0xFF123FD6)
        : const Color(0xFF374151);
    final dotColor = selected
        ? const Color(0xFF6F8EEB)
        : const Color(0xFF8A95A6);

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            height: 10,
            width: 10,
            decoration: BoxDecoration(
              color: dotColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  const _TrackingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF1D1F27),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _WorldMapPainter())),
          Positioned(
            top: 18,
            right: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.location_on_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Live Tracking',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 18,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RECENT ACTIVITY',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Living Room -> Kitchen',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'MOVEMENT HISTORY',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white.withOpacity(0.15),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = const Color(0xFF23242C);
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final mapPaint = Paint()..color = const Color(0xFF6B6F78).withOpacity(0.48);
    final highlightPaint = Paint()
      ..color = const Color(0xFF7E837C).withOpacity(0.55);

    void drawOval(
      double left,
      double top,
      double width,
      double height, {
      bool highlight = false,
    }) {
      final paint = highlight ? highlightPaint : mapPaint;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, width, height),
          const Radius.circular(20),
        ),
        paint,
      );
    }

    drawOval(
      size.width * 0.05,
      size.height * 0.22,
      size.width * 0.18,
      size.height * 0.22,
    );
    drawOval(
      size.width * 0.15,
      size.height * 0.18,
      size.width * 0.14,
      size.height * 0.18,
      highlight: true,
    );
    drawOval(
      size.width * 0.32,
      size.height * 0.25,
      size.width * 0.1,
      size.height * 0.12,
    );
    drawOval(
      size.width * 0.47,
      size.height * 0.18,
      size.width * 0.22,
      size.height * 0.18,
      highlight: true,
    );
    drawOval(
      size.width * 0.68,
      size.height * 0.18,
      size.width * 0.18,
      size.height * 0.22,
    );
    drawOval(
      size.width * 0.83,
      size.height * 0.30,
      size.width * 0.07,
      size.height * 0.12,
      highlight: true,
    );
    drawOval(
      size.width * 0.08,
      size.height * 0.58,
      size.width * 0.16,
      size.height * 0.2,
      highlight: true,
    );
    drawOval(
      size.width * 0.27,
      size.height * 0.62,
      size.width * 0.14,
      size.height * 0.18,
    );
    drawOval(
      size.width * 0.52,
      size.height * 0.56,
      size.width * 0.12,
      size.height * 0.16,
      highlight: true,
    );
    drawOval(
      size.width * 0.74,
      size.height * 0.56,
      size.width * 0.16,
      size.height * 0.2,
    );

    final dotsPaint = Paint()
      ..color = const Color(0xFFE0A35B).withOpacity(0.65);
    final points = <Offset>[
      Offset(size.width * 0.24, size.height * 0.38),
      Offset(size.width * 0.41, size.height * 0.42),
      Offset(size.width * 0.55, size.height * 0.48),
      Offset(size.width * 0.72, size.height * 0.35),
      Offset(size.width * 0.83, size.height * 0.55),
    ];
    for (final point in points) {
      canvas.drawCircle(point, 2.2, dotsPaint);
    }

    final linePaint = Paint()
      ..color = const Color(0xFFF1D6A3).withOpacity(0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.44)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.3,
        size.width * 0.63,
        size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.58,
        size.width * 0.84,
        size.height * 0.42,
      );
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gait & Mobility\nInsights',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              Text(
                'WEEKLY\nREPORT',
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF1550D4),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GridView(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            children: const [
              _InsightTile(
                label: 'AVG SPEED',
                value: '0.8 m/s',
                color: Color(0xFF1550D4),
              ),
              _InsightTile(
                label: 'STABILITY',
                value: 'High',
                color: Color(0xFFF59E0B),
              ),
              _InsightTile(
                label: 'STEPS',
                value: '4,120',
                color: Color(0xFF17B26A),
              ),
              _InsightTile(
                label: 'REST STOPS',
                value: '3 Today',
                color: Color(0xFF3B82F6),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE7ECF5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            _NavItem(
              icon: Icons.dashboard_rounded,
              label: 'Dashboard',
              selected: selectedIndex == 0,
              onTap: () => onTabSelected(0),
            ),
            _NavItem(
              icon: Icons.show_chart_rounded,
              label: 'Tracker',
              selected: selectedIndex == 1,
              onTap: () => onTabSelected(1),
            ),
            _NavItem(
              icon: Icons.notifications_rounded,
              label: 'Alerts',
              selected: selectedIndex == 2,
              onTap: () => onTabSelected(2),
            ),
            _NavItem(
              icon: Icons.menu_book_rounded,
              label: 'Edukasi',
              selected: selectedIndex == 3,
              onTap: () => onTabSelected(3),
            ),
            _NavItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              selected: selectedIndex == 4,
              onTap: () => onTabSelected(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF1550D4) : const Color(0xFF9CA3AF);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEAF0FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackerWeeklyTotalCard extends StatelessWidget {
  const _TrackerWeeklyTotalCard({required this.distanceRepository});

  final DistanceRepository distanceRepository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: distanceRepository.watchWeeklyTotalMeters(),
      initialData: 4200,
      builder: (context, totalSnapshot) {
        final colorScheme = Theme.of(context).colorScheme;
        final meters = totalSnapshot.data ?? 0;
        return StreamBuilder<int>(
          stream: distanceRepository.watchWeeklyWalkingTimeMinutes(),
          initialData: 342,
          builder: (context, timeSnapshot) {
            final minutes = timeSnapshot.data ?? 0;
            final kilometers = meters / 1000;
            final walkingTime = _formatWeeklyWalkingTime(minutes);

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WEEKLY TOTAL',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        kilometers.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              color: const Color(0xFF1D4ED8),
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.2,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'km',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF111827),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        walkingTime,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF111827),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

String _formatWeeklyWalkingTime(int minutes) {
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;

  if (hours > 0 && remainingMinutes > 0) {
    return '${hours}h ${remainingMinutes}m walking time';
  }
  if (hours > 0) {
    return '${hours}h walking time';
  }
  return '${remainingMinutes}m walking time';
}

class _TrackerDailyTargetCard extends StatefulWidget {
  const _TrackerDailyTargetCard({required this.distanceRepository});

  final DistanceRepository distanceRepository;

  @override
  State<_TrackerDailyTargetCard> createState() => _TrackerDailyTargetCardState();
}

class _TrackerDailyTargetCardState extends State<_TrackerDailyTargetCard> {
  int? _localGoalOverride;

  Future<void> _openEditGoalDialog(BuildContext context, int currentGoal) async {
    final result = await showDialog<int>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => _EditGoalDialog(currentGoal: currentGoal),
    );

    if (result != null && result > 0 && mounted) {
      setState(() {
        _localGoalOverride = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: widget.distanceRepository.watchTodayTargetAchievementMeters(),
      initialData: 320,
      builder: (_, achievementSnapshot) {
        final achievement = achievementSnapshot.data ?? 0;

        return StreamBuilder<int>(
          stream: widget.distanceRepository.watchTodayTargetGoalMeters(),
          initialData: 500,
          builder: (_, goalSnapshot) {
            final streamGoal = goalSnapshot.data ?? 1;
            final safeGoal = (_localGoalOverride ?? streamGoal).clamp(1, 999999);
            final progress = (achievement / safeGoal).clamp(0.0, 1.0);
            final percentage = (progress * 100).round();

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Today's Target",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      InkWell(
                        onTap: () => _openEditGoalDialog(context, safeGoal),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.edit_rounded,
                            size: 18,
                            color: const Color(0xFF7C4DFF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: SizedBox(
                      height: 220,
                      width: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(220, 220),
                            painter: _DonutProgressPainter(
                              progress: progress,
                              backgroundColor: const Color(0xFFE0E0E0),
                              foregroundColor: const Color(0xFF7C4DFF),
                              strokeWidth: 24,
                            ),
                          ),
                          Text(
                            '$percentage%',
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1F1B2E),
                                  fontSize: 45,
                                  height: 1,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Achievement',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '${_formatThousands(achievement)}m',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daily Goal',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '${_formatThousands(safeGoal)}m',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _EditGoalDialog extends StatefulWidget {
  const _EditGoalDialog({required this.currentGoal});

  final int currentGoal;

  @override
  State<_EditGoalDialog> createState() => _EditGoalDialogState();
}

class _EditGoalDialogState extends State<_EditGoalDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.currentGoal.toString());

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.flag_rounded, color: Color(0xFF7C4DFF), size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Edit Daily Goal',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Set a new daily walking distance target in meters.',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Daily Goal (meters)',
              hintText: 'e.g. 500',
              suffixText: 'm',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 2),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF7C4DFF),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            final parsed = int.tryParse(_controller.text.trim());
            Navigator.of(context).pop(parsed);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _DonutProgressPainter extends CustomPainter {
  const _DonutProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color backgroundColor;
  final Color foregroundColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final foregroundPaint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, 2 * pi, false, backgroundPaint);

    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(rect, startAngle, sweepAngle, false, foregroundPaint);
  }

  @override
  bool shouldRepaint(covariant _DonutProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.foregroundColor != foregroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _TrackerRehabScoreCard extends StatelessWidget {
  const _TrackerRehabScoreCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rehab Score',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Based on gait stability & speed',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    height: 10,
                    width: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1D4ED8),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CURRENT\nWEEK',
                    textAlign: TextAlign.left,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF111827),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 44),
          SizedBox(
            height: 140,
            child: CustomPaint(
              painter: _SimpleLineChartPainter(),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('MON'),
              Text('TUE'),
              Text('WED'),
              Text(
                'THU',
                style: TextStyle(
                  color: Color(0xFF1D4ED8),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text('FRI'),
              Text('SAT'),
              Text('SUN'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SimpleLineChartPainter extends CustomPainter {
  const _SimpleLineChartPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;

    for (var i = 0; i < 3; i++) {
      final y = size.height * (0.25 + i * 0.32);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePaint = Paint()
      ..color = const Color(0xFF1D4ED8)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.48,
        size.width * 0.44,
        size.height * 0.56,
      )
      ..quadraticBezierTo(
        size.width * 0.58,
        size.height * 0.62,
        size.width * 0.72,
        size.height * 0.36,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.20,
        size.width * 0.92,
        size.height * 0.26,
      );

    canvas.drawPath(path, linePaint);

    final pointPaint = Paint()..color = const Color(0xFF1D4ED8);
    final points = [
      Offset(size.width * 0.08, size.height * 0.72),
      Offset(size.width * 0.44, size.height * 0.56),
      Offset(size.width * 0.72, size.height * 0.36),
      Offset(size.width * 0.92, size.height * 0.26),
    ];
    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TrackerSessionHistoryCard extends StatelessWidget {
  const _TrackerSessionHistoryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Session History',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SessionHistoryPage(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'View All',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF1D4ED8),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const _SessionRow(
            title: 'Afternoon Walk',
            duration: '15 mins',
            date: 'Oct 24 • 02:30 PM',
          ),
          const Divider(height: 1),
          const _SessionRow(
            title: 'Morning Rehab',
            duration: '10 mins',
            date: 'Oct 24 • 09:15 AM',
          ),
          const Divider(height: 1),
          const _SessionRow(
            title: 'Garden Stroll',
            duration: '25 mins',
            date: 'Oct 23 • 04:45 PM',
          ),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.title,
    required this.duration,
    required this.date,
  });

  final String title;
  final String duration;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.directions_walk_rounded,
              color: Color(0xFF1D4ED8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                            ),
                      ),
                    ),
                    Text(
                      duration,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFCBD5E1),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      date,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'DURATION',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleComingSoonPage extends StatelessWidget {
  const _SimpleComingSoonPage({required this.title, required this.description});

  final String title;
  final String description;

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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.construction_rounded,
                  size: 54,
                  color: Color(0xFF1D4ED8),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

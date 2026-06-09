part of roro_main;

class DashboardHome extends StatelessWidget {
  const DashboardHome({
    super.key,
    required this.distanceRepository,
    required this.rollatorRepository,
    required this.colorScheme,
  });

  final DistanceRepository distanceRepository;
  final RollatorRepository rollatorRepository;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF9FBFF), Color(0xFFF3F5FA)],
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
              _PatientCard(colorScheme: colorScheme),
              const SizedBox(height: 16),
              const _QuickActions(),
              const SizedBox(height: 14),
              _FireStreakCard(
                distanceRepository: distanceRepository,
              ),
              const SizedBox(height: 14),
              _WalkingTimeMetricCard(
                distanceRepository: distanceRepository,
              ),
              const SizedBox(height: 16),
              _OperatingModeCard(
                distanceRepository: distanceRepository,
                rollatorRepository: rollatorRepository,
              ),
              const SizedBox(height: 16),
              const _InsightsCard(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

part of roro_main;

class TrackerPage extends StatelessWidget {
  const TrackerPage({super.key, required this.distanceRepository, required this.colorScheme});

  final DistanceRepository distanceRepository;
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
              Text(
                'Rehab Tracker',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: const Color(0xFF111827),
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Consistency is the key to recovery, John.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF4B5563),
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F6BFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'On track for your weekly goal!',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _TrackerWeeklyTotalCard(distanceRepository: distanceRepository),
              const SizedBox(height: 16),
              _TrackerDailyTargetCard(distanceRepository: distanceRepository),
              const SizedBox(height: 16),
              const _TrackerRehabScoreCard(),
              const SizedBox(height: 16),
              const _TrackerSessionHistoryCard(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

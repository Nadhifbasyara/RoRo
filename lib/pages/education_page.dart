part of roro_main;

class EducationPage extends StatefulWidget {
  const EducationPage({super.key, required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  State<EducationPage> createState() => _EducationPageState();
}

class _EducationPageState extends State<EducationPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<_EducationArticle> _allArticles = [
    _EducationArticle(
      id: 'latihan-fisik',
      category: 'Latihan Fisik',
      categoryIcon: Icons.directions_walk_rounded,
      categoryColor: Color(0xFF3B82F6),
      title: 'Panduan Latihan Fisik Pasca Stroke',
      description:
          'Panduan mobilitas harian dan latihan motorik halus untuk mempercepat kemandirian fisik.',
    ),
    _EducationArticle(
      id: 'nutrisi',
      category: 'Nutrisi & Diet',
      categoryIcon: Icons.restaurant_rounded,
      categoryColor: Color(0xFF10B981),
      title: 'Nutrisi & Diet untuk Pemulihan',
      description:
          'Rencana makan sehat jantung yang dirancang untuk mendukung pemulihan saraf dan energi.',
    ),
    _EducationArticle(
      id: 'mental',
      category: 'Kesehatan Mental',
      categoryIcon: Icons.self_improvement_rounded,
      categoryColor: Color(0xFF8B5CF6),
      title: 'Dukungan Psikologis Pasca Stroke',
      description:
          'Dukungan psikologis, meditasi, dan teknik manajemen stres selama masa transisi.',
    ),
    _EducationArticle(
      id: 'komunikasi',
      category: 'Komunikasi',
      categoryIcon: Icons.record_voice_over_rounded,
      categoryColor: Color(0xFFF59E0B),
      title: 'Latihan Bicara & Komunikasi',
      description:
          'Teknik terapi wicara dan strategi komunikasi alternatif untuk membantu pemulihan bahasa.',
    ),
    _EducationArticle(
      id: 'keluarga',
      category: 'Peran Keluarga',
      categoryIcon: Icons.people_rounded,
      categoryColor: Color(0xFFEF4444),
      title: 'Panduan Keluarga sebagai Caregiver',
      description:
          'Cara mendampingi pasien stroke di rumah — dari rutinitas harian hingga deteksi tanda bahaya.',
    ),
    _EducationArticle(
      id: 'obat',
      category: 'Pengobatan',
      categoryIcon: Icons.medication_rounded,
      categoryColor: Color(0xFF06B6D4),
      title: 'Manajemen Obat Pasca Stroke',
      description:
          'Panduan penting tentang kepatuhan minum obat, efek samping umum, dan jadwal kontrol rutin.',
    ),
  ];

  List<_EducationArticle> get _filteredArticles {
    if (_searchQuery.isEmpty) return _allArticles;
    final q = _searchQuery.toLowerCase();
    return _allArticles
        .where((a) =>
            a.title.toLowerCase().contains(q) ||
            a.category.toLowerCase().contains(q) ||
            a.description.toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredArticles;

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
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TopBar(colorScheme: widget.colorScheme),
                    const SizedBox(height: 18),
                    Text(
                      'Edukasi Pasca Stroke',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                            color: const Color(0xFF111827),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Panduan komprehensif untuk perjalanan pemulihan Anda.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF4B5563),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 16),
                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: const InputDecoration(
                          hintText: 'Cari artikel kesehatan...',
                          hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                          prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF9CA3AF)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Featured card
                    if (_searchQuery.isEmpty) ...[
                      _FeaturedCard(colorScheme: widget.colorScheme),
                      const SizedBox(height: 24),
                    ],
                    // Section header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kategori Sumber Daya',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF111827),
                              ),
                        ),
                        Text(
                          'Lihat Semua',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: const Color(0xFF1D4ED8),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            // Article list
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= filtered.length) return null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ArticleTile(
                        article: filtered[index],
                        onTap: () => _openArticle(context, filtered[index]),
                      ),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
            // Daily insight card
            if (_searchQuery.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  child: _DailyInsightCard(),
                ),
              )
            else
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  void _openArticle(BuildContext context, _EducationArticle article) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ArticleDetailPage(article: article),
      ),
    );
  }
}

// ─── Data model ──────────────────────────────────────────────────────────────

class _EducationArticle {
  const _EducationArticle({
    required this.id,
    required this.category,
    required this.categoryIcon,
    required this.categoryColor,
    required this.title,
    required this.description,
  });

  final String id;
  final String category;
  final IconData categoryIcon;
  final Color categoryColor;
  final String title;
  final String description;
}

// ─── Featured card ───────────────────────────────────────────────────────────

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D4ED8), Color(0xFF1E40AF)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'TERBARU',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Panduan Pemulihan Utama',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Langkah-langkah krusial untuk 90 hari pertama pemulihan di rumah. Disusun oleh tim ahli saraf.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.88),
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Buka di Google Drive',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: const Color(0xFF1D4ED8),
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.open_in_new_rounded, size: 16, color: Color(0xFF1D4ED8)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Article tile ─────────────────────────────────────────────────────────────

class _ArticleTile extends StatelessWidget {
  const _ArticleTile({required this.article, required this.onTap});

  final _EducationArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: article.categoryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(article.categoryIcon, color: article.categoryColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.category,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: article.categoryColor,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    article.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF111827),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7280),
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFC5CCD8), size: 22),
          ],
        ),
      ),
    );
  }
}

// ─── Daily insight card ───────────────────────────────────────────────────────

class _DailyInsightCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INSIGHT HARIAN',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF1D4ED8),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '"Setiap langkah kecil adalah kemenangan besar."',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E3A8A),
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1D4ED8).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_rounded, color: Color(0xFF1D4ED8), size: 26),
          ),
        ],
      ),
    );
  }
}

// ─── Article detail page ──────────────────────────────────────────────────────

class _ArticleDetailPage extends StatelessWidget {
  const _ArticleDetailPage({required this.article});

  final _EducationArticle article;

  // Sample content per article id
  static const Map<String, List<_ArticleSection>> _content = {
    'latihan-fisik': [
      _ArticleSection(
        heading: 'Mengapa Latihan Fisik Penting?',
        body:
            'Latihan fisik secara rutin membantu otak membentuk jalur saraf baru melalui neuroplastisitas. Dimulai dari gerakan ringan, intensitas dapat ditingkatkan seiring waktu.',
      ),
      _ArticleSection(
        heading: 'Program Latihan Minggu Pertama',
        body:
            '• Rentangkan jari tangan 10× pagi dan sore\n• Angkat tumit sambil duduk 2 set × 15 ulangan\n• Berjalan di dalam rumah dengan pendamping minimal 10 menit',
      ),
      _ArticleSection(
        heading: 'Tips Keamanan',
        body:
            'Selalu ada pendamping saat latihan. Hentikan jika muncul nyeri dada, pusing hebat, atau sesak napas. Laporkan perkembangan ke terapis setiap minggu.',
      ),
    ],
    'nutrisi': [
      _ArticleSection(
        heading: 'Prinsip Diet Pasca Stroke',
        body:
            'Konsumsi makanan rendah garam (<2g/hari), tinggi serat, dan hindari lemak jenuh. Fokus pada sayuran hijau, ikan berlemak, dan buah-buahan segar.',
      ),
      _ArticleSection(
        heading: 'Contoh Menu Harian',
        body:
            'Pagi: Oatmeal + pisang + teh hijau\nSiang: Nasi merah + ikan kukus + sayur bayam\nMalam: Sup brokoli + dada ayam tanpa kulit\nCamilan: Kacang almond atau buah potong',
      ),
      _ArticleSection(
        heading: 'Suplemen yang Direkomendasikan',
        body:
            'Konsultasikan dengan dokter sebelum mengonsumsi suplemen. Omega-3 dan vitamin D umumnya direkomendasikan, namun dosis harus disesuaikan kondisi pasien.',
      ),
    ],
    'mental': [
      _ArticleSection(
        heading: 'Depresi Pasca Stroke',
        body:
            'Sekitar 30% penyintas stroke mengalami depresi. Kenali gejalanya: sedih berkepanjangan, tidak nafsu makan, sulit tidur. Segera konsultasikan ke psikiater.',
      ),
      _ArticleSection(
        heading: 'Teknik Relaksasi Sederhana',
        body:
            '1. Tarik napas dalam 4 hitungan, tahan 4, lepas 6\n2. Visualisasi tempat yang menenangkan selama 5 menit\n3. Dengarkan musik lembut sebelum tidur',
      ),
      _ArticleSection(
        heading: 'Dukungan Komunitas',
        body:
            'Bergabung dengan grup dukungan stroke lokal atau online dapat sangat membantu. Berbagi pengalaman dengan sesama penyintas memberikan motivasi dan rasa tidak sendirian.',
      ),
    ],
    'komunikasi': [
      _ArticleSection(
        heading: 'Afasia Pasca Stroke',
        body:
            'Afasia adalah kesulitan berbicara atau memahami bahasa akibat kerusakan area Broca/Wernicke. Kondisi ini dapat membaik dengan latihan terapi wicara yang konsisten.',
      ),
      _ArticleSection(
        heading: 'Latihan Harian',
        body:
            '• Baca keras-keras 10 menit per hari\n• Latih nama benda sehari-hari di sekitar rumah\n• Gunakan kartu gambar untuk membantu ekspresi\n• Latih percakapan singkat dengan anggota keluarga',
      ),
      _ArticleSection(
        heading: 'Komunikasi Alternatif',
        body:
            'Gunakan papan komunikasi bergambar, aplikasi text-to-speech, atau gestur sederhana yang disepakati bersama keluarga sebagai sistem komunikasi sementara.',
      ),
    ],
    'keluarga': [
      _ArticleSection(
        heading: 'Peran Caregiver',
        body:
            'Caregiver keluarga adalah pilar utama pemulihan. Tugas utama meliputi: memastikan kepatuhan obat, mendampingi latihan, dan memantau tanda-tanda komplikasi.',
      ),
      _ArticleSection(
        heading: 'Tanda Bahaya yang Harus Diwaspadai',
        body:
            '🔴 Segera ke IGD jika:\n• Wajah, tangan, atau kaki tiba-tiba lemah sebelah\n• Bicara tiba-tiba tidak jelas\n• Sakit kepala sangat hebat mendadak\n• Penglihatan tiba-tiba kabur',
      ),
      _ArticleSection(
        heading: 'Jaga Kesehatan Caregiver',
        body:
            'Caregiver yang kelelahan tidak dapat memberikan perawatan optimal. Jangan ragu meminta bantuan anggota keluarga lain, dan sisihkan waktu untuk diri sendiri.',
      ),
    ],
    'obat': [
      _ArticleSection(
        heading: 'Obat Wajib Pasca Stroke',
        body:
            'Umumnya dokter meresepkan antiplatelet (aspirin/clopidogrel) atau antikoagulan, antihipertensi, dan statin. Jangan berhenti minum obat tanpa konsultasi dokter.',
      ),
      _ArticleSection(
        heading: 'Tips Kepatuhan Minum Obat',
        body:
            '• Gunakan pill organizer berlabel hari\n• Pasang alarm pengingat di HP\n• Minum obat di waktu yang sama setiap hari\n• Catat di buku harian jika sudah minum',
      ),
      _ArticleSection(
        heading: 'Jadwal Kontrol Rutin',
        body:
            'Kontrol ke dokter spesialis saraf setiap 1-3 bulan di tahun pertama. Bawa catatan perkembangan, daftar obat, dan catat pertanyaan sebelum kunjungan.',
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final sections = _content[article.id] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: article.categoryColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      article.categoryColor,
                      article.categoryColor.withOpacity(0.7),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            article.category.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          article.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= sections.length) return null;
                  final section = sections[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.heading,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF111827),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            section.body,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF374151),
                                  height: 1.6,
                                ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                childCount: sections.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _ArticleSection {
  const _ArticleSection({required this.heading, required this.body});

  final String heading;
  final String body;
}

part of roro_main;

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.colorScheme,
    required this.rollatorRepository,
    required this.onSignOut,
    required this.onReconfigureWifi,
  });

  final ColorScheme colorScheme;
  final RollatorRepository rollatorRepository;
  final Future<void> Function() onSignOut;
  final Future<void> Function() onReconfigureWifi;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _profileImageBytes;
  bool _pushNotificationsEnabled = true;
  String _selectedLanguage = 'English';
  String _displayName = 'John Doe';
  late Future<RollatorDeviceSession?> _deviceSessionFuture;
  EmergencyContact? _emergencyContact;

  @override
  void initState() {
    super.initState();
    _deviceSessionFuture = RollatorSessionStore.loadDeviceSession();
    _loadEmergencyContact();
  }

  Future<void> _loadEmergencyContact() async {
    final contact = await EmergencyContactStore.load();
    if (mounted) setState(() => _emergencyContact = contact);
  }

  @override
  Widget build(BuildContext context) {
    final initials = _buildInitials(_displayName);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FAFF), Color(0xFFF3F6FB)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileAppBar(colorScheme: widget.colorScheme),
              const SizedBox(height: 28),
              Center(
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          onTap: _pickProfileImage,
                          child: Container(
                            height: 116,
                            width: 116,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 22,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF22304A),
                                    Color(0xFF0F172A),
                                  ],
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (_profileImageBytes != null)
                                    Positioned.fill(
                                      child: ClipOval(
                                        child: Image.memory(
                                          _profileImageBytes!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  else ...[
                                    Positioned(
                                      top: 14,
                                      left: 18,
                                      child: Container(
                                        height: 22,
                                        width: 22,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.08),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.person_rounded,
                                      color: Colors.white,
                                      size: 70,
                                    ),
                                    Positioned(
                                      bottom: 14,
                                      child: Text(
                                        initials,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: 4,
                          child: GestureDetector(
                            onTap: _openEditProfileSheet,
                            child: Container(
                              height: 38,
                              width: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D4ED8),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF1D4ED8,
                                    ).withOpacity(0.28),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _displayName,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                            color: const Color(0xFF111827),
                          ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shield_rounded,
                            size: 16,
                            color: widget.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'PRIMARY CAREGIVER',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: const Color(0xFF1D4ED8),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _ConnectedDeviceCard(
                colorScheme: widget.colorScheme,
                sessionFuture: _deviceSessionFuture,
                rollatorRepository: widget.rollatorRepository,
                onTap: () => _openDeviceDetails(),
              ),
              const SizedBox(height: 22),
              const _SectionLabel(title: 'KONTAK DARURAT SOS'),
              const SizedBox(height: 12),
              _EmergencyContactCard(
                contact: _emergencyContact,
                onTap: _openEditEmergencyContactSheet,
              ),
              const SizedBox(height: 22),
              const _SectionLabel(title: 'SECURITY & ACCOUNT'),
              const SizedBox(height: 12),
              _SectionCard(
                children: [
                  _SettingsTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Edit Profile',
                    onTap: _openEditProfileSheet,
                  ),
                  const _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Change Password',
                    onTap: _openChangePasswordSheet,
                  ),
                  const _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.verified_user_outlined,
                    title: 'Security Settings',
                    onTap: _openSecuritySettingsSheet,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const _SectionLabel(title: 'APP PREFERENCES'),
              const SizedBox(height: 12),
              _SectionCard(
                children: [
                  _SettingsTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Push Notifications',
                    trailing: Switch.adaptive(
                      value: _pushNotificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _pushNotificationsEnabled = value;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? 'Push notifications turned on.'
                                  : 'Push notifications turned off.',
                            ),
                          ),
                        );
                      },
                      activeColor: widget.colorScheme.primary,
                    ),
                  ),
                  const _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.language_rounded,
                    title: 'Language',
                    onTap: _openLanguageSheet,
                    trailing: Text(
                      _selectedLanguage,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF1D4ED8),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const _SectionLabel(title: 'SUPPORT & LEGAL'),
              const SizedBox(height: 12),
              _SectionCard(
                children: [
                  _SettingsTile(
                    icon: Icons.wifi_tethering_rounded,
                    title: 'Ubah WiFi',
                    onTap: () async => widget.onReconfigureWifi(),
                  ),
                  const _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Help Center',
                    onTap: _openHelpCenter,
                  ),
                  const _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    onTap: () => _openInfoSheet(
                      'Terms of Service',
                      'Use RoRo responsibly and keep the app updated to the latest version.',
                    ),
                  ),
                  const _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.policy_outlined,
                    title: 'Privacy Policy',
                    onTap: () => _openInfoSheet(
                      'Privacy Policy',
                      'RoRo stores only the data needed to operate tracking, alerts, and profile preferences.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _confirmSignOut,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(58),
                    backgroundColor: const Color(0xFFF8EDED),
                    foregroundColor: const Color(0xFFC81E1E),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    textStyle: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text('Sign Out from RoRo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    final pickedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (pickedImage == null) {
      return;
    }

    final imageBytes = await pickedImage.readAsBytes();
    if (!mounted) {
      return;
    }

    setState(() {
      _profileImageBytes = imageBytes;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile picture updated.')));
  }

  String _buildInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'JD';
    }

    final buffer = StringBuffer();
    for (final part in parts.take(2)) {
      buffer.write(part.substring(0, 1));
    }
    return buffer.toString().toUpperCase();
  }

  void _openEditProfileSheet() {
    final controller = TextEditingController(text: _displayName);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 4,
                    width: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Edit Profile',
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  'Change the display name shown on the profile screen.',
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      setState(() {
                        _displayName = controller.text.trim().isEmpty
                            ? _displayName
                            : controller.text.trim();
                      });
                      Navigator.of(sheetContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile updated locally.'),
                        ),
                      );
                    },
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openEditEmergencyContactSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _EmergencyContactSheet(
        initial: _emergencyContact,
        onSaved: (contact) {
          setState(() => _emergencyContact = contact);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kontak darurat tersimpan.')),
          );
        },
        onDeleted: () {
          setState(() => _emergencyContact = null);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kontak darurat dihapus.')),
          );
        },
      ),
    );
  }

  void _openChangePasswordSheet() {    _openInfoSheet(
      'Change Password',
      'Password changes can be wired to Firebase Auth later. For now, this opens the interaction and confirms the action.',
      actionLabel: 'Request Reset',
      onAction: () {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset flow opened.')),
        );
      },
    );
  }

  void _openSecuritySettingsSheet() {
    _openInfoSheet(
      'Security Settings',
      'Security toggles like device lock, login alerts, and biometric unlock can be connected later.',
      actionLabel: 'Got it',
    );
  }

  void _openLanguageSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Language',
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              _languageOption(sheetContext, 'English'),
              const SizedBox(height: 10),
              _languageOption(sheetContext, 'Bahasa Indonesia'),
              const SizedBox(height: 10),
              _languageOption(sheetContext, 'Spanish'),
            ],
          ),
        );
      },
    );
  }

  Widget _languageOption(BuildContext sheetContext, String language) {
    final selected = _selectedLanguage == language;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedLanguage = language;
        });
        Navigator.of(sheetContext).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Language set to $language.')));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF0FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF1D4ED8) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              language,
              style: Theme.of(
                sheetContext,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF1D4ED8)),
          ],
        ),
      ),
    );
  }

  Future<void> _openDeviceDetails() async {
    final session = await RollatorSessionStore.loadDeviceSession();
    if (!mounted) return;

    if (session == null) {
      _openInfoSheet(
        'Connected Device',
        'Belum ada perangkat aktif. Scan QR perangkat dulu untuk menampilkan device_id dan mDNS.',
      );
      return;
    }

    _openInfoSheet(
      'Connected Device',
      'Nama: ${session.deviceName ?? 'Belum ada di QR'}\nDevice ID: ${session.rollatorCode}\nmDNS: ${session.mdnsHost ?? 'rorro.local'}',
      actionLabel: 'Refresh Status',
      onAction: () {
        Navigator.of(context).pop();
        setState(() {
          _deviceSessionFuture = RollatorSessionStore.loadDeviceSession();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device status refreshed.')),
        );
      },
    );
  }

  void _openHelpCenter() {
    _openInfoSheet(
      'Help Center',
      'Need help? Contact support at support@roro.app or check the onboarding guide for device pairing.',
      actionLabel: 'Contact Support',
      onAction: () {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Support contact copied to the queue.')),
        );
      },
    );
  }

  void _openInfoSheet(
    String title,
    String description, {
    String actionLabel = 'Close',
    VoidCallback? onAction,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF4B5563),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onAction ?? () => Navigator.of(sheetContext).pop(),
                  child: Text(actionLabel),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign out?'),
          content: const Text(
            'This will log you out from RoRo on this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (shouldSignOut != true || !mounted) {
      return;
    }

    await FirebaseAuth.instance.signOut();
    await widget.onSignOut();
  }

  void _openMoreActions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Quick Actions',
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: const Text('Edit Profile'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openEditProfileSheet();
                },
              ),
              ListTile(
                leading: const Icon(Icons.language_rounded),
                title: const Text('Change Language'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openLanguageSheet();
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Sign Out'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _confirmSignOut();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileAppBar extends StatelessWidget {
  const _ProfileAppBar({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        'Account Settings',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
          color: const Color(0xFF111827),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          height: 42,
          width: 42,
          child: Icon(icon, color: const Color(0xFF1D4ED8), size: 22),
        ),
      ),
    );
  }
}

class _EmergencyContactSheet extends StatefulWidget {
  const _EmergencyContactSheet({
    required this.onSaved,
    required this.onDeleted,
    this.initial,
  });

  final EmergencyContact? initial;
  final void Function(EmergencyContact) onSaved;
  final VoidCallback onDeleted;

  @override
  State<_EmergencyContactSheet> createState() => _EmergencyContactSheetState();
}

class _EmergencyContactSheetState extends State<_EmergencyContactSheet> {
  late final TextEditingController _nameCtrl =
      TextEditingController(text: widget.initial?.name ?? '');
  late final TextEditingController _phoneCtrl =
      TextEditingController(text: widget.initial?.phone ?? '');
  late final TextEditingController _relationCtrl =
      TextEditingController(text: widget.initial?.relation ?? '');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _relationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.emergency_rounded, color: Color(0xFFDC2626), size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'Kontak Darurat SOS',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Nomor ini akan dihubungi otomatis saat tombol SOS aktif.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280)),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nama',
                hintText: 'contoh: Budi Santoso',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Nomor Telepon',
                hintText: 'contoh: 08123456789',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _relationCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Hubungan',
                hintText: 'contoh: Anak, Istri, Suami',
                prefixIcon: const Icon(Icons.people_outline_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  final phone = _phoneCtrl.text.trim();
                  if (phone.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nomor telepon wajib diisi.')),
                    );
                    return;
                  }
                  final contact = EmergencyContact(
                    name: _nameCtrl.text.trim(),
                    phone: phone,
                    relation: _relationCtrl.text.trim(),
                  );
                  await EmergencyContactStore.save(contact);
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  widget.onSaved(contact);
                },
                child: const Text('Simpan Kontak', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
            if (widget.initial != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    await EmergencyContactStore.clear();
                    if (!mounted) return;
                    Navigator.of(context).pop();
                    widget.onDeleted();
                  },
                  child: const Text('Hapus Kontak', style: TextStyle(color: Color(0xFF9CA3AF))),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmergencyContactCard extends StatelessWidget {
  const _EmergencyContactCard({required this.contact, required this.onTap});

  final EmergencyContact? contact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: contact != null ? const Color(0xFFFCA5A5) : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: contact == null ? _buildEmpty(context) : _buildFilled(context),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.emergency_rounded, color: Color(0xFFDC2626), size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Belum ada kontak darurat',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF374151),
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                'Tap untuk menambahkan nomor keluarga',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF9CA3AF),
                    ),
              ),
            ],
          ),
        ),
        const Icon(Icons.add_circle_rounded, color: Color(0xFFDC2626), size: 24),
      ],
    );
  }

  Widget _buildFilled(BuildContext context) {
    final c = contact!;
    return Row(
      children: [
        Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.emergency_rounded, color: Color(0xFFDC2626), size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (c.name.isNotEmpty)
                Text(
                  c.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF111827),
                      ),
                ),
              const SizedBox(height: 3),
              Text(
                c.phone,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFDC2626),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
              ),
              if (c.relation.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  c.relation,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                ),
              ],
            ],
          ),
        ),
        const Icon(Icons.edit_rounded, color: Color(0xFF9CA3AF), size: 20),
      ],
    );
  }
}

class _ConnectedDeviceCard extends StatelessWidget {
  const _ConnectedDeviceCard({
    required this.colorScheme,
    required this.sessionFuture,
    required this.rollatorRepository,
    required this.onTap,
  });

  final ColorScheme colorScheme;
  final Future<RollatorDeviceSession?> sessionFuture;
  final RollatorRepository rollatorRepository;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
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
                  'Connected Device',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                Icon(
                  Icons.precision_manufacturing_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<RollatorDeviceSession?>(
              future: sessionFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _ConnectedDeviceBody.loading(context);
                }

                final session = snapshot.data;
                if (session == null) {
                  return _ConnectedDeviceBody.empty(context);
                }

                return StreamBuilder<RollatorRecord?>(
                  stream: rollatorRepository.watchRollatorByCode(
                    session.rollatorCode,
                  ),
                  builder: (_, rollatorSnapshot) {
                    final rollator = rollatorSnapshot.data;
                    return _ConnectedDeviceBody(
                      colorScheme: colorScheme,
                      deviceName:
                          session.deviceName ??
                          rollator?.label ??
                          'RoRo Device',
                      deviceId: session.rollatorCode,
                      mdnsHost: session.mdnsHost,
                      isOnline: rollator?.isOnline ?? false,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectedDeviceBody extends StatelessWidget {
  const _ConnectedDeviceBody({
    required this.colorScheme,
    required this.deviceName,
    required this.deviceId,
    this.mdnsHost,
    this.isOnline,
  });

  factory _ConnectedDeviceBody.loading(BuildContext context) {
    return _ConnectedDeviceBody(
      colorScheme: Theme.of(context).colorScheme,
      deviceName: 'Memuat device...',
      deviceId: '...',
      mdnsHost: null,
      isOnline: null,
    );
  }

  factory _ConnectedDeviceBody.empty(BuildContext context) {
    return _ConnectedDeviceBody(
      colorScheme: Theme.of(context).colorScheme,
      deviceName: 'Belum ada device',
      deviceId: 'Scan QR perangkat dulu',
      mdnsHost: null,
      isOnline: null,
    );
  }

  final ColorScheme colorScheme;
  final String deviceName;
  final String deviceId;
  final String? mdnsHost;
  /// null = belum ada data dari firmware
  final bool? isOnline;

  @override
  Widget build(BuildContext context) {
    final displayMdns = (mdnsHost == null || mdnsHost!.trim().isEmpty) ? 'rorro.local' : mdnsHost!.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.device_hub_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              // Status dot — kanan bawah icon
              if (isOnline != null)
                Positioned(
                  right: -3,
                  bottom: -3,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isOnline! ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF),
                      shape: BoxShape.circle,
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        deviceName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF111827),
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Badge ON / OFF
                    _OnlineBadge(isOnline: isOnline),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'ID: $deviceId',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DeviceInfoChip(
                      icon: Icons.dns_rounded,
                      label: 'mDNS',
                      value: displayMdns,
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

class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge({required this.isOnline});

  final bool? isOnline;

  @override
  Widget build(BuildContext context) {
    // isOnline == null berarti loading/belum ada device — jangan tampilkan badge
    if (isOnline == null) return const SizedBox.shrink();

    final on = isOnline!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: on ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: on ? const Color(0xFF86EFAC) : const Color(0xFFD1D5DB),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: on ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            on ? 'ON' : 'OFF',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: on ? const Color(0xFF15803D) : const Color(0xFF6B7280),
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceInfoChip extends StatelessWidget {
  const _DeviceInfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF2563EB)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$label: $value',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF374151),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: const Color(0xFF77829A),
          fontWeight: FontWeight.w900,
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Column(children: children),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9));
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F5FA),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(icon, color: const Color(0xFF4B5563), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (trailing != null) trailing!,
            if (trailing == null)
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFC5CCD8),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

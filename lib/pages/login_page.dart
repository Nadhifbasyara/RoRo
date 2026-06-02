part of roro_main;

class LoginPage extends StatelessWidget {
  const LoginPage({
    super.key,
    required this.distanceRepository,
    required this.rollatorRepository,
  });

  final DistanceRepository distanceRepository;
  final RollatorRepository rollatorRepository;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7F9FD), Color(0xFFF1F4F9)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LoginTopBar(
                  colorScheme: colorScheme,
                  onMenuPressed: () => _showLoginMenu(context),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 8,
                        width: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F4FDB),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SECURE ACCESS',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF0F4FDB),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Welcome back to\nRoRo',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.2,
                    height: 1.02,
                    color: const Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Log in to monitor your patient\nand manage robotic care.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF475467),
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),
                _DeviceLoginCard(
                  onScanFromGallery: () => _scanAndOpenProvisioning(context),
                  onDeviceTap: () => _scanAndOpenProvisioning(context),
                ),
                const SizedBox(height: 22),
                Center(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF475467),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showInfo(
                          context,
                          'Sign Up feature belum dihubungkan.',
                        ),
                        child: Text(
                          'Sign Up',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: const Color(0xFF0F4FDB),
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: Text(
                    '┬⌐ 2024 RORO MEDICAL ROBOTICS ΓÇó ALL RIGHTS\nRESERVED',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF98A2B3),
                      letterSpacing: 2.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goToDashboard(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DashboardPage(
          distanceRepository: distanceRepository,
          rollatorRepository: rollatorRepository,
        ),
      ),
    );
  }

  void _showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _scanAndOpenProvisioning(BuildContext context) async {
    final scannedCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _RollatorQrScannerPage(),
      ),
    );

    if (!context.mounted || scannedCode == null || scannedCode.trim().isEmpty) {
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FirmwareProvisioningPage(
          rollatorRepository: rollatorRepository,
          initialRollatorCode: scannedCode.trim(),
        ),
      ),
    );

    if (!context.mounted) {
      return;
    }

    if (result == true) {
      _goToDashboard(context);
    }
  }
}

class _CreateRollatorSheet extends StatefulWidget {
  const _CreateRollatorSheet({required this.rollatorRepository});

  final RollatorRepository rollatorRepository;

  @override
  State<_CreateRollatorSheet> createState() => _CreateRollatorSheetState();
}

class _CreateRollatorSheetState extends State<_CreateRollatorSheet> {
  final TextEditingController _labelController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final created = await widget.rollatorRepository.createRollator(
        label: _labelController.text.trim().isEmpty
            ? null
            : _labelController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Rollator QR',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'The generated Firestore document ID will become the QR payload.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF667085)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _labelController,
                decoration: const InputDecoration(
                  labelText: 'Label (optional)',
                  hintText: 'Example: Rollator A',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create QR'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JoinRollatorDialog extends StatefulWidget {
  const _JoinRollatorDialog({required this.rollatorRepository});

  final RollatorRepository rollatorRepository;

  @override
  State<_JoinRollatorDialog> createState() => _JoinRollatorDialogState();
}

class _JoinRollatorDialogState extends State<_JoinRollatorDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan rollator code dulu.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final claimResult = await widget.rollatorRepository
        .claimCurrentUserToRollator(code);
    if (!mounted) return;
    Navigator.of(context).pop(claimResult);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Join Rollator'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Rollator Code',
              hintText: 'Paste QR payload here',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A rollator can only be linked to 2 accounts.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF667085)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Join'),
        ),
      ],
    );
  }
}

class _LoginTopBar extends StatelessWidget {
  const _LoginTopBar({required this.colorScheme, required this.onMenuPressed});

  final ColorScheme colorScheme;
  final VoidCallback onMenuPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.08),
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
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: onMenuPressed,
          icon: const Icon(Icons.menu_rounded),
          color: const Color(0xFF0F172A),
        ),
      ],
    );
  }
}

class _DeviceLoginCard extends StatelessWidget {
  const _DeviceLoginCard({
    required this.onScanFromGallery,
    required this.onDeviceTap,
  });

  final VoidCallback onScanFromGallery;
  final VoidCallback onDeviceTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDeviceTap,
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
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Device Login',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF101828),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Scan QR Code on Device',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF667085),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            _QrScannerMock(onTap: onDeviceTap),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: onScanFromGallery,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE5E7EB),
                  foregroundColor: const Color(0xFF101828),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.image_outlined, size: 20),
                label: const Text(
                  'Scan from Gallery',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFB54708),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ensure the QR code is centered and well-lit for faster recognition.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFB54708),
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on LoginPage {
  void _showLoginMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rollator Options',
                    style: Theme.of(sheetContext).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a new rollator QR, join an existing one, or start firmware provisioning.',
                    style: Theme.of(sheetContext).textTheme.bodyMedium
                        ?.copyWith(color: const Color(0xFF667085)),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(
                      Icons.qr_code_2_rounded,
                      color: Color(0xFF0F4FDB),
                    ),
                    title: const Text('Create Rollator QR'),
                    subtitle: const Text(
                      'Generate a unique QR code from Firestore',
                    ),
                    onTap: () async {
                      await Navigator.of(sheetContext).maybePop();
                      await Future<void>.delayed(
                        const Duration(milliseconds: 200),
                      );
                      if (context.mounted) {
                        _showCreateRollatorBottomSheet(context);
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.login_rounded,
                      color: Color(0xFF0F4FDB),
                    ),
                    title: const Text('Join Rollator'),
                    subtitle: const Text('Claim a rollator using the QR code'),
                    onTap: () async {
                      await Navigator.of(sheetContext).maybePop();
                      await Future<void>.delayed(
                        const Duration(milliseconds: 200),
                      );
                      if (context.mounted) {
                        _showJoinRollatorDialog(context);
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.router_rounded,
                      color: Color(0xFF0F4FDB),
                    ),
                    title: const Text('Firmware Provisioning'),
                    subtitle: const Text(
                      'Scan QR, cek AP, dan kirim WiFi rumah',
                    ),
                    onTap: () async {
                      await Navigator.of(sheetContext).maybePop();
                      await Future<void>.delayed(
                        const Duration(milliseconds: 200),
                      );
                      if (context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FirmwareProvisioningPage(
                              rollatorRepository: rollatorRepository,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showJoinRollatorDialog(BuildContext context) async {
    final result = await showDialog<RollatorClaimResult>(
      context: context,
      builder: (dialogContext) =>
          _JoinRollatorDialog(rollatorRepository: rollatorRepository),
    );

    if (!context.mounted || result == null) return;

    if (result.success) {
      final rollator = result.rollator!;
      await RollatorSessionStore.saveDeviceSession(
        rollatorCode: rollator.code,
        deviceName: rollator.label,
      );
      _goToDashboard(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  Future<void> _showCreateRollatorBottomSheet(BuildContext context) async {
    // Show a bottom sheet that owns its own controller and disposes it properly.
    final record = await showModalBottomSheet<RollatorRecord>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) =>
          _CreateRollatorSheet(rollatorRepository: rollatorRepository),
    );

    if (!context.mounted || record == null) {
      return;
    }

    await RollatorSessionStore.saveDeviceSession(
      rollatorCode: record.code,
      deviceName: record.label,
    );

    // Give the previous bottom sheet a short moment to fully unmount before
    // presenting the next one.
    await Future<void>.delayed(const Duration(milliseconds: 200));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Rollator QR Created',
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F8FC),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: QrImageView(
                    data: record.code,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Firestore code: ${record.code}',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QrScannerMock extends StatelessWidget {
  const _QrScannerMock({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 248,
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD7DEEA), width: 1.2),
        ),
        child: Stack(
          children: [
            CustomPaint(
              painter: _QrCornerPainter(),
              child: const SizedBox.expand(),
            ),
            Center(
              child: Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.86),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFDCE6F7)),
                ),
                child: Icon(
                  Icons.qr_code_2_rounded,
                  size: 66,
                  color: const Color(0xFFBED0F5),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0x00FFFFFF),
                      Color(0xFF0F4FDB),
                      Color(0x00FFFFFF),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F4FDB).withOpacity(0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1649E4)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 22.0;
    const padding = 14.0;

    void drawCorner(Offset start, Offset horizontal, Offset vertical) {
      canvas.drawLine(start, start + horizontal, paint);
      canvas.drawLine(start, start + vertical, paint);
    }

    drawCorner(
      const Offset(padding, padding),
      const Offset(cornerLength, 0),
      const Offset(0, cornerLength),
    );
    drawCorner(
      Offset(size.width - padding, padding),
      const Offset(-cornerLength, 0),
      const Offset(0, cornerLength),
    );
    drawCorner(
      Offset(padding, size.height - padding),
      const Offset(cornerLength, 0),
      const Offset(0, -cornerLength),
    );
    drawCorner(
      Offset(size.width - padding, size.height - padding),
      const Offset(-cornerLength, 0),
      const Offset(0, -cornerLength),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RollatorQrScannerPage extends StatefulWidget {
  const _RollatorQrScannerPage();

  @override
  State<_RollatorQrScannerPage> createState() => _RollatorQrScannerPageState();
}

class _RollatorQrScannerPageState extends State<_RollatorQrScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _didReturnResult = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_didReturnResult) {
      return;
    }

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue?.trim();
      if (rawValue == null || rawValue.isEmpty) {
        continue;
      }

      _didReturnResult = true;
      Navigator.of(context).pop(rawValue);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1220),
        foregroundColor: Colors.white,
        title: const Text('Scan Rollator QR'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        controller: _controller,
                        onDetect: _handleDetect,
                      ),
                      IgnorePointer(
                        child: CustomPaint(
                          painter: _ScannerOverlayPainter(),
                          child: const SizedBox.expand(),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.72),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Arahkan kamera ke QR rollator. Saat kode terbaca, app akan langsung menghubungkan akunmu.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.white, height: 1.35),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Close Scanner'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dimPaint = Paint()..color = Colors.black.withOpacity(0.45);
    canvas.drawRect(Offset.zero & size, dimPaint);

    final frameWidth = size.width * 0.72;
    final frameHeight = size.width * 0.72;
    final frameLeft = (size.width - frameWidth) / 2;
    final frameTop = (size.height - frameHeight) / 2 - 32;
    final frameRect = Rect.fromLTWH(
      frameLeft,
      frameTop,
      frameWidth,
      frameHeight,
    );

    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, dimPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(24)),
      Paint()
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.fill,
    );
    canvas.restore();

    final borderPaint = Paint()
      ..color = const Color(0xFF0F4FDB)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(24)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

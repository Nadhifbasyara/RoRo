part of roro_main;

class FirmwareProvisioningPage extends StatefulWidget {
  const FirmwareProvisioningPage({
    super.key,
    required this.rollatorRepository,
    this.initialRollatorCode,
  });

  final RollatorRepository rollatorRepository;
  final String? initialRollatorCode;

  @override
  State<FirmwareProvisioningPage> createState() =>
      _FirmwareProvisioningPageState();
}

class _FirmwareProvisioningPageState extends State<FirmwareProvisioningPage> {
  final RollatorFirmwareClient _client = RollatorFirmwareClient();
  final TextEditingController _rollatorCodeController = TextEditingController();
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _staIpController = TextEditingController();

  FirmwareApiResponse? _statusResponse;
  FirmwareApiResponse? _lastActionResponse;
  bool _checkingStatus = false;
  bool _checkingStaStatus = false;
  bool _sendingWifi = false;
  bool _startingProvisioning = false;
  bool _continuingToApp = false;
  bool _canContinue = false;
  String? _scannedRollatorCode;
  RollatorQrPayload? _scannedQrPayload;
  String? _restartMessage;
  int? _restartSecondsLeft;
  Timer? _restartTimer;

  @override
  void initState() {
    super.initState();
    final initialCode = widget.initialRollatorCode?.trim();
    if (initialCode != null && initialCode.isNotEmpty) {
      final payload = RollatorQrPayload.parse(initialCode);
      _scannedQrPayload = payload;
      _scannedRollatorCode = payload.rollatorCode;
      _rollatorCodeController.text = payload.rollatorCode;
    }
  }

  @override
  void dispose() {
    _rollatorCodeController.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    _staIpController.dispose();
    _restartTimer?.cancel();
    super.dispose();
  }

  Future<void> _scanRollatorQr() async {
    final scannedCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _RollatorQrScannerPage(),
      ),
    );

    if (!mounted || scannedCode == null || scannedCode.trim().isEmpty) {
      return;
    }

    setState(() {
      _scannedQrPayload = RollatorQrPayload.parse(scannedCode);
      _scannedRollatorCode = _scannedQrPayload!.rollatorCode;
      _rollatorCodeController.text = _scannedRollatorCode!;
      _lastActionResponse = null;
      _statusResponse = null;
      _restartMessage = null;
      _restartSecondsLeft = null;
      _canContinue = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rollator QR tersimpan: $_scannedRollatorCode')),
    );
  }

  Future<void> _checkStatus() async {
    setState(() => _checkingStatus = true);
    try {
      final response = await _client.fetchStatus();
      if (!mounted) return;
      setState(() {
        _statusResponse = response;
        _lastActionResponse = response;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.ok ? 'Status AP berhasil dibaca.' : response.message,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _lastActionResponse = FirmwareApiResponse(
          ok: false,
          message: error.toString(),
          rawBody: error.toString(),
          statusCode: 0,
          data: const <String, dynamic>{},
        );
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal cek status: $error')));
    } finally {
      if (mounted) {
        setState(() => _checkingStatus = false);
      }
    }
  }

  Future<void> _checkStaStatus() async {
    final staHost = _normalizeStaHost(_staIpController.text);
    if (staHost == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Isi IP ESP32 atau rorro.local dulu untuk cek status STA.',
          ),
        ),
      );
      return;
    }

    setState(() => _checkingStaStatus = true);
    try {
      final response = await _client.fetchStatus(targetHost: staHost);
      if (!mounted) return;
      setState(() {
        _statusResponse = response;
        _lastActionResponse = response;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.ok ? 'Status STA berhasil dibaca.' : response.message,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _lastActionResponse = FirmwareApiResponse(
          ok: false,
          message: error.toString(),
          rawBody: error.toString(),
          statusCode: 0,
          data: const <String, dynamic>{},
        );
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal cek status STA: $error')));
    } finally {
      if (mounted) {
        setState(() => _checkingStaStatus = false);
      }
    }
  }

  Future<void> _sendWifi() async {
    final ssid = _ssidController.text.trim();
    final password = _passwordController.text;
    if (ssid.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('SSID rumah belum diisi.')));
      return;
    }

    setState(() => _sendingWifi = true);
    try {
      final response = await _client.submitWifiCredentials(
        ssid: ssid,
        password: password,
      );
      if (!mounted) return;

      setState(() {
        _lastActionResponse = response;
        _statusResponse = response;
      });

      if (response.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.message.isEmpty ? 'WiFi terkirim.' : response.message,
            ),
          ),
        );
        _startRestartCountdown(response.restartInMs);
        if ((response.restartInMs ?? 0) <= 0) {
          setState(() {
            _canContinue = true;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.message.isEmpty
                  ? 'WiFi gagal dikirim.'
                  : response.message,
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _lastActionResponse = FirmwareApiResponse(
          ok: false,
          message: error.toString(),
          rawBody: error.toString(),
          statusCode: 0,
          data: const <String, dynamic>{},
        );
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal kirim WiFi: $error')));
    } finally {
      if (mounted) {
        setState(() => _sendingWifi = false);
      }
    }
  }

  Future<void> _startWifiChange() async {
    final staHost = _normalizeStaHost(_staIpController.text);
    if (staHost == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi IP ESP32 mode STA dulu, contoh: 192.168.1.25.'),
        ),
      );
      return;
    }

    setState(() => _startingProvisioning = true);
    try {
      final response = await _client.startProvisioning(targetHost: staHost);
      if (!mounted) return;

      setState(() {
        _lastActionResponse = response;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.ok ? 'Mode provisioning dimulai.' : response.message,
          ),
        ),
      );

      if (response.ok) {
        _startRestartCountdown(response.restartInMs);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _lastActionResponse = FirmwareApiResponse(
          ok: false,
          message: error.toString(),
          rawBody: error.toString(),
          statusCode: 0,
          data: const <String, dynamic>{},
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mulai provisioning: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _startingProvisioning = false);
      }
    }
  }

  String? _normalizeStaHost(String value) {
    var host = value.trim();
    if (host.isEmpty) {
      return null;
    }

    host = host.replaceFirst(RegExp(r'^https?://'), '');
    final slashIndex = host.indexOf('/');
    if (slashIndex >= 0) {
      host = host.substring(0, slashIndex);
    }

    host = host.trim();
    return host.isEmpty ? null : host;
  }

  void _startRestartCountdown(int? restartInMs) {
    _restartTimer?.cancel();
    if (restartInMs == null || restartInMs <= 0) {
      setState(() {
        _restartMessage =
            'Perangkat sedang restart. Tunggu beberapa detik lalu sambungkan lagi ke AP.';
        _restartSecondsLeft = null;
        _canContinue = true;
      });
      return;
    }

    setState(() {
      _restartSecondsLeft = (restartInMs / 1000).ceil();
      _restartMessage = 'Perangkat akan restart otomatis.';
      _canContinue = false;
    });

    _restartTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final nextValue = (_restartSecondsLeft ?? 0) - 1;
      if (nextValue <= 0) {
        timer.cancel();
        setState(() {
          _restartSecondsLeft = null;
          _restartMessage =
              'Restart selesai. Silakan sambungkan lagi ke AP perangkat dan ulangi langkah status/WiFi jika perlu.';
          _canContinue = true;
        });
        return;
      }

      setState(() {
        _restartSecondsLeft = nextValue;
      });
    });
  }

  Future<void> _continueToApp() async {
    final code = _scannedRollatorCode ?? _rollatorCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Scan QR perangkat dulu.')));
      return;
    }

    setState(() {
      _continuingToApp = true;
    });

    try {
      final claimResult = await widget.rollatorRepository
          .claimCurrentUserToRollator(code);
      if (!mounted) return;

      if (!claimResult.success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(claimResult.message)));
        return;
      }

      await RollatorSessionStore.saveDeviceSession(
        rollatorCode: code,
        deviceName: _scannedQrPayload?.deviceName,
        ipAddress: _scannedQrPayload?.ipAddress,
        mdnsHost: _scannedQrPayload?.mdnsHost,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal masuk ke app: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _continuingToApp = false;
        });
      }
    }
  }

  Widget _buildInfoCard({
    required String title,
    required String body,
    Color? color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5ECFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF475467),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSummary() {
    final response = _statusResponse;
    if (response == null) {
      return const SizedBox.shrink();
    }

    final fields = <String, String>{
      for (final entry in response.data.entries)
        if (entry.value != null) entry.key: entry.value.toString(),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: response.ok ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: response.ok
              ? const Color(0xFFBBF7D0)
              : const Color(0xFFFECACA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            response.ok ? 'AP status ok' : 'AP status error',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: response.ok
                  ? const Color(0xFF166534)
                  : const Color(0xFF991B1B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            response.message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: response.ok
                  ? const Color(0xFF166534)
                  : const Color(0xFF991B1B),
              height: 1.45,
            ),
          ),
          if (response.restartInMs != null) ...[
            const SizedBox(height: 8),
            Text(
              'restart_in_ms: ${response.restartInMs}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
          if (fields.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: fields.entries
                  .take(6)
                  .map(
                    (entry) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: response.ok
                              ? const Color(0xFFBBF7D0)
                              : const Color(0xFFFECACA),
                        ),
                      ),
                      child: Text(
                        '${entry.key}: ${entry.value}',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingGuide() {
    String body;
    if (_checkingStatus) {
      body =
          'Aplikasi sedang memanggil GET /api/status ke 192.168.4.1. Tetap berada di WiFi AP perangkat sampai response muncul.';
    } else if (_checkingStaStatus) {
      final staHost = _normalizeStaHost(_staIpController.text) ?? '<IP_ESP32>';
      body =
          'Aplikasi sedang memanggil GET http://$staHost/api/status untuk memastikan HP bisa menjangkau ESP32 saat mode STA.';
    } else if (_sendingWifi) {
      body =
          'Aplikasi sedang mengirim SSID dan password sebagai JSON ke POST /api/wifi. Jangan pindah WiFi dulu sampai perangkat memberi response.';
    } else if (_startingProvisioning) {
      final staHost = _normalizeStaHost(_staIpController.text) ?? '<IP_ESP32>';
      body =
          'Aplikasi sedang meminta perangkat masuk mode provisioning lewat POST http://$staHost/api/provisioning/start dengan body {"reason":"change_wifi"}. Setelah sukses, perangkat akan restart ke mode AP.';
    } else {
      return const SizedBox.shrink();
    }

    return _buildInfoCard(
      title: 'Sedang loading',
      body: body,
      color: const Color(0xFFEFF6FF),
    );
  }

  String _actionResponseBody(FirmwareApiResponse response) {
    if (response.ok) {
      return response.message.isEmpty
          ? 'Perintah diterima firmware. Ikuti instruksi restart atau lanjutkan jika setup sudah selesai.'
          : response.message;
    }

    final details = <String>[
      response.message.isEmpty
          ? 'Firmware mengembalikan error tanpa pesan.'
          : response.message,
      '',
      'Yang perlu dicek:',
      '1) HP masih tersambung ke AP ESP/RoRo, bukan WiFi rumah.',
      '2) Endpoint firmware aktif di http://192.168.4.1.',
      '3) Untuk WiFi rumah, request dikirim ke POST /api/wifi dengan JSON berisi ssid dan password.',
      '4) IP STA bisa didapat dari log serial "[WiFi] Connected. IP: x.x.x.x" atau dari router.',
      '5) Untuk Ubah WiFi saat STA, request harus ke IP ESP32 dari router/log serial atau rorro.local jika mDNS tersedia, bukan 192.168.4.1.',
      '6) Jika muncul request handler not found, berarti ada request ke path yang tidak terdaftar, misalnya /.',
      '7) Jika timeout, ulangi setelah perangkat selesai restart atau matikan-nyalakan perangkat.',
    ];

    if (response.statusCode > 0) {
      details.insert(1, 'HTTP status: ${response.statusCode}.');
    }

    return details.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text('Firmware Provisioning'),
        backgroundColor: const Color(0xFFF6F8FC),
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(
                title: 'Alur provisioning',
                body:
                    'A. Provisioning pertama kali: 1) Scan QR rollator untuk menyimpan device_id. 2) Sambungkan HP ke SSID AP ESP/RoRo, misalnya "RoRo R1"; internet HP boleh terputus sementara. 3) Tekan Cek status AP untuk memastikan GET http://192.168.4.1/api/status bisa dijangkau. 4) Isi SSID dan password WiFi rumah. 5) Tekan Kirim WiFi; aplikasi mengirim JSON ke POST http://192.168.4.1/api/wifi. 6) Jika ok=true, ESP menyimpan kredensial lalu restart sesuai restart_in_ms. 7) Setelah restart, ESP masuk mode STA dan AP mati. IP STA bisa didapat dari log serial "[WiFi] Connected. IP: x.x.x.x" atau dari router. B. Ubah WiFi saat STA: HP harus satu WiFi dengan ESP32, isi IP ESP32 dari router/log serial atau rorro.local jika mDNS tersedia, verifikasi GET http://rorro.local/api/status atau GET http://<IP_ESP32>/api/status, lalu kirim POST http://<IP_ESP32>/api/provisioning/start dengan body {"reason":"change_wifi"}. ESP restart ke mode AP, lalu ulangi langkah A.2-A.6.',
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'Langkah 1 - QR perangkat',
                body: _scannedRollatorCode == null
                    ? 'Scan QR dari perangkat untuk menyimpan id rollator.'
                    : 'Rollator id tersimpan: $_scannedRollatorCode',
                color: const Color(0xFFEFF6FF),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _scanRollatorQr,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: Text(
                    _scannedRollatorCode == null
                        ? 'Scan QR perangkat'
                        : 'Scan QR ulang',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _rollatorCodeController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Rollator ID',
                  hintText: 'Hasil scan QR akan muncul di sini',
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'Langkah 2 - Hubungkan ke AP',
                body:
                    'Pindahkan HP ke WiFi AP perangkat dengan SSID sesuai firmware. Android/iOS mungkin menampilkan peringatan "tanpa internet"; tetap pilih jaringan ini. Setelah tersambung, tekan "Cek status AP". Jika gagal atau timeout, pastikan alamat firmware 192.168.4.1 aktif dan HP belum otomatis pindah ke WiFi lain.',
                color: const Color(0xFFFFFBEB),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _checkingStatus ? null : _checkStatus,
                  icon: _checkingStatus
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering_rounded),
                  label: Text(
                    _checkingStatus ? 'Mengecek status...' : 'Cek status AP',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildStatusSummary(),
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'Langkah 4 - WiFi rumah',
                body:
                    'Isi SSID dan password WiFi rumah, lalu kirim ke perangkat. Data dikirim ke POST /api/wifi dalam format JSON. Jika password kosong, firmware akan menerima password kosong; pastikan SSID persis sama dengan nama WiFi rumah, termasuk huruf besar/kecil.',
                color: const Color(0xFFF0FDF4),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ssidController,
                decoration: const InputDecoration(
                  labelText: 'SSID WiFi rumah',
                  hintText: 'Contoh: MyHomeWiFi',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password WiFi rumah',
                  hintText: 'Masukkan password',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _sendingWifi ? null : _sendWifi,
                  icon: _sendingWifi
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _sendingWifi ? 'Mengirim...' : 'Kirim WiFi ke perangkat',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildLoadingGuide(),
              if (_checkingStatus ||
                  _checkingStaStatus ||
                  _sendingWifi ||
                  _startingProvisioning)
                const SizedBox(height: 12),
              if (_restartMessage != null)
                _buildInfoCard(
                  title: 'Restart perangkat',
                  body: _restartSecondsLeft == null
                      ? '$_restartMessage Jika AP belum muncul atau perangkat belum online, tunggu 10-20 detik lagi lalu cek ulang.'
                      : '$_restartMessage Sisa waktu: ${_restartSecondsLeft!} detik. Selama restart, request bisa timeout dan WiFi AP bisa hilang sebentar.',
                  color: const Color(0xFFEEF2FF),
                ),
              if (_lastActionResponse != null) ...[
                const SizedBox(height: 12),
                _buildInfoCard(
                  title: _lastActionResponse!.ok
                      ? 'Response sukses'
                      : 'Response error',
                  body: _actionResponseBody(_lastActionResponse!),
                  color: _lastActionResponse!.ok
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFFEF2F2),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed:
                      _canContinue &&
                          !_startingProvisioning &&
                          !_continuingToApp
                      ? _continueToApp
                      : null,
                  icon: _continuingToApp
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login_rounded),
                  label: Text(
                    _canContinue
                        ? 'Lanjut ke Aplikasi'
                        : 'Tunggu setup selesai',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                title: 'Mode STA - Ubah WiFi',
                body:
                    'Jika perangkat sudah masuk STA dan kamu ingin memulai provisioning ulang, pastikan HP berada di WiFi yang sama dengan ESP32. Isi IP ESP32 dari router/log serial "[WiFi] Connected. IP: x.x.x.x", atau isi rorro.local jika mDNS tersedia. Cek status STA dulu jika perlu, lalu aplikasi akan memanggil POST http://<IP_ESP32>/api/provisioning/start dengan body JSON {"reason":"change_wifi"}. Jika sukses, ESP restart dan membuka AP lagi.',
                color: const Color(0xFFF8FAFF),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _staIpController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'IP ESP32 / mDNS mode STA',
                  hintText: 'Contoh: 192.168.1.25 atau rorro.local',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _checkingStaStatus ? null : _checkStaStatus,
                  icon: _checkingStaStatus
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.network_check_rounded),
                  label: Text(
                    _checkingStaStatus ? 'Mengecek STA...' : 'Cek status STA',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _startingProvisioning || _checkingStaStatus
                      ? null
                      : _startWifiChange,
                  icon: _startingProvisioning
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.restart_alt_rounded),
                  label: Text(
                    _startingProvisioning ? 'Memulai...' : 'Ubah WiFi',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Setelah perangkat restart ke mode AP, sambungkan HP ke AP itu lagi lalu ulangi langkah 2-6.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

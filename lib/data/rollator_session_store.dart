import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class RollatorSessionStore {
  static const String _activeRollatorCodeKey = 'active_rollator_code';
  static const String _activeDeviceNameKey = 'active_device_name';
  static const String _activeDeviceIpKey = 'active_device_ip';
  static const String _activeDeviceMdnsKey = 'active_device_mdns';

  static Future<void> saveRollatorCode(String rollatorCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeRollatorCodeKey, rollatorCode.trim());
  }

  static Future<void> saveDeviceSession({
    required String rollatorCode,
    String? deviceName,
    String? ipAddress,
    String? mdnsHost,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeRollatorCodeKey, rollatorCode.trim());
    await _setOrRemove(prefs, _activeDeviceNameKey, deviceName);
    await _setOrRemove(prefs, _activeDeviceIpKey, ipAddress);
    await _setOrRemove(prefs, _activeDeviceMdnsKey, mdnsHost);
  }

  static Future<String?> loadRollatorCode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_activeRollatorCodeKey);
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static Future<bool> hasActiveSession() async {
    return (await loadRollatorCode()) != null;
  }

  static Future<RollatorDeviceSession?> loadDeviceSession() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_activeRollatorCodeKey)?.trim();
    if (code == null || code.isEmpty) {
      return null;
    }

    return RollatorDeviceSession(
      rollatorCode: code,
      deviceName: _readOptional(prefs, _activeDeviceNameKey),
      ipAddress: _readOptional(prefs, _activeDeviceIpKey),
      mdnsHost: _readOptional(prefs, _activeDeviceMdnsKey),
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeRollatorCodeKey);
    await prefs.remove(_activeDeviceNameKey);
    await prefs.remove(_activeDeviceIpKey);
    await prefs.remove(_activeDeviceMdnsKey);
  }

  static Future<void> _setOrRemove(
    SharedPreferences prefs,
    String key,
    String? value,
  ) async {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, trimmed);
  }

  static String? _readOptional(SharedPreferences prefs, String key) {
    final value = prefs.getString(key)?.trim();
    return value == null || value.isEmpty ? null : value;
  }
}

class RollatorDeviceSession {
  const RollatorDeviceSession({
    required this.rollatorCode,
    this.deviceName,
    this.ipAddress,
    this.mdnsHost,
  });

  final String rollatorCode;
  final String? deviceName;
  final String? ipAddress;
  final String? mdnsHost;
}

class RollatorQrPayload {
  const RollatorQrPayload({
    required this.rollatorCode,
    this.deviceName,
    this.ipAddress,
    this.mdnsHost,
  });

  final String rollatorCode;
  final String? deviceName;
  final String? ipAddress;
  final String? mdnsHost;

  factory RollatorQrPayload.parse(String rawValue) {
    final raw = rawValue.trim();
    if (raw.isEmpty) {
      return const RollatorQrPayload(rollatorCode: '');
    }

    final decodedJson = _tryDecodeJson(raw);
    if (decodedJson != null) {
      return RollatorQrPayload(
        rollatorCode:
            _firstString(decodedJson, const [
              'device_id',
              'deviceId',
              'rollator_id',
              'rollatorId',
              'rollator_code',
              'code',
              'id',
            ]) ??
            raw,
        deviceName: _firstString(decodedJson, const [
          'device_name',
          'deviceName',
          'name',
          'label',
        ]),
        ipAddress: _firstString(decodedJson, const ['sta_ip', 'staIp', 'ip']),
        mdnsHost: _firstString(decodedJson, const [
          'mdns',
          'mdns_host',
          'mdnsHost',
          'hostname',
        ]),
      );
    }

    final parsedUri = Uri.tryParse(raw);
    if (parsedUri != null && parsedUri.queryParameters.isNotEmpty) {
      final params = parsedUri.queryParameters;
      return RollatorQrPayload(
        rollatorCode:
            _firstString(params, const [
              'device_id',
              'rollator_id',
              'code',
              'id',
            ]) ??
            raw,
        deviceName: _firstString(params, const [
          'device_name',
          'name',
          'label',
        ]),
        ipAddress: _firstString(params, const ['sta_ip', 'ip']),
        mdnsHost: _firstString(params, const ['mdns', 'mdns_host', 'hostname']),
      );
    }

    return RollatorQrPayload(rollatorCode: raw);
  }

  static Map<String, dynamic>? _tryDecodeJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static String? _firstString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}

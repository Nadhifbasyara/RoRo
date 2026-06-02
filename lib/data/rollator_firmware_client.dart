import 'dart:convert';

import 'package:http/http.dart' as http;

class RollatorFirmwareClient {
  RollatorFirmwareClient({http.Client? client, this.host = '192.168.4.1'})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String host;

  Uri _uri(String path, {String? targetHost}) =>
      Uri.parse('http://${targetHost ?? host}$path');

  Future<FirmwareApiResponse> fetchStatus({String? targetHost}) {
    return _request('GET', '/api/status', targetHost: targetHost);
  }

  Future<FirmwareApiResponse> startProvisioning({
    String? targetHost,
    String reason = 'change_wifi',
  }) {
    return _request(
      'POST',
      '/api/provisioning/start',
      targetHost: targetHost,
      body: <String, String>{'reason': reason},
    );
  }

  Future<FirmwareApiResponse> submitWifiCredentials({
    required String ssid,
    required String password,
  }) {
    return _request(
      'POST',
      '/api/wifi',
      body: <String, String>{'ssid': ssid, 'password': password},
    );
  }

  Future<FirmwareApiResponse> _request(
    String method,
    String path, {
    String? targetHost,
    Map<String, dynamic>? body,
  }) async {
    final request = http.Request(method, _uri(path, targetHost: targetHost))
      ..headers['Accept'] = 'application/json';

    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    return _send(request);
  }

  Future<FirmwareApiResponse> _send(http.Request request) async {
    final streamedResponse = await _client
        .send(request)
        .timeout(const Duration(seconds: 8));
    final response = await http.Response.fromStream(streamedResponse);
    return FirmwareApiResponse.fromHttp(response);
  }
}

class FirmwareApiResponse {
  const FirmwareApiResponse({
    required this.ok,
    required this.message,
    required this.rawBody,
    required this.statusCode,
    required this.data,
    this.restartInMs,
  });

  final bool ok;
  final String message;
  final String rawBody;
  final int statusCode;
  final Map<String, dynamic> data;
  final int? restartInMs;

  factory FirmwareApiResponse.fromHttp(http.Response response) {
    final rawBody = response.body.trim();
    Map<String, dynamic> data = <String, dynamic>{};

    if (rawBody.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawBody);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {
        data = <String, dynamic>{};
      }
    }

    final ok =
        response.statusCode >= 200 &&
        response.statusCode < 300 &&
        (data['ok'] as bool? ?? true);
    final message =
        (data['message'] as String?)?.trim() ??
        (rawBody.isNotEmpty ? rawBody : 'HTTP ${response.statusCode}');
    final restartInMs = data['restart_in_ms'] is int
        ? data['restart_in_ms'] as int
        : int.tryParse('${data['restart_in_ms']}');

    return FirmwareApiResponse(
      ok: ok,
      message: message,
      rawBody: rawBody,
      statusCode: response.statusCode,
      data: data,
      restartInMs: restartInMs,
    );
  }
}

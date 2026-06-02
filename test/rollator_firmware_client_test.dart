import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:roro/data/rollator_firmware_client.dart';

void main() {
  test('submitWifiCredentials posts JSON credentials to firmware', () async {
    http.BaseRequest? capturedRequest;

    final client = RollatorFirmwareClient(
      client: _CaptureClient((request) async {
        capturedRequest = request;
        return http.Response(
          '{"ok":true,"message":"saved","restart_in_ms":1000}',
          200,
        );
      }),
    );

    final response = await client.submitWifiCredentials(
      ssid: 'Home WiFi',
      password: 'secret123',
    );

    final request = capturedRequest as http.Request;
    expect(response.ok, isTrue);
    expect(request.method, 'POST');
    expect(request.url.toString(), 'http://192.168.4.1/api/wifi');
    expect(request.headers['Content-Type'], contains('application/json'));
    expect(jsonDecode(request.body), <String, String>{
      'ssid': 'Home WiFi',
      'password': 'secret123',
    });
  });

  test('startProvisioning posts change_wifi reason to STA host', () async {
    http.BaseRequest? capturedRequest;

    final client = RollatorFirmwareClient(
      client: _CaptureClient((request) async {
        capturedRequest = request;
        return http.Response('{"ok":true,"message":"restarting"}', 200);
      }),
    );

    final response = await client.startProvisioning(targetHost: '192.168.1.25');

    final request = capturedRequest as http.Request;
    expect(response.ok, isTrue);
    expect(request.method, 'POST');
    expect(
      request.url.toString(),
      'http://192.168.1.25/api/provisioning/start',
    );
    expect(request.headers['Content-Type'], contains('application/json'));
    expect(jsonDecode(request.body), <String, String>{'reason': 'change_wifi'});
  });

  test('fetchStatus can verify STA or mDNS host', () async {
    http.BaseRequest? capturedRequest;

    final client = RollatorFirmwareClient(
      client: _CaptureClient((request) async {
        capturedRequest = request;
        return http.Response('{"ok":true,"mode":"sta"}', 200);
      }),
    );

    final response = await client.fetchStatus(targetHost: 'rorro.local');

    final request = capturedRequest as http.Request;
    expect(response.ok, isTrue);
    expect(request.method, 'GET');
    expect(request.url.toString(), 'http://rorro.local/api/status');
  });
}

class _CaptureClient extends http.BaseClient {
  _CaptureClient(this._handler);

  final Future<http.Response> Function(http.BaseRequest request) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _handler(request);
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

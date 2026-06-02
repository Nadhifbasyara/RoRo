import 'package:flutter_test/flutter_test.dart';
import 'package:roro/data/rollator_session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('RollatorQrPayload parses device metadata from QR JSON', () {
    final payload = RollatorQrPayload.parse(
      '{"device_id":"RORO-01","device_name":"RoRo R1","sta_ip":"192.168.1.25","mdns":"rorro.local"}',
    );

    expect(payload.rollatorCode, 'RORO-01');
    expect(payload.deviceName, 'RoRo R1');
    expect(payload.ipAddress, '192.168.1.25');
    expect(payload.mdnsHost, 'rorro.local');
  });

  test('RollatorSessionStore persists connected device metadata', () async {
    SharedPreferences.setMockInitialValues({});

    await RollatorSessionStore.saveDeviceSession(
      rollatorCode: 'RORO-01',
      deviceName: 'RoRo R1',
      ipAddress: '192.168.1.25',
      mdnsHost: 'rorro.local',
    );

    final session = await RollatorSessionStore.loadDeviceSession();

    expect(session?.rollatorCode, 'RORO-01');
    expect(session?.deviceName, 'RoRo R1');
    expect(session?.ipAddress, '192.168.1.25');
    expect(session?.mdnsHost, 'rorro.local');
  });
}

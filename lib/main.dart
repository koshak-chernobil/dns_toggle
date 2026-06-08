import 'package:flutter/material.dart';
import 'package:flutter_vpn_service/flutter_vpn_service.dart';
import 'package:quick_settings/quick_settings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final notifications = FlutterLocalNotificationsPlugin();

@pragma("vm:entry-point")
Tile onTileClicked(Tile tile) {
  if (tile.tileStatus == TileStatus.active) {
    _stopDns();
    tile.label = "DNS OFF";
    tile.tileStatus = TileStatus.inactive;
  } else {
    _startDns();
    tile.label = "DNS ON";
    tile.tileStatus = TileStatus.active;
  }
  return tile;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await notifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  
  QuickSettings.setup(onTileClicked: onTileClicked);
  
  runApp(const MyApp());
}

Future<void> _startDns() async {
  try {
    await FlutterVpnService.prepare();
    await FlutterVpnService.addAddress("0.0.0.0", 0);
    await FlutterVpnService.addRoute("0.0.0.0", 0);
    await FlutterVpnService.setDnsAddresses(["1.1.1.1", "1.0.0.1"]);
    await FlutterVpnService.establish();
    
    await notifications.show(
      1,
      'DNS Toggle',
      '✅ DNS ВКЛЮЧЕН',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'dns_channel',
          'DNS Toggle',
          importance: Importance.high,
        ),
      ),
    );
  } catch (e) {
    await notifications.show(3, 'Ошибка', e.toString(), const NotificationDetails(android: AndroidNotificationDetails('dns_channel', 'DNS Toggle')));
  }
}

Future<void> _stopDns() async {
  try {
    await FlutterVpnService.stop();
    await notifications.show(
      2,
      'DNS Toggle',
      '❌ DNS ВЫКЛЮЧЕН',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'dns_channel',
          'DNS Toggle',
          importance: Importance.high,
        ),
      ),
    );
  } catch (e) {
    await notifications.show(3, 'Ошибка', e.toString(), const NotificationDetails(android: AndroidNotificationDetails('dns_channel', 'DNS Toggle')));
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDnsActive = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final isRunning = await FlutterVpnService.isRunning() ?? false;
    setState(() {
      _isDnsActive = isRunning;
    });
  }

  Future<void> _toggleDns() async {
    if (!_isDnsActive) {
      await _startDns();
    } else {
      await _stopDns();
    }
    await _checkStatus();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('DNS Toggle'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isDnsActive ? Icons.vpn_key : Icons.vpn_lock,
                size: 80,
                color: _isDnsActive ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 20),
              Text(
                _isDnsActive ? 'DNS ВКЛЮЧЕН' : 'DNS ВЫКЛЮЧЕН',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _isDnsActive ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _toggleDns,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isDnsActive ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text(_isDnsActive ? 'ВЫКЛЮЧИТЬ' : 'ВКЛЮЧИТЬ'),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  QuickSettings.addTileToQuickSettings(
                    label: 'DNS Toggle',
                    drawableName: 'ic_quick_settings',
                  );
                },
                child: const Text('➕ Добавить плитку в шторку'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

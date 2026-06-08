import 'package:flutter/material.dart';
import 'package:flutter_vpn_service/flutter_vpn_service.dart';
import 'package:quick_settings_tile/quick_settings_tile.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final notifications = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await notifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  
  _initQuickSettingsTile();
  runApp(const MyApp());
}

void _initQuickSettingsTile() {
  QuickSettingsTile.setClickHandler(() async {
    final isRunning = await FlutterVpnService.isRunning() ?? false;
    
    if (!isRunning) {
      await _startDns();
    } else {
      await _stopDns();
    }
  });
}

Future<void> _startDns() async {
  await FlutterVpnService.prepare();
  await FlutterVpnService.addAddress("0.0.0.0", 0);
  await FlutterVpnService.addRoute("0.0.0.0", 0);
  await FlutterVpnService.setDnsAddresses(["1.1.1.1", "1.0.0.1"]);
  await FlutterVpnService.establish();
  
  await notifications.show(
    1,
    'DNS Toggle',
    'DNS профиль ВКЛЮЧЕН',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'dns_channel',
        'DNS Toggle',
        importance: Importance.high,
      ),
    ),
  );
  QuickSettingsTile.updateTileState(TileState.ACTIVE);
}

Future<void> _stopDns() async {
  await FlutterVpnService.stop();
  
  await notifications.show(
    2,
    'DNS Toggle',
    'DNS профиль ВЫКЛЮЧЕН',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'dns_channel',
        'DNS Toggle',
        importance: Importance.high,
      ),
    ),
  );
  QuickSettingsTile.updateTileState(TileState.INACTIVE);
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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _isDnsActive ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isDnsActive ? '✅ DNS ВКЛЮЧЕН' : '❌ DNS ВЫКЛЮЧЕН',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _toggleDns,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isDnsActive ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: Text(_isDnsActive ? 'ВЫКЛЮЧИТЬ DNS' : 'ВКЛЮЧИТЬ DNS'),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  QuickSettingsTile.addTileToQuickSettings(
                    label: 'DNS Toggle',
                    drawableName: 'ic_quick_settings',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('➕ Добавить плитку в шторку'),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  'После добавления плитки откройте шторку и нажмите на неё для быстрого переключения DNS',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

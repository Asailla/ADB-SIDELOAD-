import 'package:flutter/material.dart';
import 'screens/pair_screen.dart';
import 'screens/connect_screen.dart';
import 'screens/install_screen.dart';
import 'screens/tools_screen.dart';
import 'services/device_storage_service.dart';
import 'services/adb_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final storage = DeviceStorageService();
  await storage.initialize();
  
  final adbService = AdbService(storage: storage);
  
  runApp(AdbSchoolLoaderApp(
    storage: storage,
    adbService: adbService,
  ));
}

class AdbSchoolLoaderApp extends StatelessWidget {
  final DeviceStorageService storage;
  final AdbService adbService;

  const AdbSchoolLoaderApp({
    super.key,
    required this.storage,
    required this.adbService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ADB School Loader',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
          primary: Colors.tealAccent,
          surface: const Color(0xFF1E1E1E),
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF252525),
          margin: EdgeInsets.all(8),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.tealAccent, width: 2),
          ),
        ),
      ),
      home: MainNavigationScaffold(
        storage: storage,
        adbService: adbService,
      ),
    );
  }
}

class MainNavigationScaffold extends StatefulWidget {
  final DeviceStorageService storage;
  final AdbService adbService;

  const MainNavigationScaffold({
    super.key,
    required this.storage,
    required this.adbService,
  });

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _currentIndex = 1;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      PairScreen(adbService: widget.adbService, storage: widget.storage),
      ConnectScreen(adbService: widget.adbService, storage: widget.storage),
      InstallScreen(adbService: widget.adbService),
      ToolsScreen(adbService: widget.adbService),
    ];
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerAutoReconnect();
    });
  }

  Future<void> _triggerAutoReconnect() async {
    final lastDevice = widget.storage.getLastConnectedDevice();
    final isAuto = widget.storage.getAutoReconnectSetting();
    
    if (isAuto && lastDevice != null) {
      widget.storage.addLog('[Auto] Found last connected device ${lastDevice['name'] ?? lastDevice['ip']}');
      widget.storage.addLog('[Auto] Attempting automatic reconnection...');
      
      final ip = lastDevice['ip'] ?? '';
      final port = int.tryParse(lastDevice['adbPort']?.toString() ?? '5555') ?? 5555;
      
      if (ip.isNotEmpty) {
        final success = await widget.adbService.connect(ip, port);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success
                  ? 'Auto-reconnected to ${lastDevice['name'] ?? ip} Successfully!'
                  : 'Auto-reconnect failed. Check target IP and device status.'),
              backgroundColor: success ? Colors.green : Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADB School Loader'),
        centerTitle: true,
        actions: [
          StreamBuilder<bool>(
            stream: widget.adbService.connectionStateStream,
            initialData: false,
            builder: (context, snapshot) {
              final connected = snapshot.data ?? false;
              return Container(
                margin: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    Icon(
                      connected ? Icons.cloud_done : Icons.cloud_off,
                      color: connected ? Colors.tealAccent : Colors.redAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      connected ? 'CONNECTED' : 'DISCONNECTED',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: connected ? Colors.tealAccent : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.vpn_key), label: 'Pairing'),
          NavigationDestination(icon: Icon(Icons.devices), label: 'Connect'),
          NavigationDestination(icon: Icon(Icons.system_update), label: 'Install APKs'),
          NavigationDestination(icon: Icon(Icons.build_circle), label: 'ADB Tools'),
        ],
      ),
    );
  }
}

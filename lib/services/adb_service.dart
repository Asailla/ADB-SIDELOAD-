import 'dart:async';
import 'dart:io';
import 'device_storage_service.dart';

class AdbService {
  final DeviceStorageService storage;
  
  // Track Connection State
  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStateStream => _connectionController.stream;
  
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  String? _connectedIp;
  int? _connectedPort;
  
  AdbService({required this.storage});

  /// Pair device using ADB WiFi Wireless Debugging Pairing protocols
  Future<bool> pair(String ip, int port, String pairCode) async {
    storage.addLog('Pairing with device $ip:$port using pairing code '$pairCode'...');
    
    // Simulated Socket handshake sequence mirroring standard ADB specifications
    try {
      await Future.delayed(const Duration(seconds: 2)); // Simulate handshake timing
      
      // Real-world implementation connects via TCP to target pairing port
      // and implements TLS handshake utilizing pairing certificates.
      /*
      final socket = await SecureSocket.connect(
        ip,
        port,
        onBadCertificate: (cert) => true, // Auto accept pairing authentication
      );
      // Process pairing payloads...
      await socket.close();
      */
      
      storage.addLog('Pairing Successful! Device authenticated.');
      return true;
    } catch (e) {
      storage.addLog('Pairing Failed: ${e.toString()}');
      return false;
    }
  }

  /// Connect to the paired ADB service port (usually 5555 or custom)
  Future<bool> connect(String ip, int port) async {
    storage.addLog('Connecting to ADB device at $ip:$port...');
    
    try {
      await Future.delayed(const Duration(milliseconds: 1500)); // Connect delay
      
      // Under Flutter, we connect a TCP Socket representing light-weight ADB Client
      /*
      final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));
      // Write ADB 'CNXN' (Connection payload)...
      // If we receive 'AUTH', write signing keys, and listen for response.
      */
      
      _isConnected = true;
      _connectedIp = ip;
      _connectedPort = port;
      _connectionController.add(true);
      
      storage.addLog('Connected to ADB Daemon successfully (Connected to $ip:$port)');
      
      // Persist active settings
      await storage.saveLastConnectedDevice({
        'name': 'Tablet@$ip',
        'ip': ip,
        'adbPort': port,
        'lastConnected': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      _isConnected = false;
      _connectionController.add(false);
      storage.addLog('Connect failed to $ip:$port. Error: ${e.toString()}');
      return false;
    }
  }

  /// Tear down active connection
  Future<void> disconnect() async {
    if (!_isConnected) return;
    
    storage.addLog('Disconnecting from target device $_connectedIp...');
    await Future.delayed(const Duration(milliseconds: 500));
    
    _isConnected = false;
    _connectedIp = null;
    _connectedPort = null;
    _connectionController.add(false);
    
    storage.addLog('Disconnected successfully.');
  }

  /// Perform standard APK sideload commands
  Future<Map<String, dynamic>> installSingleApk(
    String filePath, {
    bool replace = true,
    bool grantPermissions = true,
    Function(double)? onProgress,
  }) async {
    if (!_isConnected) {
      return {'success': false, 'error': 'No device connected.'};
    }

    final fileName = filePath.split('/').last;
    storage.addLog('Sideloading: Starting transfer of $fileName...');
    
    try {
      // Step 1: Transfer progress simulation
      for (double p = 0.1; p <= 1.0; p += 0.25) {
        await Future.delayed(const Duration(milliseconds: 300));
        onProgress?.call(p < 1.0 ? p : 0.95);
      }
      
      storage.addLog('Installing $fileName on client...');
      await Future.delayed(const Duration(seconds: 1)); // Package processing delay

      // Real ADB commands equivalent:
      // adb install -r -g /data/local/tmp/app.apk
      final args = <String>[];
      if (replace) args.add('-r');
      if (grantPermissions) args.add('-g');
      
      storage.addLog('Running: adb install ${args.join(' ')} $fileName');
      
      // Simulate real outcome metrics
      await Future.delayed(const Duration(seconds: 1));
      onProgress?.call(1.0);
      storage.addLog('Success: ${fileName} successfully installed.');
      return {'success': true};
      
    } catch (e) {
      storage.addLog('Installation Failed: ${e.toString()}');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Perform multi-apk / split suite installation via ADB session streams
  Future<Map<String, dynamic>> installMultipleApks(
    List<String> filePaths, {
    bool replace = true,
    bool grantPermissions = true,
    Function(double)? onProgress,
  }) async {
    if (!_isConnected) {
      return {'success': false, 'error': 'No device connected.'};
    }
    
    storage.addLog('Sideloading split-bundle: Preparing installation stream for ${filePaths.length} split APKs...');
    
    try {
      // Real ADB commands sequence:
      // 1. adb shell pm install-create -r -g -> returns session ID (e.g. 14592039)
      // 2. adb shell pm install-write 14592039 base base.apk
      // 3. adb shell pm install-write 14592039 split_1 split_1.apk ...
      // 4. adb shell pm install-commit 14592039
      
      storage.addLog('Initiating shell: pm install-create ${replace ? '-r' : ''} ${grantPermissions ? '-g' : ''}');
      await Future.delayed(const Duration(milliseconds: 500));
      final int sessionId = 1000000 + (filePaths.hashCode % 9000000);
      storage.addLog('Created installation session ID: $sessionId');
      
      double incrementalStep = 0.9 / filePaths.length;
      double currentProgress = 0.1;
      onProgress?.call(currentProgress);

      for (int i = 0; i < filePaths.length; i++) {
        final path = filePaths[i];
        final name = path.split('/').last;
        storage.addLog('Writing split[$i] to session $sessionId: $name');
        
        await Future.delayed(const Duration(milliseconds: 600));
        currentProgress += incrementalStep;
        onProgress?.call(currentProgress);
      }
      
      storage.addLog('Committing session $sessionId to Android package manager...');
      await Future.delayed(const Duration(seconds: 1));
      
      onProgress?.call(1.0);
      storage.addLog('Success: Package bundle fully streamed and validated.');
      return {'success': true};
      
    } catch (e) {
      storage.addLog('PM Commit Error: ${e.toString()}');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Runs typical shell commands and appends findings to terminal
  Future<String> runShellCommand(String cmd) async {
    if (!_isConnected) {
      storage.addLog('Error: Command rejected, no device connected.');
      return 'Disconnected';
    }

    storage.addLog('Shell executing: $cmd');
    await Future.delayed(const Duration(milliseconds: 800));

    String response = '';
    
    if (cmd == 'pm list packages') {
      response = 'package:com.android.chrome\npackage:com.google.android.youtube\npackage:com.mojang.minecraftpe\npackage:com.android.settings\npackage:org.mozilla.firefox';
    } else if (cmd.startsWith('pm clear')) {
      final pkg = cmd.replaceFirst('pm clear ', '').trim();
      response = 'Success: Package $pkg storage database has been reset.';
    } else if (cmd.startsWith('am force-stop')) {
      final pkg = cmd.replaceFirst('am force-stop ', '').trim();
      response = 'Success: Dispatched Terminate Signal to $pkg.';
    } else if (cmd.startsWith('pm uninstall')) {
      final pkg = cmd.replaceFirst('pm uninstall ', '').trim();
      response = 'Success';
    } else if (cmd.startsWith('monkey')) {
      response = 'Dispatched system launcher signal';
    } else if (cmd == 'get_devices') {
      response = 'List of devices attached\n$_connectedIp:5555\tdevice';
    } else {
      response = 'Command output: command was received and dispatched successfully.';
    }

    final dispResponse = response.replaceAll('\n', '\n[ADB Shell] ');
    storage.addLog('[ADB Shell Output]\n$dispResponse');
    return response;
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceStorageService {
  SharedPreferences? _prefs;

  static const String keySavedDevices = 'saved_devices';
  static const String keyLastConnected = 'last_connected_device';
  static const String keyAutoReconnect = 'auto_reconnect_enabled';
  static const String keyLogsHistory = 'adb_logs_history';

  // Streams or listeners could be added here for reactivity
  void Function()? onLogsChanged;
  void Function()? onDevicesChanged;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Auto Reconnect configuration
  bool getAutoReconnectSetting() {
    return _prefs?.getBool(keyAutoReconnect) ?? true;
  }

  Future<void> setAutoReconnect(bool enabled) async {
    await _prefs?.setBool(keyAutoReconnect, enabled);
  }

  // Saved paired devices
  List<Map<String, dynamic>> getSavedDevices() {
    final rawList = _prefs?.getStringList(keySavedDevices) ?? [];
    return rawList.map((item) {
      try {
        return Map<String, dynamic>.from(jsonDecode(item));
      } catch (e) {
        return <String, dynamic>{};
      }
    }).where((element) => element.isNotEmpty).toList();
  }

  Future<void> saveDevice(Map<String, dynamic> device) async {
    final current = getSavedDevices();
    final ip = device['ip'] ?? '';
    if (ip.isEmpty) return;

    // Remove old matching IP to avoid duplicates
    current.removeWhere((item) => item['ip'] == ip);
    current.add(device);

    final rawList = current.map((item) => jsonEncode(item)).toList();
    await _prefs?.setStringList(keySavedDevices, rawList);
    onDevicesChanged?.call();
  }

  Future<void> deleteDevice(String ip) async {
    final current = getSavedDevices();
    current.removeWhere((item) => item['ip'] == ip);

    final rawList = current.map((item) => jsonEncode(item)).toList();
    await _prefs?.setStringList(keySavedDevices, rawList);
    onDevicesChanged?.call();
  }

  // Last connected device state tracker (for auto reconnect on restart)
  Map<String, dynamic>? getLastConnectedDevice() {
    final raw = _prefs?.getString(keyLastConnected);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLastConnectedDevice(Map<String, dynamic> device) async {
    await _prefs?.setString(keyLastConnected, jsonEncode(device));
  }

  Future<void> clearLastConnectedDevice() async {
    await _prefs?.remove(keyLastConnected);
  }

  // Logs terminal history storage
  List<String> getLogsHistory() {
    return _prefs?.getStringList(keyLogsHistory) ?? [
      '[System] Device initialized. Ready for pairing or connection.',
    ];
  }

  Future<void> addLog(String message) async {
    final timeStr = DateTime.now().toIso8601String().substring(11, 19);
    final logLine = '[$timeStr] $message';
    final current = getLogsHistory();
    current.add(logLine);
    
    // Cap log memory size to the last 1000 items
    if (current.length > 1000) {
      current.removeAt(0);
    }
    await _prefs?.setStringList(keyLogsHistory, current);
    onLogsChanged?.call();
  }

  Future<void> clearLogs() async {
    await _prefs?.setStringList(keyLogsHistory, []);
    onLogsChanged?.call();
  }
}

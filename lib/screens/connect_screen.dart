import 'package:flutter/material.dart';
import '../services/adb_service.dart';
import '../services/device_storage_service.dart';

class ConnectScreen extends StatefulWidget {
  final AdbService adbService;
  final DeviceStorageService storage;

  const ConnectScreen({
    super.key,
    required this.adbService,
    required this.storage,
  });

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController(text: '192.168.1.100');
  final _portController = TextEditingController(text: '5555');
  
  bool _isConnecting = false;
  bool _autoReconnect = true;
  List<Map<String, dynamic>> _savedDevices = [];

  @override
  void initState() {
    super.initState();
    _autoReconnect = widget.storage.getAutoReconnectSetting();
    _loadSavedDevices();
    
    // Register change listeners from services
    widget.storage.onDevicesChanged = () {
      if (mounted) _loadSavedDevices();
    };
  }

  void _loadSavedDevices() {
    setState(() {
      _savedDevices = widget.storage.getSavedDevices();
    });
  }

  Future<void> _connectDevice(String ip, int port) async {
    setState(() {
      _isConnecting = true;
    });

    final success = await widget.adbService.connect(ip, port);

    setState(() {
      _isConnecting = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Connected to $ip successfully!' : 'Connection Refused by ADB host.'),
          backgroundColor: success ? Colors.teal : Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleAutoReconnect(bool val) async {
    setState(() {
      _autoReconnect = val;
    });
    await widget.storage.setAutoReconnect(val);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Connection control Panel Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manual ADB Client Connection',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.tealAccent),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ipController,
                      decoration: const InputDecoration(
                        labelText: 'Tablet Local Network IP',
                        prefixIcon: Icon(Icons.wifi_tethering),
                        hintText: 'e.g., 192.168.1.100',
                      ),
                      keyboardType: TextInputType.values[2], // IP Style
                      validator: (v) => v!.isEmpty ? 'IP address required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _portController,
                      decoration: const InputDecoration(
                        labelText: 'ADB Port',
                        prefixIcon: Icon(Icons.power_input),
                        hintText: 'Default: 5555',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Port required' : null,
                    ),
                    const SizedBox(height: 12),
                    
                    // Switch
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Auto-reconnect on startup'),
                      subtitle: const Text('Connects to last active device immediately'),
                      value: _autoReconnect,
                      onChanged: (val) => _toggleAutoReconnect(val),
                      activeColor: Colors.tealAccent,
                    ),
                    const Divider(height: 24, color: Colors.white24),
                    
                    Row(
                      children: [
                        Expanded(
                          child: StreamBuilder<bool>(
                            stream: widget.adbService.connectionStateStream,
                            initialData: widget.adbService.isConnected,
                            builder: (context, snapshot) {
                              final connected = snapshot.data ?? false;
                              return ElevatedButton(
                                onPressed: _isConnecting
                                  ? null 
                                  : () {
                                      if (connected) {
                                        widget.adbService.disconnect();
                                      } else {
                                        if (!_formKey.currentState!.validate()) return;
                                        _connectDevice(
                                          _ipController.text.trim(),
                                          int.tryParse(_portController.text.trim()) ?? 5555,
                                        );
                                      }
                                    },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: connected ? Colors.redAccent : Colors.tealAccent,
                                  foregroundColor: connected ? Colors.white : Colors.black,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isConnecting
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Text(connected ? 'CLOSE DISCONNECT' : 'ESTABLISH CONNECT'),
                              );
                            }
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Library list of saved tablets
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Paired Devices Directory', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text('${_savedDevices.length} Saved', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          
          if (_savedDevices.isEmpty)
            Card(
              color: Colors.transparent,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.white10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                child: Column(
                  children: [
                    Icon(Icons.devices_other, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('No Saved Devices Found', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Paired items will show up here for one-click connection', style: TextStyle(color: Colors.white24, fontSize: 11), textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _savedDevices.length,
              itemBuilder: (context, idx) {
                final d = _savedDevices[idx];
                final name = d['name'] ?? 'School Tablet';
                final ip = d['ip'] ?? '0.0.0.0';
                final adbPort = d['adbPort'] ?? 5555;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Icon(Icons.tablet_mac, color: Colors.white),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('IP: $ip:$adbPort'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _connectDevice(ip, adbPort),
                          icon: const Icon(Icons.flash_on, color: Colors.tealAccent),
                          tooltip: 'Quick connect',
                        ),
                        IconButton(
                          onPressed: () => widget.storage.deleteDevice(ip),
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          tooltip: 'Remove',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

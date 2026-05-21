import 'package:flutter/material.dart';
import '../services/adb_service.dart';
import '../services/device_storage_service.dart';

class PairScreen extends StatefulWidget {
  final AdbService adbService;
  final DeviceStorageService storage;

  const PairScreen({
    super.key,
    required this.adbService,
    required this.storage,
  });

  @override
  State<PairScreen> createState() => _PairScreenState();
}

class _PairScreenState extends State<PairScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'School Tablet');
  final _ipController = TextEditingController(text: '192.168.1.100');
  final _portController = TextEditingController(text: '37965');
  final _codeController = TextEditingController(text: '123456');
  
  bool _isPairing = false;
  List<String> _localLogs = [];

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    _portController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _addLocalLog(String msg) {
    if (!mounted) return;
    setState(() {
      final time = DateTime.now().toIso8601String().substring(11, 19);
      _localLogs.add('[$time] $msg');
    });
  }

  Future<void> _pairDevice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isPairing = true;
      _localLogs.clear();
    });

    final name = _nameController.text.trim();
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 0;
    final code = _codeController.text.trim();

    _addLocalLog('Starting pairing routine to ip=$ip, port=$port...');
    
    // Call ADB pair service
    final success = await widget.adbService.pair(ip, port, code);

    setState(() {
      _isPairing = false;
    });

    if (success) {
      _addLocalLog('Pairing successful! Saving credentials...');
      
      // Save paired credential locally
      final device = {
        'name': name,
        'ip': ip,
        'pairPort': port,
        'adbPort': 5555, // Default ADB WiFi service port
        'autoReconnect': true,
        'lastConnected': DateTime.now().toIso8601String(),
      };
      await widget.storage.saveDevice(device);
      
      _addLocalLog('Device credential has been recorded locally in database.');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // แก้บรรทัดนี้
content: Text("'$name' Paired and Saved Successfully!"),
            backgroundColor: Colors.tealAccent,
          ),
        );
      }
    } else {
      _addLocalLog('Pairing sequence aborted by remote client host.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Settings Title Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.vpn_key_rounded, size: 48, color: Colors.tealAccent),
                    const SizedBox(height: 12),
                    Text(
                      'Wireless Pairing Mode',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enable Wireless Debugging in Android Developer Options, then tap Pair with device.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Text Inputs
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Credentials Setup',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.tealAccent),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Device Nickname',
                        prefixIcon: Icon(Icons.label),
                      ),
                      validator: (v) => v!.isEmpty ? 'Invalid value' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ipController,
                      decoration: const InputDecoration(
                        labelText: 'IP Address',
                        prefixIcon: Icon(Icons.wifi),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'IP is required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _portController,
                            decoration: const InputDecoration(
                              labelText: 'Pairing Port',
                              prefixIcon: Icon(Icons.numbers),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Port required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _codeController,
                            decoration: const InputDecoration(
                              labelText: 'Pairing Code',
                              prefixIcon: Icon(Icons.security),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Pair Code required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _isPairing ? null : _pairDevice,
                      icon: _isPairing 
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.bolt),
                      label: Text(_isPairing ? 'PAIRING...' : 'PAIR & SAVE DEVICE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.tealAccent,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Local Progress logger
            if (_localLogs.isNotEmpty || _isPairing)
              Card(
                color: Colors.black45,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.terminal, size: 16, color: Colors.greenAccent),
                          SizedBox(width: 8),
                          Text('Pairing Protocol Terminal', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(color: Colors.white24),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          itemCount: _localLogs.length,
                          itemBuilder: (context, idx) => Text(
                            _localLogs[idx],
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.green),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}

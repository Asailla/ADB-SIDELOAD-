import 'package:flutter/material.dart';
import '../services/adb_service.dart';

class ToolsScreen extends StatefulWidget {
  final AdbService adbService;

  const ToolsScreen({super.key, required this.adbService});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final _cmdController = TextEditingController();
  List<String> _output = [];
  bool _isRunning = false;

  final List<Map<String, String>> _quickCommands = [
    {'label': 'List Packages', 'cmd': 'pm list packages'},
    {'label': 'List Devices', 'cmd': 'get_devices'},
  ];

  Future<void> _runCommand(String cmd) async {
    if (cmd.trim().isEmpty) return;
    setState(() {
      _isRunning = true;
    });
    final result = await widget.adbService.runShellCommand(cmd.trim());
    setState(() {
      _output.insert(0, '> $cmd\n$result');
      _isRunning = false;
    });
  }

  @override
  void dispose() {
    _cmdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Commands',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.tealAccent)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _quickCommands.map((q) {
                      return ElevatedButton(
                        onPressed: _isRunning ? null : () => _runCommand(q['cmd']!),
                        child: Text(q['label']!),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cmdController,
                  decoration: const InputDecoration(
                    labelText: 'ADB Shell Command',
                    prefixIcon: Icon(Icons.terminal),
                  ),
                  onSubmitted: (v) => _runCommand(v),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isRunning ? null : () => _runCommand(_cmdController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(60, 56),
                ),
                child: const Icon(Icons.send),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              color: Colors.black45,
              child: _output.isEmpty
                  ? const Center(
                      child: Text('Output will appear here',
                          style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _output.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: Colors.white12),
                      itemBuilder: (context, i) => Text(
                        _output[i],
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Colors.greenAccent),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/adb_service.dart';

class ToolsScreen extends StatefulWidget {
  final AdbService adbService;

  const ToolsScreen({
    super.key,
    required this.adbService,
  });

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  bool _isLoading = false;
  String _toolResponse = '';

  Future<void> _dispatchCommand(String name, String cmd) async {
    if (!widget.adbService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Execute failed. No tablet device connected via ADB Wi-Fi.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _toolResponse = '';
    });

    final res = await widget.adbService.runShellCommand(cmd);

    setState(() {
      _isLoading = false;
      _toolResponse = res;
    });

    if (mounted) {
      _showResponseDialog(name, res);
    }
  }

  void _showResponseDialog(String title, String output) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.tealAccent)),
        content: Container(
          width: double.maxFinite,
          maxHeight: 250,
          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            child: Text(
              output,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.green),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: output));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied output to clipboard!')));
            },
            child: const Text('COPY ALL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Future<void> _promptTargetPackage(String title, String actionCmdPrefix) async {
    final controller = TextEditingController(text: 'com.mojang.minecraftpe');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Target Package ID',
            hintText: 'e.g., com.example.app',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              final pkg = controller.text.trim();
              if (pkg.isNotEmpty) {
                _dispatchCommand(title, '$actionCmdPrefix $pkg');
              }
            },
            child: const Text('EXECUTE RUN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner statistics info card
          Card(
            color: Colors.teal.withOpacity(0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.teal, width: 0.5),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.dashboard_customize, size: 36, color: Colors.tealAccent),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ADB Master Toolbox', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 4),
                        Text('Dispatcher for rapid tablet actions, database resets, and task termination commands.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text('Device Management Suite', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // Tools grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              _ToolCard(
                icon: Icons.list_alt,
                color: Colors.amberAccent,
                title: 'List Installed',
                description: 'Show app packages',
                onTap: () => _dispatchCommand('Installed Apps List', 'pm list packages'),
              ),
              _ToolCard(
                icon: Icons.play_arrow_rounded,
                color: Colors.lightBlueAccent,
                title: 'Open Package',
                description: 'Launch application',
                onTap: () => _promptTargetPackage('Open / Launch Package', 'monkey -p'),
              ),
              _ToolCard(
                icon: Icons.dangerous,
                color: Colors.redAccent,
                title: 'Force Stop App',
                description: 'Kill application PID',
                onTap: () => _promptTargetPackage('Force Stop App', 'am force-stop'),
              ),
              _ToolCard(
                icon: Icons.cleaning_services,
                color: Colors.pinkAccent,
                title: 'Clear App Data',
                description: 'Reset databases / files',
                onTap: () => _promptTargetPackage('Clear Application Data', 'pm clear'),
              ),
              _ToolCard(
                icon: Icons.delete_sweep,
                color: Colors.orangeAccent,
                title: 'Uninstall Package',
                description: 'Full app file removal',
                onTap: () => _promptTargetPackage('Uninstall App', 'pm uninstall'),
              ),
              _ToolCard(
                icon: Icons.sync,
                color: Colors.tealAccent,
                title: 'Test Connections',
                description: 'Ping running adb services',
                onTap: () => _dispatchCommand('Test Connectivity', 'get_devices'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Log terminal shortcut
          Card(
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.terminal, color: Colors.greenAccent),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Real-Time ADB Sideload Console', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('Open the main tray terminal log to see socket packets and install progress streams.', style: TextStyle(color: Colors.grey, fontSize: 10)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 28, color: color),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(description, style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

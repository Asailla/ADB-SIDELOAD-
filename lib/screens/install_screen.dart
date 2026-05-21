import 'package:flutter/material.dart';
import '../services/adb_service.dart';
import '../services/apks_service.dart';

class InstallScreen extends StatefulWidget {
  final AdbService adbService;

  const InstallScreen({
    super.key,
    required this.adbService,
  });

  @override
  State<InstallScreen> createState() => _InstallScreenState();
}

class _InstallScreenState extends State<InstallScreen> {
  // Option Flags
  bool _replaceExisting = true;
  bool _grantPermissions = true;
  bool _installAllInFolder = false;

  // Selected state
  String? _selectedSourceType; // 'APK', 'APKS', 'FOLDER'
  String? _sourceLabel;
  List<String> _pendingApkList = [];
  
  // Progress tracker
  bool _isInstalling = false;
  double _currentProgressValue = 0.0;
  String _currentInstallLabel = 'Ready to Sideload';

  final ApksService _apksDecoder = ApksService();

  Future<void> _pickSingleApk() async {
    // In Flutter, we trigger standard package file picker
    /*
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['apk'],
    );
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      setState(() {
        _selectedSourceType = 'APK';
        _sourceLabel = result.files.single.name;
        _pendingApkList = [path];
      });
    }
    */
    // Sideload sample file emulator
    setState(() {
      _selectedSourceType = 'APK';
      _sourceLabel = 'com.microsoft.teams.apk';
      _pendingApkList = ['/storage/emulated/0/Download/com.microsoft.teams.apk'];
    });
  }

  Future<void> _pickApksSuite() async {
    // Emulated selector mimicking APK Split Archives (.apks, .xapk zip extract files)
    setState(() {
      _selectedSourceType = 'APKS';
      _sourceLabel = 'com.mojang.minecraft.apks';
      _pendingApkList = [
        '/storage/emulated/0/Download/minecraft_splits/base.apk',
        '/storage/emulated/0/Download/minecraft_splits/config.arm64.apk',
        '/storage/emulated/0/Download/minecraft_splits/config.en.apk',
        '/storage/emulated/0/Download/minecraft_splits/config.xxhdpi.apk'
      ];
    });
  }

  Future<void> _pickFolder() async {
    setState(() {
      _selectedSourceType = 'FOLDER';
      _sourceLabel = 'Downloads/School_Suite';
      _pendingApkList = [
        '/storage/emulated/0/School_Suite/classroom.apk',
        '/storage/emulated/0/School_Suite/zoom.apk',
        '/storage/emulated/0/School_Suite/duolingo.apk'
      ];
    });
  }

  void _clearSelected() {
    setState(() {
      _selectedSourceType = null;
      _sourceLabel = null;
      _pendingApkList.clear();
      _currentProgressValue = 0.0;
      _currentInstallLabel = 'Ready to Sideload';
    });
  }

  Future<void> _startQueueInstall() async {
    if (!widget.adbService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No active connection found. Connect to a tablet first.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_pendingApkList.isEmpty) return;

    setState(() {
      _isInstalling = true;
    });

    try {
      if (_selectedSourceType == 'APKS') {
        // Run adb install-multiple logic
        setState(() {
          _currentInstallLabel = 'Bundling and uploading split archive: $_sourceLabel';
        });
        
        final res = await widget.adbService.installMultipleApks(
          _pendingApkList,
          replace: _replaceExisting,
          grantPermissions: _grantPermissions,
          onProgress: (p) {
            setState(() {
              _currentProgressValue = p;
            });
          },
        );

        if (mounted) {
          _showToast(res['success'] ?? false, 'APKS sideload finished.');
        }

      } else {
        // Iterate through single queue setup
        for (int i = 0; i < _pendingApkList.length; i++) {
          final apk = _pendingApkList[i];
          final name = apk.split('/').last;

          setState(() {
            _currentInstallLabel = 'Sideloading (${i + 1}/${_pendingApkList.length}): $name';
            _currentProgressValue = 0.05;
          });

          final res = await widget.adbService.installSingleApk(
            apk,
            replace: _replaceExisting,
            grantPermissions: _grantPermissions,
            onProgress: (progress) {
              setState(() {
                _currentProgressValue = progress;
              });
            },
          );

          if (!(res['success'] ?? false)) {
            if (mounted) {
              _showToast(false, 'Failed on item $name: ${res['error']}');
            }
            break;
          }
        }
        
        _showToast(true, 'All queued installations finished successfully.');
      }
    } catch (e) {
      _showToast(false, 'Unexpected Sideload Error: $e');
    } finally {
      setState(() {
        _isInstalling = false;
        _currentInstallLabel = 'Finished';
      });
    }
  }

  void _showToast(bool isSuccess, String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess ? Colors.teal : Colors.redAccent,
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
          // Select file widgets card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step 1: Pick Packages Source',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.tealAccent, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _ActionTileButton(
                          icon: Icons.install_mobile_outlined,
                          title: 'apk File',
                          subtitle: 'Single application',
                          onTap: _pickSingleApk,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionTileButton(
                          icon: Icons.unarchive_outlined,
                          title: 'apks File',
                          subtitle: 'Split archives',
                          onTap: _pickApksSuite,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionTileButton(
                          icon: Icons.folder_zip_sharp,
                          title: 'Folder',
                          subtitle: 'Batch Installer',
                          onTap: _pickFolder,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (_selectedSourceType != null) ...[
            // Chosen package summary
            Card(
              color: const Color(0xFF2A2D32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.tealAccent, width: 1)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.snippet_folder, color: Colors.tealAccent),
                            const SizedBox(width: 8),
                            Text('Queue Payload Structure', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        IconButton(
                          onPressed: _isInstalling ? null : _clearSelected,
                          icon: const Icon(Icons.cancel, color: Colors.grey),
                          tooltip: 'Reset Queue',
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12),
                    Text('Method Type: $_selectedSourceType', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.tealAccent)),
                    const SizedBox(height: 4),
                    Text('Package target: $_sourceLabel', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 6),
                    Text('Resolved File stream count: ${_pendingApkList.length} packages', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 10),
                    
                    Container(
                      height: 100,
                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.all(8),
                      child: ListView.builder(
                        itemCount: _pendingApkList.length,
                        itemBuilder: (context, idx) {
                          final p = _pendingApkList[idx];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.circle, size: 6, color: Colors.tealAccent),
                                const SizedBox(width: 8),
                                Expanded(child: Text(p, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey))),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Installer modifiers list
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step 2: Install Options',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  CheckboxListTile(
                    title: const Text('Replace existing packages (-r)'),
                    subtitle: const Text('Retains application database states'),
                    value: _replaceExisting,
                    onChanged: (v) {
                      setState(() {
                        _replaceExisting = v ?? true;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.tealAccent,
                  ),
                  CheckboxListTile(
                    title: const Text('Auto Grant runtime permissions (-g)'),
                    subtitle: const Text('Accepts camera, location, storage bypass flags'),
                    value: _grantPermissions,
                    onChanged: (v) {
                      setState(() {
                        _grantPermissions = v ?? true;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.tealAccent,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sideload trigger button
          ElevatedButton.icon(
            onPressed: (_pendingApkList.isEmpty || _isInstalling) ? null : _startQueueInstall,
            icon: const Icon(Icons.install_desktop),
            label: const Text('DEPLOY & START SIDELOAD', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),

          // Live Progress Monitoring Frame
          if (_isInstalling || _currentProgressValue > 0.0)
            Card(
              color: Colors.black38,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_currentInstallLabel, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.tealAccent, fontSize: 13)),
                        Text('${(_currentProgressValue * 100).toStringAsFixed(0)}%', style: const TextStyle(fontFamily: 'monospace', color: Colors.tealAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _currentProgressValue,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.tealAccent),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionTileButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTileButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, size: 28, color: Colors.tealAccent),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 8, color: Colors.grey), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../services/update_checker_service.dart';
import '../widgets/sidebar_page.dart';

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  final UpdateCheckerService _updates = UpdateCheckerService();
  PackageInfo? _packageInfo;
  UpdateInfo? _latest;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        PackageInfo.fromPlatform(),
        _updates.fetchLatest(),
      ]);
      if (!mounted) return;
      setState(() {
        _packageInfo = results[0] as PackageInfo;
        _latest = results[1] as UpdateInfo?;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _download(UpdateInfo update) async {
    final ok = await launchUrl(
      Uri.parse(update.apkUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open ${update.apkUrl}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentBuild = int.tryParse(_packageInfo?.buildNumber ?? '') ?? 0;
    final hasUpdate = _latest != null && _latest!.isNewerThan(currentBuild);

    return SidebarPage(
      title: 'Update App',
      path: '/update',
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.system_update_alt, color: AppColors.primary),
                        SizedBox(width: 10),
                        Text(
                          'App Update',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Installed version: ${_packageInfo?.version ?? '-'} build ${_packageInfo?.buildNumber ?? '-'}',
                    ),
                    const SizedBox(height: 8),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      Text(
                        'Update check failed: $_error',
                        style: const TextStyle(color: Colors.red),
                      )
                    else if (_latest == null)
                      const Text(
                        'No release information is available right now.',
                      )
                    else ...[
                      Text(
                        'Latest version: ${_latest!.version} build ${_latest!.build}',
                      ),
                      if (_latest!.date.isNotEmpty)
                        Text('Released: ${_latest!.date}'),
                      const SizedBox(height: 12),
                      Text(
                        hasUpdate
                            ? 'A newer version is available.'
                            : 'You are using the latest version.',
                        style: TextStyle(
                          color: hasUpdate ? AppColors.primary : Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_latest!.features.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'What is new:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        for (final feature in _latest!.features)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('- $feature'),
                          ),
                      ],
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _loading ? null : _load,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Check Again'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _latest == null
                                ? null
                                : () => _download(_latest!),
                            icon: const Icon(Icons.download),
                            label: const Text('Download'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'If Play Protect blocks the APK, install through a Play Console testing track or temporarily allow this sideloaded install. Play Protect reputation cannot be fixed only in app code.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _updates.dispose();
    super.dispose();
  }
}

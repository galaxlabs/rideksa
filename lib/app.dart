import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'core/theme.dart';
import 'core/routes.dart';
import 'providers/auth_provider.dart';
import 'services/integrity_service.dart';
import 'services/update_checker_service.dart';

class RideKSAApp extends StatefulWidget {
  const RideKSAApp({super.key});
  @override
  State<RideKSAApp> createState() => _RideKSAAppState();
}

class _RideKSAAppState extends State<RideKSAApp> {
  GoRouter? _router;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    _router ??= createRouter(authProvider);

    return MaterialApp.router(
      title: 'RideKSA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      routerConfig: _router!,
    );
  }
}

class AppDependencies extends StatefulWidget {
  final Widget child;
  const AppDependencies({super.key, required this.child});

  @override
  State<AppDependencies> createState() => _AppDependenciesState();
}

class _AppDependenciesState extends State<AppDependencies> {
  final UpdateCheckerService _updateChecker = UpdateCheckerService();
  bool _checkedUpdates = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkSession();
      _runIntegrityCheck();
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    if (_checkedUpdates) return;
    _checkedUpdates = true;
    await Future.delayed(const Duration(seconds: 3));
    try {
      final update = await _updateChecker.checkForUpdate();
      if (update == null || !mounted) return;
      await _showUpdateDialog(update);
    } catch (e) {
      debugPrint('UPDATE CHECK ERROR: $e');
    }
  }

  Future<void> _showUpdateDialog(UpdateInfo update) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.system_update_alt, color: AppColors.accent, size: 40),
        title: Text('New update available v${update.version}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (update.date.isNotEmpty)
                Text('Released ${update.date}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 12),
              if (update.features.isNotEmpty) ...[
                Text('What is new:', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                ...update.features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('• ', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                    Expanded(child: Text(f)),
                  ]),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await launchUrl(Uri.parse(update.apkUrl), mode: LaunchMode.externalApplication);
              if (!ok) {
                debugPrint('FAILED to open: ${update.apkUrl}');
              }
            },
            icon: const Icon(Icons.download),
            label: const Text('Download'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Future<void> _runIntegrityCheck() async {
    try {
      final integrity = context.read<IntegrityService>();
      if (!integrity.supported) return;
      await Future.delayed(const Duration(seconds: 2));
      final result = await integrity.runCheck();
      if (!result.passed && result.error != null) {
        debugPrint('PLAY INTEGRITY: ${result.error}');
      } else {
        debugPrint('PLAY INTEGRITY: passed (app=${result.appVerdict}, device=${result.deviceVerdict})');
      }
    } catch (e) {
      debugPrint('PLAY INTEGRITY ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
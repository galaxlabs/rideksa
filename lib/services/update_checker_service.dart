import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../core/constants.dart';
import 'app_config_service.dart';

class UpdateInfo {
  final String version;
  final int build;
  final String date;
  final List<String> features;
  final String apkUrl;

  UpdateInfo({
    required this.version,
    required this.build,
    required this.date,
    required this.features,
    required this.apkUrl,
  });

  bool isNewerThan(int currentBuild) => build > currentBuild;
}

class UpdateCheckerService {
  static const String githubRepo = 'galaxlabs/rideksa';
  static const String githubApiLatest =
      'https://api.github.com/repos/$githubRepo/releases/latest';

  String get _landingBaseUrl =>
      AppConfigService.instance.config.updateCheckUrl.isNotEmpty
      ? _stripPath(AppConfigService.instance.config.updateCheckUrl)
      : 'https://rideksa.celtcoksa.com';

  String get releasesJsonUrl => '$_landingBaseUrl/releases.json';

  String get defaultApkUrl =>
      AppConfigService.instance.config.apkDownloadUrl.isNotEmpty
      ? AppConfigService.instance.config.apkDownloadUrl
      : '$_landingBaseUrl/app-release.apk';

  String _stripPath(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return '${uri.scheme}://${uri.host}';
  }

  final http.Client _client = http.Client();

  Future<UpdateInfo?> fetchLatest() async {
    UpdateInfo? fromGithub;
    try {
      fromGithub = await _fetchFromGithub();
    } catch (e) {
      debugPrintSafe('UPDATE CHECKER github failed: $e');
    }
    if (fromGithub != null) return fromGithub;
    try {
      return await _fetchFromLanding();
    } catch (e) {
      debugPrintSafe('UPDATE CHECKER landing failed: $e');
    }
    return null;
  }

  Future<UpdateInfo?> _fetchFromGithub() async {
    final res = await _client
        .get(
          Uri.parse(githubApiLatest),
          headers: {
            'Accept': 'application/vnd.github+json',
            'User-Agent': 'RideKSA',
          },
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return null;

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final tag = json['tag_name'] as String? ?? '';
    final match = RegExp(r'v?(\d+\.\d+\.\d+)(?:\+(\d+))?').firstMatch(tag);
    if (match == null) return null;

    final version = match.group(1)!;
    final build =
        int.tryParse(match.group(2) ?? '') ?? _buildFromVersion(version);

    String apkUrl = defaultApkUrl;
    final assets = json['assets'] as List? ?? [];
    for (final a in assets) {
      if (a is Map && (a['name'] as String? ?? '').endsWith('.apk')) {
        apkUrl = a['browser_download_url'] as String? ?? apkUrl;
        break;
      }
    }

    final body = json['body'] as String? ?? '';
    final features = body
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim().replaceFirst(RegExp(r'^[-*\d.\s]+'), ''))
        .where((l) => l.isNotEmpty)
        .toList();

    return UpdateInfo(
      version: version,
      build: build,
      date: json['published_at']?.toString().substring(0, 10) ?? '',
      features: features,
      apkUrl: apkUrl,
    );
  }

  Future<UpdateInfo?> _fetchFromLanding() async {
    final res = await _client
        .get(Uri.parse(releasesJsonUrl))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return null;
    final list = jsonDecode(res.body) as List;
    if (list.isEmpty) return null;
    final first = list.first as Map<String, dynamic>;
    final version = first['version'] as String? ?? '';
    final build = (first['build'] as num?)?.toInt() ?? 0;
    final features = (first['features'] as List? ?? [])
        .map((f) => f.toString())
        .toList();
    if (version.isEmpty || build == 0) return null;
    return UpdateInfo(
      version: version,
      build: build,
      date: first['date'] as String? ?? '',
      features: features,
      apkUrl: defaultApkUrl,
    );
  }

  int _buildFromVersion(String version) {
    final parts = version.split('.');
    if (parts.length == 3) {
      return (int.tryParse(parts[0]) ?? 0) * 10000 +
          (int.tryParse(parts[1]) ?? 0) * 100 +
          (int.tryParse(parts[2]) ?? 0);
    }
    return 0;
  }

  Future<UpdateInfo?> checkForUpdate() async {
    final info = await fetchLatest();
    if (info == null) return null;
    final currentBuild = await _currentBuildNumber();
    if (!info.isNewerThan(currentBuild)) return null;
    return info;
  }

  Future<int> _currentBuildNumber() async {
    if (kIsWeb) return AppConstants.appBuildNumber;
    try {
      final pkg = await PackageInfo.fromPlatform();
      return int.tryParse(pkg.buildNumber) ?? AppConstants.appBuildNumber;
    } catch (_) {
      return AppConstants.appBuildNumber;
    }
  }

  void debugPrintSafe(String msg) {
    // ignore: avoid_print
    print(msg);
  }

  void dispose() => _client.close();
}

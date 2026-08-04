import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../firebase_options.dart';

class AppConfig {
  final String backendBaseUrl;
  final String firebaseProjectId;
  final String firebaseAuthDomain;
  final String firebaseStorageBucket;
  final String firebaseMessagingSenderId;
  final String firebaseWebAppId;
  final String firebaseAndroidAppId;
  final String firebaseWebApiKey;
  final String firebaseAndroidApiKey;
  final String mapsApiKey;
  final String mapsProvider;
  final String playIntegrityProjectNumber;
  final String apkDownloadUrl;
  final String updateCheckUrl;
  final int minSupportedBuild;
  final String platformName;
  final String defaultCurrency;
  final double platformCommissionRate;
  final bool maintenanceMode;

  const AppConfig({
    this.backendBaseUrl = AppConstants.backendBaseUrl,
    this.firebaseProjectId = '',
    this.firebaseAuthDomain = '',
    this.firebaseStorageBucket = '',
    this.firebaseMessagingSenderId = '',
    this.firebaseWebAppId = '',
    this.firebaseAndroidAppId = '',
    this.firebaseWebApiKey = '',
    this.firebaseAndroidApiKey = '',
    this.mapsApiKey = '',
    this.mapsProvider = 'Google',
    this.playIntegrityProjectNumber = AppConstants.playIntegrityCloudProjectNumber,
    this.apkDownloadUrl = '',
    this.updateCheckUrl = '',
    this.minSupportedBuild = 0,
    this.platformName = 'RideKSA',
    this.defaultCurrency = 'SAR',
    this.platformCommissionRate = 0.05,
    this.maintenanceMode = false,
  });

  AppConfig copyWith({
    String? backendBaseUrl,
    String? firebaseProjectId,
    String? firebaseAuthDomain,
    String? firebaseStorageBucket,
    String? firebaseMessagingSenderId,
    String? firebaseWebAppId,
    String? firebaseAndroidAppId,
    String? firebaseWebApiKey,
    String? firebaseAndroidApiKey,
    String? mapsApiKey,
    String? mapsProvider,
    String? playIntegrityProjectNumber,
    String? apkDownloadUrl,
    String? updateCheckUrl,
    int? minSupportedBuild,
    String? platformName,
    String? defaultCurrency,
    double? platformCommissionRate,
    bool? maintenanceMode,
  }) => AppConfig(
    backendBaseUrl: backendBaseUrl ?? this.backendBaseUrl,
    firebaseProjectId: firebaseProjectId ?? this.firebaseProjectId,
    firebaseAuthDomain: firebaseAuthDomain ?? this.firebaseAuthDomain,
    firebaseStorageBucket: firebaseStorageBucket ?? this.firebaseStorageBucket,
    firebaseMessagingSenderId: firebaseMessagingSenderId ?? this.firebaseMessagingSenderId,
    firebaseWebAppId: firebaseWebAppId ?? this.firebaseWebAppId,
    firebaseAndroidAppId: firebaseAndroidAppId ?? this.firebaseAndroidAppId,
    firebaseWebApiKey: firebaseWebApiKey ?? this.firebaseWebApiKey,
    firebaseAndroidApiKey: firebaseAndroidApiKey ?? this.firebaseAndroidApiKey,
    mapsApiKey: mapsApiKey ?? this.mapsApiKey,
    mapsProvider: mapsProvider ?? this.mapsProvider,
    playIntegrityProjectNumber: playIntegrityProjectNumber ?? this.playIntegrityProjectNumber,
    apkDownloadUrl: apkDownloadUrl ?? this.apkDownloadUrl,
    updateCheckUrl: updateCheckUrl ?? this.updateCheckUrl,
    minSupportedBuild: minSupportedBuild ?? this.minSupportedBuild,
    platformName: platformName ?? this.platformName,
    defaultCurrency: defaultCurrency ?? this.defaultCurrency,
    platformCommissionRate: platformCommissionRate ?? this.platformCommissionRate,
    maintenanceMode: maintenanceMode ?? this.maintenanceMode,
  );

  Map<String, dynamic> toJson() => {
    'backend_base_url': backendBaseUrl,
    'firebase_project_id': firebaseProjectId,
    'firebase_auth_domain': firebaseAuthDomain,
    'firebase_storage_bucket': firebaseStorageBucket,
    'firebase_messaging_sender_id': firebaseMessagingSenderId,
    'firebase_web_app_id': firebaseWebAppId,
    'firebase_android_app_id': firebaseAndroidAppId,
    'firebase_web_api_key': firebaseWebApiKey,
    'firebase_android_api_key': firebaseAndroidApiKey,
    'maps_api_key': mapsApiKey,
    'maps_provider': mapsProvider,
    'play_integrity_project_number': playIntegrityProjectNumber,
    'apk_download_url': apkDownloadUrl,
    'update_check_url': updateCheckUrl,
    'min_supported_build': minSupportedBuild,
    'platform_name': platformName,
    'default_currency': defaultCurrency,
    'platform_commission_rate': platformCommissionRate,
    'maintenance_mode': maintenanceMode,
  };

  factory AppConfig.fromJson(Map<String, dynamic> json) => AppConfig(
    backendBaseUrl: json['backend_base_url'] as String? ?? AppConstants.backendBaseUrl,
    firebaseProjectId: json['firebase_project_id'] as String? ?? '',
    firebaseAuthDomain: json['firebase_auth_domain'] as String? ?? '',
    firebaseStorageBucket: json['firebase_storage_bucket'] as String? ?? '',
    firebaseMessagingSenderId: json['firebase_messaging_sender_id'] as String? ?? '',
    firebaseWebAppId: json['firebase_web_app_id'] as String? ?? '',
    firebaseAndroidAppId: json['firebase_android_app_id'] as String? ?? '',
    firebaseWebApiKey: json['firebase_web_api_key'] as String? ?? '',
    firebaseAndroidApiKey: json['firebase_android_api_key'] as String? ?? '',
    mapsApiKey: json['maps_api_key'] as String? ?? '',
    mapsProvider: json['maps_provider'] as String? ?? 'Google',
    playIntegrityProjectNumber: json['play_integrity_project_number'] as String? ?? AppConstants.playIntegrityCloudProjectNumber,
    apkDownloadUrl: json['apk_download_url'] as String? ?? '',
    updateCheckUrl: json['update_check_url'] as String? ?? '',
    minSupportedBuild: (json['min_supported_build'] as num?)?.toInt() ?? 0,
    platformName: json['platform_name'] as String? ?? 'RideKSA',
    defaultCurrency: json['default_currency'] as String? ?? 'SAR',
    platformCommissionRate: (json['platform_commission_rate'] as num?)?.toDouble() ?? 0.05,
    maintenanceMode: json['maintenance_mode'] as bool? ?? false,
  );
}

class AppConfigService {
  static final AppConfigService instance = AppConfigService._();
  AppConfigService._();

  AppConfig _config = const AppConfig();
  bool _loaded = false;
  static const String _cacheKey = 'app_config_cache_v1';

  AppConfig get config => _config;
  bool get loaded => _loaded;

  static const String _endpoint = 'ftms.api.config.get_app_config';

  Future<AppConfig> load({bool force = false}) async {
    if (_loaded && !force) return _config;
    final cached = await _readCache();
    _config = cached ?? _config;
    _loaded = true;

    final uri = Uri.parse('${AppConstants.backendBaseUrl}/api/method/$_endpoint')
        .replace(queryParameters: {'include_private': '1'});
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final data = body['message'] as Map<String, dynamic>? ?? {};
        _config = _mergeRemote(data);
        _loaded = true;
        await _writeCache(_config);
      }
    } catch (e) {
      debugPrint('APP CONFIG: fetch failed, using cache/defaults: $e');
    }
    return _config;
  }

  AppConfig _mergeRemote(Map<String, dynamic> data) {
    var cfg = _config;
    final firebase = data['firebase'] as Map<String, dynamic>? ?? {};
    final maps = data['maps'] as Map<String, dynamic>? ?? {};
    final updates = data['updates'] as Map<String, dynamic>? ?? {};
    final api = data['api'] as Map<String, dynamic>? ?? {};
    final platform = data['platform'] as Map<String, dynamic>? ?? {};

    String pick(Map<String, dynamic> src, String key) {
      final v = src[key];
      return v is String ? v : '';
    }

    cfg = cfg.copyWith(
      backendBaseUrl: pick(api, 'base_url').isNotEmpty ? pick(api, 'base_url') : cfg.backendBaseUrl,
      firebaseProjectId: pick(firebase, 'project_id'),
      firebaseAuthDomain: pick(firebase, 'auth_domain'),
      firebaseStorageBucket: pick(firebase, 'storage_bucket'),
      firebaseMessagingSenderId: pick(firebase, 'messaging_sender_id'),
      firebaseWebAppId: pick(firebase, 'web_app_id'),
      firebaseAndroidAppId: pick(firebase, 'android_app_id'),
      firebaseWebApiKey: pick(firebase, 'web_api_key'),
      firebaseAndroidApiKey: pick(firebase, 'android_api_key'),
      mapsApiKey: pick(maps, 'api_key'),
      mapsProvider: pick(maps, 'provider'),
      playIntegrityProjectNumber: pick(data, 'play_integrity_project_number'),
      apkDownloadUrl: pick(updates, 'apk_download_url'),
      updateCheckUrl: pick(updates, 'update_check_url'),
      minSupportedBuild: (updates['min_supported_build'] as num?)?.toInt() ?? cfg.minSupportedBuild,
      platformName: pick(platform, 'platform_name'),
      defaultCurrency: pick(platform, 'default_currency'),
      platformCommissionRate: (platform['platform_commission_rate'] as num?)?.toDouble() ?? cfg.platformCommissionRate,
      maintenanceMode: platform['maintenance_mode'] as bool? ?? cfg.maintenanceMode,
    );
    return cfg;
  }

  FirebaseOptions get firebaseOptions {
    final fallback = DefaultFirebaseOptions.currentPlatform;
    final cfg = _config;
    final isWeb = kIsWeb;
    final apiKey = isWeb
        ? (cfg.firebaseWebApiKey.isNotEmpty ? cfg.firebaseWebApiKey : fallback.apiKey)
        : (cfg.firebaseAndroidApiKey.isNotEmpty ? cfg.firebaseAndroidApiKey : fallback.apiKey);
    final appId = isWeb
        ? (cfg.firebaseWebAppId.isNotEmpty ? cfg.firebaseWebAppId : fallback.appId)
        : (cfg.firebaseAndroidAppId.isNotEmpty ? cfg.firebaseAndroidAppId : fallback.appId);
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: cfg.firebaseMessagingSenderId.isNotEmpty ? cfg.firebaseMessagingSenderId : fallback.messagingSenderId,
      projectId: cfg.firebaseProjectId.isNotEmpty ? cfg.firebaseProjectId : fallback.projectId,
      authDomain: cfg.firebaseAuthDomain.isNotEmpty ? cfg.firebaseAuthDomain : fallback.authDomain,
      storageBucket: cfg.firebaseStorageBucket.isNotEmpty ? cfg.firebaseStorageBucket : fallback.storageBucket,
    );
  }

  Future<AppConfig?> _readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return null;
      return AppConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(AppConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(config.toJson()));
    } catch (_) {}
  }
}

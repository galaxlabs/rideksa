import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/errors.dart';
import 'app_config_service.dart';
import 'token_storage.dart';
import 'http_client.dart';

class FrappeApiClient {
  final http.Client _client;
  final TokenStorage _storage = createTokenStorage();
  String? _cookie;
  Future<void> Function()? sessionRefresher;
  Future<String?> Function(bool forceRefresh)? firebaseTokenProvider;

  FrappeApiClient({http.Client? client})
    : _client = client ?? createFrappeHttpClient();

  String get _baseUrl => AppConfigService.instance.config.backendBaseUrl;

  Uri _methodUri(String method) => Uri.parse('$_baseUrl/api/method/$method');

  Map<String, String>? _queryParameters(Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return null;
    return query.map((key, value) => MapEntry(key, value?.toString() ?? ''));
  }

  Uri _resourceUri(String doctype, [String? name]) {
    final base = '$_baseUrl/api/resource/$doctype';
    return Uri.parse(name != null ? '$base/$name' : base);
  }

  Future<void> _restoreSession() async {
    _cookie = await _storage.read(key: 'frappe_session');
  }

  Future<void> _addFirebaseAuth(
    Map<String, String> headers, {
    bool forceRefresh = false,
  }) async {
    final token = await firebaseTokenProvider?.call(forceRefresh);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<bool> get hasSession async {
    await _restoreSession();
    return _cookie != null && _cookie!.isNotEmpty;
  }

  Future<void> login({required String email, required String password}) async {
    final bodyStr =
        'usr=${Uri.encodeComponent(email)}&pwd=${Uri.encodeComponent(password)}';
    final response = await _client.post(
      _methodUri('login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: bodyStr,
    );
    if (response.statusCode >= 400) {
      throw const ApiException('Frappe login failed');
    }
    final setCookie = response.headers['set-cookie'];
    if (setCookie == null || !setCookie.contains('sid=')) {
      throw const ApiException('No session cookie');
    }
    _cookie = setCookie
        .split(';')
        .firstWhere((p) => p.trim().startsWith('sid='))
        .trim();
    await _storage.write(key: 'frappe_session', value: _cookie!);
  }

  Future<Map<String, dynamic>?> loginWithFirebaseIdToken(String idToken) async {
    final response = await _client.post(
      _methodUri('ftms.api.auth.login_with_firebase'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'id_token': idToken}),
    );
    final decoded = _decode(response);
    if (response.statusCode >= 400) {
      throw ApiException(
        decoded['message']?.toString() ?? 'Frappe Firebase login failed',
      );
    }
    final setCookie = response.headers['set-cookie'];
    if (setCookie != null && setCookie.contains('sid=')) {
      _cookie = setCookie
          .split(';')
          .firstWhere((p) => p.trim().startsWith('sid='))
          .trim();
      await _storage.write(key: 'frappe_session', value: _cookie!);
    }
    final message = decoded is Map<String, dynamic> ? decoded['message'] : null;
    if (message is Map && message['api_token'] != null) {
      await _storage.write(
        key: 'frappe_api_token',
        value: message['api_token'].toString(),
      );
    }
    return message is Map<String, dynamic> ? message : null;
  }

  Future<String> getFirebaseCustomToken({
    required String email,
    required String password,
    String? mobileNo,
  }) async {
    final result = _messageMap(
      await callMethod(
        'ftms.api.auth.firebase_token_from_frappe_password',
        body: {
          'email': email,
          if (mobileNo != null) 'mobile_no': mobileNo,
          'password': password,
        },
        requiresSession: false,
      ),
    );
    final token = result['custom_token']?.toString();
    if (token == null || token.isEmpty) {
      throw const ApiException('The login server did not return a token.');
    }
    return token;
  }

  Future<String> registerAndGetFirebaseCustomToken({
    required String email,
    required String password,
    String? displayName,
    String? mobileNo,
  }) async {
    final result = _messageMap(
      await callMethod(
        'ftms.api.auth.register_with_frappe_password',
        body: {
          'email': email,
          'password': password,
          'display_name': displayName,
          'mobile_no': mobileNo,
        },
        requiresSession: false,
      ),
    );
    final token = result['custom_token']?.toString();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        'The registration server did not return a token.',
      );
    }
    return token;
  }

  Future<void> requestFrappePasswordReset(String email) async {
    await callMethod(
      'ftms.api.auth.request_frappe_password_reset',
      body: {'email': email},
      requiresSession: false,
    );
  }

  Future<void> logout() async {
    try {
      await callMethod('logout');
    } catch (_) {}
    _cookie = null;
    await _storage.delete(key: 'frappe_session');
    await _storage.delete(key: 'frappe_api_token');
  }

  Future<dynamic> callMethod(
    String method, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
    bool requiresSession = true,
  }) async {
    if (requiresSession) await _restoreSession();
    final uri = _methodUri(
      method,
    ).replace(queryParameters: _queryParameters(query));
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_cookie != null) headers['Cookie'] = _cookie!;
    if (requiresSession) await _addFirebaseAuth(headers);

    Future<http.Response> send() => body != null
        ? _client.post(uri, headers: headers, body: jsonEncode(body))
        : _client.get(uri, headers: headers);

    var response = await send();
    if (requiresSession &&
        (response.statusCode == 401 || response.statusCode == 403) &&
        sessionRefresher != null) {
      await sessionRefresher!();
      await _restoreSession();
      if (_cookie != null) headers['Cookie'] = _cookie!;
      await _addFirebaseAuth(headers, forceRefresh: true);
      response = await send();
    }

    final decoded = _decode(response);
    if (response.statusCode >= 400) {
      throw ApiException(
        decoded['message']?.toString() ??
            decoded['_server_messages']?.toString() ??
            'HTTP ${response.statusCode}',
      );
    }
    return decoded;
  }

  Future<List<dynamic>> getList(
    String doctype, {
    Map<String, dynamic>? filters,
    List<String>? fields,
    int limit = 50,
  }) async {
    await _restoreSession();
    final params = <String, String>{
      'fields': jsonEncode(fields ?? ['*']),
      'limit_page_length': limit.toString(),
    };
    if (filters != null) params['filters'] = jsonEncode(filters);
    final uri = _resourceUri(doctype).replace(queryParameters: params);
    final headers = <String, String>{'Accept': 'application/json'};
    if (_cookie != null) headers['Cookie'] = _cookie!;
    await _addFirebaseAuth(headers);
    final response = await _client.get(uri, headers: headers);
    final data = _decode(response);
    if (response.statusCode >= 400)
      throw ApiException(data['message'] ?? 'HTTP ${response.statusCode}');
    return data['data'] as List<dynamic>? ?? [];
  }

  Future<Map<String, dynamic>> getDoc(String doctype, String name) async {
    await _restoreSession();
    final uri = _resourceUri(doctype, name);
    final headers = <String, String>{'Accept': 'application/json'};
    if (_cookie != null) headers['Cookie'] = _cookie!;
    await _addFirebaseAuth(headers);
    final response = await _client.get(uri, headers: headers);
    final data = _decode(response);
    if (response.statusCode >= 400)
      throw ApiException(data['message'] ?? 'HTTP ${response.statusCode}');
    return data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createDoc(
    String doctype,
    Map<String, dynamic> doc,
  ) async {
    await _restoreSession();
    final uri = _resourceUri(doctype);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_cookie != null) headers['Cookie'] = _cookie!;
    await _addFirebaseAuth(headers);
    final response = await _client.post(
      uri,
      headers: headers,
      body: jsonEncode(doc),
    );
    final data = _decode(response);
    if (response.statusCode >= 400)
      throw ApiException(data['message'] ?? 'HTTP ${response.statusCode}');
    return data['data'] as Map<String, dynamic>;
  }

  static const _apiBase = 'ftms.api';

  Future<List<Map<String, dynamic>>> getAvailableRoutes() async {
    final result = await callMethod(
      '$_apiBase.route.list_routes',
      requiresSession: false,
    );
    return _messageList(result);
  }

  Future<Map<String, dynamic>> createBooking({
    required String pickup,
    required String dropoff,
    required String date,
    String? customerName,
    String? phone,
    String? route,
    int passengers = 1,
    double fare = 0,
    String? vehicleType,
    double? pickupLat,
    double? pickupLng,
    List<Map<String, dynamic>>? passengerList,
    String? externalReference,
    String? group,
    String? groupName,
    String? groupLeaderName,
    String? groupLeaderMobile,
  }) async {
    final body = <String, dynamic>{
      'pickup_point': pickup,
      'drop_point': dropoff,
      'booking_date': date,
      'passenger_count': passengers,
      'fare_amount': fare,
    };
    if (customerName != null) body['customer_name'] = customerName;
    if (phone != null) body['mobile_no'] = phone;
    if (route != null) body['route'] = route;
    if (vehicleType != null) body['vehicle_type'] = vehicleType;
    if (pickupLat != null) body['pickup_latitude'] = pickupLat;
    if (pickupLng != null) body['pickup_longitude'] = pickupLng;
    if (externalReference != null) {
      body['external_reference'] = externalReference;
    }
    if (passengerList != null && passengerList.isNotEmpty) {
      body['passengers'] = passengerList;
      body['seat_count'] = passengerList.length;
    }
    if (group != null) body['group'] = group;
    if (groupName != null) body['group_name'] = groupName;
    if (groupLeaderName != null) body['group_leader_name'] = groupLeaderName;
    if (groupLeaderMobile != null) {
      body['group_leader_mobile'] = groupLeaderMobile;
    }
    final result = await callMethod(
      '$_apiBase.booking.create_booking',
      body: body,
    );
    return _messageMap(result);
  }

  Future<Map<String, dynamic>> completeOnboarding({
    required String purpose,
    String? partnerType,
    String? serviceContractType,
    String? companyName,
    String? legalName,
    String? companyNameAr,
    String? vatNo,
    String? taxId,
    String? crNo,
    String? licenseNo,
    String? phone,
    String? address,
    String? city,
    String? country,
    String? nationality,
    String? idDocumentType,
    String? idNumber,
    String? idExpiryDate,
    String? licenseExpiryDate,
    String? iqamaNo,
    String? iqamaExpiryDate,
    String? driverCardNo,
    String? driverCardExpiryDate,
    String? serviceTypes,
    required String fullName,
    String? companyTaxId,
  }) async {
    final role = purpose == 'partner_company'
        ? 'Partner'
        : purpose == 'customer_company'
        ? 'Customer Company'
        : purpose == 'captain'
        ? 'Captain'
        : 'Passenger';
    final roleResult = await callMethod(
      '$_apiBase.onboarding.set_role',
      body: {'role': role},
    );
    if (purpose == 'passenger') {
      return _messageMap(
        await callMethod(
          '$_apiBase.onboarding.create_passenger_profile',
          body: {
            'full_name': fullName,
            'mobile_no': phone,
            'nationality': nationality,
            'id_document_type': idDocumentType,
            'id_number': idNumber,
            'id_expiry_date': idExpiryDate,
          },
        ),
      );
    }
    if (purpose == 'captain') {
      return _messageMap(
        await callMethod(
          '$_apiBase.onboarding.create_captain_profile',
          body: {
            'full_name': fullName,
            'mobile_no': phone,
            'nationality': nationality,
            'id_document_type': idDocumentType,
            'national_id': idNumber,
            'license_no': licenseNo,
            'license_expiry_date': licenseExpiryDate,
            'iqama_no': iqamaNo,
            'iqama_expiry_date': iqamaExpiryDate,
            'driver_card_no': driverCardNo,
            'driver_card_expiry_date': driverCardExpiryDate,
            'city': city,
            'address': address,
            'company_name': companyName,
            'company_tax_id': companyTaxId,
            'company_name_ar': companyNameAr,
          },
        ),
      );
    }
    if (purpose == 'customer_company') {
      return _messageMap(
        await callMethod(
          '$_apiBase.onboarding.create_customer_company',
          body: {
            'company_name': companyName,
            'legal_name': legalName,
            'vat_no': vatNo,
            'tax_id': taxId,
            'cr_no': crNo,
            'phone': phone,
            'email': null,
            'address': address,
            'city': city,
            'country': country,
            'full_name': fullName,
            'mobile_no': phone,
          },
        ),
      );
    }
    final result = await callMethod(
      '$_apiBase.onboarding.create_partner_profile',
      body: {
        'partner_type': partnerType,
        'service_contract_type': serviceContractType,
        'company_name': companyName,
        'legal_name': legalName,
        'company_name_ar': companyNameAr,
        'vat_no': vatNo,
        'tax_id': taxId,
        'cr_no': crNo,
        'license_no': licenseNo,
        'phone': phone,
        'address': address,
        'city': city,
        'country': country,
        'mobile_no': phone,
        'service_types': serviceTypes,
        'full_name': fullName,
      },
    );
    final payload = _messageMap(result);
    if (payload.isEmpty && roleResult is Map) return _messageMap(roleResult);
    return payload;
  }

  Future<Map<String, dynamic>> requestCaptainCompanyByVat(String vatNo) async {
    return _messageMap(
      await callMethod(
        '$_apiBase.onboarding.request_join_company_by_vat',
        body: {'vat_no': vatNo},
      ),
    );
  }

  Future<Map<String, dynamic>> registerVehicle({
    required String plateNo,
    required String vehicleMake,
    required String vehicleModel,
    String? vehicleType,
    int? modelYear,
    String? color,
    int? passengerCapacity,
    String? registrationNo,
  }) async {
    return _messageMap(
      await callMethod(
        '$_apiBase.vehicle.create_vehicle',
        body: {
          'plate_no': plateNo,
          'vehicle_make': vehicleMake,
          'vehicle_model': vehicleModel,
          'vehicle_type': vehicleType,
          'model_year': modelYear,
          'color': color,
          'passenger_capacity': passengerCapacity,
          'registration_no': registrationNo,
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> listMyVehicles() async {
    return _messageList(await callMethod('$_apiBase.vehicle.list_my_vehicles'));
  }

  Future<Map<String, dynamic>> getVehicleCatalog({
    String? make,
    String? model,
    String? type,
  }) async {
    final query = <String, dynamic>{'limit': '100'};
    if (make != null) query['make'] = make;
    if (model != null) query['model'] = model;
    if (type != null) query['vehicle_type'] = type;
    return _messageMap(
      await callMethod(
        '$_apiBase.vehicle.list_vehicle_catalog',
        query: query,
        requiresSession: false,
      ),
    );
  }

  Future<Map<String, dynamic>> inviteCompanyMember({
    required String company,
    required String email,
    required String role,
  }) async {
    return _messageMap(
      await callMethod(
        '$_apiBase.membership.invite_member',
        body: {'company': company, 'invited_email': email, 'role': role},
      ),
    );
  }

Future<List<Map<String, dynamic>>> getMyBookings() async {
    final result = await callMethod(
      '$_apiBase.booking.list_bookings',
      query: {'mine': '1'},
    );
    return _messageList(result);
  }

  Future<Map<String, dynamic>?> getBookingDetail(String name) async {
    final result = await callMethod(
      '$_apiBase.booking.get_booking',
      query: {'name': name},
    );
    final payload = result is Map<String, dynamic> ? result['message'] : result;
    if (payload == null) return null;
    if (payload is Map) return Map<String, dynamic>.from(payload);
    throw const ApiException('Invalid booking response.');
  }

  Future<Map<String, dynamic>> getPriceQuote({
    required String vehicleType,
    String? route,
    double? distanceKm,
    int passengerCount = 1,
    String? company,
    String? pricingRule,
    String fareMode = 'flat',
  }) async {
    final query = <String, dynamic>{
      'vehicle_type': vehicleType,
      'passenger_count': passengerCount,
      'fare_mode': fareMode,
    };
    if (route != null) query['route'] = route;
    if (distanceKm != null) query['distance_km'] = distanceKm;
    if (company != null) query['company'] = company;
    if (pricingRule != null) query['pricing_rule'] = pricingRule;
    try {
      return _messageMap(
        await callMethod(
          '$_apiBase.pricing_rule.get_price_quote',
          query: query,
          requiresSession: false,
        ),
      );
    } on ApiException {
      return {};
    }
  }

  Future<Map<String, dynamic>> cancelBooking(String bookingName) async {
    return _messageMap(
      await callMethod(
        '$_apiBase.booking.cancel_booking',
        query: {'booking_name': bookingName},
      ),
    );
  }

  Future<Map<String, dynamic>> completeAssignedTrip({
    String? trip,
    String? booking,
    required String operationId,
  }) async {
    return _messageMap(
      await callMethod(
        '$_apiBase.ride.complete_assigned_trip',
        body: {'name': trip, 'booking': booking, 'operation_id': operationId},
      ),
    );
  }

  Future<Map<String, dynamic>> acceptBookingAsCaptain({
    required String booking,
    required double offeredFare,
    String? vehicle,
  }) async {
    return _messageMap(
      await callMethod(
        '$_apiBase.booking.accept_booking_as_captain',
        body: {
          'booking_name': booking,
          'offered_fare': offeredFare,
          if (vehicle?.isNotEmpty == true) 'vehicle': vehicle,
        },
      ),
    );
  }

  Future<Map<String, dynamic>> previewCancelPenalty(String bookingName) async {
    return _messageMap(
      await callMethod(
        '$_apiBase.booking.preview_cancellation_penalty',
        query: {'booking_name': bookingName},
      ),
    );
  }

  Future<Map<String, dynamic>> verifyPlayIntegrity(
    String integrityToken,
  ) async {
    return _messageMap(
      await callMethod(
        '$_apiBase.auth.verify_play_integrity',
        body: {'integrity_token': integrityToken},
        requiresSession: false,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getMyTrips() async {
    final result = await callMethod(
      '$_apiBase.trip.list_trips',
      query: {'mine': 1},
    );
    return _messageList(result);
  }

  Future<List<Map<String, dynamic>>> getMyInvoices() async {
    final result = await callMethod(
      '$_apiBase.invoice.list_invoices',
      query: {'mine': 1},
    );
    return _messageList(result);
  }

  Future<List<Map<String, dynamic>>> getMyNotifications() async {
    final result = await callMethod(
      '$_apiBase.notifications.list_my_notifications',
    );
    return _messageList(result);
  }

  Future<void> markNotificationRead(String name) async {
    await callMethod(
      '$_apiBase.notifications.mark_read',
      query: {'name': name},
    );
  }

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String? deviceId,
  }) async {
    await callMethod(
      '$_apiBase.notifications.register_device_token',
      body: {'token': token, 'platform': platform, 'device_id': deviceId},
    );
  }

  Future<void> unregisterDeviceToken(String token) async {
    await callMethod(
      '$_apiBase.notifications.unregister_device_token',
      body: {'token': token},
    );
  }

  Future<Map<String, dynamic>> saveGroup({
    required String groupName,
    String? groupLeaderName,
    String? groupLeaderMobile,
    bool isGroupLeaderSelf = false,
    String? defaultPickupPoint,
    String? defaultDropPoint,
    String? defaultVehicleType,
    String? group,
    List<Map<String, dynamic>>? passengers,
  }) async {
    return _messageMap(
      await callMethod(
        '$_apiBase.group.save_group',
        body: {
          'group_name': groupName,
          'group_leader_name': groupLeaderName,
          'group_leader_mobile': groupLeaderMobile,
          'is_group_leader_self': isGroupLeaderSelf,
          'default_pickup_point': defaultPickupPoint,
          'default_drop_point': defaultDropPoint,
          'default_vehicle_type': defaultVehicleType,
          'group': group,
          'passengers': passengers,
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> listMyGroups() async {
    return _messageList(
      await callMethod('$_apiBase.group.list_my_groups'),
    );
  }

  Future<Map<String, dynamic>> getGroup(String group) async {
    return _messageMap(
      await callMethod('$_apiBase.group.get_group', query: {'group': group}),
    );
  }

  Future<Map<String, dynamic>> deleteGroup(String group) async {
    return _messageMap(
      await callMethod(
        '$_apiBase.group.delete_group',
        query: {'group': group},
      ),
    );
  }

  Future<Map<String, dynamic>> startBooking(String bookingName) async {
    return _messageMap(
      await callMethod(
        '$_apiBase.booking.start_booking',
        query: {'booking_name': bookingName},
      ),
    );
  }

  Future<Map<String, dynamic>> completeBooking(String bookingName) async {
    return _messageMap(
      await callMethod(
        '$_apiBase.booking.complete_booking',
        query: {'booking_name': bookingName},
      ),
    );
  }

  Future<Map<String, dynamic>> getCurrentFrappeUser() async {
    return _messageMap(
      await callMethod(
        'ftms.api.auth.get_current_user',
        requiresSession: false,
      ),
    );
  }

  Future<Map<String, dynamic>> getPaymentConfig() async {
    return _messageMap(
      await callMethod(
        'ftms.api.payment.payment_config',
        requiresSession: false,
      ),
    );
  }

  Future<Map<String, dynamic>> createMoyasserPayment({
    required double amount,
    String currency = 'SAR',
    String? description,
    String? company,
  }) async {
    return _messageMap(
      await callMethod(
        'ftms.api.payment.create_moyasser_payment',
        body: {
          'amount': amount,
          'currency': currency,
          'description': description,
          'company': company,
        },
      ),
    );
  }

  Future<Map<String, dynamic>> checkPaymentStatus(String paymentId) async {
    return _messageMap(
      await callMethod(
        'ftms.api.payment.check_payment_status',
        query: {'payment_id': paymentId},
      ),
    );
  }

  Future<List<Map<String, dynamic>>> driverMatchedBookings({
    String? vehicleType,
    double? latitude,
    double? longitude,
    int limit = 50,
  }) async {
    return _messageList(
      await callMethod(
        'ftms.matching.driver_matched_bookings',
        query: {
          if (vehicleType != null) 'vehicle_type': vehicleType,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          'limit': limit,
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> bookingMatchedOffers(
    String bookingName, {
    int limit = 50,
  }) async {
    return _messageList(
      await callMethod(
        'ftms.matching.booking_matched_offers',
        query: {'booking_name': bookingName, 'limit': limit},
      ),
    );
  }

  Future<Map<String, dynamic>> createGroupInvite(
    String bookingName, {
    int? expiresInHours,
  }) async {
    return _messageMap(
      await callMethod(
        '$_apiBase.booking.create_group_invite',
        query: {
          'booking_name': bookingName,
          if (expiresInHours != null) 'expires_in_hours': expiresInHours,
        },
      ),
    );
  }

  Future<Map<String, dynamic>> joinBookingGroup({
    required String token,
    required String passengerName,
    String? nationality,
    String? mobileNo,
    String? documentType,
    String? documentNumber,
  }) async {
    return _messageMap(
      await callMethod(
        '$_apiBase.booking.join_booking_group',
        body: {
          'token': token,
          'passenger_name': passengerName,
          'nationality': nationality,
          'mobile_no': mobileNo,
          'document_type': documentType,
          'document_number': documentNumber,
        },
        requiresSession: false,
      ),
    );
  }

  dynamic _decode(http.Response response) {
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return {'message': response.body};
    }
  }

  List<Map<String, dynamic>> _messageList(dynamic result) {
    final payload = result is Map<String, dynamic> ? result['message'] : result;
    if (payload is List)
      return payload
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    return [];
  }

  Map<String, dynamic> _messageMap(dynamic result) {
    final payload = result is Map<String, dynamic> ? result['message'] : result;
    if (payload is Map) return Map<String, dynamic>.from(payload);
    return {};
  }

  void dispose() => _client.close();
}

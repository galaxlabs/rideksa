import 'package:flutter/foundation.dart';
import '../core/errors.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/sync_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestore;
  final SyncService _syncService;

  AuthState _state = AuthState.initial;
  UserModel? _user;
  String? _errorMessage;
  String? _verificationId;
  String? _pendingPhone;

  AuthProvider(this._authService, this._firestore, this._syncService);

  AuthState get state => _state;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  String get currentUserRole => _user?.roleLabel ?? 'Passenger';

  Future<void> checkSession() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      final redirectUser = await _authService.checkGoogleRedirect();
      if (redirectUser != null) {
        _user = redirectUser;
        await _authService.applyPendingRoleIfAny();
        _user = _authService.currentUser;
        _state = AuthState.authenticated;
        _syncService.startPeriodicSync();
        notifyListeners();
        return;
      }

      if (_user != null) {
        _state = AuthState.authenticated;
        notifyListeners();
        return;
      }

      final restoredUser = await _authService.restoreSession();
      if (restoredUser != null) {
        _user = restoredUser;
        _state = AuthState.authenticated;
        _syncService.startPeriodicSync();
      } else if (_user == null) {
        _state = AuthState.unauthenticated;
      } else {
        _state = AuthState.authenticated;
      }
    } catch (e) {
      debugPrint('AUTH SESSION CHECK ERROR: $e');
      _errorMessage = 'Your session expired. Please sign in again.';
      if (_user == null) {
        _state = AuthState.unauthenticated;
      } else {
        _state = AuthState.authenticated;
      }
    }
    notifyListeners();
  }

  Future<void> sendOTP(String phone) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _pendingPhone = phone;
      final user = await _authService.signInWithPhone(phone);
      _verificationId = _authService.currentUser?.uid;
      _state = AuthState.initial;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _state = AuthState.error;
    } catch (e) {
      _errorMessage = 'Failed to send OTP';
      _state = AuthState.error;
    }
    notifyListeners();
  }

  Future<void> verifyOTP(String otp) async {
    if (_verificationId == null || _verificationId == 'pending') return;
    _state = AuthState.loading;
    notifyListeners();
    try {
      _user = await _authService.verifyOTP(_verificationId!, otp);
      _state = AuthState.authenticated;
      _syncService.startPeriodicSync();
    } on AppException catch (e) {
      _errorMessage = e.message;
      _state = AuthState.error;
    } catch (e) {
      _errorMessage = 'OTP verification failed';
      _state = AuthState.error;
    }
    notifyListeners();
  }

  Future<void> signUp(
    String email,
    String password, {
    String? displayName,
    String purpose = 'passenger',
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
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await _authService.signUpWithEmail(
        email,
        password,
        displayName: displayName,
      );
      try {
        await _authService.ensureFrappeSession();
        await _authService.completeOnboarding(
          purpose: purpose,
          partnerType: partnerType,
          serviceContractType: serviceContractType,
          companyName: companyName,
          legalName: legalName,
          companyNameAr: companyNameAr,
          vatNo: vatNo,
          taxId: taxId,
          crNo: crNo,
          licenseNo: licenseNo,
          phone: phone,
          address: address,
          city: city,
          country: country,
          nationality: nationality,
          idDocumentType: idDocumentType,
          idNumber: idNumber,
          idExpiryDate: idExpiryDate,
          licenseExpiryDate: licenseExpiryDate,
          iqamaNo: iqamaNo,
          iqamaExpiryDate: iqamaExpiryDate,
          driverCardNo: driverCardNo,
          driverCardExpiryDate: driverCardExpiryDate,
          serviceTypes: serviceTypes,
          fullName: displayName ?? email,
        );
      } catch (e) {
        debugPrint('Frappe onboarding sync failed: $e');
        throw AuthException(
          'Account was created, but the Frappe profile could not be linked. Please retry.',
        );
      }
      final selectedRole = purpose == 'captain'
          ? UserRole.driver
          : purpose == 'customer_company'
          ? UserRole.customerCompany
          : purpose == 'partner_company' && partnerType == 'Travel Agent'
          ? UserRole.travelAgent
          : purpose == 'partner_company'
          ? UserRole.partnerCompany
          : UserRole.passenger;
      await updateRole(selectedRole);
      await updateProfile(
        displayName: displayName ?? _user?.displayName,
        phone: phone ?? _user?.phone,
      );
      _state = AuthState.authenticated;
      _syncService.startPeriodicSync();
    } on AppException catch (e) {
      _errorMessage = e.message;
      _state = AuthState.error;
    } catch (e) {
      _errorMessage = 'Sign up failed';
      _state = AuthState.error;
    }
    notifyListeners();
  }

  Future<void> loginWithGoogle() async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await _authService.signInWithGoogle();
      await _authService.applyPendingRoleIfAny();
      _user = _authService.currentUser;
      _state = AuthState.authenticated;
      _syncService.startPeriodicSync();
    } on AppException catch (e) {
      if (e.message.contains('Redirecting')) {
        _errorMessage = null;
        _state = AuthState.unauthenticated;
      } else {
        _errorMessage = e.message;
        _state = AuthState.error;
      }
    } catch (e) {
      _errorMessage = 'Google sign-in failed';
      _state = AuthState.error;
    }
    notifyListeners();
  }

  Future<void> loginWithEmail(String email, String password) async {
    _state = AuthState.loading;
    notifyListeners();
    try {
      _user = await _authService.signInWithEmail(email, password);
      await _authService.applyPendingRoleIfAny();
      _user = _authService.currentUser;
      _state = AuthState.authenticated;
      _syncService.startPeriodicSync();
    } on AppException catch (e) {
      _errorMessage = e.message;
      _state = AuthState.error;
    } catch (e) {
      _errorMessage = 'Login failed';
      _state = AuthState.error;
    }
    notifyListeners();
  }

  Future<void> selectPurpose(UserRole role) async {
    await _authService.updateRole(role);
    notifyListeners();
  }

  Future<void> updateRole(UserRole role, {String? companyId}) async {
    await _authService.updateRole(role, companyId: companyId);
    _user = _authService.currentUser;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? displayName,
    String? phone,
    String? nationality,
    String? documentType,
    String? documentNo,
  }) async {
    final current = _user;
    if (current == null) return;
    final updated = UserModel(
      uid: current.uid,
      phone: phone ?? current.phone,
      email: current.email,
      displayName: displayName ?? current.displayName,
      role: current.role,
      companyId: current.companyId,
      isActive: current.isActive,
      createdAt: current.createdAt,
      lastLogin: current.lastLogin,
      frappeUserId: current.frappeUserId,
      fcmToken: current.fcmToken,
      nationality: nationality ?? current.nationality,
      documentType: documentType ?? current.documentType,
      documentNo: documentNo ?? current.documentNo,
      lastDeviceId: current.lastDeviceId,
      lastDeviceLabel: current.lastDeviceLabel,
      loginCount: current.loginCount,
    );
    await _firestore.setUser(updated);
    _user = updated;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.signOut();
    _syncService.stopSync();
    _user = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _state = AuthState.initial;
    notifyListeners();
  }
}

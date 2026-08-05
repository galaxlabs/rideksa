import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../core/errors.dart';
import '../models/user_model.dart';
import 'frappe_api_client.dart';
import 'firestore_service.dart';
import 'google_auth.dart';
import 'token_storage.dart';

class AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final TokenStorage _storage = createTokenStorage();
  final FirestoreService _firestore;
  final FrappeApiClient _frappe;

  AuthService(this._firestore, this._frappe) {
    _frappe.sessionRefresher = ensureFrappeSession;
    _frappe.firebaseTokenProvider = (forceRefresh) async {
      final user = _auth.currentUser;
      if (user == null) return null;
      return user.getIdToken(forceRefresh);
    };
    _auth.authStateChanges().listen((fbUser) async {
      if (fbUser != null && _currentUser == null) {
        try {
          final user = await _completeFirebaseUser(fbUser);
          _onAuthChanged?.call(user);
        } catch (_) {}
      } else if (fbUser == null && _currentUser != null) {
        _currentUser = null;
        _onAuthChanged?.call(null);
      }
    });
  }

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  void Function(UserModel?)? _onAuthChanged;
  set onAuthChanged(void Function(UserModel?)? cb) => _onAuthChanged = cb;

  Future<bool> get isLoggedIn async {
    if (_currentUser != null) return true;
    final restored = await restoreSession();
    return restored != null;
  }

  Future<UserModel?> restoreSession() async {
    final fbUser = _auth.currentUser;
    if (fbUser != null) {
      if (_currentUser?.uid == fbUser.uid) {
        await _syncFrappeLogin(fbUser);
        return _currentUser;
      }
      try {
        return _completeFirebaseUser(fbUser);
      } catch (e) {
        debugPrint('SESSION RESTORE ERROR: $e');
        return null;
      }
    }
    final token = await _storage.read(key: 'auth_token');
    if (token == null || token.isEmpty) return null;
    UserModel? userDoc;
    try {
      userDoc = await _firestore.getUser(token);
    } catch (_) {
      userDoc = null;
    }
    if (userDoc == null) return null;
    _currentUser = userDoc;
    return userDoc;
  }

  Future<UserModel?> checkGoogleRedirect() async {
    if (!_isRedirectReturnUrl()) return null;
    try {
      final result = await getGoogleRedirectResult(_auth);
      final fbUser = result?.user ?? _auth.currentUser;
      if (fbUser == null) return null;
      return _completeFirebaseUser(fbUser);
    } catch (_) {
      return null;
    }
  }

  bool _isRedirectReturnUrl() {
    if (kIsWeb) {
      try {
        final uri = Uri.base.toString();
        return uri.contains('__/auth/handler') || uri.contains('firebaseauth');
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  Future<String> signInWithPhone(String phone) => _verifyPhone(phone);

  Future<UserModel> verifyOTP(String verificationId, String smsCode) async {
    try {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final result = await _auth.signInWithCredential(credential);
      final fbUser = result.user;
      if (fbUser == null) throw const AuthException('OTP verification failed');

      return _completeFirebaseUser(fbUser);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'OTP failed');
    }
  }

  Future<UserModel> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
    String? phone,
  }) async {
    try {
      final customToken = await _frappe.registerAndGetFirebaseCustomToken(
        email: email,
        password: password,
        displayName: displayName,
        mobileNo: phone,
      );
      final result = await _auth.signInWithCustomToken(customToken);
      final fbUser = result.user;
      if (fbUser == null) throw const AuthException('Sign up failed');
      if (displayName != null) {
        try {
          await fbUser.updateDisplayName(displayName);
        } catch (_) {}
      }
      return _completeFirebaseUser(fbUser);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_friendlyAuthError(e));
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      final isPhone = _isMobileIdentifier(email);
      final customToken = await _frappe.getFirebaseCustomToken(
        email: isPhone ? '' : email,
        password: password,
        mobileNo: isPhone ? email : null,
      );
      final result = await _auth.signInWithCustomToken(customToken);
      final fbUser = result.user;
      if (fbUser == null) throw const AuthException('Login failed');
      return _completeFirebaseUser(fbUser);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_friendlyAuthError(e));
    } on ApiException catch (e) {
      throw AuthException(e.message);
    } catch (e, stack) {
      debugPrint('EMAIL SIGNIN ERROR: $e $stack');
      throw AuthException(e.toString());
    }
  }

  Future<void> requestPasswordReset(String email) {
    return _frappe.requestFrappePasswordReset(email);
  }

  Future<UserModel> _completeFirebaseUserWithData({
    required String uid,
    required String email,
    String displayName = '',
  }) async {
    UserModel? userDoc;
    try {
      userDoc = await _firestore.getUser(uid);
    } catch (_) {
      userDoc = null;
    }
    String? deviceId;
    try {
      deviceId = await _getOrCreateDeviceId();
    } catch (_) {
      deviceId = 'unknown';
    }
    if (userDoc == null) {
      userDoc = UserModel(
        uid: uid,
        email: email,
        displayName: displayName,
        role: UserRole.passenger,
        lastLogin: DateTime.now(),
        lastDeviceId: deviceId,
        lastDeviceLabel: _deviceLabel(),
        loginCount: 1,
      );
      try {
        await _firestore.setUser(userDoc);
      } catch (_) {}
    } else {
      userDoc = UserModel(
        uid: userDoc.uid,
        phone: userDoc.phone,
        email: userDoc.email?.isNotEmpty == true ? userDoc.email : email,
        displayName: userDoc.displayName?.isNotEmpty == true
            ? userDoc.displayName
            : displayName,
        role: userDoc.role,
        companyId: userDoc.companyId,
        isActive: userDoc.isActive,
        createdAt: userDoc.createdAt,
        lastLogin: DateTime.now(),
        frappeUserId: userDoc.frappeUserId,
        fcmToken: userDoc.fcmToken,
        nationality: userDoc.nationality,
        documentType: userDoc.documentType,
        documentNo: userDoc.documentNo,
        lastDeviceId: deviceId,
        lastDeviceLabel: _deviceLabel(),
        loginCount: userDoc.loginCount + 1,
      );
      try {
        await _firestore.setUser(userDoc);
      } catch (_) {}
    }
    try {
      await _storage.write(key: 'auth_token', value: uid);
    } catch (_) {}
    _currentUser = userDoc;
    return userDoc;
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      final result = await signInWithGoogleProvider(_auth);
      return _completeFirebaseSignIn(
        result,
        fallbackMessage: 'Google sign-in failed',
      );
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'redirect-started') {
        throw const AuthException('Redirecting to Google sign-in...');
      }
      if (e.code == 'operation-not-allowed') {
        throw const AuthException(
          'Google sign-in not enabled in Firebase Console.',
        );
      }
      if (e.code == 'unauthorized-domain') {
        throw const AuthException(
          'Add this domain to Firebase Auth authorized domains.',
        );
      }
      if (e.code == 'popup-blocked') {
        throw const AuthException('Browser blocked the Google sign-in popup.');
      }
      throw AuthException(e.message ?? 'Google sign-in failed');
    }
  }

  Future<UserModel> _completeFirebaseSignIn(
    fb.UserCredential result, {
    required String fallbackMessage,
  }) async {
    final fbUser = result.user;
    if (fbUser == null) throw AuthException(fallbackMessage);
    return _completeFirebaseUser(fbUser);
  }

  Future<UserModel> _completeFirebaseUser(fb.User fbUser) async {
    try {
      final uid = fbUser.uid;
      final email = fbUser.email ?? '';
      final displayName = fbUser.displayName ?? '';

      UserModel? userDoc;
      try {
        userDoc = await _firestore.getUser(uid);
      } catch (_) {
        userDoc = null;
      }

      String? deviceId;
      try {
        deviceId = await _getOrCreateDeviceId();
      } catch (_) {
        deviceId = 'unknown';
      }

      if (userDoc == null) {
        userDoc = UserModel(
          uid: uid,
          email: email,
          displayName: displayName,
          role: UserRole.passenger,
          lastLogin: DateTime.now(),
          lastDeviceId: deviceId,
          lastDeviceLabel: _deviceLabel(),
          loginCount: 1,
        );
        try {
          await _firestore.setUser(userDoc);
        } catch (_) {}
      } else {
        userDoc = UserModel(
          uid: userDoc.uid,
          phone: userDoc.phone,
          email: userDoc.email?.isNotEmpty == true ? userDoc.email : email,
          displayName: userDoc.displayName?.isNotEmpty == true
              ? userDoc.displayName
              : displayName,
          role: userDoc.role,
          companyId: userDoc.companyId,
          isActive: userDoc.isActive,
          createdAt: userDoc.createdAt,
          lastLogin: DateTime.now(),
          frappeUserId: userDoc.frappeUserId,
          fcmToken: userDoc.fcmToken,
          nationality: userDoc.nationality,
          documentType: userDoc.documentType,
          documentNo: userDoc.documentNo,
          lastDeviceId: deviceId,
          lastDeviceLabel: _deviceLabel(),
          loginCount: userDoc.loginCount + 1,
        );
        try {
          await _firestore.setUser(userDoc);
        } catch (_) {}
      }

      try {
        await _storage.write(key: 'auth_token', value: uid);
      } catch (_) {}
      await _syncFrappeLogin(fbUser);
      _currentUser = userDoc;
      return userDoc;
    } catch (e) {
      throw AuthException(
        'Login successful but failed to load profile: ${e.toString()}',
      );
    }
  }

  Future<void> _syncFrappeLogin(fb.User fbUser) async {
    final token = await fbUser.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw const AuthException('Could not obtain a Firebase login token.');
    }
    await _frappe.loginWithFirebaseIdToken(token);
  }

  Future<void> ensureFrappeSession() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null)
      throw const AuthException('Firebase login is required.');
    await _syncFrappeLogin(fbUser);
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
  }) {
    return _frappe.completeOnboarding(
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
      fullName: fullName,
    );
  }

  Future<String> _getOrCreateDeviceId() async {
    try {
      final existing = await _storage.read(key: 'device_id');
      if (existing != null && existing.isNotEmpty) return existing;
      final id = 'device_${DateTime.now().millisecondsSinceEpoch}';
      await _storage.write(key: 'device_id', value: id);
      return id;
    } catch (_) {
      return 'device_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  String _deviceLabel() => DateTime.now().timeZoneName;

  Future<void> updateRole(UserRole role, {String? companyId}) async {
    _currentUser ??= UserModel(
      uid: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      role: role,
      companyId: companyId,
    );
    _currentUser = UserModel(
      uid: _currentUser!.uid,
      phone: _currentUser!.phone,
      email: _currentUser!.email,
      displayName: _currentUser!.displayName,
      role: role,
      companyId: companyId ?? _currentUser!.companyId,
      lastLogin: _currentUser!.lastLogin,
      nationality: _currentUser!.nationality,
      documentType: _currentUser!.documentType,
      documentNo: _currentUser!.documentNo,
      lastDeviceId: _currentUser!.lastDeviceId,
      lastDeviceLabel: _currentUser!.lastDeviceLabel,
      loginCount: _currentUser!.loginCount,
    );
    await _storage.write(key: 'pending_role', value: role.name);
  }

  Future<UserRole?> getPendingRole() async {
    final value = await _storage.read(key: 'pending_role');
    if (value == null || value.isEmpty) return null;
    for (final r in UserRole.values) {
      if (r.name == value) return r;
    }
    return null;
  }

  Future<void> clearPendingRole() async {
    await _storage.delete(key: 'pending_role');
  }

  Future<void> applyPendingRoleIfAny() async {
    final pending = await getPendingRole();
    if (pending == null) return;
    await updateRole(pending);
    await clearPendingRole();
  }

  Future<void> signOut() async {
    try {
      await _frappe.logout();
    } finally {
      try {
        await _auth.signOut();
      } finally {
        await _storage.delete(key: 'auth_token');
        _currentUser = null;
      }
    }
  }

  Future<String> _verifyPhone(String phone) async {
    final completer = Completer<String>();
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (_) {},
      verificationFailed: (e) {
        if (!completer.isCompleted) {
          completer.completeError(
            AuthException(e.message ?? 'Phone verification failed'),
          );
        }
      },
      codeSent: (vid, _) {
        if (!completer.isCompleted) completer.complete(vid);
      },
      codeAutoRetrievalTimeout: (_) {
        if (!completer.isCompleted) {
          completer.completeError(
            const AuthException('OTP request timed out. Try again.'),
          );
        }
      },
      timeout: const Duration(seconds: 60),
    );
    return completer.future;
  }

  bool _isMobileIdentifier(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.contains('@')) return false;
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 9 && digits.length <= 15;
  }

  String _friendlyAuthError(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Try logging in.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Email or password is incorrect.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/Password sign-in is not enabled.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}

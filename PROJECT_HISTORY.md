# RideKSA — Project History & Session Log

> **Generated:** 2026-07-26  
> **Project:** RideKSA Flutter App  
> **Package:** `com.galaxylabs.ftms`  
> **Repository Root:** `E:\Projects\ftms-platform\rideksa\`

---

## 1. Project Overview

### 1.1 Purpose
Ride-hailing + fleet management app for Saudi Arabia with 4 user roles (Passenger, Driver, Company Admin, Super Admin). Hybrid architecture: Firestore for real-time data, Frappe for permanent records.

### 1.2 Stack
- **Flutter** 3.41.8 (stable)
- **Dart** 3.11.5
- **Firebase** Auth, Firestore, Messaging, Hosting
- **Frappe** backend at `https://ftms.galaxylabs.online`
- **Firebase Project:** `rideksa-84949` (ID: `482669449729`)
- **Maps API Key:** `AIzaSyCj2OCfCOyTg4mI7PA4p9rZUkX5wwqYNzo`

### 1.3 Platform Status
| Platform | Status | Notes |
|----------|--------|-------|
| Android | ✅ Working | APK builds, runs on emulator |
| Web | ✅ Working | Hosted at `https://rideksa-84949.web.app` |
| iOS | ❌ Not configured | Firebase options throw UnsupportedError |
| Windows/macOS/Linux | ❌ Not configured | Same |

---

## 2. Session Log

### Session 1: Initial App Creation & Architecture
- Created Flutter app `rideksa`
- Set up Firebase project, google-services.json
- Implemented 4-role architecture
- Firebase Auth + Firestore integration
- Frappe API client for FTMS backend

### Session 2: Auth Flow & Google Sign-In
- Login screen with Sign In / Sign Up tabs
- Google Sign-In with popup/redirect
- Phone OTP auth (never worked — see C1)
- Guest mode + role selection

### Session 3: Web Deployment & Firebase Hosting
- Flutter web build configured
- Firebase Hosting at `rideksa-84949.web.app`
- Firebase App Distribution configured

### Session 4: Bug Fixing Sprint
- Fixed `MainActivity.kt` missing crash
- Fixed `Firebase.initializeApp()` missing
- Fixed GoRouter navigation (pushNamed → push/go)
- Fixed `updateRole` not awaited
- Fixed GoRouter recreated on every build
- Fixed `Colors.white25` → `withAlpha(64)`
- Fixed `geoflutterfire2` removed (custom radius filter)
- Fixed web blank page (secure_storage → localStorage conditional)

### Session 5: Windows Path Issues
- `C:\Users\Abdul Quddos\` has space → break build tools
- Workaround: `subst K:` for Flutter SDK
- AVD stored at `E:\.android\avd\` instead of `%HOME%`

### Session 6: Business Features Sprint
- Travel Agent role
- Company setup screen
- Contract booking (pick/drop, rent-a-car)
- Group invite links (24h expiry)
- Group member management
- Profile screen (nationality, document type/no)
- In-app chat screen
- Dynamic pricing service
- Wallet with SAR 500 test credits
- 5% platform commission
- Trip transfer/resale with profit fee
- Scheduled reminders (6h→30min, 1h→15min)

### Session 7: Web Auth Crisis
- Google sign-in broken on web (COOP popup issues)
- Multiple fixes attempted:
  - `Cross-Origin-Opener-Policy: same-origin-allow-popups`
  - `authDomain` changed to `web.app` then back to `firebaseapp.com`
  - Google OAuth redirect URIs configured in Google Cloud Console
  - Custom HTTP wrappers (http.post, dart:html, window.fetch)
  - Race condition fix in checkSession()
- Root cause: **Firestore API was disabled** in project

### Session 8: Full Codebase Audit
- **38 issues found across 6 categories**
- 6 critical, 15 high, 17 medium, 8 low
- Full report in `/lib` analysis

### Session 9: Android Build & Firestore Fix
- Fixed Kotlin incremental cache corruption (space in path)
- Disabled incremental Kotlin compilation
- **Enabled Firestore API** — the root cause of all auth/routing failures
- Wallet now loads and shows balance

---

## 3. Test Accounts

| Email | Password | Role | UID |
|-------|----------|------|-----|
| `passenger1@rideksa.test` | `Test@123456` | Passenger | `wNyeHn94IbX5gji8LbiQ3asVXm03` |
| `passenger2@rideksa.test` | `Test@123456` | Passenger | `8OBSGfj2E8bKU5fC69wNcsem42K2` |
| `passenger3@rideksa.test` | `Test@123456` | Passenger | `kCNBrJsZVoYzaABH8O7uppTrUJ03` |
| `driver1@rideksa.test` | `Test@123456` | Driver | `ytQObvJt8JOfhawsvMs82P0S9eH2` |
| `admin1@rideksa.test` | `Test@123456` | Company Admin | `PLfBF1M3lYPeOPPOHl0wqFOtOBc2` |
| `test@rideksa.com` | `Test123456!` | Passenger | `GL3U2Ajd09ap4RgcDoNQbSQts5H3` |

All have **SAR 500 test credits** on first wallet load.

---

## 4. Critical Bugs (Unresolved)

### C1 — Phone OTP Auth Broken
**File:** `lib/providers/auth_provider.dart:60,73`  
**Severity:** CRITICAL  
**Issue:** `_verificationId` is set to `'pending'` (fake UID from `signInWithPhone`), not the actual Firebase verification ID. The `verifyOTP` method immediately returns because it checks for `'pending'`.  
**Fix needed:** Expose the real verification ID from `AuthService._verifyPhone()`.

### C2 — Unchecked `state.extra` Casts
**Files:** `lib/core/routes.dart:62,71`  
**Severity:** HIGH  
**Issue:** `state.extra as Map<String, dynamic>?` and `state.extra as String` will crash with `TypeError` if null or wrong type.  
**Fix needed:** Use null-safe checks.

### C3 — Wallet Transactions Non-Atomic
**File:** `lib/services/wallet_service.dart:45-46`  
**Severity:** HIGH  
**Issue:** Transaction record and balance update are separate Firestore writes. If second write fails, money is lost/created.  
**Fix needed:** Use `Firestore.runTransaction()`.

### C4 — My Rides Screen Empty Forever
**File:** `lib/screens/passenger/my_rides_screen.dart:11`  
**Severity:** CRITICAL  
**Issue:** `_rides` list is initialized empty and never populated. No Firestore query, no provider integration.  
**Fix needed:** Subscribe to completed trips from Firestore.

### C5 — ~~Wallet Never Loaded~~ ✅ **FIXED**
**File:** `lib/screens/passenger/wallet_screen.dart`  
**Fix:** Converted to StatefulWidget, calls `WalletProvider.subscribe()` in `didChangeDependencies`.

### C6 — Add Driver/Company Dialogs Lose Input
**Files:** `lib/screens/admin/driver_management_screen.dart:45-53`, `lib/screens/super_admin/company_list_screen.dart:40-52`  
**Severity:** CRITICAL  
**Issue:** TextFields created without `TextEditingController`. Input is never captured. "Add" just closes dialog.  
**Fix needed:** Add controllers and Firestore writes.

---

## 5. High Severity Bugs (Unresolved)

| ID | Bug | File | Fix Needed |
|----|-----|------|------------|
| H1 | `_deviceLabel()` always returns `web_` prefix | `auth_service.dart:242` | Remove `web_` hardcode |
| H2 | `streamAvailableDrivers` missing online status filter | `firestore_service.dart:54-59` | Add `.where('status', isEqualTo: 'online')` |
| H3 | `filterByRadius` drops driver fields | `location_service.dart:68-85` | Preserve all fields |
| H4 | `DriverModel` fabricated as coordinate carrier | `driver_provider.dart:43-50` | Use proper filter method |
| H5 | Driver location written to `users` not `drivers` | `driver_provider.dart:87-90` | Change to `setDriver` |
| H6 | Driver self-accepts own offer (market bypass) | `dashboard_screen.dart:164-175` | Split accept/offer flows |
| H7 | Only first new ride notifies | `driver_provider.dart:54-58` | Remove `break` |
| H8 | Duplicate dialog crash | `app_alert_listener.dart:36` | Queue/guard dialogs |
| H9 | Earnings screen static (SAR 0) | `earnings_screen.dart:23` | Add data integration |
| H10 | Invite link broken on mobile | `contract_booking_screen.dart:141` | Use different base URL |
| H11 | 4 missing Firestore composite indexes | `firestore_service.dart` multiple | Create in Firebase Console |
| H12 | Driver location update not pushed to Firestore | `driver_provider.dart:99` | Add `setDriver` call |
| H13 | Wallet `topUp` silent no-op | `wallet_provider.dart:42` | Return early fix (resolved with C5 fix) |

---

## 6. Medium & Low Severity

### Medium
- `cancelRide` deletes after status update (wasted write)
- `acceptOffer` uses `firstWhere` which throws if ID not found
- Test credits (500 SAR) given to EVERY new user — must remove in production
- `PricingService` per-km rate hardcoded at 2.2
- BookRideScreen hardcodes SAR 1.5/km for route extra
- Profile `_save` has no error handling (stuck button)
- `syncAll` swallows all errors silently
- Missing `ACCESS_NETWORK_STATE` permission in AndroidManifest
- `context.read` in `initState` fragile pattern
- Hardcoded 5% in UI instead of `AppConstants.commissionRate`
- `startTracking` bypasses `LocationService` abstraction

### Low
- `OTPSCreen` class name typo (extra 'S')
- 7 dead dependencies in `pubspec.yaml` (riverpod, hive, flutter_svg, etc.)
- iOS/macOS/Windows throw `UnsupportedError`
- Empty `RefreshIndicator.onRefresh`
- `signOut()` does not clear error message
- `_pendingPhone` written but never read
- No Firebase Crashlytics configured

---

## 7. Firebase Configuration

### Enabled Services
- ✅ Authentication (Email/Password + Google)
- ✅ Firestore Database (test mode)
- ✅ Firebase Hosting
- ✅ Firebase App Distribution

### Missing / Pending
- ❌ Firestore composite indexes (4 needed — see H11)
- ❌ Firestore security rules (`firestore.rules` not in project)
- ❌ Firebase Crashlytics
- ❌ Firebase Cloud Functions (for reminders, payment webhooks)
- ❌ Firebase Cloud Messaging server key configured

### Google Cloud OAuth
**Authorized Redirect URIs for Web:**
```
https://rideksa-84949.web.app/__/auth/handler
https://rideksa-84949.firebaseapp.com/__/auth/handler
```

### Firebase Console Checklist
1. Authentication → Sign-in method → Email/Password: **Enabled**
2. Authentication → Sign-in method → Google: **Enabled**
3. Authentication → Settings → Authorized domains:
   - `rideksa-84949.web.app`
   - `rideksa-84949.firebaseapp.com`
4. Firestore Database: **Created** (test mode for development)
5. Firestore Indexes: **Needed** (see below)

### Required Composite Indexes
| Collection | Fields | 
|------------|--------|
| `active_rides` | `status` (asc) |
| `transactions` | `user_id` (asc), `created_at` (desc) |
| `commissions` | `company_id` (asc), `created_at` (desc) |
| `chat_messages` | `ride_request_id` (asc), `created_at` (asc) |

---

## 8. Known Environment Issues

### Windows Path With Space
- User home: `C:\Users\Abdul Quddos\` (space in path)
- **Fix:** Flutter SDK mapped via `subst K:` → K:\bin\flutter.bat
- **Kotlin cache fix:** `kotlin.incremental=false` in `gradle.properties`
- **AVD storage:** `E:\.android\avd\` instead of default

### Emulator
- AVD name: `pixel7` (Google Pixel 7, API 34)
- SDK: `C:\Android\Sdk`
- Start: `"C:\Android\Sdk\emulator\emulator.exe" -avd pixel7`
- Kill: `taskkill //F //IM qemu-system-x86_64.exe`

### Web Build
- Flutter: `"K:/bin/flutter.bat" build web`
- Deploy: `firebase deploy --only hosting`
- URL: `https://rideksa-84949.web.app`

---

## 9. Architecture Decisions

| Decision | Rationale |
|----------|-----------|
| Firestore for real-time, Frappe for records | Hybrid: Firestore handles active rides/GPS, Frappe is permanent ledger |
| Firebase Auth (not Frappe login) | Native Google Sign-In, multi-platform session management |
| 5% fixed commission | Simple, auditable. TripTransfer model also has 5% on profit |
| Test credits (SAR 500) | Auto-credit on first wallet creation. Disable in production |
| Conditional imports for storage | Web uses localStorage, mobile uses FlutterSecureStorage |
| Firebase REST API fallback | Some firebase_auth_web versions have JS interop bugs |
| `kIsWeb` branching | Avoid fragile JS interop on web for critical auth flows |

---

## 10. Test Results Summary

| Test | Date | Result |
|------|------|--------|
| Email/Password Login (web) | 2026-07-26 | ✅ Works (was broken: Firestore disabled) |
| Google Sign-In (web) | 2026-07-26 | ✅ Works (was broken: OAuth redirect URIs + COOP) |
| Email/Password Login (Android) | 2026-07-26 | ✅ Works |
| Wallet Display | 2026-07-26 | ✅ Works (was broken: subscribe never called) |
| Route Redirection | 2026-07-26 | ✅ Works (was broken: race condition) |
| Phone OTP | Never | ❌ Never worked |
| My Rides | Never | ❌ Empty screen |
| Google Maps | Never | ❌ Placeholder only |
| Add Driver/Company | Never | ❌ Dialogs save nothing |
| Wallet Top-Up | 2026-07-26 | ✅ Works (test mode) |

---

## 11. Frappe Integration Status

### Client-Side (Flutter)
- ✅ FrappeApiClient with session cookie management
- ✅ Firebase ID token → Frappe bridge (endpoint not implemented)
- ✅ Route sync, company sync, booking/trip push

### Server-Side (Frappe — Not Yet Implemented)
- ❌ `ftms.api.auth.login_with_firebase` — verify Firebase token, create/link Frappe user
- ❌ Payment webhook handler (Mada, STC Pay, SADAD)
- ❌ Background job for scheduled trip reminders

---

## 12. Next Steps (Priority Order)

1. **Fix C1 — Phone OTP** (expose verification ID)
2. **Fix C6 — Add Driver/Company dialogs** (add controllers + Firestore writes)
3. **Fix C4 — My Rides** (subscribe to completed trips)
4. **Fix C3 — Atomic wallet** (use `runTransaction`)
5. **Fix H5 — Driver location** (write to correct collection)
6. **Fix H6 — Market bypass** (split accept/offer)
7. **Create Firestore composite indexes**
8. **Add Firebase security rules**
9. **Implement Frappe server endpoint** for Firebase auth bridge
10. **Add Firebase Crashlytics**

# RideKSA — Full Workflows & Architecture

## System Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                      RideKSA Client                          │
│  ┌──────────┐  ┌───────────┐  ┌──────────┐  ┌───────────┐  │
│  │Passenger │  │  Driver   │  │  Admin   │  │ Web App   │  │
│  │  (APK)   │  │   (APK)   │  │  (APK)   │  │ (Browser) │  │
│  └────┬─────┘  └─────┬─────┘  └────┬─────┘  └─────┬─────┘  │
│       │              │             │              │         │
│       └──────────────┼─────────────┼──────────────┘         │
│                      │             │                        │
└──────────────────────┼─────────────┼────────────────────────┘
                       │             │
              ┌────────┴─────┬───────┴────────┐
              │  Firebase    │  Frappe Backend │
              │  (Realtime)  │  (REST API)     │
              │  - Auth      │  - Bookings     │
              │  - Firestore │  - Trips        │
              │  - FCM       │  - Groups       │
              │  - Hosting   │  - Payments     │
              └──────────────┴────────────────┘
```

### Dual-Write Pattern
- **Firestore**: Real-time ride marketplace, driver-passenger matching UI
- **Frappe**: Authoritative backend (bookings, trips, payments, groups)
- `sync_service.dart` syncs Firestore → Frappe on booking creation/acceptance

---

## 1. Authentication Flow

```
User opens app → Login Screen
    │
    ├── Email + Password Login (auto-detect phone)
    │   ├── POST ftms.api.auth.firebase_token_from_frappe_password
    │   │   { email: "user@email.com" | "05xxxxxxxx", password }
    │   ├── Backend resolves mobile → Frappe User (if phone)
    │   ├── Authenticates via LoginManager
    │   └── Returns Firebase custom token + initiates Firebase Auth
    │
    ├── Google Sign-In
    │   └── Firebase Auth → Frappe login_with_firebase → Session
    │
    └── Phone OTP
        └── Firebase Phone Auth → OTP → Frappe session
```

### User Roles
| Role | Capabilities |
|---|---|
| **Passenger** | Create bookings, join groups, view own bookings, cancel own |
| **Driver/Captain** | Browse open bookings, make offers, accept rides, complete trips |
| **Company Admin** | Create/edit company bookings, manage drivers, view all company data |
| **Dispatcher** | Create company bookings, assign drivers |
| **Super Admin** | Full access |

### Data Isolation
- `list_bookings(mine=true)` → only `main_rider_user = session.user`
- `_booking_detail_access` → owner / company operator / assigned captain
- Users never see other passengers' bookings

---

## 2. Booking Creation Flow

```
Passenger opens Book Ride screen
    │
    ├── Enter pickup, drop-off, date, vehicle type, fare
    ├── Optional: Group booking toggle
    │   ├── Add passengers row by row
    │   ├── "Apply saved group" → loads Trip Group from Frappe
    │   └── Group auto-saved on booking submit
    │
    ├── Submit
    │   ├── 1. saveGroup() to Frappe (if group booking)
    │   ├── 2. rideProvider.createRideRequest() → Firestore
    │   ├── 3. sync_service.pushRideToFrappe() → create_booking
    │   └── 4. wallet_service.reserveAndCreateBooking()
    │
    └── Booking appears in "My Rides"
        Status: Draft → Awaiting Offers
```

---

## 3. Group Booking & Reuse

```
Create Group Booking
    │
    ├── Toggle "Group booking" ON
    ├── Enter group name
    ├── Add passengers (name, mobile, nationality, document)
    │
    ├── [NEW] Apply saved group dropdown
    │   ├── Loads from ftms.api.group.list_my_groups
    │   ├── Select group → auto-fills passengers + name
    │   └── On submit: saveGroup() updates/creates group in Frappe
    │
    ├── Share: Groups screen → "Share" → create_group_invite
    │   ├── Generates signed HMAC token (expiring link)
    │   └── Link: https://rideksa.celtcoksa.com/#/join/{token}
    │
    └── Join via invite:
        ├── Guest opens join link → JoinGroupRideScreen
        ├── Fills passenger details → join_booking_group
        └── Added to Trip Passenger child table

Repeat Booking (from completed)
    │
    ├── Booking Detail → "Repeat Booking" button
    │   (only visible for Completed/Closed/Trip Created)
    ├── Navigates to /passenger/book with route+passengers pre-filled
    └── Same submission flow as new booking

Trip Group (saved passenger list)
    │
    ├── Stored in Trip Group doctype (Frappe)
    ├── Fields: group_name, owner_user, group_leader, passengers
    ├── Tracked: times_used, last_used_on
    └── Reused in create_booking via group= parameter
```

---

## 4. Driver Matching & Offer Flow

```
Driver opens Dashboard
    │
    ├── Toggle "Online" → subscribes to Firestore activeRides
    │
    ├── Frappe matching engine (ftms.matching):
    │   ├── driver_matched_bookings(latitude, longitude, vehicle_type)
    │   ├── Filters: radius (5km default), vehicle type, capacity
    │   ├── Ranks: distance ascending, fare descending
    │   └── Schedule check: active ride lock, max 3 scheduled
    │
    ├── Driver sees Nearby Rides
    │   ├── "Make Offer" → enters fare, vehicle, seat capacity
    │   │   └── rideProvider.makeOffer() → Firestore activeOffers
    │   │
    │   └── "Accept" (direct booking)
    │       └── acceptBookingAsCaptain → Frappe accept_booking_as_captain
    │
    └── Passenger sees Offers
        ├── bookingMatchedOffers → pending offers sorted by fare asc
        ├── "Accept Offer" → accept_offer
        └── Atomic: SELECT FOR UPDATE → Trip created → competing offers rejected
```

### Driver Schedule Limits
| Rule | Enforcement |
|---|---|
| Active immediate ride | Blocks browsing/offering on other rides |
| Max 3 scheduled rides | `check_schedule_availability()` rejects 4th |
| Date overlap | Rejects same-date bookings |
| Cancel penalty | Processed before marketplace eligibility restored |

### Atomic Acceptance
```
accept_offer / accept_booking_as_captain
    │
    ├── 1. SELECT ... FOR UPDATE (row-level lock)
    ├── 2. Verify negotiation_status = "Awaiting Offers"
    ├── 3. check_schedule_availability()
    ├── 4. Create Trip + Partnership via _accept_offer_for_booking
    ├── 5. Reject all competing pending offers
    ├── 6. Emit events (Offer Accepted, Trip Assigned)
    └── 7. COMMIT
```

---

## 5. Ride Lifecycle

```
Draft
  │
  ├── Driver accepts → Trip Created, booking Confirmed
  │
  ├── Passenger "Start Ride" → booking Checked In
  │
  ├── Trip departs → booking Boarded
  │
  ├── Trip arrives → booking Closed? 
  │
  └── Trip completes → booking Closed, settlement Approved
```

### Start/Complete Flow
- **Passenger**: Booking Detail → "Start Ride" button (owner only)
  - Calls `start_booking(booking_name)` → Frappe sets booking checked-in
- **Driver**: Active Trip → "Complete Trip" button
  - Calls `complete_booking(booking_name)` → Frappe `complete_assigned_trip`
  - Transitions trip: Draft→Scheduled→Departed→Arrived→Completed

---

## 6. Payment Flow

See [MOYASSER_PAYMENT.md](./MOYASSER_PAYMENT.md) for full details.

```
Wallet Screen → "Top Up"
    │
    ├── Select "Moyasser" → enter amount → Proceed
    ├── POST create_moyasser_payment → Frappe calls Moyasser API
    ├── Redirect to Moyasser checkout page
    ├── User pays (Card / Mada / Apple Pay)
    ├── Moyasser sends webhook → Frappe verifies → credits wallet
    └── Transaction appears in wallet history

Admin Test Credit:
    └── "Test Credit (Admin only)" → instantly credits via test_credit_wallet
```

---

## 7. Data Model

### Trip Booking
| Field | Description |
|---|---|
| `main_rider_user` | Owner reference (isolation key) |
| `booking_group_code` | Group identifier for sharing |
| `negotiation_status` | Awaiting Offers → Trip Created |
| `booking_status` | Draft → Confirmed → Checked In → Boarded → Closed |
| `passengers` | Child table (Trip Passenger) |
| `passenger_count`, `seat_count` | Capacity tracking |

### Trip Group (Saved passenger lists)
| Field | Description |
|---|---|
| `group_name` | Display name |
| `owner_user` | Owner (isolation key) |
| `group_leader_name/mobile` | Leader info |
| `passengers` | Child table (Trip Group Passenger) |
| `times_used`, `last_used_on` | Reuse tracking |

### States
```
Trip Status:     Draft → Scheduled → Departed → Arrived → Completed
Booking Status:  Draft → Confirmed → Checked In → Boarded → Closed
Both:            Cancelled (terminal)
```

---

## 8. Deploy Sequence

```bash
# Backend (VPS)
ssh dg@168.231.78.48
cd /home/dg/dev-b/apps/ftms
git pull --ff-only upstream master
bench --site ftms.galaxylabs.online migrate
bench clear-cache
bench restart

# Flutter Web
cd E:\Projects\ftms-platform\rideksa
flutter build web --release
npx firebase deploy --only hosting --project rideksa-84949

# Flutter APK
flutter build apk --release
gh release create "v0.0.16+19" build/app/outputs/flutter-apk/app-release.apk
```

---

## 9. Key Files Index

### Backend (`ftms/`)
| File | Purpose |
|---|---|
| `api/auth.py` | Firebase token bridge, phone+password login |
| `api/booking.py` | Booking CRUD, group invite, offer acceptance, start/complete |
| `api/payment.py` | Payment webhook, Moyasser endpoints, wallet |
| `api/group.py` | Trip Group CRUD, reuse in bookings |
| `api/ride.py` | Trip/booking state transitions |
| `matching.py` | Driver-booking matching engine, schedule limits |
| `payments/moyaser.py` | Moyasser API client |
| `tenant.py` | Company/user access checks |

### Flutter (`rideksa/`)
| File | Purpose |
|---|---|
| `lib/services/auth_service.dart` | Firebase + Frappe auth bridge |
| `lib/services/frappe_api_client.dart` | All Frappe REST API calls |
| `lib/services/sync_service.dart` | Firestore ↔ Frappe sync |
| `lib/screens/auth/login_screen.dart` | Email/phone login, signup |
| `lib/screens/passenger/book_ride_screen.dart` | Booking creation with group reuse |
| `lib/screens/passenger/booking_detail_screen.dart` | Booking view, start, cancel, repeat |
| `lib/screens/passenger/wallet_screen.dart` | Wallet + Moyasser payment |
| `lib/screens/driver/dashboard_screen.dart` | Driver online/offline, nearby rides |
| `lib/providers/ride_provider.dart` | Firestore ride marketplace |
| `lib/providers/driver_provider.dart` | Driver matching subscription |

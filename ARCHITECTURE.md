# RideKSA — Flutter App Architecture

## Overview
RideKSA is a ride-hailing and fleet management mobile app designed for the Saudi market. It syncs with the Frappe FTMS backend for permanent records while using Firebase/Firestore for real-time active ride data, GPS-based nearby ride discovery, and offline capability.

## Architecture: Hybrid Sync Model

```
┌────────────────────────────────────────────────────┐
│                   RideKSA App                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │ Firebase  │  │ Firestore│  │  Local SQLite    │  │
│  │   Auth    │  │ (Active) │  │  (Offline Cache) │  │
│  └────┬─────┘  └────┬─────┘  └────────┬─────────┘  │
│       │             │                  │            │
│  ┌────┴─────────────┴──────────────────┴─────────┐  │
│  │          Sync Engine (Background)             │  │
│  │  Active Rides ←→ Firestore                    │  │
│  │  History ←→ Frappe REST API                   │  │
│  └───────────────────────────────────────────────┘  │
└──────────────────────┬─────────────────────────────┘
                       │ HTTPS (REST API)
┌──────────────────────┴─────────────────────────────┐
│              Frappe FTMS Backend                     │
│  Trip Booking → Trip → Invoice → Wallet → Reports   │
└────────────────────────────────────────────────────┘
```

## Data Flow

### Active Ride Booking Flow
1. **Passenger** opens app → GPS gets current location
2. App queries **Firestore** `active_rides` for nearby rides (GeoQuery)
3. Passenger selects ride → creates booking in **Frappe** via API
4. Booking synced to **Firestore** `active_rides` as real-time doc
5. **Drivers** near pickup point get push notification
6. Driver makes offer → stored in **Firestore** `active_offers`
7. Passenger accepts offer → **Frappe** creates Trip record
8. Trip status streamed via **Firestore** real-time listener
9. On completion → Trip archived in **Frappe**, removed from Firestore

### Wallet/Funds Flow
1. Passenger/Driver tops up wallet via **online payment gateway**
2. Transaction recorded in **Firestore** + **Frappe**
3. On ride completion, **5% commission** deducted to platform
4. Driver receives 95% of fare to wallet
5. Company admin views wallet reports via **Frappe**

## Firestore Collections

| Collection | Purpose | Real-time? | Expiry |
|-----------|---------|-----------|--------|
| `users/` | App users (Firebase UID + Frappe link) | No | Permanent |
| `drivers/` | Driver profiles + last GPS location | Yes | Permanent |
| `active_rides/` | Current ride requests (open for offers) | Yes | 24h TTL |
| `active_offers/` | Driver offers on active rides | Yes | Until accepted |
| `active_trips/` | In-progress trips (GPS tracking) | Yes | Until completed |
| `companies/` | Company profiles (cached from Frappe) | No | Weekly cache |
| `routes/` | Common routes (cached from Frappe) | No | Weekly cache |

## User Roles & Permissions

| Role | Access |
|------|--------|
| **Super Admin** | All companies, platform settings, subscription plans, global reports |
| **Company Admin** | Own company, manage drivers/vehicles, commission settings, reports |
| **Driver/Captain** | View nearby rides, make offers, start/complete trips, view earnings |
| **Passenger/Rider** | Book rides, track trips, wallet, ride history |

## Commission Model
- **Fixed 5%** on every completed trip transaction
- No cap — applies to all fares regardless of amount
- Split: 95% to driver, 5% to platform (company admin)
- Tracked per trip in Frappe + Firestore commission records

## Subscription Model
- **Company Admin** subscribes to platform (monthly/annual)
- Plans: Basic, Professional, Enterprise
- Features gated by subscription tier (max drivers, vehicles, reports)

## Core Technologies

| Technology | Purpose |
|-----------|---------|
| Flutter 3.x | Cross-platform UI |
| Firebase Auth | Phone OTP authentication |
| Cloud Firestore | Real-time active data |
| Firebase Cloud Messaging | Push notifications |
| Frappe REST API | Permanent records, reports |
| Google Maps / Apple Maps | Map rendering + geocoding |
| GeoFlutterFire | Geo-queries for nearby rides |
| Provider | State management |
| GoRouter | Declarative routing |
| Hive | Local offline cache |
| Flutter Secure Storage | Secure token storage |

## Project Structure

```
rideksa/
├── lib/
│   ├── main.dart
│   ├── core/               # Constants, theme, routes, errors
│   ├── models/             # Data models (DTOs)
│   ├── services/           # Business logic layer
│   ├── providers/          # State management
│   ├── screens/auth/       # Login, OTP, role select
│   ├── screens/passenger/  # Passenger screens
│   ├── screens/driver/     # Driver screens
│   ├── screens/admin/      # Company admin screens
│   ├── screens/super_admin/# Super admin screens
│   └── widgets/            # Shared widgets
├── firebase/               # Firebase config files
└── test/                   # Unit & widget tests
```

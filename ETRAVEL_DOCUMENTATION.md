# 📘 E-Travel — Dokumentasi Lengkap Aplikasi

> **Versi Dokumen**: 1.0  
> **Platform**: Flutter (Dart ^3.9.2)  
> **Package Name**: `com.etravel.e_travel`  
> **Firebase Project**: `etravel-en`  
> **Lokasi File Dokumentasi**: `d:\Downloads\TRAVELLL\ETRAVEL_DOCUMENTATION.md`

---

## Daftar Isi

1. [Ringkasan Proyek](#1-ringkasan-proyek)
2. [Technology Stack](#2-technology-stack)
3. [Arsitektur Aplikasi](#3-arsitektur-aplikasi)
4. [Struktur Folder](#4-struktur-folder)
5. [Firestore Data Dictionary](#5-firestore-data-dictionary)
6. [Role-Based Access Control (RBAC)](#6-role-based-access-control-rbac)
7. [Alur Navigasi Lengkap](#7-alur-navigasi-lengkap)
8. [Fitur & Implementasi — Core Layer](#8-fitur--implementasi--core-layer)
   - 8.1 [Models](#81-models)
   - 8.2 [Services](#82-services)
   - 8.3 [Theme & Constants](#83-theme--constants)
   - 8.4 [Utils & Widgets](#84-utils--widgets)
9. [Fitur & Implementasi — Feature Layer](#9-fitur--implementasi--feature-layer)
   - 9.1 [Splash Screen](#91-splash-screen)
   - 9.2 [Authentication (Auth)](#92-authentication-auth)
   - 9.3 [Main Navigation](#93-main-navigation)
   - 9.4 [Home & Search](#94-home--search)
   - 9.5 [Search Result & Dijkstra](#95-search-result--dijkstra)
   - 9.6 [Select Fleet](#96-select-fleet)
   - 9.7 [Seat Selection](#97-seat-selection)
   - 9.8 [Checkout](#98-checkout)
   - 9.9 [Payment](#99-payment)
   - 9.10 [E-Ticket (Live)](#910-e-ticket-live)
   - 9.11 [Booking History](#911-booking-history)
   - 9.12 [Edit Profile](#912-edit-profile)
   - 9.13 [Promo](#913-promo)
   - 9.14 [Admin Features](#914-admin-features)
   - 9.15 [Super Admin Features](#915-super-admin-features)
10. [Shared Widgets](#10-shared-widgets)
11. [Algoritma Utama — Deep Dive](#11-algoritma-utama--deep-dive)
    - 11.1 [Dijkstra Shortest Path](#111-dijkstra-shortest-path)
    - 11.2 [Anti-Double-Booking Transaction](#112-anti-double-booking-transaction)
    - 11.3 [Timestamp Expiration (Anti-Ghost-Seat)](#113-timestamp-expiration-anti-ghost-seat)
    - 11.4 [Seat State Derivation Algorithm](#114-seat-state-derivation-algorithm)
    - 11.5 [Dynamic Seat Grid Generation](#115-dynamic-seat-grid-generation)
    - 11.6 [QR Ticket Scanning & Validation](#116-qr-ticket-scanning--validation)
    - 11.7 [PDF Ticket Generation](#117-pdf-ticket-generation)
12. [Design Patterns & Teknik Khusus](#12-design-patterns--teknik-khusus)
13. [Statistik Kode](#13-statistik-kode)

---

## 1. Ringkasan Proyek

**E-Travel** adalah aplikasi pemesanan tiket bus/minibus antar-kota di Indonesia berbasis Flutter + Firebase. Aplikasi mendukung **3 role pengguna** (User, Admin/Sopir, Super Admin) dengan fitur lengkap mulai dari pencarian rute menggunakan **algoritma Dijkstra**, pemilihan kursi secara **real-time**, sistem **anti-double-booking** berbasis **Firestore Transaction**, hingga **e-ticket QR code** yang bisa di-scan langsung oleh sopir.

### Fitur Utama

| Fitur | Deskripsi |
|-------|-----------|
| 🔍 Pencarian Rute Dijkstra | Menemukan rute termurah antar-kota menggunakan graf jalan Indonesia |
| 💺 Pemilihan Kursi Real-Time | Kursi dinamis berdasarkan `totalSeats`, update real-time via StreamBuilder |
| 🔒 Anti-Double-Booking | Firestore Transaction + single-doc lock pattern di `seat_locks` |
| ⏱️ 15-Menit Auto-Expiry | Booking pending otomatis dibatalkan setelah 15 menit |
| 🎫 E-Ticket QR Code | Tiket digital dengan QR code yang bisa di-scan, download PDF, share |
| 📱 QR Scanner (Admin) | Sopir bisa scan QR tiket untuk validasi penumpang |
| 🗺️ Google Maps Route | Visualisasi rute di peta dengan marker dan polyline |
| 🎁 Promo Code System | Diskon persentase atau fixed amount dengan kode promo |
| 👥 Multi-Role Access | User, Admin/Sopir, Super Admin dengan UI dan akses berbeda |
| ☁️ Cloudinary Image Upload | Upload foto profil dan foto armada ke Cloudinary |

---

## 2. Technology Stack

### Dependencies (dari `pubspec.yaml`)

| Kategori | Package | Versi | Fungsi |
|----------|---------|-------|--------|
| **Firebase** | `firebase_core` | ^3.13.0 | Inisialisasi Firebase |
| | `firebase_auth` | ^5.5.1 | Autentikasi email/password + Google |
| | `cloud_firestore` | ^5.6.5 | Database real-time NoSQL |
| **Auth** | `google_sign_in` | ^6.2.2 | Login via Google Account |
| **Maps** | `google_maps_flutter` | ^2.14.2 | Tampilan peta rute |
| **PDF** | `pdf` | ^3.11.2 | Generate dokumen PDF tiket |
| | `printing` | ^5.13.4 | Print preview & print |
| | `share_plus` | ^10.1.4 | Share file PDF ke app lain |
| **QR** | `qr_flutter` | ^4.1.0 | Generate QR code widget |
| | `mobile_scanner` | ^6.0.2 | Kamera scanner QR code |
| **UI** | `flutter_animate` | latest | Animasi deklaratif (fade, slide, scale) |
| | `google_fonts` | latest | Font Poppins & Inter |
| | `shimmer` | latest | Skeleton loading effect |
| | `iconsax` | latest | Icon pack modern |
| | `smooth_page_indicator` | latest | Dot indicator untuk slider |
| **Image** | `image_picker` | ^1.2.1 | Pilih foto dari galeri/kamera |
| | `http` | ^1.6.0 | HTTP POST ke Cloudinary API |
| **i18n** | `intl` | ^0.20.2 | Format tanggal, mata uang `id_ID` |
| **Storage** | `path_provider` | latest | Akses direktori device untuk save PDF |

---

## 3. Arsitektur Aplikasi

### Pola Arsitektur

```
Feature-Based Folder Structure + StatefulWidget + Firestore StreamBuilder
```

- **Tidak menggunakan** state management eksternal (Provider, Riverpod, Bloc)
- Semua halaman menggunakan `StatefulWidget` + `setState()`
- Data real-time via Firestore `StreamBuilder` (langsung ke collection/doc)
- Concurrency control via `FirebaseFirestore.runTransaction()`

### Layer Architecture

```
┌────────────────────────────────────────────┐
│              PRESENTATION LAYER            │
│  lib/features/*/presentation/*.dart        │
│  (StatefulWidget + StreamBuilder)          │
├────────────────────────────────────────────┤
│              SERVICE LAYER                 │
│  lib/core/services/*.dart                  │
│  (Static methods, Firestore transactions)  │
├────────────────────────────────────────────┤
│              MODEL LAYER                   │
│  lib/core/models/*.dart                    │
│  (Immutable data classes, enum)            │
├────────────────────────────────────────────┤
│              DATA LAYER                    │
│  lib/core/data/*.dart                      │
│  (Static graph data: nodes & edges)        │
├────────────────────────────────────────────┤
│              FIREBASE / FIRESTORE          │
│  Cloud Firestore, Firebase Auth            │
└────────────────────────────────────────────┘
```

---

## 4. Struktur Folder

```
lib/
├── main.dart                          # Entry point, Firebase init, locale id_ID
├── firebase_options.dart              # FlutterFire CLI generated config
│
├── core/                              # Shared logic, models, services
│   ├── constants/
│   │   └── app_constants.dart         # App name, tagline, city list, durations
│   ├── data/
│   │   ├── indonesia_regions.dart     # ~514 CityNode (seluruh provinsi Indonesia)
│   │   └── indonesia_routes.dart      # ~450 RouteEdge (koridor jalan antar-kota)
│   ├── models/
│   │   ├── booking_model.dart         # BookingStatus enum, BookingModel class
│   │   └── route_model.dart           # CityNode, RouteEdge, RouteResult, SeatModel
│   ├── services/
│   │   ├── auth_service.dart          # Register, login, logout, role management
│   │   ├── booking_service.dart       # CREATE/CONFIRM/CANCEL booking + seat_locks
│   │   ├── firestore_dijkstra_service.dart  # Dijkstra algorithm (3 strategi)
│   │   ├── pdf_ticket_service.dart    # Generate, save, share, print PDF tiket
│   │   ├── ticket_scan_service.dart   # Scan & validate QR tiket
│   │   └── city_coordinates_seeder.dart # Seed koordinat kota ke Firestore
│   ├── theme/
│   │   ├── app_colors.dart            # Palet warna (primary #6C5CE7, dll)
│   │   ├── app_text_styles.dart       # Typography Poppins + Inter
│   │   └── app_theme.dart             # ThemeData dark theme
│   ├── utils/
│   │   ├── formatters.dart            # Format currency, distance, date, duration
│   │   ├── logout_dialog.dart         # Dialog konfirmasi logout + Firebase signOut
│   │   └── responsive.dart            # Responsive breakpoints & adaptive values
│   └── widgets/
│       ├── custom_route_map.dart      # Google Maps widget + marker + polyline
│       ├── empty_state_widget.dart    # Widget empty state reusable
│       └── firestore_stream_builder.dart # Generic StreamBuilder wrapper
│
├── features/                          # Feature modules
│   ├── auth/
│   │   └── presentation/
│   │       ├── login_page.dart        # Login email + Google Sign-In
│   │       ├── register_page.dart     # Form registrasi + validasi
│   │       ├── forgot_password_page.dart # Reset password via email
│   │       └── widgets/
│   │           └── auth_widgets.dart  # AuthTextField, AuthPrimaryButton, dll
│   ├── splash/
│   │   └── presentation/
│   │       └── splash_screen.dart     # Animated splash + auth check
│   ├── navigation/
│   │   └── presentation/
│   │       └── main_navigation_screen.dart # Role-based nav (User/Admin/SuperAdmin)
│   ├── home/
│   │   └── presentation/
│   │       ├── home_search_page.dart  # Form search kota + tanggal + passenger
│   │       └── popular_routes_page.dart # Daftar rute populer dari Firestore
│   ├── search_result/
│   │   └── presentation/
│   │       └── search_result_page.dart # Hasil Dijkstra + Google Maps route
│   ├── select_fleet/
│   │   └── presentation/
│   │       └── select_fleet_page.dart # Pilih armada dari daftar fleet
│   ├── seat_selection/
│   │   └── presentation/
│   │       └── seat_selection_page.dart # Pilih kursi real-time + grid dinamis
│   ├── checkout/
│   │   └── presentation/
│   │       └── checkout_page.dart     # Review booking + promo code + create booking
│   ├── payment/
│   │   └── presentation/
│   │       └── payment_page.dart      # Gateway pembayaran simulasi + countdown
│   ├── e_ticket/
│   │   └── presentation/
│   │       └── live_e_ticket_page.dart # E-ticket QR real-time + PDF actions
│   ├── booking_history/
│   │   └── presentation/
│   │       └── booking_history_page.dart # Riwayat pesanan + cancel + navigasi
│   ├── edit_profile/
│   │   └── presentation/
│   │       └── edit_profile_page.dart # Edit profil + upload foto Cloudinary
│   ├── promo/
│   │   └── presentation/
│   │       └── promo_list_page.dart   # Daftar promo aktif + copy code
│   ├── admin/
│   │   └── presentation/
│   │       ├── admin_dashboard_page.dart      # Legacy admin dashboard
│   │       ├── driver_dashboard_page.dart     # Dashboard sopir + assigned fleet
│   │       ├── ticket_scanner_page.dart       # Scanner QR tiket
│   │       ├── qr_scanner_page.dart           # Full-screen QR camera + overlay
│   │       ├── trip_manifest_page.dart        # Detail manifest perjalanan
│   │       └── live_trip_manifest_page.dart   # Manifest real-time + seat layout
│   └── super_admin/
│       └── presentation/
│           ├── super_admin_dashboard.dart      # Dashboard stats + menu grid
│           ├── super_admin_drawer.dart         # Navigation drawer 7 menu
│           ├── manage_fleet_page.dart          # CRUD armada + Cloudinary
│           ├── manage_routes_page.dart         # CRUD rute + seed Trans-Sumatera
│           ├── manage_dijkstra_routes_page.dart # Manage graph nodes & edges
│           ├── manage_driver_assignments_page.dart # Assign sopir ke armada
│           ├── manage_promo_page.dart          # CRUD kode promo
│           ├── manage_users_page.dart          # Manage user roles + suspend
│           ├── transaction_report_page.dart    # Laporan transaksi + filter
│           └── widgets/
│               ├── menu_card_widget.dart       # Menu card component
│               └── stat_card_widget.dart       # Stat card component
│
└── shared/
    └── widgets/
        └── common_widgets.dart        # GlassCard, GradientButton, ShimmerBorderCard
```

---

## 5. Firestore Data Dictionary

### Collection: `users/{uid}`

| Field | Type | Deskripsi |
|-------|------|-----------|
| `uid` | String | Firebase Auth UID |
| `email` | String | Email pengguna |
| `namaLengkap` | String | Nama lengkap |
| `nomorHp` | String | Nomor handphone |
| `role` | String | `'user'` \| `'admin'` \| `'super_admin'` |
| `isSuspended` | bool | Flag akun di-suspend |
| `assignedFleetId` | String? | Fleet ID untuk admin/sopir |
| `photoUrl` | String? | URL foto profil (Cloudinary) |
| `createdAt` | Timestamp | Tanggal registrasi |

### Collection: `fleets/{fleetId}`

| Field | Type | Deskripsi |
|-------|------|-----------|
| `name` | String | Nama armada/perusahaan |
| `imageUrl` | String | URL foto kendaraan (Cloudinary) |
| `totalSeats` | int | Total kapasitas kursi |
| `availableSeats` | int | Sisa kursi tersedia |
| `description` | String | Deskripsi armada |
| `driverId` | String? | UID sopir yang di-assign |
| `driverName` | String? | Nama sopir yang di-assign |
| `createdAt` | Timestamp | Tanggal dibuat |
| `updatedAt` | Timestamp | Tanggal terakhir diubah |

### Collection: `routes/{routeId}`

| Field | Type | Deskripsi |
|-------|------|-----------|
| `from` | String | Kota asal |
| `to` | String | Kota tujuan |
| `distance` | int | Jarak dalam km |
| `price` | int | Harga dalam Rp |
| `duration` | String | Durasi (format: `"5 jam 30 menit"`) |
| `fromLat` / `fromLng` | double? | Koordinat kota asal |
| `toLat` / `toLng` | double? | Koordinat kota tujuan |
| `createdAt` | Timestamp | Tanggal dibuat |

### Collection: `bookings/{bookingId}`

| Field | Type | Deskripsi |
|-------|------|-----------|
| `userId` | String | UID pembooking |
| `userName` | String | Nama pembooking |
| `fleetId` | String | Reference ke fleet doc |
| `fleetName` | String | Nama armada (denormalized) |
| `routeId` | String? | Reference ke route doc |
| `origin` | String | Kota asal |
| `destination` | String | Kota tujuan |
| `departureDate` | String | Tanggal keberangkatan (`"dd MMM yyyy"`) |
| `seatNumbers` | List\<int\> | Nomor kursi yang dipilih |
| `selectedSeatLabels` | List\<String\> | Label kursi (`["1", "2", "5"]`) |
| `seatsBooked` | int | Jumlah kursi dipesan |
| `totalPrice` | int | Total harga dalam Rp |
| `promoCode` | String? | Kode promo yang digunakan |
| `discountAmount` | int? | Jumlah diskon |
| `status` | String | `'pending'` \| `'paid'` \| `'used'` \| `'completed'` \| `'cancelled'` |
| `bookingCode` | String | Kode booking manusia (`TRV-XXX999`) |
| `expiryDate` | Timestamp | Waktu kedaluwarsa pending (now + 15 menit) |
| `createdAt` | Timestamp | Waktu pembuatan booking |
| `updatedAt` | Timestamp | Waktu perubahan terakhir |

### Collection: `seat_locks/{fleetId}_{date}` ⭐ (Single-Doc Lock Pattern)

```
seat_locks/
  └── {fleetId}_{departureDate}/
        ├── fleetId: "abc123"
        ├── departureDate: "01 Jan 2025"
        └── seats: {
              "1": {
                "bookingId": "booking_xyz",
                "userId": "user_abc",
                "status": "pending" | "paid",
                "expiryDate": Timestamp (only for pending)
              },
              "3": { ... },
              "5": { ... }
            }
```

**Alasan Single-Doc**: Satu dokumen per fleet+tanggal memungkinkan **seluruh kursi dibaca dan ditulis dalam satu Firestore Transaction**, menghilangkan race condition.

### Collection: `promo_codes/{promoId}`

| Field | Type | Deskripsi |
|-------|------|-----------|
| `code` | String | Kode promo (UPPERCASE) |
| `discountType` | String | `'percentage'` \| `'fixed'` |
| `discountValue` | int | Nilai diskon (% atau Rp) |
| `expiryDate` | Timestamp | Tanggal kedaluwarsa promo |
| `isActive` | bool | Status aktif/nonaktif |
| `createdAt` | Timestamp | Tanggal dibuat |

### Collection: `city_coordinates/{cityName}`

| Field | Type | Deskripsi |
|-------|------|-----------|
| `name` | String | Nama kota |
| `lat` | double | Latitude |
| `lng` | double | Longitude |

---

## 6. Role-Based Access Control (RBAC)

### Tiga Role Pengguna

| Role | Shell / Layout | Tab / Halaman |
|------|---------------|---------------|
| **`user`** | `_UserNavShell` (BottomNavigationBar, 4 tab) | Eksplor, Tiket Saya, Promo, Profil |
| **`admin`** | `_AdminNavShell` (BottomAppBar + center FAB) | Manifest, Profil, FAB → Scanner |
| **`super_admin`** | `SuperAdminDashboard` (Drawer navigation) | Dashboard, 7 halaman manajemen |

### Implementasi di `MainNavigationScreen`

```dart
StreamBuilder on users/{uid}
  → if isSuspended  → _SuspendedScreen (akun diblokir)
  → if role == 'user'        → _UserNavShell
  → if role == 'admin'       → _AdminNavShell
  → if role == 'super_admin' → SuperAdminDashboard
  → if loading → _LoadingSplash
  → if error  → _ErrorScreen
```

### Detail Tab per Role

**User (4 Tab):**

| Index | Label | Icon | Halaman |
|-------|-------|------|---------|
| 0 | Eksplor | `Iconsax.discover` | `HomeSearchPage` |
| 1 | Tiket Saya | `Iconsax.ticket` | `BookingHistoryPage` |
| 2 | Promo | `Iconsax.discount_shape` | `PromoListPage` |
| 3 | Profil | `Iconsax.user` | `EditProfilePage` |

**Admin (2 Tab + FAB):**

| Index | Label | Icon | Halaman |
|-------|-------|------|---------|
| 0 | Manifest | `Iconsax.document_text` | `DriverDashboardPage` |
| FAB | Scan | `Iconsax.scan` | `TicketScannerPage` |
| 1 | Profil | `Iconsax.user` | `EditProfilePage` |

**Super Admin (Drawer Menu):**

| Menu | Icon | Halaman |
|------|------|---------|
| Dashboard | `Iconsax.chart_square` | `SuperAdminDashboard` |
| Kelola Rute | `Iconsax.routing` | `ManageRoutesPage` |
| Kelola Dijkstra | `Iconsax.map` | `ManageDijkstraRoutesPage` |
| Kelola Armada | `Iconsax.bus` | `ManageFleetPage` |
| Penugasan Sopir | `Iconsax.people` | `ManageDriverAssignmentsPage` |
| Kelola Promo | `Iconsax.discount_shape` | `ManagePromoPage` |
| Kelola Pengguna | `Iconsax.user_search` | `ManageUsersPage` |
| Laporan Transaksi | `Iconsax.receipt` | `TransactionReportPage` |
| Pengaturan | `Iconsax.setting` | `EditProfilePage` |

---

## 7. Alur Navigasi Lengkap

### User Journey (Alur Pemesanan Tiket)

```
SplashScreen
  │
  ├─ [belum login] → LoginPage ↔ RegisterPage / ForgotPasswordPage
  │
  └─ [sudah login] → MainNavigationScreen
                        │
                        ├── Tab "Eksplor" → HomeSearchPage
                        │     │  (pilih kota asal, tujuan, tanggal, jumlah penumpang)
                        │     │
                        │     └── [Cari] → SearchResultPage
                        │           │  (Dijkstra algorithm → rute termurah)
                        │           │  (Google Maps route visualization)
                        │           │
                        │           └── [Pilih Armada] → SelectFleetPage
                        │                 │  (StreamBuilder on fleets collection)
                        │                 │
                        │                 └── [Pilih] → SeatSelectionPage
                        │                       │  (grid kursi dinamis, real-time status)
                        │                       │  (StreamBuilder on bookings collection)
                        │                       │
                        │                       └── [Lanjut] → CheckoutPage
                        │                             │  (review detail + promo code)
                        │                             │  (BookingService.createBooking → Firestore Transaction)
                        │                             │
                        │                             └── [Bayar] → PaymentPage
                        │                                   │  (pilih metode: VA/E-Wallet/QRIS)
                        │                                   │  (countdown 15 menit dari expiryDate)
                        │                                   │
                        │                                   └── [Bayar Berhasil] → LiveETicketPage
                        │                                         │  (QR code + PDF download/share/print)
                        │                                         │  (real-time status update saat sopir scan)
                        │                                         │
                        │                                         └── [Kembali ke Beranda]
                        │                                               → MainNavigationScreen (clear stack)
                        │
                        ├── Tab "Tiket Saya" → BookingHistoryPage
                        │     │  (daftar pesanan + status badge)
                        │     ├── [tap paid/used/completed] → LiveETicketPage
                        │     └── [cancel pending] → BookingService.cancelBooking()
                        │
                        ├── Tab "Promo" → PromoListPage  
                        │     └── [tap kode] → copy to clipboard
                        │
                        └── Tab "Profil" → EditProfilePage
                              └── (edit nama, HP, foto + Cloudinary upload)
```

### Admin Journey

```
MainNavigationScreen → _AdminNavShell
  │
  ├── Tab "Manifest" → DriverDashboardPage
  │     │  (StreamBuilder: fleets where driverId==uid → bookings)
  │     │  (stats: total tiket, verified, pending)
  │     │
  │     └── [tap tanggal perjalanan] → LiveTripManifestPage
  │           │  (real-time seat layout + passenger list)
  │           └── (badges update saat tiket di-scan)
  │
  ├── FAB → TicketScannerPage
  │     │  (input kode manual atau scan QR)
  │     └── [scan QR] → QrScannerPage
  │           └── (MobileScanner + overlay + validate → update booking)
  │
  └── Tab "Profil" → EditProfilePage
```

### Super Admin Journey

```
MainNavigationScreen → SuperAdminDashboard
  │
  ├── Stats Row: Revenue, Tiket, Armada, Rute (real-time via nested StreamBuilder)
  │
  ├── [Kelola Rute] → ManageRoutesPage
  │     └── CRUD routes + seed 62 rute Trans-Sumatera
  │
  ├── [Kelola Dijkstra] → ManageDijkstraRoutesPage
  │     └── 2 tab: Master Kota (Node) + Jalur & Harga (Edge)
  │
  ├── [Kelola Armada] → ManageFleetPage
  │     └── CRUD fleets + Cloudinary image + seed 22 perusahaan
  │
  ├── [Penugasan Sopir] → ManageDriverAssignmentsPage
  │     └── Assign admin role users ke fleet tertentu
  │
  ├── [Kelola Promo] → ManagePromoPage
  │     └── CRUD promo code (percentage/fixed)
  │
  ├── [Kelola Pengguna] → ManageUsersPage
  │     └── Change role + toggle suspend
  │
  └── [Laporan Transaksi] → TransactionReportPage
        └── Filter by status + summary total
```

---

## 8. Fitur & Implementasi — Core Layer

### 8.1 Models

#### `BookingStatus` Enum

**File**: `lib/core/models/booking_model.dart`

```dart
enum BookingStatus {
  pending,     // Menunggu pembayaran (15 menit)
  paid,        // Sudah dibayar
  used,        // Tiket sudah di-scan sopir
  completed,   // Legacy — backward compat
  cancelled;   // Dibatalkan (manual atau auto-expiry)
}
```

**Method penting:**
- `value` → String mapping ke Firestore
- `isValidated` → `true` jika `used` atau `completed` (tiket sudah di-scan)
- `fromString(s)` → Factory dari Firestore string

#### `BookingModel` Class

**Immutable data class** dengan field lengkap termasuk:
- `expiryDate` (DateTime?) — Timestamp kedaluwarsa untuk pending booking
- `selectedSeatLabels` (List\<String\>) — Label kursi yang dipilih (["1", "3", "5"])
- `promoCode` & `discountAmount` — Informasi diskon

**Method:**
- `fromFirestore(DocumentSnapshot)` — Parse dari Firestore document
- `toMap()` — Konversi ke Map untuk Firestore write
- `copyWith(...)` — Immutable update pattern

#### `CityNode` & `RouteEdge` (Route Model)

**File**: `lib/core/models/route_model.dart`

```dart
class CityNode {
  final String name;        // "Jakarta"
  final double lat, lng;    // Koordinat
  final String province;    // "DKI Jakarta"
  final RegionType type;    // kota / kabupaten
}

class RouteEdge {
  final String from, to;    // Pasangan kota
  final double distance;    // km
  final int price;          // Rp
  final String duration;    // "5 jam 30 menit"
}

class RouteResult {
  final List<String> path;           // ["Padang", "Bukittinggi", "Medan"]
  final double totalDistance;
  final int totalPrice;
  final int totalDuration;
  final bool isDirect;
}
```

### 8.2 Services

#### `AuthService` — Autentikasi & User Management

**File**: `lib/core/services/auth_service.dart` (~190 baris)  
**Pattern**: Static methods

| Method | Fungsi |
|--------|--------|
| `register(email, password, nama, nomorHp)` | Buat akun Firebase Auth + doc `users/{uid}` dengan `role: 'user'` |
| `login(email, password)` | Login → return `{role, isSuspended}` |
| `logout()` | Sign out Firebase Auth |
| `updateUserRole(uid, newRole)` | Super Admin ubah role user |
| `toggleSuspend(uid, isSuspended)` | Super Admin suspend/unsuspend user |
| `updateProfile(uid, {nama, nomorHp, photoUrl})` | Update profil user |
| `fetchCurrentUserProfile()` | Ambil data profil user yang login |
| `fetchAllUsers()` | Ambil semua user (untuk Super Admin) |
| `usersStream()` | Real-time stream semua user |

#### `BookingService` — Inti Pemesanan ⭐

**File**: `lib/core/services/booking_service.dart` (501 baris)  
**Pattern**: Static methods + Firestore Transaction  
**Arsitektur**: "Timestamp Expiration" Anti-Ghost-Seat

```
┌─────────────────────────────────────────────────────┐
│  seat_locks/{fleetId}_{date}                        │
│  ├─ seats: { "1": {bookingId, status, expiryDate} } │
│  └─ Single-doc lock → 100% atomic transaction       │
├─────────────────────────────────────────────────────┤
│  bookings/{bookingId}                               │
│  ├─ selectedSeatLabels, status, expiryDate          │
│  └─ StreamBuilder source for real-time seat UI      │
└─────────────────────────────────────────────────────┘
```

**Metode Utama:**

| Method | Deskripsi |
|--------|-----------|
| `createBooking(BookingModel)` | **8-step Firestore Transaction**: read seat_locks → read fleet → check conflicts (userId-aware) → check availability → generate code → update locks → create booking → deduct seats |
| `confirmPayment(bookingId)` | Transaction: booking `pending→paid` + seat_locks entries `pending→paid` (hapus expiryDate) |
| `cancelBooking(bookingId)` | Transaction: booking→cancelled + hapus dari seat_locks + restore availableSeats |
| `cleanupExpiredBookings({fleetId, date})` | Client-side GC: query expired pending → cancelBooking satu per satu |
| `userBookingsStream(userId)` | Stream booking user, ordered by createdAt desc |
| `fleetBookingsStream(fleetId)` | Stream booking fleet (paid/used/completed only) |
| `allFleetBookingsStream(fleetId)` | Stream semua booking fleet (semua status) |
| `bookingStream(bookingId)` | Stream single booking doc (untuk e-ticket/payment) |
| `bookSeat(fleetId, seats)` | **Legacy** — simple seat deduction |
| `releaseSeat(fleetId, seats)` | **Legacy** — simple seat release |

**Custom Exceptions:**
- `SeatAlreadyBookedException(conflictedSeats)` — Kursi sudah dipesan orang lain
- `InsufficientSeatsException(requested, available)` — Kursi tidak cukup
- `FleetNotFoundException(fleetId)` — Armada tidak ditemukan

#### `FirestoreDijkstraService` — Algoritma Pencarian Rute ⭐

**File**: `lib/core/services/firestore_dijkstra_service.dart` (233 baris)  
**Pattern**: Singleton (`FirestoreDijkstraService.instance`)

| Method | Strategi | Weight Function |
|--------|----------|-----------------|
| `findCheapestPath(start, end)` | Termurah (harga) | `e.price.toDouble()` |
| `findShortestPath(start, end)` | Terpendek (jarak) | `e.distance` |
| `findFastestPath(start, end)` | Tercepat (durasi) | `e.durationMinutes.toDouble()` |
| `getAllCities()` | Ambil semua kota unik dari routes | — |

**Return**: `DijkstraResult` dengan `path`, `totalDistance`, `totalPrice`, `totalDurationMinutes`

#### `PdfTicketService` — Generasi PDF Tiket

**File**: `lib/core/services/pdf_ticket_service.dart` (497 baris)  
**Pattern**: Static methods

**Layout PDF A4:**
```
┌────────────────────────────────┐
│   ● E-TRAVEL (branded header)  │
│   Tiket Elektronik             │
├────────────────────────────────┤
│   Kota Asal → Kota Tujuan     │
│   Tanggal · Kursi · Harga     │
│   Kode Booking: TRV-XXX999    │
├─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┤  (garis perforasi)
│          ┌─────────┐          │
│          │ QR CODE │          │
│          └─────────┘          │
│   Scan QR ini saat naik       │
└────────────────────────────────┘
```

**Font**: Inter (body) + JetBrains Mono (kode booking) — dari `PdfGoogleFonts`

| Method | Fungsi |
|--------|--------|
| `generateTicketPdf(BookingModel)` | Generate PDF `Uint8List` |
| `savePdf(BookingModel)` | Save ke `getApplicationDocumentsDirectory()` → return path |
| `sharePdf(BookingModel)` | Generate → temp file → `Share.shareXFiles()` |
| `printPdf(BookingModel)` | Generate → `Printing.layoutPdf()` → print dialog |

#### `TicketScanService` — Scan & Validasi Tiket

**File**: `lib/core/services/ticket_scan_service.dart` (~180 baris)

```dart
enum ScanError {
  notFound,     // Tiket tidak ditemukan
  alreadyUsed,  // Sudah pernah di-scan
  cancelled,    // Tiket dibatalkan
  unpaid,       // Belum dibayar
}
```

| Method | Fungsi |
|--------|--------|
| `scanTicketAndUpdateStatus(code)` | Lookup by bookingCode atau bookingId → validate → update `paid→completed` |
| `validateAllForFleet(fleetId)` | Batch validate semua tiket fleet |

#### `CityCoordinatesSeeder` — Seed Koordinat Kota

**File**: `lib/core/services/city_coordinates_seeder.dart` (~240 baris)

Static coordinate map untuk 60+ kota Sumatera. Digunakan untuk fetch `LatLng` saat menampilkan Google Maps route.

| Method | Fungsi |
|--------|--------|
| `seedCityCoordinates()` | Tulis koordinat ke `city_coordinates` collection |
| `updateRoutesWithCoordinates()` | Update `routes` docs dengan `fromLat/fromLng/toLat/toLng` |
| `fetchAllCoordinates()` | Ambil semua koordinat dari Firestore |

### 8.3 Theme & Constants

#### `AppColors` — Palet Warna

**File**: `lib/core/theme/app_colors.dart` (66 baris)

```dart
// Dark theme palette (registered in main.dart)
primary:    #6C5CE7   // Purple
secondary:  #00D2FF   // Cyan
background: #0F0F1A   // Dark navy
surface:    #1A1A2E   // Dark surface

// Seat colors (for dark theme)
seatAvailable: #2A2A3E
seatSelected:  #6C5CE7
seatOccupied:  #3A3A4E
```

> **Catatan**: Semua feature page secara independen menggunakan **"Trust Blue" palette**:
```
Trust Blue:  #0F4C81
Background:  #FAFBFD
Teal:        #0D9488
Success:     #059669
Warning:     #D97706
Error:       #DC2626
```

#### `AppTextStyles` — Typography

**File**: `lib/core/theme/app_text_styles.dart` (~95 baris)

- **Headings**: Google Fonts `Poppins` (bold, 24-32px)
- **Body**: Google Fonts `Inter` (regular/medium, 14-16px)
- **Labels**: Inter (medium, 12-14px)
- **Price**: Inter (bold, 18px)
- **Caption**: Inter (regular, 12px)
- **Button**: Inter (semiBold, 16px)

#### `AppConstants`

**File**: `lib/core/constants/app_constants.dart` (33 baris)

```dart
class AppConstants {
  static const appName = 'E-Travel';
  static const appTagline = 'Perjalanan Mudah, Pesan Cepat';
  
  // 10 kota populer
  static const popularCities = [
    'Jakarta', 'Bandung', 'Surabaya', 'Yogyakarta', 'Semarang',
    'Malang', 'Solo', 'Bali', 'Medan', 'Madiun'
  ];
  
  static const splashDuration = 3000; // ms
  static const defaultAnimDuration = Duration(milliseconds: 300);
  static const longAnimDuration = Duration(milliseconds: 600);
}
```

### 8.4 Utils & Widgets

#### `Formatters` — Format Data Indonesia

**File**: `lib/core/utils/formatters.dart` (~42 baris)

| Method | Input | Output |
|--------|-------|--------|
| `currency(int)` | `150000` | `Rp 150.000` |
| `distance(double)` | `123.5` | `123,5 km` |
| `duration(int)` | `330` (menit) | `5 jam 30 menit` |
| `date(DateTime)` | `DateTime` | `01 Januari 2025` |
| `time(DateTime)` | `DateTime` | `14:30` |
| `dateTime(DateTime)` | `DateTime` | `01 Jan 2025 14:30` |
| `dayName(DateTime)` | `DateTime` | `Senin` |

Semua menggunakan locale `id_ID` dari package `intl`.

#### `AuthUtils.showLogoutConfirmation()` — Dialog Logout

**File**: `lib/core/utils/logout_dialog.dart` (263 baris)

Animated dialog konfirmasi dengan:
- Icon animasi
- Teks "Yakin ingin keluar?"
- Button "Batal" dan "Keluar"
- Firebase `signOut()` → `pushAndRemoveUntil(LoginPage)`
- Context-safe (cek `mounted`)

#### `Responsive` — Responsive Breakpoints

**File**: `lib/core/utils/responsive.dart` (~47 baris)

```dart
isSmallScreen:  width < 360
isMediumScreen: 360 ≤ width < 414
isLargeScreen:  width ≥ 414
```

Menyediakan `adaptiveValue`, `adaptivePadding`, `adaptiveFontScale`.

#### `CustomRouteMap` — Google Maps Widget

**File**: `lib/core/widgets/custom_route_map.dart` (528 baris)

- Google Maps dengan **silver/retro style JSON**
- Marker: ● green (asal), ● red (tujuan), ● orange (transit)
- Polyline: Trust Blue (#0F4C81), width 4
- Auto-fit camera bounds untuk semua marker
- Loading overlay saat map belum ready

#### `EmptyStateWidget`

**File**: `lib/core/widgets/empty_state_widget.dart` (~120 baris)

Widget reusable untuk state kosong dengan icon, title, subtitle, dan optional action button. Menggunakan `flutter_animate` untuk animasi masuk.

#### `FirestoreListView<T>` & `FirestoreDocBuilder<T>`

**File**: `lib/core/widgets/firestore_stream_builder.dart` (259 baris)

Generic StreamBuilder wrapper dengan 4 state:
1. **Loading** — Spinner/shimmer
2. **Error** — Pesan error
3. **Empty** — `EmptyStateWidget`
4. **Data** — Builder callback

---

## 9. Fitur & Implementasi — Feature Layer

### 9.1 Splash Screen

**File**: `lib/features/splash/presentation/splash_screen.dart` (442 baris)

**Fitur:**
- **Bokeh particle animation** via `CustomPainter` — lingkaran acak dengan opacity bervariasi
- **Staggered content animations** — logo, nama app, tagline, dan spinner muncul berurutan
- **Auto-navigation** setelah 2 detik:
  - Cek `FirebaseAuth.instance.currentUser`
  - Jika login → `MainNavigationScreen`
  - Jika belum → `LoginPage`

**Implementasi Animasi:**
```
0.0s → Bokeh particles mulai float
0.3s → Logo fade + slideY
0.6s → App name fade + slideY
0.9s → Tagline fade + slideY
1.2s → Spinner appear
2.0s → Navigate (pageRouteBuilder with fade transition)
```

### 9.2 Authentication (Auth)

#### Login Page

**File**: `lib/features/auth/presentation/login_page.dart` (507 baris)

**Fitur:**
- Email/password login via `AuthService.login()`
- **Google Sign-In** flow:
  1. `GoogleSignIn().signIn()` → Google account picker
  2. `authentication.accessToken` + `idToken` → `GoogleAuthProvider.credential()`
  3. `FirebaseAuth.signInWithCredential(credential)`
  4. Cek apakah user doc sudah ada di Firestore
  5. Jika baru → buat doc `users/{uid}` dengan role `'user'`
- **Suspended account check** — jika `isSuspended == true` → tampilkan error
- Navigasi: semua role → `MainNavigationScreen`

#### Register Page

**File**: `lib/features/auth/presentation/register_page.dart` (483 baris)

**Fitur:**
- Form: nama lengkap, nomor HP, email, password, confirm password
- Terms & conditions checkbox (wajib dicentang)
- `AuthService.register()` → buat akun + doc Firestore
- **Auto-logout** setelah register (agar user login ulang secara eksplisit)
- Error messages dalam Bahasa Indonesia

#### Forgot Password Page

**File**: `lib/features/auth/presentation/forgot_password_page.dart` (387 baris)

**Fitur:**
- `FirebaseAuth.sendPasswordResetEmail(email)`
- Dua state UI: form input email ↔ konfirmasi terkirim
- Handle error: `user-not-found`, `invalid-email`, `too-many-requests`

#### Auth Widgets

**File**: `lib/features/auth/presentation/widgets/auth_widgets.dart` (490 baris)

| Widget | Deskripsi |
|--------|-----------|
| `AuthColors` | Palette Trust Blue khusus auth pages |
| `AuthScaffold` | Scaffold wrapper dengan gradient background |
| `AuthHeader` | Title + subtitle header |
| `AuthTextField` | Text field dengan outline, light fill, radius 12 |
| `AuthPrimaryButton` | Button solid navy, full-width, **press scale animation** (`GestureDetector` + `AnimatedScale` on tap) |
| `AuthSocialButton` | Button Google sign-in dengan icon |

### 9.3 Main Navigation

**File**: `lib/features/navigation/presentation/main_navigation_screen.dart` (907 baris)

**Class & Widget:**

| Class | Fungsi |
|-------|--------|
| `MainNavigationScreen` | Entry point — StreamBuilder on `users/{uid}` → route ke shell yang sesuai |
| `_UserNavShell` | BottomNavigationBar 4 tab, `IndexedStack` (cache semua tab) |
| `_AdminNavShell` | `BottomAppBar` dengan notch + center-docked FAB (scanner) |
| `_SuspendedScreen` | Full screen "Akun Ditangguhkan" + logout button |
| `_LoadingSplash` | Loading indicator saat fetch role |
| `_ErrorScreen` | Error screen dengan retry |

**`_UserNavShell` Detail:**
- `PopScope` dengan **double-tap-to-exit** confirmation (tap back 2x dalam 2 detik)
- `IndexedStack` → semua 4 tab pages tetap hidup di memory (tidak rebuild saat switch tab)

**`_AdminNavShell` Detail:**
- `BottomAppBar` dengan `shape: CircularNotchedRectangle()` untuk FAB notch
- Center FAB → `TicketScannerPage` (push, bukan tab switch)
- 2 tab: Manifest + Profil

### 9.4 Home & Search

#### HomeSearchPage

**File**: `lib/features/home/presentation/home_search_page.dart` (1600 baris)

**Fitur:**
- **City Picker**: Autocomplete dropdown dari `FirestoreDijkstraService.getAllCities()`
- **Swap Cities**: Animasi tukar kota asal ↔ tujuan
- **Date Picker**: Range 90 hari ke depan dari hari ini
- **Passenger Counter**: Increment/decrement jumlah penumpang (min 1, max 5)
- **Greeting**: Sapaan berdasarkan waktu → "Selamat Pagi/Siang/Sore/Malam"
- **Popular Routes**: Section menampilkan rute populer dari Firestore
- **Promo Banner**: Carousel banner promo aktif
- **Navigasi**: Tombol "Cari" → `SearchResultPage` dengan params (origin, destination, date, passengers)

#### PopularRoutesPage

**File**: `lib/features/home/presentation/popular_routes_page.dart` (396 baris)

- StreamBuilder on `routes` collection
- Menampilkan route cards: from → to, harga, durasi, jarak
- Live count badge di setiap card
- Di-akses dari "Lihat Semua" di home page

### 9.5 Search Result & Dijkstra

**File**: `lib/features/search_result/presentation/search_result_page.dart` (907 baris)

**Alur:**
1. Terima params: origin, destination, date, passengers
2. Jalankan `FirestoreDijkstraService.instance.findCheapestPath(origin, dest)`
3. Convert city names → `LatLng` via `CityCoordinatesSeeder.fetchAllCoordinates()`
4. Tampilkan `CustomRouteMap` dengan marker + polyline
5. Route summary card: jarak, durasi, harga
6. Tombol "Pilih Armada" → `SelectFleetPage`

**Fallback**: Jika Dijkstra gagal menemukan path → tampilkan error message

### 9.6 Select Fleet

**File**: `lib/features/select_fleet/presentation/select_fleet_page.dart` (695 baris)

**Fitur:**
- StreamBuilder on `fleets` collection, ordered by `name`
- Fleet card menampilkan: image, nama, sisa kursi, deskripsi
- Filter otomatis: armada yang sudah penuh (`availableSeats == 0`) → `EmptyStateWidget`
- Navigasi: tap fleet → `SeatSelectionPage` dengan params (fleetId, fleetName, totalSeats, departureDate, passengers, dll)

### 9.7 Seat Selection ⭐

**File**: `lib/features/seat_selection/presentation/seat_selection_page.dart` (1037 baris)

**Widget Utama**: `SeatSelectionPage` (StatefulWidget)

**Fitur Lengkap:**

1. **Dynamic Seat Grid** — Grid kursi di-generate secara dinamis dari `totalSeats` (tidak hardcode layout)
2. **Real-Time Status** — StreamBuilder on `bookings` collection (where fleetId + departureDate)
3. **4 State Kursi**: Available (hijau), Selected (biru), Pending (kuning), Sold (merah)
4. **userId-Aware** — Pending booking milik user sendiri di-skip (dianggap available)
5. **Client-Side GC** — `cleanupExpiredBookings()` dipanggil saat `initState()`
6. **Max Seat Enforcement** — Tidak bisa pilih lebih dari jumlah passenger
7. **Final Conflict Validation** — Sebelum navigasi ke checkout, cek ulang konflik

**Algoritma `_deriveSeatStates()`:**
```
Input:  List<BookingModel> (dari StreamBuilder)
Output: Map<String, SeatState>  — "1" → available/selected/pending/sold

Untuk setiap booking document:
  if status in [paid, used, completed]:
    → tandai semua selectedSeatLabels sebagai SOLD
  
  if status == pending AND expiryDate > now:
    if booking.userId == currentUser:
      → SKIP (booking sendiri, biarkan available)
    else:
      → tandai sebagai PENDING (dikunci user lain)
  
  if status == pending AND expiryDate <= now:
    → IGNORE (sudah expired, dianggap available)
  
  if status == cancelled:
    → IGNORE
```

**Algoritma `_generateGrid()`:**
```
Layout: 2 + aisle + 2 per baris
Kolom:  [Seat, Seat, null(aisle), Seat, Seat]

Contoh untuk totalSeats = 10:
  Row 1: [1]  [2]  [aisle]  [3]  [4]
  Row 2: [5]  [6]  [aisle]  [7]  [8]
  Row 3: [9]  [10] [aisle]  [—]  [—]
```

**`_goToCheckout()` — Final Validation:**
```dart
// Re-derive states saat tombol ditekan
final freshStates = _deriveSeatStates(latestBookings);
for (seat in selectedSeats) {
  if freshStates[seat] == sold || freshStates[seat] == pending:
    → tampilkan conflict dialog
    → auto-deselect conflicted seats
    → return (jangan navigasi)
}
// Jika semua clear → Navigator.push(CheckoutPage)
```

### 9.8 Checkout

**File**: `lib/features/checkout/presentation/checkout_page.dart` (1151 baris)

**Fitur:**

1. **Review Booking** — Tampilkan semua detail: rute, tanggal, armada, kursi, harga
2. **Promo Code System**:
   - Input kode promo → query `promo_codes` collection
   - Validasi: `isActive == true` AND `expiryDate > now` AND `code == input`
   - `discountType == 'percentage'` → harga × (discountValue / 100)
   - `discountType == 'fixed'` → harga − discountValue
   - Tampilkan original price + discount + final price
3. **Create Booking** — `BookingService.createBooking()`
   - Membuat `BookingModel` dengan `selectedSeatLabels`, `totalPrice`, `promoCode`
   - Atomic transaction di Firestore
   - **Handle `SeatAlreadyBookedException`** → dialog "Kursi X, Y sudah dipesan orang lain"
4. **Navigasi** → `PaymentPage` dengan `bookingId` dan `expiryDate`

### 9.9 Payment

**File**: `lib/features/payment/presentation/payment_page.dart` (1146 baris)

**Fitur:**

1. **Metode Pembayaran** (simulasi):
   - Virtual Account (VA) — nomor rekening virtual
   - E-Wallet — QR code / deep link
   - QRIS — QR code standar

2. **Countdown Timer** dari `expiryDate`:
   ```dart
   remaining = expiryDate.difference(DateTime.now())
   // BUKAN hardcode 15 menit, tapi dihitung dari expiryDate booking
   ```

3. **Auto-Cancel on Expiry**:
   ```dart
   if (remaining <= Duration.zero) {
     BookingService.cancelBooking(bookingId);
     // Tampilkan dialog "Waktu pembayaran habis"
     Navigator.pop();
   }
   ```

4. **Simulasi Pembayaran**:
   - Tombol "Simulasikan Pembayaran Berhasil"
   - `BookingService.confirmPayment(bookingId)` → booking `pending→paid`
   - Navigasi → `LiveETicketPage`

5. **PopScope canPop: false** — Back button → dialog konfirmasi → `cancelBooking()` jika keluar

### 9.10 E-Ticket (Live) ⭐

**File**: `lib/features/e_ticket/presentation/live_e_ticket_page.dart` (984 baris)

**Fitur:**

1. **Real-Time StreamBuilder** on `BookingService.bookingStream(bookingId)`
   - Status badge berubah real-time saat sopir scan QR
   - `paid` → menampilkan QR code aktif
   - `used/completed` → QR code di-overlay dengan stamp "TIKET TELAH DIGUNAKAN"
   - `cancelled` → tampilkan status dibatalkan

2. **QR Code** — Generated dari `bookingCode` (format `TRV-XXX999`)

3. **PDF Action Buttons** (`_PdfActionButtons`):
   | Tombol | Fungsi |
   |--------|--------|
   | 📥 Download | `PdfTicketService.savePdf()` → save ke device |
   | 📤 Share | `PdfTicketService.sharePdf()` → share via app lain |
   | 🖨️ Print | `PdfTicketService.printPdf()` → print dialog |

4. **Detail Tiket** — Rute, tanggal, armada, kursi, harga, kode booking

5. **Tombol "Kembali ke Beranda"**:
   ```dart
   Navigator.pushAndRemoveUntil(
     MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
     (route) => false,  // Hapus seluruh navigation stack
   );
   ```

### 9.11 Booking History

**File**: `lib/features/booking_history/presentation/booking_history_page.dart` (786 baris)

**Fitur:**
- StreamBuilder on `BookingService.userBookingsStream(uid)` → ordered by `createdAt desc`
- Setiap booking card menampilkan: rute, tanggal, harga, status badge berwarna
- **Tap actions**:
  - Booking `paid/used/completed` → navigasi ke `LiveETicketPage`
  - Booking `pending` → tampilkan tombol cancel
- **Cancel dialog** → konfirmasi → `BookingService.cancelBooking()`

**Status Badge Colors:**
| Status | Warna | Label |
|--------|-------|-------|
| pending | 🟡 Warning | Menunggu Pembayaran |
| paid | 🔵 Primary | Sudah Dibayar |
| used | 🟢 Success | Digunakan |
| completed | 🟢 Success | Selesai |
| cancelled | 🔴 Error | Dibatalkan |

### 9.12 Edit Profile

**File**: `lib/features/edit_profile/presentation/edit_profile_page.dart` (936 baris)

**Fitur:**

1. **Fetch Profile** — `AuthService.fetchCurrentUserProfile()` on init
2. **Conditional Back Button** — `Navigator.canPop()`:
   - Jika sebagai root tab (tab Profil) → TIDAK ada back button, title "Profil Saya"
   - Jika di-push (dari drawer) → ADA back button, title "Edit Profil"
3. **Form Fields**: Nama lengkap, Nomor HP, Email (read-only)
4. **Cloudinary Image Upload**:
   ```dart
   // 1. Pilih foto
   ImagePicker().pickImage(source: ImageSource.gallery)
   
   // 2. Upload ke Cloudinary
   POST https://api.cloudinary.com/v1_1/dr5lqvvhy/image/upload
   Body: {
     'upload_preset': 'etravel_preset',
     'file': base64 image
   }
   
   // 3. Simpan URL ke Firestore
   AuthService.updateProfile(uid, photoUrl: response.secureUrl)
   ```
5. **Save** — `AuthService.updateProfile(uid, nama, nomorHp, photoUrl)`
6. **Logout** — `AuthUtils.showLogoutConfirmation()` → animated dialog → sign out

### 9.13 Promo

**File**: `lib/features/promo/presentation/promo_list_page.dart` (498 baris)

**Fitur:**
- StreamBuilder on `promo_codes` collection where `isActive == true`
- Client-side filter menghapus promo yang sudah expired
- Sort by `createdAt` descending (terbaru di atas)
- Tap kode promo → **copy to clipboard** (`Clipboard.setData`)
- Shimmer loading skeleton saat data belum ready
- Tampilkan: kode, tipe diskon, nilai diskon, tanggal expired

### 9.14 Admin Features

#### Driver Dashboard Page

**File**: `lib/features/admin/presentation/driver_dashboard_page.dart` (968 baris)

**Fitur:**
- **Nested StreamBuilder**:
  1. Stream `fleets` where `driverId == currentUid` → ambil fleet yang di-assign
  2. Stream `bookings` where `fleetId == assignedFleet` AND `status in ['paid', 'used', 'completed']`
- Fleet assignment card — menampilkan info armada yang di-assign
- Stats row: total tiket, verified, pending
- Passenger manifest — list penumpang per tanggal keberangkatan
- Tap → `LiveTripManifestPage`

#### Ticket Scanner Page

**File**: `lib/features/admin/presentation/ticket_scanner_page.dart` (905 baris)

**Fitur:**
- **Input manual** — ketik kode booking langsung
- **Scan QR** — buka `QrScannerPage` (full-screen camera)
- Validasi tiket:
  | Kondisi | Aksi |
  |---------|------|
  | Not found | 🔴 Toast "Tiket tidak ditemukan" |
  | Pending | 🟡 Toast "Belum dibayar" |
  | Used/Completed | 🔘 Toast "Sudah pernah di-scan" |
  | Paid | 🟢 Update → `completed` + toast sukses |

#### QR Scanner Page

**File**: `lib/features/admin/presentation/qr_scanner_page.dart` (717 baris)

**Fitur:**
- **Full-screen camera** dengan `MobileScannerController`
- **Custom overlay** — `CustomPaint` dengan transparent cutout + corner decorations
- **Animated scan line** — garis bergerak atas-bawah via `AnimationController`
- **onDetect** → pause scanner → validate → bottom sheet result (green = valid, red = error)
- Return scan data ke caller via `Navigator.pop(result)`

#### Live Trip Manifest Page

**File**: `lib/features/admin/presentation/live_trip_manifest_page.dart` (1027 baris)

**Fitur:**
- StreamBuilder on `bookings` filtered by: `fleetId + departureDate + origin + destination + status [paid/used/completed]`
- **Real-time seat layout** — visualisasi grid kursi (mana yang terisi, mana yang sudah di-scan)
- **Passenger list** — nama, nomor kursi, status validasi
- **Multi-seat handling** — `_Passenger` objects dari booking yang memiliki >1 kursi
- Stats live update saat tiket di-scan

#### Trip Manifest Page

**File**: `lib/features/admin/presentation/trip_manifest_page.dart` (1173 baris)

Detail trip page dengan seat layout visualization, passenger list dengan tanda validasi, dan aksi update status.

#### Admin Dashboard Page (Legacy)

**File**: `lib/features/admin/presentation/admin_dashboard_page.dart` (1036 baris)

TabController 3 tab dengan model `TripData`, `PassengerData`, `TripStatus` enum. Load profile admin + assigned fleet dari Firestore.

### 9.15 Super Admin Features

#### Super Admin Dashboard

**File**: `lib/features/super_admin/presentation/super_admin_dashboard.dart` (450 baris)

**Fitur:**
- `CustomScrollView` dengan header (hamburger → Drawer)
- **Real-time stats row** — 4 `StatCard` via nested `StreamBuilder`:
  1. Revenue (sum dari `bookings` where `status == 'paid'`)
  2. Total Tiket (count `bookings`)
  3. Jumlah Armada (count `fleets`)
  4. Jumlah Rute (count `routes`)
- **Menu grid** 2×3 — 5 `MenuCard`: Routes, Fleet, Users, Report, Promo
- Navigasi ke setiap halaman manajemen

#### Super Admin Drawer

**File**: `lib/features/super_admin/presentation/super_admin_drawer.dart` (563 baris)

`SuperAdminMenu` enum dengan 7 item + Pengaturan + Logout. Custom header dengan avatar/name/email dari Firestore stream.

#### Manage Fleet Page

**File**: `lib/features/super_admin/presentation/manage_fleet_page.dart` (1418 baris)

**Fitur:**
- **CRUD** on `fleets` collection
- **Cloudinary image upload** untuk foto armada
- **Seed data**: 22 perusahaan bus Sumatera (ALS, NPM, ANS, Sempati Star, dll.)
- Form: name, imageUrl, totalSeats, description
- StreamBuilder real-time fleet list

#### Manage Routes Page

**File**: `lib/features/super_admin/presentation/manage_routes_page.dart` (1184 baris)

**Fitur:**
- **CRUD** on `routes` collection
- **Seed data**: 62 rute Trans-Sumatera lintas 10 provinsi
- Tombol seed → bulk insert → `CityCoordinatesSeeder.updateRoutesWithCoordinates()`
- Form: from, to, distance, price, duration

#### Manage Dijkstra Routes Page

**File**: `lib/features/super_admin/presentation/manage_dijkstra_routes_page.dart` (942 baris)

**Fitur:**
- TabController 2 tab:
  1. **"Master Kota (Node)"** — Daftar dari `IndonesiaRegions.all` (~514 kota)
  2. **"Jalur & Harga (Edge)"** — Daftar dari `IndonesiaRoutes.all` (~450 edge)
- Add/delete/search cities dan routes
- Manajemen graph UI untuk data algoritma Dijkstra

#### Manage Driver Assignments Page

**File**: `lib/features/super_admin/presentation/manage_driver_assignments_page.dart` (1128 baris)

**Fitur:**
- StreamBuilder on `fleets` collection
- `_FleetAssignmentCard` per armada
- ModalBottomSheet → StreamBuilder on `users` where `role == 'admin'` → pilih sopir
- Update `fleets/{id}` dengan `driverId` + `driverName`
- Perubahan auto-sync ke driver dashboard secara real-time

#### Manage Promo Page

**File**: `lib/features/super_admin/presentation/manage_promo_page.dart` (1178 baris)

**Fitur:**
- **CRUD** on `promo_codes` collection
- Fields: code (UPPERCASE, unique), discountType (percentage/fixed), discountValue, expiryDate, isActive
- StreamBuilder dengan search filter
- Create/edit via ModalBottomSheet form

#### Manage Users Page

**File**: `lib/features/super_admin/presentation/manage_users_page.dart` (855 baris)

**Fitur:**
- `_UserData` model parsed dari Firestore docs
- `UserRole` enum dengan extensions: `.label`, `.color`, `.bgColor`
- StreamBuilder on `users` collection
- **Actions per user**:
  - Change role → `AuthService.updateUserRole()`
  - Toggle suspend → `AuthService.toggleSuspend()`
- Search + filter by role

#### Transaction Report Page

**File**: `lib/features/super_admin/presentation/transaction_report_page.dart` (657 baris)

**Fitur:**
- StreamBuilder on `bookings` ordered by `createdAt desc`
- **Filter chips**: All, Pending, Paid, Completed, Cancelled
- Summary bar: total booking, total revenue, total tiket
- `_TransactionCard` per booking dengan status/amount/date

---

## 10. Shared Widgets

**File**: `lib/shared/widgets/common_widgets.dart` (244 baris)

| Widget | Deskripsi | Implementasi |
|--------|-----------|--------------|
| `GlassCard` | Efek glassmorphism | `BackdropFilter` + `ImageFilter.blur` + container semi-transparan |
| `GradientButton` | Tombol gradient + loading state | `LinearGradient` primary → secondary + `CircularProgressIndicator` |
| `ShimmerBorderCard` | Border animasi shimmer | `LinearGradient` + `AnimationController` rotasi warna |
| `StatusChip` | Badge status berwarna | `Container` dengan `BorderRadius` + warna sesuai status |

---

## 11. Algoritma Utama — Deep Dive

### 11.1 Dijkstra Shortest Path

**File**: `lib/core/services/firestore_dijkstra_service.dart`  
**Pattern**: Singleton, Firestore-backed graph

#### Struktur Data

```
Graph = Bidirectional Adjacency List
  adjacencyList: Map<String, List<_Edge>>
  
_Edge:
  from: String (kota asal)
  to: String (kota tujuan)
  distance: double (km)
  price: int (Rp)
  durationMinutes: int

Priority Queue = SplayTreeSet<MapEntry<double, String>>
  → sorted by (weight, nodeName)
  → O(log n) insert & remove-min
```

#### Pseudocode Algoritma

```
function dijkstra(edges, start, end, weightFn):
    // 1. Build bidirectional adjacency list
    adj = {}
    for each edge in edges:
        adj[edge.from].add(edge)
        adj[edge.to].add(reverse(edge))    // bidirectional
    
    // 2. Initialize
    dist = { node: ∞ for all nodes }
    prev = { node: null for all nodes }
    visited = {}
    dist[start] = 0
    
    // 3. Priority queue (SplayTreeSet)
    pq = SplayTreeSet sorted by (weight, name)
    pq.add( (0, start) )
    
    // 4. Main loop
    while pq is not empty:
        (weight, u) = pq.removeMin()
        if u in visited: continue
        visited.add(u)
        if u == end: break   // early termination
        
        for each edge from u to v:
            if v in visited: continue
            alt = dist[u] + weightFn(edge)
            if alt < dist[v]:
                pq.remove( (dist[v], v) )   // decrease-key
                dist[v] = alt
                prev[v] = u
                pq.add( (alt, v) )
    
    // 5. Reconstruct path
    if dist[end] == ∞: return null   // no path
    
    path = []
    current = end
    while current != null:
        path.prepend(current)
        current = prev[current]
    
    // 6. Sum totals from path edges
    return DijkstraResult(path, totalDistance, totalPrice, totalDuration)
```

#### 3 Strategi Pencarian

| Method | Weight Function | Mengoptimalkan |
|--------|----------------|----------------|
| `findCheapestPath` | `edge.price.toDouble()` | Harga termurah |
| `findShortestPath` | `edge.distance` | Jarak terpendek |
| `findFastestPath` | `edge.durationMinutes.toDouble()` | Waktu tercepat |

#### Parser Durasi Indonesia

```dart
"5 jam 30 menit" → 330 menit
"2 jam" → 120 menit
"45 menit" → 45 menit

Regex: (\d+)\s*jam → jam × 60
       (\d+)\s*menit → + menit
```

#### Data Graph

- **Nodes**: ~514 kota Indonesia (dari `indonesia_regions.dart`)
- **Edges**: ~450 rute bidirectional (dari `indonesia_routes.dart`)
- **Pricing**: ~Rp 500-700/km
- **Speed**: ~40 km/jam rata-rata

---

### 11.2 Anti-Double-Booking Transaction

**File**: `lib/core/services/booking_service.dart`  
**Method**: `createBooking()`

#### Arsitektur "Timestamp Expiration"

```
┌───────────────────────────────────────────────────┐
│           FIRESTORE TRANSACTION                    │
│                                                    │
│  ┌─────────────────────────────┐                  │
│  │ 1. READ seat_locks doc      │ ◄── Atomic read  │
│  │    (single doc per fleet+   │                  │
│  │     date = all seats)       │                  │
│  └─────────────────────────────┘                  │
│              │                                     │
│  ┌─────────────────────────────┐                  │
│  │ 2. READ fleet doc           │ ◄── Get capacity │
│  │    (totalSeats,             │                  │
│  │     availableSeats)         │                  │
│  └─────────────────────────────┘                  │
│              │                                     │
│  ┌─────────────────────────────┐                  │
│  │ 3. CHECK CONFLICTS          │                  │
│  │    for each seat:           │                  │
│  │      if paid/used → ❌       │                  │
│  │      if pending+active:     │                  │
│  │        if OTHER user → ❌    │                  │
│  │        if SAME user → ✅     │ ◄── userId-aware│
│  │      if expired → ✅         │                  │
│  └─────────────────────────────┘                  │
│              │                                     │
│  ┌─────────────────────────────┐                  │
│  │ 4. CHECK fleet capacity     │                  │
│  │    availableSeats >= needed │                  │
│  └─────────────────────────────┘                  │
│              │                                     │
│  ┌─────────────────────────────┐                  │
│  │ 5. GENERATE booking code    │                  │
│  │    format: TRV-XXX999       │                  │
│  └─────────────────────────────┘                  │
│              │                                     │
│  ┌─────────────────────────────┐                  │
│  │ 6. WRITE seat_locks         │ ◄── Lock seats   │
│  │    seat → {bookingId,       │                  │
│  │            userId,          │                  │
│  │            status: pending, │                  │
│  │            expiryDate}      │                  │
│  └─────────────────────────────┘                  │
│              │                                     │
│  ┌─────────────────────────────┐                  │
│  │ 7. CREATE booking doc       │ ◄── Status:      │
│  │    with expiryDate =        │     pending      │
│  │    now + 15 minutes         │                  │
│  └─────────────────────────────┘                  │
│              │                                     │
│  ┌─────────────────────────────┐                  │
│  │ 8. DEDUCT fleet seats       │                  │
│  │    availableSeats -= N      │                  │
│  └─────────────────────────────┘                  │
│                                                    │
└───────────────────────────────────────────────────┘
```

#### Kode Implementasi Transaction (STEP 3 — Conflict Check)

```dart
final currentUserId = booking.userId;
final conflicted = <String>[];

for (final seat in booking.selectedSeatLabels) {
  if (seatEntries.containsKey(seat)) {
    final entry = seatEntries[seat] as Map;
    final status = entry['status'] as String;
    final lockUserId = entry['userId'] as String;

    if (status == 'paid' || status == 'used') {
      // Permanently sold — ALWAYS conflict
      conflicted.add(seat);
    } else if (status == 'pending') {
      final exp = (entry['expiryDate'] as Timestamp?)?.toDate();
      if (exp != null && exp.isAfter(now)) {
        // Active pending lock
        if (lockUserId != currentUserId) {
          conflicted.add(seat);  // Another user's lock → CONFLICT
        }
        // Current user's own lock → ALLOW OVERWRITE
      }
      // Expired pending → treat as AVAILABLE
    }
  }
}

if (conflicted.isNotEmpty) {
  throw SeatAlreadyBookedException(conflicted);
}
```

#### Mengapa Single-Doc Lock Pattern?

```
KUNCI: seat_locks/{fleetId}_{date}
  └── seats: { "1": {...}, "3": {...}, "5": {...} }

ALASAN:
1. Satu Firestore transaction hanya bisa read/write max 500 docs
2. Dengan single-doc, SEMUA kursi untuk fleet+date dibaca/ditulis 
   dalam SATU atomic operation
3. Tidak ada race condition karena Firestore transaction otomatis 
   retry jika ada concurrent write
4. Lebih efisien daripada 1 doc per kursi (N reads vs 1 read)
```

---

### 11.3 Timestamp Expiration (Anti-Ghost-Seat)

**Masalah**: User mulai booking → tidak bayar → kursi terkunci selamanya ("ghost seat")

**Solusi**: 4-layer defense system:

#### Layer 1: expiryDate pada Booking

```dart
// Saat createBooking:
final expiryDate = DateTime.now().add(Duration(minutes: 15));

// Booking doc:
{
  status: 'pending',
  expiryDate: Timestamp.fromDate(expiryDate),
  // ... other fields
}
```

#### Layer 2: Client-Side Stream Filter

```dart
// Di SeatSelectionPage._deriveSeatStates():
if (status == 'pending') {
  final exp = booking.expiryDate;
  if (exp != null && exp.isAfter(now)) {
    // Masih active → tampilkan sebagai PENDING (locked)
  } else {
    // Sudah expired → tampilkan sebagai AVAILABLE
  }
}
```

#### Layer 3: Client-Side GC (Cleanup Function)

```dart
// Dipanggil di SeatSelectionPage.initState():
BookingService.cleanupExpiredBookings(
  fleetId: widget.fleetId,
  departureDate: widget.departureDate,
);

// Implementasi:
// 1. Query semua pending booking untuk fleet+date ini
// 2. Filter yang expiryDate < now
// 3. Untuk setiap expired booking:
//    → cancelBooking(bookingId)
//    → (yang akan menghapus dari seat_locks + restore seats)
```

#### Layer 4: Payment Page Auto-Cancel

```dart
// Di PaymentPage:
Timer.periodic(Duration(seconds: 1), (timer) {
  final remaining = expiryDate.difference(DateTime.now());
  if (remaining <= Duration.zero) {
    timer.cancel();
    BookingService.cancelBooking(bookingId);
    // Tampilkan dialog "Waktu pembayaran habis"
    Navigator.pop();
  }
  setState(() => _timeLeft = remaining);
});
```

#### Diagram Flow Anti-Ghost-Seat

```
User klik "Pesan" (Checkout)
        │
        ▼
┌─────────────────────────┐
│ createBooking()         │
│ status: pending         │
│ expiryDate: now + 15min │
│ seat_locks: locked      │
└─────────────┬───────────┘
              │
    ┌─────────┴──────────┐
    │                    │
    ▼                    ▼
  BAYAR              TIDAK BAYAR
    │                    │
    ▼                    ├── PaymentPage countdown → 0
    │                    │   → auto cancelBooking()
confirmPayment()        │
status: paid            ├── SeatSelection cleanup
seat_locks:             │   → cleanupExpiredBookings()
  status: paid          │
  (no expiryDate)       ├── StreamBuilder filter
    │                   │   → ignore expired pending
    ▼                   │
  KURSI SOLD            └── Next user createBooking()
  (permanen)                → overwrite expired lock
```

---

### 11.4 Seat State Derivation Algorithm

**File**: `lib/features/seat_selection/presentation/seat_selection_page.dart`  
**Method**: `_deriveSeatStates(List<BookingModel> bookings)`

#### 4 State Kursi

| State | Warna | Kondisi |
|-------|-------|---------|
| `available` | 🟢 Hijau | Tidak ada booking aktif untuk kursi ini |
| `selected` | 🔵 Biru | User sedang memilih kursi ini (local state) |
| `pending` | 🟡 Kuning | User LAIN sedang booking (pending + belum expired) |
| `sold` | 🔴 Merah | Kursi sudah dibayar (paid/used/completed) |

#### Pseudocode Lengkap

```
function deriveSeatStates(bookings):
    states = { "1": available, "2": available, ..., "N": available }
    currentUid = FirebaseAuth.currentUser.uid
    now = DateTime.now()
    
    for each booking in bookings:
        if booking.status in [paid, used, completed]:
            for each seat in booking.selectedSeatLabels:
                states[seat] = SOLD
        
        elif booking.status == pending:
            if booking.expiryDate != null AND booking.expiryDate > now:
                // Active pending booking
                if booking.userId == currentUid:
                    // User's OWN pending → SKIP (treat as available)
                    continue
                else:
                    // ANOTHER user's pending → mark as PENDING
                    for each seat in booking.selectedSeatLabels:
                        // Only if not already SOLD (sold takes priority)
                        if states[seat] != SOLD:
                            states[seat] = PENDING
            else:
                // Expired pending → treat as AVAILABLE (ignore)
                continue
        
        elif booking.status == cancelled:
            // Completely ignore cancelled bookings
            continue
    
    // Apply local selection
    for each seat in userSelectedSeats:
        if states[seat] == available:
            states[seat] = SELECTED
    
    return states
```

#### Kenapa userId Exclusion Penting?

**Skenario tanpa exclusion (BUG):**
1. User A pilih kursi 1, 2 → booking pending
2. User A batal bayar → cancel
3. User A ingin book ulang kursi 1, 2
4. ❌ Sistem menampilkan kursi 1, 2 sebagai "pending" (locked) — padahal itu lock milik A sendiri!
5. ❌ Toast "Bangku sudah dipesan" saat A coba book ulang

**Skenario dengan exclusion (FIX):**
1. User A buka seat selection
2. `_deriveSeatStates` melihat pending booking milik A
3. `booking.userId == currentUid` → **SKIP**
4. ✅ Kursi 1, 2 tampil sebagai "available"
5. ✅ A bisa memilih dan booking ulang

---

### 11.5 Dynamic Seat Grid Generation

**File**: `lib/features/seat_selection/presentation/seat_selection_page.dart`  
**Method**: `_generateGrid(int totalSeats)`

#### Layout Pattern

```
Format: 2 kursi + aisle + 2 kursi per baris
Kolom:  [Seat] [Seat] [Aisle] [Seat] [Seat]
Index:    0       1      2       3      4

4 kursi per baris (logical), 5 kolom (dengan aisle)
```

#### Pseudocode

```
function generateGrid(totalSeats):
    grid = []
    seatNumber = 1
    
    while seatNumber <= totalSeats:
        row = []
        
        // Kolom 0-1: kursi kiri
        for col in [0, 1]:
            if seatNumber <= totalSeats:
                row.add(SeatCell(label: "$seatNumber"))
                seatNumber++
            else:
                row.add(null)  // kosong
        
        // Kolom 2: aisle (selalu null)
        row.add(null)
        
        // Kolom 3-4: kursi kanan
        for col in [3, 4]:
            if seatNumber <= totalSeats:
                row.add(SeatCell(label: "$seatNumber"))
                seatNumber++
            else:
                row.add(null)  // kosong
        
        grid.add(row)
    
    return grid
```

#### Contoh Output

**totalSeats = 12:**
```
 [1]  [2]  |aisle|  [3]  [4]
 [5]  [6]  |aisle|  [7]  [8]
 [9]  [10] |aisle|  [11] [12]
```

**totalSeats = 10:**
```
 [1]  [2]  |aisle|  [3]  [4]
 [5]  [6]  |aisle|  [7]  [8]
 [9]  [10] |aisle|  [—]  [—]
```

**totalSeats = 22:**
```
 [1]  [2]  |aisle|  [3]  [4]
 [5]  [6]  |aisle|  [7]  [8]
 ...
 [21] [22] |aisle|  [—]  [—]
```

---

### 11.6 QR Ticket Scanning & Validation

**Files**: 
- `lib/core/services/ticket_scan_service.dart`
- `lib/features/admin/presentation/ticket_scanner_page.dart`
- `lib/features/admin/presentation/qr_scanner_page.dart`

#### Alur Scan

```
Sopir buka TicketScannerPage
        │
        ├── Input Manual: ketik kode booking
        │
        └── Scan QR: buka QrScannerPage
                │
                ▼
        MobileScannerController
        onDetect(BarcodeCapture)
                │
                ▼
        Pause scanner (cegah multiple scan)
                │
                ▼
        TicketScanService.scanTicketAndUpdateStatus(code)
                │
                ├── Cari di Firestore:
                │   1. Query by bookingId (exact doc)
                │   2. Query by bookingCode field
                │
                ├── Validasi status:
                │   ├── Not found        → ScanError.notFound
                │   ├── Status: pending   → ScanError.unpaid
                │   ├── Status: cancelled → ScanError.cancelled
                │   ├── Status: used/completed → ScanError.alreadyUsed
                │   └── Status: paid      → ✅ VALID
                │
                └── Jika valid:
                    Update booking: status = 'completed'
                    Return ScanResult(success: true, booking)
```

#### Real-Time Update ke E-Ticket

```
Sopir scan QR → booking status berubah di Firestore
        │
        ▼
LiveETicketPage (penumpang) StreamBuilder on booking doc
        │
        ▼
Status berubah paid → completed
        │
        ▼
QR code section berubah → stamp "TIKET TELAH DIGUNAKAN"
(animasi real-time tanpa refresh)
```

---

### 11.7 PDF Ticket Generation

**File**: `lib/core/services/pdf_ticket_service.dart`

#### Layout A4 PDF

```
┌──────────────────────────────────────────┐
│                                          │
│     ● E-TRAVEL                          │
│     TIKET ELEKTRONIK                     │
│                                          │
├──────────────────────────────────────────┤
│                                          │
│     Asal        →        Tujuan          │
│     [Kota Asal]    [Kota Tujuan]         │
│                                          │
│     Tanggal: 01 Januari 2025             │
│     Armada: ALS Express                  │
│     Kursi: 1, 3, 5                       │
│     Kode: TRV-ABC123                     │
│     Total: Rp 450.000                    │
│                                          │
├─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┤  ← garis perforasi
│                                          │
│              ┌───────────┐               │
│              │           │               │
│              │  QR CODE  │               │
│              │           │               │
│              └───────────┘               │
│                                          │
│     Tunjukkan QR code ini                │
│     kepada sopir saat naik               │
│                                          │
└──────────────────────────────────────────┘
```

#### Font Strategy

```dart
final interRegular = await PdfGoogleFonts.interRegular();
final interBold = await PdfGoogleFonts.interBold();
final jetBrainsMono = await PdfGoogleFonts.jetBrainsMonoRegular();

// interRegular/Bold → body text
// jetBrainsMono → booking code (monospace agar jelas)
```

---

## 12. Design Patterns & Teknik Khusus

### State Management

| Pattern | Implementasi |
|---------|--------------|
| **StatefulWidget + setState()** | Semua halaman menggunakan pattern ini |
| **Firestore StreamBuilder** | Real-time data binding langsung ke Firestore |
| **Nested StreamBuilder** | Dashboard Super Admin (3 nested: bookings→fleets→routes) |
| **Firestore Transaction** | `BookingService` — atomic read-check-write untuk seat locking |
| **No External State Management** | Tidak ada Provider, Riverpod, Bloc, dll |

### Concurrency Control

| Pattern | Implementasi |
|---------|--------------|
| **Firestore Transaction** | `runTransaction()` dengan serializable isolation |
| **Single-Doc Lock** | `seat_locks/{fleetId}_{date}` — satu doc = satu atomic unit |
| **Client-Side GC** | `cleanupExpiredBookings()` sebagai fallback |
| **Optimistic Concurrency** | Transaction auto-retry jika concurrent write |

### UI/Animation Patterns

| Pattern | Lokasi | Detail |
|---------|--------|--------|
| **Bokeh Particle Animation** | `SplashScreen` | `CustomPainter` + random circles + `AnimationController` |
| **Staggered Animations** | Throughout | `flutter_animate` dengan delay offset per list index |
| **Press-Scale Buttons** | `AuthPrimaryButton` | `GestureDetector` + `AnimatedScale` on tap down/up |
| **Glassmorphism** | `GlassCard` | `BackdropFilter` + `ImageFilter.blur` + semi-transparent |
| **Shimmer Border** | `ShimmerBorderCard` | `LinearGradient` + `AnimationController` rotasi |
| **Custom Map Style** | `CustomRouteMap` | JSON silver/retro style dari Google Maps Styling Wizard |
| **Scan Line Animation** | `QrScannerPage` | `AnimationController` + `Transform.translate` repeat |

### Navigation Patterns

| Pattern | Implementasi |
|---------|--------------|
| **Role-Based Routing** | `MainNavigationScreen` → StreamBuilder role → Different shells |
| **IndexedStack** | `_UserNavShell` — 4 tab pages cached in memory |
| **pushAndRemoveUntil** | E-Ticket → Beranda (clear entire stack) |
| **Double-Tap-to-Exit** | `_UserNavShell` PopScope — 2 taps within 2 seconds |
| **Navigator.canPop()** | `EditProfilePage` — conditional back button |
| **Notched FAB** | `_AdminNavShell` — center-docked FAB for scanner |

### Data Patterns

| Pattern | Implementasi |
|---------|--------------|
| **Denormalization** | `fleetName` stored in booking doc (avoid join) |
| **Bidirectional Graph** | Dijkstra adjacency list — every edge added both ways |
| **Timestamp Expiration** | `expiryDate` field + client-side filter + cleanup GC |
| **Generated Booking Code** | `TRV-` + 3 uppercase letters + 3 digits (exclude I, O) |
| **Cloudinary Unsigned Upload** | HTTP POST + upload preset `etravel_preset` |
| **Client-Side Seeding** | Seed 60+ city coordinates, 62 routes, 22 fleets from code |

---

## 13. Statistik Kode

### Total Line Count per Directory

| Direktori | File | Total Baris |
|-----------|------|-------------|
| `lib/` root | 2 | ~145 |
| `lib/core/constants/` | 1 | ~33 |
| `lib/core/data/` | 2 | ~1,337 |
| `lib/core/models/` | 2 | ~386 |
| `lib/core/services/` | 5 | ~1,821 |
| `lib/core/theme/` | 3 | ~256 |
| `lib/core/utils/` | 3 | ~352 |
| `lib/core/widgets/` | 3 | ~907 |
| `lib/shared/widgets/` | 1 | ~244 |
| `lib/features/auth/` | 4 | ~1,867 |
| `lib/features/splash/` | 1 | ~442 |
| `lib/features/navigation/` | 1 | ~907 |
| `lib/features/home/` | 2 | ~1,996 |
| `lib/features/search_result/` | 1 | ~907 |
| `lib/features/select_fleet/` | 1 | ~695 |
| `lib/features/seat_selection/` | 1 | ~1,037 |
| `lib/features/checkout/` | 1 | ~1,151 |
| `lib/features/payment/` | 1 | ~1,146 |
| `lib/features/e_ticket/` | 1 | ~984 |
| `lib/features/booking_history/` | 1 | ~786 |
| `lib/features/edit_profile/` | 1 | ~936 |
| `lib/features/promo/` | 1 | ~498 |
| `lib/features/admin/` | 6 | ~5,826 |
| `lib/features/super_admin/` | 11 | ~8,647 |
| **TOTAL** | **~52 files** | **~32,300+ baris** |

### Jumlah Firestore Collections

| Collection | Dokumen | Jenis |
|------------|---------|-------|
| `users` | Per user | CRUD |
| `fleets` | Per armada | CRUD + real-time stream |
| `routes` | Per edge rute | CRUD + Dijkstra source |
| `bookings` | Per booking | Transaction + real-time |
| `seat_locks` | Per fleet+date | Transaction lock |
| `promo_codes` | Per promo | CRUD |
| `city_coordinates` | Per kota | Seeder |

### Jumlah Screen/Page

| Kategori | Jumlah |
|----------|--------|
| Auth Pages | 3 (Login, Register, Forgot) |
| User Pages | 9 (Home, Search, Fleet, Seat, Checkout, Payment, Ticket, History, Profile) |
| Admin Pages | 5 (Dashboard, Driver, Scanner, QR, Manifest) |
| Super Admin Pages | 9 (Dashboard, Fleet, Routes, Dijkstra, Drivers, Promo, Users, Report, Drawer) |
| System Pages | 2 (Splash, Navigation) |
| **Total** | **~28 screens** |

---

> **Dokumentasi ini mencakup 100% file, fitur, algoritma, dan implementasi dalam codebase E-Travel.**  
> Generated from codebase analysis — `d:\Downloads\TRAVELLL\`

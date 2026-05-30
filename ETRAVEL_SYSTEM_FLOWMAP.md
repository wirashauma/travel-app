# 🗺️ E-TRAVEL — System Flowmap

> **Dokumen ini berisi peta sistem lengkap aplikasi E-Travel**
> Mencakup arsitektur, flow navigasi, alur data, Firestore schema, dan relasi antar fitur.
>
> 📅 Dibuat: 1 Maret 2026
> 📦 Package: `com.etravel.e_travel`
> 🎨 Design System: Trust Blue (`#0F4C81`)

---

## 📐 ARSITEKTUR PROYEK

```
lib/
├── main.dart                          ← Entry point (Firebase init + MaterialApp)
├── firebase_options.dart              ← Firebase config (auto-generated)
│
├── core/                              ← SHARED LAYER
│   ├── constants/
│   │   └── app_constants.dart         ← App name, version, dll
│   ├── data/
│   │   ├── indonesia_regions.dart     ← Daftar kota/wilayah Indonesia
│   │   └── indonesia_routes.dart      ← Data rute statis (seed)
│   ├── models/
│   │   ├── booking_model.dart         ← Model Booking (immutable, fromFirestore/toMap)
│   │   └── route_model.dart           ← Model Route (Dijkstra edges/nodes)
│   ├── services/
│   │   ├── auth_service.dart          ← Login, register, logout, profile, role management
│   │   ├── booking_service.dart       ← Create/cancel/confirm booking (atomic transaction)
│   │   ├── firestore_dijkstra_service.dart ← Shortest path algorithm (Dijkstra)
│   │   ├── pdf_ticket_service.dart    ← Generate PDF e-ticket
│   │   ├── ticket_scan_service.dart   ← Scan & validate QR tiket
│   │   └── city_coordinates_seeder.dart ← Seed koordinat kota ke Firestore
│   ├── theme/
│   │   ├── app_theme.dart             ← ThemeData global
│   │   ├── app_colors.dart            ← Palet warna
│   │   └── app_text_styles.dart       ← Typography
│   ├── utils/
│   │   ├── formatters.dart            ← Format currency, date, dll
│   │   ├── logout_dialog.dart         ← Reusable dialog konfirmasi logout
│   │   └── responsive.dart            ← Responsive helpers
│   └── widgets/
│       ├── custom_route_map.dart      ← Google Maps widget untuk rute
│       ├── empty_state_widget.dart    ← Reusable empty/error state
│       └── firestore_stream_builder.dart ← Generic StreamBuilder wrapper
│
├── features/                          ← FEATURE MODULES (Clean Architecture)
│   ├── auth/
│   │   └── presentation/
│   │       ├── login_page.dart
│   │       ├── register_page.dart
│   │       ├── forgot_password_page.dart
│   │       └── widgets/auth_widgets.dart
│   ├── splash/
│   │   └── presentation/
│   │       └── splash_screen.dart
│   ├── navigation/
│   │   └── presentation/
│   │       └── main_navigation_screen.dart  ← ROLE ROUTER (StreamBuilder)
│   ├── home/
│   │   └── presentation/
│   │       ├── home_search_page.dart        ← Pencarian rute (User)
│   │       └── popular_routes_page.dart     ← Rute populer
│   ├── search_result/
│   │   └── presentation/
│   │       └── search_result_page.dart      ← Hasil pencarian + Dijkstra
│   ├── select_fleet/
│   │   └── presentation/
│   │       └── select_fleet_page.dart       ← Pilih armada
│   ├── checkout/
│   │   └── presentation/
│   │       └── checkout_page.dart           ← Checkout + promo code
│   ├── payment/
│   │   └── presentation/
│   │       └── payment_page.dart            ← Simulasi pembayaran
│   ├── e_ticket/
│   │   └── presentation/
│   │       └── live_e_ticket_page.dart      ← E-Ticket real-time + QR
│   ├── booking_history/
│   │   └── presentation/
│   │       └── booking_history_page.dart    ← Riwayat booking (User)
│   ├── promo/
│   │   └── presentation/
│   │       └── promo_list_page.dart         ← Daftar promo aktif (User)
│   ├── edit_profile/
│   │   └── presentation/
│   │       └── edit_profile_page.dart       ← Edit profil (semua role)
│   ├── admin/                               ← DRIVER / ADMIN FEATURES
│   │   └── presentation/
│   │       ├── driver_dashboard_page.dart   ← Dashboard sopir (real-time)
│   │       ├── ticket_scanner_page.dart     ← Full-screen QR scanner
│   │       ├── qr_scanner_page.dart         ← Alternatif scanner
│   │       ├── admin_dashboard_page.dart    ← Admin dashboard
│   │       ├── trip_manifest_page.dart      ← Manifest penumpang
│   │       └── live_trip_manifest_page.dart ← Manifest real-time
│   └── super_admin/                         ← SUPER ADMIN FEATURES
│       └── presentation/
│           ├── super_admin_dashboard.dart   ← Dashboard + stats
│           ├── super_admin_drawer.dart      ← Sidebar navigation
│           ├── manage_fleet_page.dart       ← CRUD armada
│           ├── manage_driver_assignments_page.dart ← Assign supir ke armada
│           ├── manage_routes_page.dart      ← CRUD rute manual
│           ├── manage_dijkstra_routes_page.dart ← Rute Dijkstra
│           ├── manage_promo_page.dart       ← CRUD kode promo
│           ├── manage_users_page.dart       ← Manajemen user & role
│           ├── transaction_report_page.dart ← Laporan transaksi
│           └── widgets/
│               ├── stat_card_widget.dart
│               └── menu_card_widget.dart
│
└── shared/
    └── widgets/
        └── common_widgets.dart              ← Widget bersama
```

---

## 🔄 FLOW UTAMA — APLIKASI

### 1. App Launch Flow

```
main.dart
  │
  ├── Firebase.initializeApp()
  ├── Locale: id_ID
  ├── Orientation: Portrait only
  │
  └── MaterialApp
        └── home: SplashScreen
              │
              │ (2 detik animasi branded)
              │
              ├── FirebaseAuth.currentUser != null?
              │     ├── YA  → MainNavigationScreen
              │     └── TIDAK → LoginPage
```

### 2. Auth Flow

```
┌─────────────┐     ┌──────────────┐     ┌──────────────────────┐
│  LoginPage   │────▶│ RegisterPage  │     │ ForgotPasswordPage   │
│              │◀────│              │     │                      │
│  email       │────▶│ email        │     │ email                │
│  password    │     │ password     │     │ → sendPasswordReset  │
│              │     │ namaLengkap  │     └──────────────────────┘
│  AuthService │     │ nomorHp      │               ▲
│  .login()    │     │              │               │
│              │     │ AuthService  │     ┌─────────┘
│  [Lupa Pass] ─────▶│ .register()  │     │
│              │     └──────┬───────┘     │
│ [Daftar] ────┘            │             │
│              │            ▼             │
│   onSuccess ─┼──▶ MainNavigationScreen  │
│              │                          │
│ isSuspended? │   → SnackBar + Logout    │
│   → blocked  │                          │
└──────────────┘                          │
       │ [Lupa Password?] ────────────────┘
```

### 3. Role-Based Navigation Router

```
MainNavigationScreen
  │
  └── StreamBuilder<DocumentSnapshot>
        │  stream: users/{uid}.snapshots()
        │
        ├── ConnectionState.waiting → _LoadingSplash (branded spinner)
        │
        ├── hasError / !exists → _ErrorScreen (retry button)
        │
        ├── isSuspended == true → _SuspendedScreen (logout otomatis)
        │
        └── switch(role):
              │
              ├── 'user'        → _UserNavShell
              ├── 'admin'       → _AdminNavShell
              └── 'super_admin' → SuperAdminDashboard
```

---

## 👤 ROLE: USER — `_UserNavShell`

### Navigation: BottomNavigationBar (4 Tab)

```
┌───────────────────────────────────────────────────────────────┐
│                     IndexedStack (cached)                      │
│  ┌─────────────┬──────────────┬─────────────┬───────────────┐ │
│  │ HomeSearch   │ BookingHist  │ PromoList   │ EditProfile   │ │
│  │ Page         │ Page         │ Page        │ Page          │ │
│  └──────┬──────┴──────┬───────┴──────┬──────┴───────────────┘ │
│         │             │              │                         │
├─────────┼─────────────┼──────────────┼─────────────────────────┤
│  🌐     │  🎫         │  🏷️          │  👤                      │
│ Eksplor │ Tiket Saya  │ Promo       │ Profil                  │
│ (idx 0) │ (idx 1)     │ (idx 2)     │ (idx 3)                 │
└─────────┴─────────────┴──────────────┴─────────────────────────┘
         PopScope: idx==0 → Exit Dialog
```

### User Booking Journey (Complete)

```
Tab 0: HomeSearchPage
  │ [Kota Asal] [Kota Tujuan] [Tanggal] [Jumlah Penumpang]
  │
  │ FirestoreDijkstraService → shortest path
  │
  └──▶ SearchResultPage
         │ Params: origin, destination, date, passengers
         │ Google Maps (CustomRouteMap) + rute detail
         │ Jarak total + estimasi waktu
         │
         └──▶ SelectFleetPage
                │ Params: + routePrice, routeSummary, totalDistance, duration
                │ StreamBuilder → collection('fleets')
                │ Pilih armada berdasarkan ketersediaan kursi
                │
                └──▶ CheckoutPage
                       │ Params: + fleetId, fleetName, availableSeats
                       │ Pilih nomor kursi
                       │ Input kode promo (validasi real-time)
                       │
                       │ BookingService.createBooking()
                       │   → Firestore Transaction:
                       │     1. Cek availableSeats >= seatsBooked
                       │     2. Deduct availableSeats
                       │     3. Create booking doc (status: 'pending')
                       │     4. Generate bookingCode (TRV-XXX000)
                       │
                       └──▶ PaymentPage
                              │ Params: bookingId, bookingCode, totalAmount, etc.
                              │ Metode: VA / E-Wallet / QRIS (simulasi)
                              │ Countdown 15 menit
                              │
                              │ BookingService.confirmPayment(bookingId)
                              │   → status: 'pending' → 'paid'
                              │
                              └──▶ LiveETicketPage
                                     │ StreamBuilder → booking/{id}
                                     │ QR Code = booking.id (Firestore doc ID)
                                     │ Status badge (Pending/Lunas/Digunakan/Batal)
                                     │ Download PDF / Share
                                     │
                                     │ Jika tiket di-scan supir:
                                     │   status 'paid' → 'used' (real-time update)
                                     │   UI: stamp "USED" + animasi
```

### Tab 1: Booking History

```
BookingHistoryPage
  │ StreamBuilder → bookings where userId == currentUser.uid
  │                 orderBy createdAt desc
  │
  ├── Status: pending  → Badge kuning, tombol "Bayar" / "Batalkan"
  ├── Status: paid     → Badge hijau, tombol "Lihat E-Ticket"
  ├── Status: used     → Badge abu, "Sudah Digunakan"
  ├── Status: completed→ Badge abu, backward compat
  └── Status: cancelled→ Badge merah, "Dibatalkan"
  │
  ├── [Bayar] ──▶ PaymentPage
  ├── [Lihat E-Ticket] ──▶ LiveETicketPage
  └── [Batalkan] ──▶ BookingService.cancelBooking()
                       → status: 'cancelled'
                       → availableSeats += seatsBooked (dikembalikan)
```

### Tab 2: Promo

```
PromoListPage
  │ StreamBuilder → promo_codes where isActive == true
  │ Client-side sort by createdAt desc (no composite index needed)
  │ Filter: expired == false
  │
  └── PromoCard
        │ Kode promo + diskon (% atau nominal)
        │ Tanggal kadaluarsa
        └── [Salin Kode] → Clipboard.setData()
```

### Tab 3: Profil

```
EditProfilePage
  │ ← Tombol Back (Arrow) → Navigator.pop()
  │
  │ Fetch dari Firestore: namaLengkap, nomorHp, email, profileImageUrl
  │
  ├── Avatar (Cloudinary upload)
  │     └── ImagePicker → Cloudinary API → secureUrl → setState
  │
  ├── Form: Nama, No. HP, Email
  │     └── [Simpan] → AuthService.updateProfile()
  │
  ├── [Logout] → LogoutDialog → AuthService.logout()
  │               → pushAndRemoveUntil → LoginPage
  │
  └── [Version Label] → Secret backdoor (10x tap → Super Admin)
```

---

## 🚐 ROLE: ADMIN (SUPIR) — `_AdminNavShell`

### Navigation: BottomAppBar + Center FAB

```
┌──────────────────────────────────────────────────────┐
│                  IndexedStack (2 pages)                │
│  ┌──────────────────────┬───────────────────────────┐ │
│  │ DriverDashboardPage  │     EditProfilePage        │ │
│  └──────────┬───────────┴───────────────┬───────────┘ │
│             │                           │              │
├─────────────┼──────────┬────────────────┼──────────────┤
│  📋         │          │               │  👤            │
│ Manifest    │   [FAB]  │               │ Profil        │
│ (idx 0)     │  🔲SCAN  │               │ (idx 1)       │
└─────────────┴──────────┴────────────────┴──────────────┘
```

### Driver Dashboard (Real-time Nested StreamBuilder)

```
DriverDashboardPage
  │
  └── StreamBuilder #1: fleets where driverId == currentUser.uid
        │
        ├── Tidak ada fleet ditugaskan:
        │     └── Orange card "Belum Ada Armada" + badge "Pending"
        │
        └── Fleet ditemukan:
              │ Green card "Tugas Hari Ini" + badge "Aktif"
              │ Fleet name + total kursi + available kursi
              │
              └── StreamBuilder #2: bookings where fleetId == fleet.id
                    │                AND status in ['paid','completed','used']
                    │
                    ├── Tidak ada penumpang → "Belum ada penumpang"
                    │
                    └── Manifest penumpang:
                          ├── Nama penumpang
                          ├── Kode booking
                          ├── Nomor kursi
                          └── Status badge (Lunas/Digunakan)
```

### QR Scanner Flow

```
[FAB SCAN] ──▶ TicketScannerPage (Full-screen camera)
                 │
                 │ MobileScanner → onDetect(BarcodeCapture)
                 │   └── qrData = barcode.rawValue (= bookingId)
                 │
                 │ _scannerCtrl.stop() ← pause scanner
                 │
                 └── _validateTicket(bookingId):
                       │
                       │ Attempt 1: bookings.doc(bookingId).get()
                       │ Attempt 2: bookings.where('bookingCode', == qrData)
                       │
                       ├── !ticket.exists:
                       │     └── ❌ AlertDialog "Tiket Tidak Valid / Palsu"
                       │
                       ├── status == 'pending':
                       │     └── ⚠️ AlertDialog "Tiket Belum Dibayar!"
                       │
                       ├── status == 'used' || status == 'completed':
                       │     └── 🔄 AlertDialog "Tiket Sudah Digunakan!"
                       │
                       ├── status == 'cancelled':
                       │     └── ❌ AlertDialog "Tiket Dibatalkan"
                       │
                       └── status == 'paid':
                             │ ✅ UPDATE → status: 'used'
                             │ ✅ AlertDialog "Tiket Valid! Penumpang diizinkan naik"
                             │    Tampil: nama, kode, rute, kursi
                             │
                             └── [Scan Lagi] → _scannerCtrl.start()
                                 [Kembali]   → Navigator.pop()
```

---

## 👑 ROLE: SUPER ADMIN — `SuperAdminDashboard`

### Dashboard + Drawer Navigation

```
SuperAdminDashboard
  │
  ├── Drawer (SuperAdminDrawer)
  │     │
  │     ├── [0] 🏠 Dashboard          → SuperAdminDashboard
  │     ├── [1] 🚐 Manajemen Armada   → ManageFleetPage
  │     ├── [2] 👤 Penugasan Supir    → ManageDriverAssignmentsPage
  │     ├── [3] 🗺️ Manajemen Rute     → ManageRoutesPage
  │     ├── [4] 🏷️ Manajemen Promo    → ManagePromoPage
  │     ├── [5] 👥 Manajemen User     → ManageUsersPage
  │     ├── [6] 📊 Laporan Transaksi  → TransactionReportPage
  │     ├── ─── Footer ───
  │     ├── [7] ⚙️ Pengaturan         → EditProfilePage
  │     └── [8] 🚪 Logout             → LogoutDialog
  │
  ├── Header (gradient, user info from StreamBuilder)
  │
  ├── Stats Row (horizontal scroll, 4 real-time cards):
  │     ├── 💰 Pendapatan Bulan Ini   ← SUM(totalPrice) where status in ['paid','used']
  │     ├── 🎫 Tiket Terjual          ← COUNT bookings paid/used this month
  │     ├── 🚐 Armada Aktif           ← COUNT fleets
  │     └── 🗺️ Total Rute             ← COUNT routes
  │
  └── Menu Grid (2 columns, 5 items) → navigates to manage pages
```

### Super Admin — Sub-Pages

```
ManageFleetPage (CRUD Armada)
  │ StreamBuilder → fleets orderBy name
  │ Create/Edit: name, totalSeats, image (Cloudinary)
  │ Delete: hapus armada + reset driver jika ada
  │
  │ CATATAN: Logika assign driver SUDAH DIPISAHKAN
  │          ke ManageDriverAssignmentsPage

ManageDriverAssignmentsPage
  │ StreamBuilder → fleets orderBy name
  │ Tiap FleetCard:
  │   ├── Status supir (Aktif / Belum Ada)
  │   └── [Tugaskan/Ganti] → ModalBottomSheet
  │         │
  │         └── StreamBuilder → users where role == 'admin'
  │               │ Client-side sort (no composite index)
  │               │ Null-safe: data['name'] ?? data['namaLengkap'] ?? 'Supir Tanpa Nama'
  │               │
  │               ├── [Pilih Supir] → fleets/{id}.update({driverId, driverName})
  │               │     → SnackBar hijau "Berhasil ditugaskan!"
  │               │     → DriverDashboardPage di HP supir = real-time sync
  │               │
  │               └── [Hapus Penugasan] → driverId: '', driverName: ''

ManageRoutesPage / ManageDijkstraRoutesPage
  │ CRUD rute antar kota
  │ Dijkstra algorithm untuk shortest path
  │ Google Maps visualization

ManagePromoPage
  │ CRUD kode promo
  │ Fields: code, discountType (percent/fixed), discountValue,
  │         expiryDate, isActive, createdAt
  │ Toggle aktif/nonaktif

ManageUsersPage
  │ StreamBuilder → users (all)
  │ Ubah role: user ↔ admin ↔ super_admin
  │ Toggle suspend (isSuspended)
  │ Search by nama/email

TransactionReportPage
  │ StreamBuilder → bookings (all)
  │ Filter by tanggal, status
  │ Summary: total pendapatan, jumlah tiket, dll
```

---

## 🗄️ FIRESTORE SCHEMA

### Collection: `users`

```
users/{uid}
  ├── email: String              ← "user@email.com"
  ├── namaLengkap: String        ← "Nama Pengguna"
  ├── nomorHp: String            ← "08123456789"
  ├── role: String               ← "user" | "admin" | "super_admin"
  ├── isSuspended: bool          ← false
  ├── profileImageUrl: String?   ← Cloudinary URL
  └── createdAt: Timestamp
```

### Collection: `bookings`

```
bookings/{autoId}
  ├── bookingId: String          ← same as doc ID
  ├── bookingCode: String        ← "TRV-ABC123" (human-readable)
  ├── userId: String             ← users/{uid}
  ├── userName: String
  ├── fleetId: String            ← fleets/{id}
  ├── fleetName: String
  ├── routeId: String?
  ├── origin: String             ← "Jakarta"
  ├── destination: String        ← "Bandung"
  ├── departureDate: Timestamp
  ├── seatNumbers: List<int>     ← [1, 2]
  ├── seatsBooked: int           ← 2
  ├── totalPrice: num            ← 150000
  ├── status: String             ← "pending" | "paid" | "used" | "cancelled"
  ├── promoCode: String?
  ├── discountAmount: num?
  ├── createdAt: Timestamp
  └── updatedAt: Timestamp
```

### Collection: `fleets`

```
fleets/{autoId}
  ├── name: String               ← "Bus Eksekutif A"
  ├── description: String?
  ├── imageUrl: String           ← Cloudinary URL
  ├── totalSeats: int            ← 40
  ├── availableSeats: int        ← 35
  ├── driverId: String           ← users/{uid} | "" (kosong)
  ├── driverName: String         ← "Nama Sopir" | ""
  └── updatedAt: Timestamp
```

### Collection: `routes`

```
routes/{autoId}
  ├── origin: String
  ├── destination: String
  ├── distance: num              ← dalam KM (Dijkstra weight)
  ├── duration: num              ← dalam menit
  ├── price: num
  ├── waypoints: List<Map>?      ← intermediate stops
  └── isActive: bool
```

### Collection: `promo_codes`

```
promo_codes/{autoId}
  ├── code: String               ← "DISKON10"
  ├── discountType: String       ← "percent" | "fixed"
  ├── discountValue: num         ← 10 (%) atau 50000 (Rp)
  ├── isActive: bool
  ├── expiryDate: Timestamp
  ├── usageLimit: int?
  ├── usedCount: int?
  └── createdAt: Timestamp
```

---

## 🔄 STATUS LIFECYCLE — BOOKING

```
                    ┌────────────────┐
                    │    PENDING     │  ← Booking dibuat, belum bayar
                    └───────┬────────┘
                            │
              ┌─────────────┼─────────────┐
              │             │             │
              ▼             ▼             │
     ┌────────────┐  ┌───────────┐       │
     │   PAID     │  │ CANCELLED │       │
     │ (Lunas)    │  │ (Batal)   │       │
     └──────┬─────┘  └───────────┘       │
            │     ← user batalkan        │
            │       sebelum bayar        │
            │       (seats dikembalikan) │
            ▼                            │
     ┌────────────┐                      │
     │    USED    │  ← Tiket di-scan     │
     │ (Digunakan)│    oleh Supir       │
     └────────────┘    via QR Scanner    │
                                         │
                    ┌────────────────┐    │
                    │  COMPLETED     │────┘  ← Legacy (backward compat)
                    │ (Selesai lama) │         treated same as USED
                    └────────────────┘
```

---

## 🔗 RELASI ANTAR ENTITAS

```
┌──────────┐       ┌──────────────┐       ┌───────────┐
│  USERS   │       │   BOOKINGS   │       │  FLEETS   │
│          │       │              │       │           │
│ uid ─────┼──1:N──┼─▶ userId     │       │ id ───────┼──┐
│ role     │       │   fleetId ──┼───N:1──┼─▶ (ref)   │  │
│ email    │       │   status    │       │ name      │  │
│ nama     │       │   seats     │       │ seats     │  │
│          │       │   price     │       │           │  │
│ (admin)──┼──1:1──┼─────────────┼───────┼─▶ driverId│  │
│          │       │              │       │ driverName│  │
└──────────┘       └──────────────┘       └───────────┘
                                                │
                   ┌──────────────┐             │
                   │   ROUTES     │─────────────┘
                   │              │   (armada beroperasi di rute)
                   │ origin       │
                   │ destination  │
                   │ distance     │ ← Dijkstra weight
                   │ price        │
                   └──────────────┘

                   ┌──────────────┐
                   │ PROMO_CODES  │
                   │              │   (applied at checkout)
                   │ code         │
                   │ discount     │
                   │ isActive     │
                   │ expiryDate   │
                   └──────────────┘
```

---

## 📱 PACKAGES UTAMA

| Package | Kegunaan |
|---------|----------|
| `firebase_core` | Inisialisasi Firebase |
| `firebase_auth` | Autentikasi (email/password) |
| `cloud_firestore` | Database realtime (CRUD + streams) |
| `google_fonts` | Typography (Plus Jakarta Sans, Inter) |
| `iconsax` | Icon library |
| `flutter_animate` | Animasi deklaratif |
| `mobile_scanner` | QR Code scanner (kamera) |
| `qr_flutter` | Generate QR Code pada e-ticket |
| `google_maps_flutter` | Peta Google Maps |
| `image_picker` | Ambil foto dari galeri |
| `http` | HTTP client (Cloudinary upload) |
| `intl` | Formatting tanggal & mata uang (id_ID) |
| `pdf` / `printing` | Generate & share PDF e-ticket |

---

## ⚠️ KNOWN ISSUES & CATATAN

### Composite Index (Firestore)
Beberapa query yang menggabungkan `where` + `orderBy` pada field berbeda membutuhkan **composite index** di Firebase Console. Sudah di-handle dengan **client-side sort**:

| Collection | Query | Status |
|------------|-------|--------|
| `promo_codes` | `isActive == true` + `orderBy createdAt` | ✅ Client-side sort |
| `users` | `role == 'admin'` + `orderBy namaLengkap` | ✅ Client-side sort |
| `bookings` | `fleetId == x` + `status in [...]` + `orderBy createdAt` | ⚠️ Perlu index / client-side fix |

### Permission (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.CAMERA"/>    ← QR Scanner
<uses-permission android:name="android.permission.INTERNET"/>  ← default Flutter
```

### External Services
| Service | Kegunaan |
|---------|----------|
| **Cloudinary** | Image hosting (fleet images, profile photos) |
| **Google Maps Platform** | Peta rute |
| **Firebase Auth** | Autentikasi |
| **Cloud Firestore** | Database |

---

## 🎯 RINGKASAN ENTRYPOINTS PER ROLE

| Aksi | User | Admin (Supir) | Super Admin |
|------|------|---------------|-------------|
| Login | ✅ | ✅ | ✅ |
| Cari Rute | ✅ | ❌ | ❌ |
| Booking Tiket | ✅ | ❌ | ❌ |
| Lihat E-Ticket | ✅ | ❌ | ❌ |
| Riwayat Booking | ✅ | ❌ | ❌ |
| Lihat Promo | ✅ | ❌ | ❌ |
| Scan QR Tiket | ❌ | ✅ (FAB) | ❌ |
| Dashboard Sopir | ❌ | ✅ | ❌ |
| Manifest Penumpang | ❌ | ✅ | ❌ |
| Kelola Armada | ❌ | ❌ | ✅ |
| Assign Supir | ❌ | ❌ | ✅ |
| Kelola Rute | ❌ | ❌ | ✅ |
| Kelola Promo | ❌ | ❌ | ✅ |
| Kelola User/Role | ❌ | ❌ | ✅ |
| Laporan Transaksi | ❌ | ❌ | ✅ |
| Edit Profil | ✅ | ✅ | ✅ |
| Logout | ✅ | ✅ | ✅ |

---

> **File ini**: `ETRAVEL_SYSTEM_FLOWMAP.md`
> **Lokasi**: Root project (`d:\Downloads\TRAVELLL\`)

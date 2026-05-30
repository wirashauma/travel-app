# 3. Perancangan Layanan Backend (Firebase Backend-as-a-Service)

## 3.1 Arsitektur Komunikasi Data

Sistem E-Travel menggunakan arsitektur **serverless** dengan pendekatan **Backend-as-a-Service (BaaS)** yang disediakan oleh **Google Firebase**. Berbeda dengan arsitektur REST API tradisional yang memerlukan server backend terpisah, sistem ini berkomunikasi langsung dari aplikasi Flutter ke layanan Firebase menggunakan **Firebase SDK**.

Firebase SDK menangani seluruh proses autentikasi, penyimpanan data, dan sinkronisasi data secara *real-time* tanpa memerlukan server perantara (*middleware*). Protokol komunikasi yang digunakan oleh Firebase SDK secara internal adalah **gRPC** dan **WebSocket**, bukan HTTP REST konvensional. Hal ini memungkinkan fitur *real-time streaming* dimana perubahan data di server langsung terpropagasi ke aplikasi klien tanpa perlu melakukan *polling*.

Berikut adalah diagram arsitektur komunikasi data pada sistem E-Travel:

```
┌──────────────────────────────────────────────────────────────────┐
│                    ARSITEKTUR SISTEM E-TRAVEL                    │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────┐         Firebase SDK (gRPC/WebSocket)      │
│  │   Flutter App     │                                           │
│  │                   │         ┌──────────────────────────┐      │
│  │  ┌─────────────┐  │────────►│   Firebase Authentication │      │
│  │  │ AuthService  │  │        │  (Registrasi, Login,     │      │
│  │  └─────────────┘  │        │   Google Sign-In)        │      │
│  │                   │        └──────────────────────────┘      │
│  │  ┌─────────────┐  │         ┌──────────────────────────┐      │
│  │  │BookingService│  │────────►│   Cloud Firestore        │      │
│  │  └─────────────┘  │        │  (Database NoSQL)        │      │
│  │                   │        │  - bookings              │      │
│  │  ┌─────────────┐  │        │  - fleets                │      │
│  │  │ StreamBuilder│  │◄───────│  - users                 │      │
│  │  │ (Real-time)  │  │        │  - routes                │      │
│  │  └─────────────┘  │        │  - seat_locks            │      │
│  └──────────────────┘         │  - promo_codes           │      │
│                               └──────────────────────────┘      │
│         HTTP REST (Hanya Layanan Pihak Ketiga)                  │
│  ┌──────────────────┐         ┌──────────────────────────┐      │
│  │EmailTicketService │────────►│  EmailJS (Kirim E-Tiket) │      │
│  │EditProfilePage    │────────►│  Cloudinary (Upload Foto)│      │
│  └──────────────────┘         └──────────────────────────┘      │
└──────────────────────────────────────────────────────────────────┘
```

### Keuntungan Arsitektur Serverless Firebase:

| No | Keuntungan | Keterangan |
|----|-----------|------------|
| 1 | *Real-time synchronization* | Data otomatis tersinkronisasi ke semua klien yang terhubung tanpa *polling* |
| 2 | *Atomic transactions* | Operasi pemesanan kursi menggunakan Firestore Transaction sehingga terhindar dari *race condition* |
| 3 | Tanpa server backend | Tidak memerlukan pengelolaan server, mengurangi biaya infrastruktur |
| 4 | Skalabilitas otomatis | Firebase menangani *scaling* secara otomatis sesuai jumlah pengguna |
| 5 | Keamanan terintegrasi | Firebase Security Rules melindungi akses data pada level *collection* dan *document* |

---

## 3.2 Layanan Autentikasi (Firebase Authentication)

Sistem autentikasi pada E-Travel menggunakan **Firebase Authentication** yang menangani proses registrasi, login, dan manajemen sesi pengguna. Firebase Authentication secara otomatis mengelola *token* autentikasi (ID Token) tanpa perlu dikelola secara manual oleh *developer*. Seluruh layanan autentikasi diimplementasikan pada kelas `AuthService` yang bersifat *static*.

### a. Registrasi Pengguna

Layanan ini memungkinkan pengguna baru mendaftarkan akun ke dalam sistem.

| Aspek | Detail |
|-------|--------|
| **Service Method** | `AuthService.register()` |
| **Parameter Input** | `email` (String, wajib), `password` (String, wajib), `namaLengkap` (String, wajib), `nomorHp` (String, opsional) |
| **Return Type** | `Future<User?>` |
| **Operasi Firebase** | 1. `FirebaseAuth.createUserWithEmailAndPassword(email, password)` — membuat akun di Firebase Auth |
| | 2. `user.updateDisplayName(namaLengkap)` — menyimpan nama pada profil Auth |
| | 3. `Firestore.collection('users').doc(uid).set({...})` — membuat dokumen profil pengguna |

**Struktur data yang disimpan ke Firestore (`users/{uid}`):**

| Field | Tipe | Keterangan |
|-------|------|------------|
| `uid` | String | ID unik pengguna dari Firebase Auth |
| `email` | String | Alamat email pengguna |
| `namaLengkap` | String | Nama lengkap pengguna |
| `nomorHp` | String | Nomor handphone (opsional) |
| `role` | String | Peran pengguna, default: `'user'` |
| `isSuspended` | bool | Status akun ditangguhkan, default: `false` |
| `createdAt` | Timestamp | Waktu pembuatan akun (server timestamp) |

**Respons:**
- **Berhasil:** Mengembalikan objek `User` yang berisi `uid`, `email`, dan `displayName`.
- **Gagal:** Melempar `FirebaseAuthException` dengan kode error seperti `email-already-in-use`, `weak-password`, atau `invalid-email`.

---

### b. Login Pengguna

Layanan ini memungkinkan pengguna yang telah terdaftar untuk masuk ke dalam sistem.

| Aspek | Detail |
|-------|--------|
| **Service Method** | `AuthService.login()` |
| **Parameter Input** | `email` (String, wajib), `password` (String, wajib) |
| **Return Type** | `Future<Map<String, dynamic>>` |
| **Operasi Firebase** | 1. `FirebaseAuth.signInWithEmailAndPassword(email, password)` — verifikasi kredensial |
| | 2. `Firestore.collection('users').doc(uid).get()` — membaca profil dan role pengguna |

**Respons:**
- **Berhasil:** Mengembalikan `Map` berisi data pengguna termasuk `role` (`'user'`, `'admin'`, atau `'super_admin'`).
- **Gagal:** Melempar `FirebaseAuthException` dengan kode `user-not-found`, `wrong-password`, atau `user-disabled`.

**Mekanisme *Role-Based Access Control* (RBAC):**

Setelah login berhasil, sistem membaca field `role` dari dokumen pengguna di Firestore untuk menentukan halaman navigasi:

| Role | Halaman Utama | Fitur yang Diakses |
|------|--------------|-------------------|
| `user` | Beranda Pengguna | Pencarian tiket, pemesanan, riwayat booking, e-tiket |
| `admin` (Sopir) | Dashboard Sopir | Manifest penumpang, scanner QR tiket, dashboard perjalanan |
| `super_admin` | Dashboard Super Admin | Manajemen armada, rute, pengguna, promo, laporan transaksi |

---

### c. Login dengan Google

Selain login manual, sistem juga menyediakan opsi masuk menggunakan akun Google.

| Aspek | Detail |
|-------|--------|
| **Implementasi** | Halaman `LoginPage` |
| **Package** | `google_sign_in` |
| **Operasi Firebase** | 1. `GoogleSignIn().signIn()` → mendapatkan `GoogleSignInAccount` |
| | 2. `GoogleSignInAuthentication` → mengambil `accessToken` dan `idToken` |
| | 3. `FirebaseAuth.signInWithCredential(GoogleAuthProvider.credential(...))` |

---

### d. Logout

| Aspek | Detail |
|-------|--------|
| **Service Method** | `AuthService.logout()` |
| **Return Type** | `Future<void>` |
| **Operasi Firebase** | `FirebaseAuth.signOut()` — menghapus sesi autentikasi lokal |

---

### e. Layanan Manajemen Pengguna (Super Admin)

| Service Method | Parameter | Operasi Firestore | Keterangan |
|----------------|-----------|-------------------|------------|
| `updateUserRole()` | `uid`, `newRole` | `users/{uid}.update({'role': newRole})` | Mengubah peran pengguna |
| `toggleSuspend()` | `uid`, `isSuspended` | `users/{uid}.update({'isSuspended': ...})` | Menangguhkan/mengaktifkan akun |
| `updateProfile()` | `uid`, `namaLengkap`, `nomorHp`, `email` | `users/{uid}.update({...})` | Memperbarui profil pengguna |
| `fetchAllUsers()` | — | `users.orderBy('createdAt').get()` | Mengambil seluruh data pengguna |
| `usersStream()` | — | `users.orderBy('createdAt').snapshots()` | Stream *real-time* daftar pengguna |

---

## 3.3 Layanan Pemesanan (Booking Service)

Layanan pemesanan merupakan inti dari sistem E-Travel. Seluruh operasi pemesanan diimplementasikan pada kelas `BookingService` menggunakan pola **Firestore Transaction** untuk menjamin konsistensi data dan mencegah *race condition* (dua pengguna memesan kursi yang sama secara bersamaan).

### Arsitektur Anti-Ghost-Seat

Sistem menggunakan pola **"Timestamp Expiration"** dengan dokumen `seat_locks` untuk menghindari *ghost seat* (kursi yang terkunci oleh pemesanan yang tidak diselesaikan):

```
┌────────────────────────────────────────────────────────────┐
│              POLA ANTI GHOST-SEAT                          │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  seat_locks/{fleetId}_{tanggal}                            │
│  ┌──────────────────────────────────────────────┐          │
│  │ seats: {                                      │          │
│  │   "A1": { bookingId, userId, status,          │          │
│  │           expiryDate (15 menit) },             │          │
│  │   "A2": { bookingId, userId, status: "paid",  │          │
│  │           expiryDate: null (permanen) },       │          │
│  │ }                                             │          │
│  └──────────────────────────────────────────────┘          │
│                                                            │
│  ATURAN:                                                   │
│  • pending + belum expired + milik user lain → TERKUNCI    │
│  • pending + sudah expired → TERSEDIA (overwrite)          │
│  • pending + milik user sendiri → TERSEDIA (re-book)       │
│  • paid / used / validated → TERJUAL (permanen)            │
│  • Batas waktu pembayaran: 15 menit                        │
└────────────────────────────────────────────────────────────┘
```

---

### a. Pemesanan Travel (Create Booking)

Layanan ini memungkinkan pengguna memesan kursi travel berdasarkan armada dan tanggal keberangkatan.

| Aspek | Detail |
|-------|--------|
| **Service Method** | `BookingService.createBooking()` |
| **Parameter Input** | `BookingModel booking` (berisi `userId`, `fleetId`, `selectedSeatLabels`, `seatsBooked`, `departureDate`, `origin`, `destination`, `totalPrice`, dll.) |
| **Return Type** | `Future<BookingModel>` |
| **Mekanisme** | Firestore Transaction (atomic) |

**Alur Transaksi (8 Langkah Atomik):**

| Langkah | Operasi | Keterangan |
|---------|---------|------------|
| 1 | `READ seat_locks/{fleetId}_{tanggal}` | Membaca peta kunci kursi saat ini |
| 2 | `READ fleets/{fleetId}` | Membaca data armada (totalSeats, nama) |
| 3 | Validasi kursi vs. peta kunci | Mengecek setiap kursi yang dipilih: apakah sudah terjual (`paid`/`used`) atau dikunci pengguna lain (`pending` aktif) |
| 4 | Hitung ketersediaan kursi | Menghitung kursi tersedia dari `seat_locks` secara *real-time* (bukan dari field statis) |
| 5 | Generate kode booking | Format: `TRV-XXX999` (3 huruf + 3 angka acak) |
| 6 | `WRITE seat_locks` | Menambahkan entri kursi baru dengan status `'pending'` dan `expiryDate` (15 menit) |
| 7 | `WRITE bookings/{new_id}` | Membuat dokumen booking baru |
| 8 | `WRITE fleets/{fleetId}` | Memperbarui jumlah kursi tersedia |

**Struktur Dokumen Booking (`bookings/{bookingId}`):**

| Field | Tipe | Keterangan |
|-------|------|------------|
| `id` | String | ID dokumen Firestore |
| `userId` | String | ID pengguna yang memesan |
| `userName` | String | Nama pengguna |
| `fleetId` | String | ID armada yang dipesan |
| `fleetName` | String | Nama armada |
| `routeId` | String? | ID rute (opsional) |
| `origin` | String | Kota asal |
| `destination` | String | Kota tujuan |
| `departureDate` | String | Tanggal keberangkatan |
| `seatNumbers` | List\<int> | Nomor kursi yang dipesan |
| `selectedSeatLabels` | List\<String> | Label kursi (misal: "A1", "B2") |
| `seatsBooked` | int | Jumlah kursi yang dipesan |
| `totalPrice` | int | Total harga (dalam Rupiah) |
| `status` | String | Status booking (lihat tabel di bawah) |
| `bookingCode` | String | Kode booking unik (TRV-XXX999) |
| `expiryDate` | Timestamp | Batas waktu pembayaran |
| `createdAt` | Timestamp | Waktu pembuatan (server timestamp) |
| `updatedAt` | Timestamp | Waktu pembaruan terakhir |

**Status Pemesanan (Booking Lifecycle):**

| Status | Keterangan | Transisi Dari |
|--------|------------|---------------|
| `pending` | Pemesanan dibuat, menunggu pembayaran (15 menit) | — (awal) |
| `paid` | Pembayaran dikonfirmasi | `pending` |
| `validated` | Tiket telah divalidasi sebelum keberangkatan | `paid` |
| `used` | Tiket telah di-scan saat keberangkatan | `paid` atau `validated` |
| `completed` | Perjalanan selesai (legacy) | `used` |
| `cancelled` | Pemesanan dibatalkan / kedaluwarsa | `pending` |

```
pending ──► paid ──► validated ──► used ──► completed
   │                                │
   └──► cancelled                   └──► completed
```

**Respons:**
- **Berhasil:** Mengembalikan `BookingModel` lengkap dengan `id`, `bookingCode`, dan `expiryDate`.
- **Gagal - Kursi sudah terisi:** Melempar `SeatAlreadyBookedException` berisi daftar kursi yang konflik.
- **Gagal - Kursi tidak cukup:** Melempar `InsufficientSeatsException` berisi jumlah kursi yang tersedia.
- **Gagal - Armada tidak ditemukan:** Melempar `FleetNotFoundException`.

---

### b. Konfirmasi Pembayaran

Layanan ini mengubah status pemesanan dari `pending` menjadi `paid` setelah pembayaran dikonfirmasi.

| Aspek | Detail |
|-------|--------|
| **Service Method** | `BookingService.confirmPayment()` |
| **Parameter Input** | `bookingId` (String) |
| **Return Type** | `Future<void>` |
| **Mekanisme** | Firestore Transaction (atomic) |

**Alur Transaksi:**

| Langkah | Operasi | Keterangan |
|---------|---------|------------|
| 1 | `READ bookings/{bookingId}` | Membaca data booking |
| 2 | `READ seat_locks/{fleetId}_{tanggal}` | Membaca peta kunci kursi |
| 3 | `WRITE bookings/{bookingId}` | Update `status: 'paid'`, hapus `expiryDate` |
| 4 | `WRITE seat_locks` | Update setiap entri kursi: `status: 'paid'`, hapus `expiryDate` (kunci permanen) |

---

### c. Pembatalan Pemesanan

Layanan ini membatalkan pemesanan yang masih berstatus `pending`, melepas kunci kursi, dan mengembalikan kuota kursi.

| Aspek | Detail |
|-------|--------|
| **Service Method** | `BookingService.cancelBooking()` |
| **Parameter Input** | `bookingId` (String) |
| **Return Type** | `Future<void>` |
| **Mekanisme** | Firestore Transaction (atomic, 3 fase) |

**Alur Transaksi (3 Fase):**

| Fase | Operasi | Keterangan |
|------|---------|------------|
| **Fase 1 - READ** | Baca `bookings/{id}`, `seat_locks/{id}`, `fleets/{id}` | Mengumpulkan seluruh data yang diperlukan |
| **Fase 2 - LOGIC** | Hapus entri kursi dari peta kunci, hitung ulang kursi tersedia | Validasi dan persiapan data |
| **Fase 3 - WRITE** | Update booking → `cancelled`, update `seat_locks`, update `fleets.availableSeats` | Seluruh penulisan dilakukan sekaligus |

---

### d. Pembersihan Otomatis Booking Kedaluwarsa

Layanan ini berfungsi sebagai *Garbage Collector* sisi klien untuk membersihkan pemesanan `pending` yang telah melewati batas waktu 15 menit.

| Aspek | Detail |
|-------|--------|
| **Service Method** | `BookingService.cleanupExpiredBookings()` |
| **Parameter Input** | `fleetId` (String), `departureDate` (String) |
| **Return Type** | `Future<int>` — jumlah booking yang dibersihkan |
| **Dipanggil Saat** | Inisialisasi halaman pemilihan kursi (*Seat Selection Page*) |

**Alur:**
1. Query `bookings` dimana `fleetId` = X, `departureDate` = Y, `status` = `'pending'`
2. Untuk setiap dokumen, cek `expiryDate` < sekarang
3. Jika sudah kedaluwarsa, panggil `cancelBooking()` untuk setiap booking tersebut
4. Mengembalikan jumlah total booking yang dibersihkan

---

## 3.4 Layanan Data Real-Time (Stream)

Salah satu keunggulan utama arsitektur Firebase adalah kemampuan **streaming data secara *real-time***. Sistem E-Travel memanfaatkan fitur `snapshots()` dari Cloud Firestore yang menggunakan **WebSocket** untuk mengirimkan perubahan data secara instan ke aplikasi klien.

Widget `StreamBuilder` pada Flutter digunakan untuk mendengarkan perubahan data dan memperbarui antarmuka secara otomatis tanpa perlu *refresh* manual.

### Daftar Stream Real-Time pada Sistem E-Travel:

| No | Service Method / Stream | Koleksi | Kegunaan | Digunakan Pada |
|----|------------------------|---------|----------|----------------|
| 1 | `BookingService.userBookingsStream(userId)` | `bookings` | Daftar booking pengguna secara *real-time* | Halaman Riwayat Booking |
| 2 | `BookingService.bookingStream(bookingId)` | `bookings` | Status tiket *live* (pending→paid→used) | Halaman E-Tiket Live |
| 3 | `BookingService.fleetBookingsStream(fleetId)` | `bookings` | Manifest penumpang untuk sopir | Halaman Manifest Perjalanan |
| 4 | `AuthService.usersStream()` | `users` | Daftar pengguna untuk manajemen | Halaman Manajemen Pengguna |
| 5 | Stream `bookings` + `fleets` (nested) | `bookings`, `fleets` | Ketersediaan kursi *real-time* | Halaman Pilih Armada, Pencarian Tiket |
| 6 | Stream `fleets.snapshots()` | `fleets` | Daftar armada untuk CRUD | Halaman Manajemen Armada |
| 7 | Stream `routes.snapshots()` | `routes` | Daftar rute untuk CRUD | Halaman Manajemen Rute |
| 8 | Stream `promo_codes.snapshots()` | `promo_codes` | Daftar kode promo | Halaman Promo & Manajemen Promo |
| 9 | Stream 3 koleksi (nested) | `bookings`, `fleets`, `routes` | Statistik dashboard | Dashboard Super Admin |
| 10 | Stream `users/{uid}.snapshots()` | `users` | Profil pengguna & deteksi suspend | Navigasi Utama |

---

## 3.5 Struktur Koleksi Firebase (Database Design)

Sistem E-Travel menggunakan **Cloud Firestore** (database NoSQL *document-oriented*) dengan 7 koleksi utama:

### a. Koleksi `users`

Menyimpan data profil dan peran pengguna.

| Field | Tipe | Keterangan |
|-------|------|------------|
| `uid` | String | ID unik dari Firebase Auth |
| `email` | String | Alamat email |
| `namaLengkap` | String | Nama lengkap |
| `nomorHp` | String | Nomor telepon |
| `role` | String | `'user'` \| `'admin'` \| `'super_admin'` |
| `photoUrl` | String | URL foto profil (Cloudinary) |
| `isSuspended` | bool | Status penangguhan akun |
| `createdAt` | Timestamp | Waktu pembuatan |

### b. Koleksi `fleets`

Menyimpan data armada transportasi.

| Field | Tipe | Keterangan |
|-------|------|------------|
| `name` | String | Nama armada (misal: "Sumbar Express 01") |
| `description` | String | Deskripsi armada |
| `imageUrl` | String | URL gambar armada (Cloudinary) |
| `totalSeats` | int | Jumlah total kursi |
| `availableSeats` | int | Jumlah kursi tersedia (counter) |
| `vehicleType` | String | Jenis kendaraan |
| `origin` | String | Kota asal |
| `destination` | String | Kota tujuan |
| `driverId` | String | ID sopir yang ditugaskan |
| `createdAt` | Timestamp | Waktu pembuatan |
| `updatedAt` | Timestamp | Waktu pembaruan |

### c. Koleksi `bookings`

Menyimpan data pemesanan travel.

*(Struktur field telah dijelaskan pada Tabel 3.3a)*

### d. Koleksi `seat_locks`

Menyimpan peta kunci kursi per armada per tanggal. Dokumen ID menggunakan pola `{fleetId}_{tanggalKeberangkatan}`.

| Field | Tipe | Keterangan |
|-------|------|------------|
| `fleetId` | String | ID armada |
| `departureDate` | String | Tanggal keberangkatan |
| `seats` | Map | Peta kursi: `{"A1": {bookingId, userId, status, expiryDate}, ...}` |

### e. Koleksi `routes`

Menyimpan data rute perjalanan antar kota untuk algoritma Dijkstra.

| Field | Tipe | Keterangan |
|-------|------|------------|
| `from` | String | ID kota asal |
| `to` | String | ID kota tujuan |
| `distance` | double | Jarak tempuh (km) |
| `price` | int | Harga per penumpang (Rupiah) |
| `duration` | int | Estimasi waktu tempuh (menit) |

### f. Koleksi `promo_codes`

Menyimpan data kode promo diskon.

| Field | Tipe | Keterangan |
|-------|------|------------|
| `code` | String | Kode promo unik |
| `discount` | int | Nilai diskon (persentase atau nominal) |
| `isActive` | bool | Status aktif/nonaktif |
| `expiryDate` | Timestamp | Tanggal kedaluwarsa promo |

### g. Koleksi `city_coordinates`

Menyimpan data koordinat kota untuk tampilan peta.

| Field | Tipe | Keterangan |
|-------|------|------------|
| `name` | String | Nama kota |
| `latitude` | double | Koordinat lintang |
| `longitude` | double | Koordinat bujur |
| `type` | String | `'kota'` atau `'kabupaten'` |
| `province` | String | Nama provinsi |

---

## 3.6 Integrasi Layanan Pihak Ketiga

Selain Firebase, sistem E-Travel mengintegrasikan dua layanan pihak ketiga melalui protokol **HTTP REST**:

### a. EmailJS — Pengiriman E-Tiket via Email

| Aspek | Detail |
|-------|--------|
| **Service** | `EmailTicketService` |
| **Endpoint** | `POST https://api.emailjs.com/api/v1.0/email/send` |
| **Format** | JSON |
| **Autentikasi** | Public Key (API Key) |
| **Timeout** | 15 detik |

**Parameter yang dikirim:**

| Parameter | Keterangan |
|-----------|------------|
| `user_name` | Nama penumpang |
| `user_email` | Email tujuan pengiriman |
| `booking_id` | ID booking |
| `route` | Rute perjalanan (asal → tujuan) |
| `fleet_name` | Nama armada |

### b. Cloudinary — Upload Gambar

| Aspek | Detail |
|-------|--------|
| **Digunakan Pada** | Upload foto profil, upload gambar armada |
| **Endpoint** | `POST https://api.cloudinary.com/v1_1/{cloud_name}/image/upload` |
| **Format** | Multipart Form Data |
| **Autentikasi** | Upload Preset (unsigned) |

---

## 3.7 Mekanisme Keamanan Akses (*Auth Guard*)

Sistem E-Travel menggunakan mekanisme pengecekan akses dua lapis (*two-layer auth check*) untuk mengamankan akses halaman:

### Lapis 1: Pengecekan Sesi (Splash Screen)

```
Aplikasi Dibuka
    │
    ▼
FirebaseAuth.currentUser != null ?
    │                    │
    ▼ Ya                 ▼ Tidak
Navigasi ke             Navigasi ke
MainNavigation          Halaman Login
```

### Lapis 2: Routing Berdasarkan Role (Main Navigation)

```
StreamBuilder → users/{uid}
    │
    ├─ isSuspended == true → Halaman Akun Ditangguhkan
    │
    ├─ role == 'super_admin' → Dashboard Super Admin
    │
    ├─ role == 'admin' → Dashboard Sopir + Scanner QR
    │
    └─ role == 'user' (default) → Beranda Pengguna
```

Pengecekan dilakukan secara *real-time* menggunakan `StreamBuilder`. Jika role pengguna diubah oleh super admin, navigasi pengguna akan berubah secara otomatis tanpa perlu login ulang. Begitu pula jika akun pengguna ditangguhkan (*suspended*), pengguna akan langsung melihat halaman "Akun Ditangguhkan".

---

## 3.8 Ringkasan Perbandingan: REST API vs Firebase SDK

Untuk memberikan konteks akademis, berikut perbandingan antara arsitektur REST API tradisional dengan arsitektur Firebase SDK yang digunakan pada sistem E-Travel:

| Aspek | REST API Tradisional | Firebase SDK (E-Travel) |
|-------|---------------------|------------------------|
| **Server Backend** | Diperlukan (Node.js, Laravel, dll.) | Tidak diperlukan (serverless) |
| **Protokol** | HTTP (request-response) | gRPC / WebSocket (*real-time*) |
| **Format Data** | JSON via HTTP body | Objek Dart native via SDK |
| **Autentikasi** | Token manual (Bearer) | Otomatis oleh Firebase SDK |
| **Endpoint** | URL path (misal: `/api/bookings`) | Method SDK (misal: `Firestore.collection('bookings')`) |
| **Real-time** | Memerlukan WebSocket/SSE terpisah | Bawaan (`snapshots()`) |
| **Transaksi Atomik** | Bergantung pada implementasi server | Bawaan (`runTransaction()`) |
| **Skalabilitas** | Harus dikonfigurasi manual | Otomatis oleh Google Cloud |
| **Biaya Infrastruktur** | Server hosting (bulanan) | *Pay-as-you-go* (berbasis penggunaan) |

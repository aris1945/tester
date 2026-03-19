# DOMPIS - Ticket Management System

Aplikasi mobile **DOMPIS** (Ticket Management System) dibangun menggunakan **Flutter** untuk mengelola tiket gangguan, teknisi, dan absensi. Aplikasi mendukung 4 role pengguna dengan dashboard masing-masing.

---

## 📋 Daftar Isi

- [Tech Stack](#-tech-stack)
- [Fitur](#-fitur)
- [Arsitektur Project](#-arsitektur-project)
- [Struktur Folder](#-struktur-folder)
- [Setup & Instalasi](#-setup--instalasi)
- [Konfigurasi](#-konfigurasi)
- [API Endpoints](#-api-endpoints)
- [Role & Routing](#-role--routing)
- [Build APK](#-build-apk)

---

## 🛠 Tech Stack

| Teknologi | Versi | Keterangan |
|-----------|-------|------------|
| **Flutter** | SDK ^3.11.1 | Framework UI |
| **Dart** | ^3.11.1 | Bahasa pemrograman |
| **Riverpod** | ^2.6.1 | State management |
| **GoRouter** | ^14.8.1 | Navigasi & routing |
| **Dio** | ^5.4.0 | HTTP client |
| **Flutter Secure Storage** | ^9.2.4 | Penyimpanan token aman |
| **Google Fonts** | ^6.2.1 | Font (Inter) |
| **Image Picker** | ^1.1.2 | Upload bukti foto |
| **Intl** | ^0.19.0 | Format tanggal & waktu |
| **URL Launcher** | ^6.3.1 | Buka link eksternal |
| **Shared Preferences** | ^2.5.4 | Penyimpanan setting lokal |

---

## ✨ Fitur

### 🔐 Autentikasi
- Login dengan username & password
- JWT token management (access + refresh token)
- Auto-refresh token saat expired (401)
- Secure storage untuk token
- Auto-redirect berdasarkan role

### 👷 Teknisi
- Dashboard dengan statistik tiket
- Daftar tiket yang di-assign
- Detail tiket dengan upload bukti (evidence)
- Absensi masuk/keluar (check-in/check-out)

### 🛡 Admin
- Dashboard overview statistik tiket dengan visualisasi high-fidelity (Next.js style)
- Filter tiket canggih (Workzone, Jenis, Status, Flagging)
- Management penugasan teknisi (Assign/Reassign/Unassign) melalui bottom sheet interaktif
- Monitoring tiket B2C (Reguler, Gold, Platinum, Diamond) dan B2B (CCAN, Indibiz, Datin, dll)
- Menu Semesta untuk monitoring tiket harian seluruh area

### 🎨 Tampilan & Tema
- **Dynamic Dark/Light Mode**: Mendukung perubahan tema secara runtime
- **Slate Aesthetic**: Replikasi visual dari project Next.js original
- **Persistent Theme**: Pilihan tema tersimpan otomatis (SharedPreferences)
- Custom theme extension untuk color system (status, customer type)
- Reusable widgets (StatCard, TicketCard, AppDrawer)
- Animasi premium pada login screen dan transisi filter


---

## 🏗 Arsitektur Project

Aplikasi menggunakan arsitektur **layered** dengan pemisahan yang jelas:

```
┌─────────────────────────────────────────┐
│              Screens (UI)               │
│   login / teknisi / admin / helpdesk    │
│              / superadmin               │
├─────────────────────────────────────────┤
│            Providers (State)            │
│      auth_provider / api_providers      │
├─────────────────────────────────────────┤
│             Data Layer                  │
│   ┌─────────────┐  ┌────────────────┐   │
│   │   API Layer  │  │    Models      │   │
│   │  api_client  │  │  ticket.dart   │   │
│   │  auth_api    │  │  user.dart     │   │
│   │  ticket_api  │  │  technician    │   │
│   │  tech_api    │  │  attendance    │   │
│   │  attend_api  │  └────────────────┘   │
│   │  interceptor │                       │
│   │  token_store │                       │
│   └─────────────┘                        │
├─────────────────────────────────────────┤
│          Core (Constants/Theme)         │
│    constants / theme / utils            │
└─────────────────────────────────────────┘
```

---

## 📂 Struktur Folder

```
lib/
├── main.dart                          # Entry point aplikasi
├── router.dart                        # GoRouter konfigurasi & redirect
│
├── core/
│   ├── constants.dart                 # API base URL & endpoint paths
│   ├── theme.dart                     # Dynamic ThemeExtension & AppTheme
│   └── utils.dart                     # Helper functions (format tanggal, dll)
│
├── data/
│   ├── api/
│   │   ├── api_client.dart            # Dio client singleton + interceptors
│   │   ├── auth_api.dart              # Login, logout, get current user
│   │   ├── auth_interceptor.dart      # Auto-attach token & refresh on 401
│   │   ├── ticket_api.dart            # CRUD tiket, upload evidence
│   │   ├── technician_api.dart        # Data teknisi
│   │   ├── attendance_api.dart        # Check-in / check-out
│   │   └── token_storage.dart         # Secure storage (access token, role)
│   │
│   └── models/
│       ├── ticket.dart                # Model Ticket
│       ├── user.dart                  # Model User
│       ├── technician.dart            # Model Technician
│       └── attendance.dart            # Model Attendance
│
├── providers/
│   ├── auth_provider.dart             # AuthNotifier (login, logout, checkAuth)
│   ├── theme_provider.dart            # persistent ThemeMode notifier
│   └── api_providers.dart             # Riverpod providers untuk semua API
│
├── screens/
│   ├── login/
│   │   └── login_screen.dart          # Halaman login
│   ├── teknisi/
│   │   ├── teknisi_dashboard.dart     # Dashboard teknisi + list tiket
│   │   ├── ticket_detail_screen.dart  # Detail tiket + upload bukti
│   │   └── attendance_screen.dart     # Halaman absensi
│   ├── admin/
│   │   ├── admin_dashboard.dart       # Dashboard utama admin (B2C/B2B tabs)
│   └── admin_semesta_screen.dart  # Monitoring tiket harian seluruh area
│   ├── helpdesk/
│   │   └── helpdesk_dashboard.dart    # Dashboard helpdesk
│   └── superadmin/
│       └── superadmin_dashboard.dart   # Dashboard superadmin
│
└── widgets/
    ├── stat_card.dart                 # Widget kartu statistik
    ├── ticket_card.dart               # Widget kartu tiket
    ├── app_drawer.dart                # Sidebar navigasi global + theme toggle
    └── assign_technician_modal.dart   # Bottom sheet penugasan teknisi
```

---

## 🚀 Setup & Instalasi

### Prasyarat
- Flutter SDK ^3.11.1
- Android Studio / VS Code
- Android SDK (untuk build Android)

### Langkah Instalasi

```bash
# 1. Clone repository
git clone <repo-url>
cd flutter_app

# 2. Install dependencies
flutter pub get

# 3. Jalankan di emulator/device
flutter run
```

---

## ⚙ Konfigurasi

### API Base URL

Ubah base URL di `lib/core/constants.dart`:

```dart
class ApiConstants {
  static const String baseUrl = 'https://dompis.ta-branchsby.co.id';
  // ...
}
```

> **Catatan untuk development:**
> - Emulator Android: gunakan `http://10.0.2.2:3000`
> - Device fisik: gunakan IP komputer di jaringan yang sama, contoh `http://192.168.x.x:3000`

### Timeout Konfigurasi

Timeout diatur di `lib/data/api/api_client.dart`:

```dart
BaseOptions(
  connectTimeout: Duration(seconds: 15),
  receiveTimeout: Duration(seconds: 15),
)
```

---

## 🔌 API Endpoints

Base URL: `https://dompis.ta-branchsby.co.id`

### Auth
| Method | Endpoint | Keterangan |
|--------|----------|------------|
| POST | `/api/auth/login` | Login (username, password) |
| POST | `/api/auth/refresh` | Refresh access token |
| POST | `/api/auth/logout` | Logout |

### Tickets
| Method | Endpoint | Keterangan |
|--------|----------|------------|
| GET | `/api/tickets` | Daftar tiket |
| GET | `/api/tickets/daily` | Tiket hari ini |
| GET | `/api/tickets/stats` | Statistik tiket |
| GET | `/api/tickets/expired` | Tiket expired |
| GET | `/api/tickets/{id}/detail` | Detail tiket |
| GET | `/api/tickets/{id}/evidence` | Evidence tiket |
| GET | `/api/tickets/{id}/technicians` | Teknisi tiket |
| POST | `/api/tickets/update` | Update tiket |
| POST | `/api/tickets/pickup` | Ambil tiket |
| POST | `/api/tickets/close` | Tutup tiket |
| POST | `/api/tickets/assign` | Penugasan teknisi |
| POST | `/api/tickets/unassign` | Hapus penugasan teknisi |
| POST | `/api/tickets/upload-evidence` | Upload bukti foto |

### Users
| Method | Endpoint | Keterangan |
|--------|----------|------------|
| GET | `/api/users/me` | Profil user saat ini |
| GET | `/api/users/me/sa` | Profil user (superadmin) |
| GET | `/api/users/role/{roleId}` | User berdasarkan role |

### Technicians
| Method | Endpoint | Keterangan |
|--------|----------|------------|
| GET | `/api/technicians` | Daftar teknisi |
| GET | `/api/technicians/{id}` | Detail teknisi |
| GET | `/api/technicians/attendance/status` | Status absensi |
| POST | `/api/technicians/attendance` | Check-in / check-out |

### Dashboard & Dropdowns
| Method | Endpoint | Keterangan |
|--------|----------|------------|
| GET | `/api/dashboard/stats` | Statistik dashboard |
| GET | `/api/area` | Daftar area |
| GET | `/api/sa` | Daftar SA |
| GET | `/api/workzone` | Daftar workzone |

---

## 🛤 Role & Routing

Setelah login, user di-redirect otomatis berdasarkan role:

| Role | Route | Screen |
|------|-------|--------|
| `teknisi` | `/teknisi` | TeknisiDashboard |
| `admin` | `/admin` | AdminDashboard |
| `helpdesk` | `/helpdesk` | HelpdeskDashboard |
| `superadmin` | `/superadmin` | SuperadminDashboard |

### Route Tambahan (Teknisi)
| Route | Screen |
|-------|--------|
| `/teknisi/ticket/:id` | TicketDetailScreen |
| `/teknisi/attendance` | AttendanceScreen |

### Guard
- User yang belum login akan selalu di-redirect ke `/login`
- User yang sudah login tidak bisa akses `/login` (redirect ke dashboard)

---

## 📦 Build APK

```bash
# Build APK release
flutter build apk

# Build APK per-ABI (ukuran lebih kecil)
flutter build apk --split-per-abi

# Output APK ada di:
# build/app/outputs/flutter-apk/app-release.apk
```

> **Penting:** Pastikan `android/app/src/main/AndroidManifest.xml` sudah memiliki permission:
> ```xml
> <uses-permission android:name="android.permission.INTERNET"/>
> ```

---

## 📄 Lisensi

Private project - Hak cipta dilindungi.
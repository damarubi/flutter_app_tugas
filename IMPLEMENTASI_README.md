# Absen.in - Aplikasi Absensi dengan Geofencing

Aplikasi absensi karyawan berbasis Flutter dengan fitur geofencing menggunakan MapTiler API.

## Fitur Utama

✅ **Map dengan Geofencing** - Menggunakan MapTiler API dengan zone radius 100 meter
✅ **Deteksi Lokasi Real-time** - Mendeteksi apakah user berada di dalam atau di luar zona
✅ **Rekap Absensi** - Menampilkan data Clock In dan Clock Out karyawan
✅ **Filter Tanggal** - Melihat rekap absensi berdasarkan tanggal yang dipilih
✅ **UI Modern** - Desain sesuai dengan mockup yang diberikan

## Screenshot

![Home Page Design](https://via.placeholder.com/300x600?text=Absen.in+Home+Page)

## Teknologi yang Digunakan

- **Flutter** - Framework utama
- **MapTiler API** - Untuk map tiles dengan kustomisasi
- **flutter_map** - Library untuk menampilkan peta
- **Geolocator** - Untuk mendapatkan lokasi user dan geofencing
- **Firebase Firestore** - Database untuk menyimpan data absensi
- **Firebase Auth** - Autentikasi user

## Instalasi

### 1. Clone Repository

```bash
git clone https://github.com/damarubi/flutter_app_tugas.git
cd flutter_app_tugas
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Konfigurasi MapTiler API Key

1. Daftar dan dapatkan API key gratis di [MapTiler Cloud](https://cloud.maptiler.com/)
2. Buka file `lib/map_widget.dart`
3. Ganti `YOUR_MAPTILER_API_KEY` dengan API key Anda:

```dart
const String mapTilerApiKey = 'YOUR_MAPTILER_API_KEY';
```

### 4. Konfigurasi Firebase

Pastikan Firebase sudah dikonfigurasi dengan benar:

- `firebase_options.dart` sudah ada
- File `google-services.json` (Android) dan `GoogleService-Info.plist` (iOS) sudah ditambahkan

### 5. Konfigurasi Permissions

#### Android (`android/app/src/main/AndroidManifest.xml`)

Tambahkan permissions berikut:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

#### iOS (`ios/Runner/Info.plist`)

Tambahkan keys berikut:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Aplikasi memerlukan akses lokasi untuk fitur geofencing absensi</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Aplikasi memerlukan akses lokasi untuk fitur geofencing absensi</string>
```

## Menjalankan Aplikasi

```bash
flutter run
```

## Struktur File Utama

```
lib/
├── main.dart                   # Entry point aplikasi
├── home_page.dart             # Halaman utama dengan map dan rekap absensi
├── map_widget.dart            # Widget map dengan geofencing
├── attendance_page.dart       # Halaman absensi (Clock In/Out)
├── login_page.dart           # Halaman login
├── register_page.dart        # Halaman registrasi
└── firebase_options.dart     # Konfigurasi Firebase
```

## Fitur Detail

### 1. Map dengan Geofencing

- Menggunakan MapTiler API untuk tiles map yang dapat dikustomisasi
- Lingkaran biru menunjukkan zona geofencing (radius 100 meter)
- Marker biru menunjukkan lokasi kantor
- Marker dengan icon person menunjukkan lokasi user saat ini
- Indikator status zona ditampilkan di bawah map

### 2. Status Laporan Absensi

- Tombol "Tanggal Laporan" untuk memilih tanggal
- Menampilkan status: "Anda belum absen hari ini" jika belum absen
- Tombol Clock In menampilkan waktu masuk
- Tombol Clock Out menampilkan waktu keluar
- Data diambil real-time dari Firebase Firestore

### 3. Geofencing

- Menggunakan `Geolocator` untuk menghitung jarak antara lokasi user dan kantor
- Radius geofencing: 100 meter
- Status ditampilkan: "You are inside the allowed zone" atau "You are outside the allowed zone"

## Kustomisasi

### Mengubah Lokasi Kantor

Edit file `lib/home_page.dart`:

```dart
final LatLng officeLocation = const LatLng(-7.7478, 110.3553); // Ganti dengan koordinat kantor Anda
```

### Mengubah Radius Geofencing

Edit file `lib/home_page.dart`:

```dart
final double geofenceRadius = 100.0; // Ubah radius dalam meter
```

### Mengubah Style Map

MapTiler menyediakan berbagai style map:

- `streets-v2` - Style default (streets)
- `basic-v2` - Style basic
- `hybrid` - Satellite dengan labels
- `satellite` - Satellite murni

Edit di `lib/map_widget.dart`:

```dart
urlTemplate: 'https://api.maptiler.com/maps/STYLE_NAME/{z}/{x}/{y}.png?key=$mapTilerApiKey'
```

## Troubleshooting

### Map tidak muncul

1. Pastikan API key MapTiler sudah benar
2. Cek koneksi internet
3. Periksa console untuk error

### Lokasi tidak terdeteksi

1. Pastikan permissions lokasi sudah diberikan
2. Aktifkan GPS di device
3. Untuk emulator, set lokasi manual

### Build error

```bash
flutter clean
flutter pub get
flutter run
```

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  firebase_core: ^4.2.0
  firebase_auth: ^6.1.1
  cloud_firestore: ^6.0.3
  firebase_storage: ^13.0.3
  image_picker: ^1.0.4
  geolocator: ^14.0.2
  flutter_map: ^8.2.2
  latlong2: ^0.9.1
  intl: ^0.19.0
  http: ^1.1.0
```

## Kontributor

- **Dika** - Developer

## Lisensi

MIT License

## Catatan Penting

⚠️ **Jangan lupa mengganti API key MapTiler dengan API key Anda sendiri!**

⚠️ **Pastikan Firebase sudah dikonfigurasi dengan benar**

⚠️ **Test geofencing di device fisik untuk hasil terbaik**

## Link Referensi

- [MapTiler Documentation](https://docs.maptiler.com/)
- [flutter_map Documentation](https://docs.fleaflet.dev/)
- [Geolocator Package](https://pub.dev/packages/geolocator)
- [Firebase Flutter](https://firebase.flutter.dev/)

---

**Happy Coding! 🚀**

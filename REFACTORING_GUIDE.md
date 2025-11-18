# 🎯 Panduan Refactoring - Clean Architecture

## ✅ Yang Sudah Dikerjakan

### 1. **Core Layer** ✨

Struktur dasar aplikasi yang dapat digunakan di seluruh project:

#### Constants

- `app_colors.dart` - Definisi warna aplikasi
- `app_strings.dart` - String constants untuk text
- `app_routes.dart` - Route names
- `app_constants.dart` - Konfigurasi umum (geofence radius, office locations, dll)

#### Theme

- `app_theme.dart` - Material theme dengan custom styling

#### Utils

- `validators.dart` - Validasi form (NIP, password, email, dll)

#### Errors

- `exceptions.dart` - Custom exceptions
- `failures.dart` - Failure classes untuk error handling

### 2. **Config Layer** 🔧

- `app_router.dart` - Centralized routing dengan `onGenerateRoute`

### 3. **Shared Layer** 🔄

#### Widgets

- `custom_button.dart` - Reusable button dengan loading state
- `custom_text_field.dart` - Custom input field dengan validasi
- `loading_widget.dart` - Loading indicator

#### Services

- `location_service.dart` - Service untuk geolocation & geofencing

### 4. **Authentication Feature** 🔐

Implementasi lengkap dengan Clean Architecture:

#### Domain Layer

- **Entity**: `user.dart`
- **Repository Interface**: `auth_repository.dart`
- **Use Cases**:
  - `login_usecase.dart`
  - `register_usecase.dart`
  - `logout_usecase.dart`

#### Data Layer

- **Model**: `user_model.dart` dengan Firebase serialization
- **Remote Data Source**: `auth_remote_datasource.dart` untuk Firebase Auth & Firestore
- **Repository Implementation**: `auth_repository_impl.dart`

#### Presentation Layer

- **Pages**:
  - `login_page.dart` - Menggunakan custom widgets & use cases
  - `register_page.dart` - Form registration dengan validasi

### 5. **Other Features** 📱

File-file existing sudah dipindahkan ke folder features dengan struktur yang benar:

- Home Feature (main_screen, home_page)
- Attendance Feature
- Profile Feature
- Face Recognition Feature

### 6. **Main App** 🚀

- `main.dart` sudah diupdate menggunakan:
  - `AppTheme.lightTheme`
  - `AppRouter.generateRoute`
  - Authentication state management dengan StreamBuilder

## 📋 Cara Menggunakan Struktur Baru

### 1. Menambah Halaman Baru

```dart
// Di app_routes.dart, tambahkan:
static const String newPage = '/new-page';

// Di app_router.dart, tambahkan case:
case AppRoutes.newPage:
  return MaterialPageRoute(builder: (_) => const NewPage());

// Navigasi:
Navigator.pushNamed(context, AppRoutes.newPage);
```

### 2. Menggunakan Custom Widgets

```dart
// Custom Button
CustomButton(
  text: 'Login',
  onPressed: () => _login(),
  isLoading: _isLoading,
)

// Custom Text Field
CustomTextField(
  controller: _nipController,
  labelText: 'NIP',
  prefixIcon: Icons.badge,
  validator: Validators.validateNIP,
)
```

### 3. Menggunakan Location Service

```dart
final locationService = LocationService();

// Get current position
final position = await locationService.getCurrentPosition();

// Check geofence
final isInside = await locationService.isWithinGeofence(
  centerLatitude: -7.7478,
  centerLongitude: 110.3553,
  radiusInMeters: 100.0,
);
```

### 4. Implementasi Use Case

```dart
// Initialize dependencies
final authDataSource = AuthRemoteDataSourceImpl(
  firebaseAuth: FirebaseAuth.instance,
  firestore: FirebaseFirestore.instance,
);
final authRepository = AuthRepositoryImpl(remoteDataSource: authDataSource);
final loginUseCase = LoginUseCase(authRepository);

// Use the use case
try {
  final user = await loginUseCase(
    nip: nipController.text,
    password: passwordController.text,
  );
  // Handle success
} catch (e) {
  // Handle error
}
```

## 🔄 Migration Path untuk Feature Lain

### Contoh: Refactor Attendance Feature

1. **Buat Domain Layer**

```
features/attendance/domain/
  ├── entities/
  │   └── attendance.dart
  ├── repositories/
  │   └── attendance_repository.dart
  └── usecases/
      ├── check_in_usecase.dart
      └── check_out_usecase.dart
```

2. **Buat Data Layer**

```
features/attendance/data/
  ├── models/
  │   └── attendance_model.dart
  ├── datasources/
  │   └── attendance_remote_datasource.dart
  └── repositories/
      └── attendance_repository_impl.dart
```

3. **Update Presentation Layer**

- Move business logic to use cases
- Use repository untuk data operations
- Keep UI logic minimal

## 🎨 Styling & Theming

Gunakan AppColors dari core/constants:

```dart
// Jangan hardcode colors
Container(color: Colors.blue) // ❌

// Gunakan AppColors
Container(color: AppColors.primary) // ✅
```

## 📝 Validation

Gunakan Validators dari core/utils:

```dart
TextFormField(
  validator: Validators.validateNIP,
)

TextFormField(
  validator: Validators.validatePassword,
)

TextFormField(
  validator: (value) => Validators.validateConfirmPassword(
    value,
    passwordController.text
  ),
)
```

## 🚀 Next Steps (Rekomendasi)

### 1. State Management

Tambahkan BLoC atau Riverpod untuk manage state:

```
features/auth/presentation/
  ├── bloc/
  │   ├── auth_bloc.dart
  │   ├── auth_event.dart
  │   └── auth_state.dart
  └── pages/
      └── login_page.dart
```

### 2. Dependency Injection

Gunakan GetIt untuk DI:

```dart
// config/di/injection_container.dart
final sl = GetIt.instance;

void init() {
  // Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: sl(),
      firestore: sl(),
    ),
  );
}
```

### 3. Unit Testing

Buat test untuk setiap layer:

```dart
// test/features/auth/domain/usecases/login_usecase_test.dart
void main() {
  late LoginUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginUseCase(mockRepository);
  });

  test('should login user successfully', () async {
    // Arrange
    when(mockRepository.login(any, any))
        .thenAnswer((_) async => tUser);

    // Act
    final result = await useCase(nip: '12345', password: 'password');

    // Assert
    expect(result, equals(tUser));
  });
}
```

## 💡 Tips & Best Practices

1. **Konsistensi Naming**

   - Classes: PascalCase
   - Files: snake_case
   - Variables: camelCase

2. **Folder Structure**

   - 1 file = 1 class (sebisa mungkin)
   - Group related files dalam folder

3. **Import Organization**

   ```dart
   // External packages
   import 'package:flutter/material.dart';

   // Internal packages
   import 'package:flutter_app_tugas/core/...';

   // Relative imports
   import '../widgets/custom_button.dart';
   ```

4. **Error Handling**

   - Gunakan try-catch
   - Show user-friendly error messages
   - Log errors untuk debugging

5. **Code Comments**
   ```dart
   /// Login user dengan NIP dan password
   ///
   /// Throws [AuthException] jika login gagal
   Future<User> login({required String nip, required String password});
   ```

## 📚 Resources

- [Flutter Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Clean Architecture in Flutter](https://resocoder.com/category/tutorials/flutter/clean-architecture/)
- [BLoC Pattern](https://bloclibrary.dev/)
- [Riverpod Documentation](https://riverpod.dev/)

---

## 🎉 Summary

Project sudah di-refactor dengan struktur enterprise-grade:

- ✅ Clean Architecture implementation
- ✅ Feature-first structure
- ✅ Reusable components
- ✅ Centralized configuration
- ✅ Better maintainability
- ✅ Ready for scaling

**Happy Coding! 🚀**

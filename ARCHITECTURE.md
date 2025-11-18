# Flutter App Tugas - Enterprise Architecture Documentation

## 📁 Struktur Folder (Clean Architecture)

Project ini telah di-refactor menggunakan **Clean Architecture** dan **Feature-First Structure** untuk scalability dan maintainability yang lebih baik.

```
lib/
├── main.dart                          # Entry point aplikasi
├── firebase_options.dart              # Firebase configuration
├── map_widget.dart                    # Map widget (legacy)
│
├── core/                              # Core utilities & shared resources
│   ├── constants/                     # Application constants
│   │   ├── app_colors.dart           # Color constants
│   │   ├── app_constants.dart        # General app constants
│   │   ├── app_routes.dart           # Route name constants
│   │   └── app_strings.dart          # String constants
│   ├── errors/                        # Error handling
│   │   ├── exceptions.dart           # Custom exceptions
│   │   └── failures.dart             # Failure classes
│   ├── theme/                         # App theming
│   │   └── app_theme.dart            # Material theme configuration
│   └── utils/                         # Utility functions
│       └── validators.dart           # Form validators
│
├── config/                            # App configuration
│   └── routes/                        # Routing configuration
│       └── app_router.dart           # Route generator
│
├── shared/                            # Shared across features
│   ├── services/                      # Shared services
│   │   └── location_service.dart     # Location & geofencing service
│   └── widgets/                       # Reusable widgets
│       ├── custom_button.dart        # Custom button widget
│       ├── custom_text_field.dart    # Custom input field
│       └── loading_widget.dart       # Loading indicator
│
└── features/                          # Feature modules (Clean Architecture)
    ├── auth/                          # Authentication feature
    │   ├── data/
    │   │   ├── datasources/
    │   │   │   └── auth_remote_datasource.dart
    │   │   ├── models/
    │   │   │   └── user_model.dart
    │   │   └── repositories/
    │   │       └── auth_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── user.dart
    │   │   ├── repositories/
    │   │   │   └── auth_repository.dart
    │   │   └── usecases/
    │   │       ├── login_usecase.dart
    │   │       ├── logout_usecase.dart
    │   │       └── register_usecase.dart
    │   └── presentation/
    │       └── pages/
    │           ├── login_page.dart
    │           └── register_page.dart
    │
    ├── home/                          # Home feature
    │   └── presentation/
    │       └── pages/
    │           ├── home_page.dart
    │           └── main_screen.dart
    │
    ├── attendance/                    # Attendance feature
    │   └── presentation/
    │       └── pages/
    │           └── attendance_page.dart
    │
    ├── face_recognition/              # Face recognition feature
    │   └── presentation/
    │       └── pages/
    │           ├── face_recognition_page.dart
    │           ├── camera_view_page.dart
    │           └── success_page.dart
    │
    └── profile/                       # Profile feature
        └── presentation/
            └── pages/
                └── profile_page.dart
```

## 🏗️ Clean Architecture Layers

### 1. **Domain Layer** (Business Logic)

- **Entities**: Pure Dart objects representing business models
- **Repositories**: Abstract contracts for data operations
- **Use Cases**: Business logic implementations

### 2. **Data Layer** (Data Management)

- **Data Sources**: Remote (Firebase) and Local data sources
- **Models**: Data Transfer Objects (DTOs) with serialization
- **Repository Implementations**: Concrete implementations of domain repositories

### 3. **Presentation Layer** (UI)

- **Pages**: Screen/Page widgets
- **Widgets**: Feature-specific UI components
- **State Management**: (Can be added with BLoC/Riverpod/Provider)

## 📦 Feature Organization

Setiap feature module memiliki struktur lengkap:

- ✅ **Self-contained**: Semua logic dalam satu folder
- ✅ **Independent**: Minimal dependency antar features
- ✅ **Testable**: Easy to write unit tests
- ✅ **Scalable**: Mudah menambah feature baru

## 🎨 Shared Resources

### Core

- **Constants**: Centralized configuration
- **Theme**: Consistent UI styling
- **Utils**: Helper functions & validators
- **Errors**: Centralized error handling

### Shared

- **Services**: Cross-feature services (Location, Storage, etc.)
- **Widgets**: Reusable UI components

## 🚀 Migration dari Struktur Lama

File-file lama telah dipindahkan ke struktur baru:

| File Lama                    | Lokasi Baru                                                   |
| ---------------------------- | ------------------------------------------------------------- |
| `login_page.dart`            | `features/auth/presentation/pages/login_page.dart`            |
| `register_page.dart`         | `features/auth/presentation/pages/register_page.dart`         |
| `home_page.dart`             | `features/home/presentation/pages/home_page.dart`             |
| `attendance_page.dart`       | `features/attendance/presentation/pages/attendance_page.dart` |
| `profile_page.dart`          | `features/profile/presentation/pages/profile_page.dart`       |
| `face_recognition_page.dart` | `features/face_recognition/presentation/pages/`               |

## 📝 Cara Menambah Feature Baru

1. Buat folder feature baru di `features/`
2. Tambahkan layer: `data/`, `domain/`, `presentation/`
3. Implementasikan:
   - Domain entities & use cases
   - Data sources & repositories
   - Presentation pages & widgets
4. Update routing di `config/routes/app_router.dart`

## 🔧 State Management (Rekomendasi)

Untuk project enterprise, disarankan menambahkan state management:

- **BLoC** (Business Logic Component) - Recommended
- **Riverpod** - Modern & powerful
- **Provider** - Simple & lightweight

## 🧪 Testing Strategy

```
test/
├── unit/                    # Unit tests
│   ├── domain/             # Use case tests
│   └── data/               # Repository tests
├── widget/                 # Widget tests
└── integration/            # Integration tests
```

## 📚 Best Practices

1. ✅ **Separation of Concerns**: Pisahkan business logic dari UI
2. ✅ **Dependency Injection**: Use GetIt atau Injectable
3. ✅ **Error Handling**: Centralized error handling
4. ✅ **Code Reusability**: Shared widgets & services
5. ✅ **Consistent Naming**: Follow Flutter/Dart conventions
6. ✅ **Documentation**: Comment complex logic

## 🔄 Next Steps

1. [ ] Implement State Management (BLoC/Riverpod)
2. [ ] Add Dependency Injection (GetIt)
3. [ ] Write Unit Tests
4. [ ] Add Environment Configuration
5. [ ] Implement Repository pattern untuk Attendance & Profile
6. [ ] Add Localization (l10n)

## 📖 Resources

- [Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples)
- [Reso Coder Flutter TDD](https://resocoder.com/flutter-clean-architecture-tdd/)

---

**Catatan**: Struktur ini dirancang untuk scalability. Untuk project yang lebih kecil, beberapa layer bisa disederhanakan.

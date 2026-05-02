# ERP Mobile - Flutter Application

A production-ready, scalable ERP mobile application built with Flutter using Clean Architecture, Riverpod, and GraphQL.

## Features

- **Authentication** - Login/Register with secure token storage
- **Point of Sale (POS)** - Product catalog, cart management, checkout
- **Staff Management** - Add/Edit/Delete staff with role management
- **Product Management** - CRUD operations for products and categories
- **Order Management** - View and manage orders
- **Dashboard** - Analytics and overview

## Architecture

This project follows **Clean Architecture** with a **feature-based folder structure**:

```
lib/
├── core/                    # Shared across all features
│   ├── constants/           # App constants, API endpoints
│   ├── errors/              # Failure classes and exceptions
│   ├── network/             # GraphQL config, network info
│   ├── providers/           # Core Riverpod providers
│   ├── storage/             # Secure storage, shared preferences
│   ├── theme/               # App theme (light/dark)
│   ├── usecases/            # Base use case classes
│   ├── utils/               # Extensions, validators, helpers
│   └── widgets/             # Reusable core widgets
│
├── features/                # Feature modules
│   ├── auth/                # Authentication feature (COMPLETE)
│   │   ├── data/
│   │   │   ├── datasources/ # Remote & local data sources
│   │   │   ├── models/      # Data models (DTOs)
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/    # Business entities
│   │   │   ├── repositories/
│   │   │   └── usecases/    # Business logic
│   │   └── presentation/
│   │       ├── providers/   # Riverpod state management
│   │       ├── pages/       # UI screens
│   │       └── widgets/     # Feature widgets
│   │
│   ├── pos/                 # POS feature (scaffold)
│   ├── staff/               # Staff feature (scaffold)
│   ├── product/             # Product feature (scaffold)
│   ├── order/               # Order feature (scaffold)
│   └── dashboard/           # Dashboard feature (scaffold)
│
└── main.dart
```

## Tech Stack

| Technology | Purpose |
|------------|---------|
| Flutter | UI Framework |
| Riverpod | State Management |
| GraphQL + graphql_flutter | API Integration |
| flutter_secure_storage | Secure Token Storage |
| shared_preferences | Local Caching |
| go_router | Navigation |
| google_fonts | Typography |
| fpdart | Functional Programming |

## Layer Responsibilities

### Domain Layer (Innermost)
- **Entities**: Pure business objects (User, Product, Order)
- **Repository Interfaces**: Define what operations are needed
- **Use Cases**: Encapsulate business logic rules

### Data Layer
- **Models**: JSON serialization/deserialization
- **Data Sources**: Remote (GraphQL) and Local (Storage)
- **Repository Implementation**: Bridge domain with data sources

### Presentation Layer (Outermost)
- **Providers**: State management with Riverpod
- **Screens**: UI pages
- **Widgets**: Reusable UI components

## Getting Started

### Prerequisites
- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd erp_mobile
```

2. Install dependencies
```bash
flutter pub get
```

3. Configure environment
```bash
cp .env.example .env
# Edit .env with your GraphQL endpoint
```

4. Run code generation (if needed)
```bash
dart run build_runner build --delete-conflicting-outputs
```

5. Run the app
```bash
flutter run
```

## Authentication Flow (Complete Implementation)

The Auth module is fully implemented as a reference for other features:

1. **UI Layer** (`pages/login_screen.dart`, `pages/register_screen.dart`)
   - Form validation using `Validators`
   - Loading states with `LoadingOverlay`
   - Error handling with SnackBars

2. **State Management** (`providers/auth_provider.dart`)
   - `AuthNotifier` manages authentication state
   - `AuthState` tracks: loading, authenticated, error states
   - Auto-redirect based on auth status

3. **Business Logic** (`domain/usecases/auth_usecases.dart`)
   - `LoginUseCase`: Validates and executes login
   - `RegisterUseCase`: Validates and executes registration
   - `GetCurrentUserUseCase`: Fetches user profile
   - `LogoutUseCase`: Clears session

4. **Data Layer** (`data/datasources/auth_remote_datasource.dart`)
   - GraphQL mutations for login/register
   - Secure token storage with `flutter_secure_storage`
   - Auth state stream for reactive updates

## Extending the System

### Adding a New Feature (e.g., "Customer Management")

1. **Create feature structure**:
```
lib/features/customer/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── providers/
    ├── pages/
    └── widgets/
```

2. **Define the entity** (`domain/entities/customer.dart`):
```dart
class Customer extends Equatable {
  final String id;
  final String name;
  final String email;
  // ... fields
}
```

3. **Create repository interface** (`domain/repositories/customer_repository.dart`):
```dart
abstract class CustomerRepository {
  Future<Either<Failure, List<Customer>>> getCustomers();
  Future<Either<Failure, Customer>> getCustomerById(String id);
  Future<Either<Failure, Customer>> createCustomer(Customer customer);
}
```

4. **Implement use cases** (`domain/usecases/`):
```dart
class GetCustomersUseCase implements NoParamsUseCase<List<Customer>> {
  final CustomerRepository repository;
  GetCustomersUseCase(this.repository);
  
  @override
  Future<Either<Failure, List<Customer>>> call() async {
    return await repository.getCustomers();
  }
}
```

5. **Implement data layer**:
   - Create GraphQL queries/mutations in `core/constants/api_constants.dart`
   - Implement `CustomerRemoteDataSource` with GraphQL calls
   - Implement `CustomerRepositoryImpl` handling errors and caching

6. **Create presentation layer**:
   - Add Riverpod provider for state management
   - Build UI screens using the provider
   - Add navigation routes in `core/router/app_router.dart`

## Rules Followed

- **No UI-Business Logic Mixing**: UI only calls providers, never repositories directly
- **No Direct API Calls from UI**: All API calls go through data sources
- **Error Handling**: Every layer has proper error handling with Failure classes
- **Dependency Injection**: Using Riverpod providers for clean dependency management
- **Testability**: All layers are independently testable with mock dependencies

## Environment Variables

| Variable | Description |
|----------|-------------|
| `GRAPHQL_ENDPOINT` | GraphQL API HTTP endpoint |
| `WEBSOCKET_ENDPOINT` | GraphQL WebSocket endpoint for subscriptions |
| `APP_ENV` | Environment (development/staging/production) |

## License

MIT License

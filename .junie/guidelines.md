# Requests Inspector Development Guidelines

## Project Overview

The `requests_inspector` is a Flutter package for logging REST APIs and GraphQL requests with a shake-to-show inspector widget. This package provides developers with an easy way to debug network requests in Flutter applications.

## Build and Configuration

### Dependencies
- **Dart SDK**: `>=2.17.0 <4.0.0`
- **Flutter**: `>=1.20.0`
- **Key Dependencies**:
  - `dio: ^5.8.0+1` - HTTP client for REST API requests
  - `graphql: ^5.2.1` & `graphql_flutter: ^5.2.0` - GraphQL client support
  - `sensors_plus: ^6.1.1` - Shake detection functionality
  - `connectivity_plus: ^6.1.4` - Network connectivity monitoring
  - `provider: ^6.1.5` - State management
  - `share_plus: ^11.0.0` - Sharing functionality

### Build Instructions
1. **Standard Flutter Package Build**: No special build steps required
2. **Get Dependencies**: `flutter pub get`
3. **Run Example**: `cd example && flutter run`
4. **Build Example**: `cd example && flutter build [platform]`

### Configuration
- The package uses standard Flutter package structure
- No additional configuration files required beyond `pubspec.yaml`
- Platform-specific configurations are handled automatically

## Testing

### Test Structure
- Tests are located in the `test/` directory
- Main test file: `test/requests_inspector_test.dart`
- Uses `flutter_test` framework

### Running Tests
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/requests_inspector_test.dart

# Run tests with coverage
flutter test --coverage
```

### Test Example
The package includes comprehensive tests covering:
- Singleton pattern verification for `InspectorController`
- `RequestDetails` object creation and property validation
- Request addition and retrieval functionality
- Different HTTP method handling
- URL name extraction functionality

### Adding New Tests
1. Create test files in the `test/` directory
2. Import required packages:
   ```dart
   import 'package:flutter_test/flutter_test.dart';
   import 'package:requests_inspector/requests_inspector.dart';
   ```
3. Use `group()` to organize related tests
4. Include `tearDown()` to reset singleton state between tests:
   ```dart
   tearDown(() {
     try {
       InspectorController().dispose();
     } catch (e) {
       // Ignore disposal errors
     }
   });
   ```

### Important Testing Notes
- **Singleton Pattern**: `InspectorController` is a singleton, so tests must account for shared state
- **RequestDetails Behavior**: Request names are automatically converted to uppercase
- **Controller State**: The controller must be enabled (`enabled: true`) to add requests to the list
- **URL Name Extraction**: When `requestName` is null, the name is extracted from the URL's last segment

## Code Style and Development Guidelines

### Linting Configuration
The project uses `flutter_lints` with custom rules defined in `analysis_options.yaml`:

**Disabled Rules**:
- `curly_braces_in_flow_control_structures: false`
- `constant_identifier_names: false`
- `file_names: false`
- `library_prefixes: false`
- `prefer_function_declarations_over_variables: false`
- `sort_child_properties_last: false`

**Enforced Rules**:
- `always_declare_return_types: true` (error level)
- `avoid_unnecessary_containers: true` (error level)
- `avoid_relative_lib_imports: error`
- `unused_import: error`
- `unused_local_variable: error`

### Architecture Patterns

#### Singleton Pattern
- `InspectorController` uses singleton pattern for global state management
- Access via `InspectorController()` factory constructor
- Dispose properly to reset singleton state

#### State Management
- Uses `ChangeNotifier` pattern with `provider` package
- Controller notifies listeners on state changes
- UI components rebuild automatically on state updates

#### Request Interception
Three methods for logging requests:
1. **Manual Logging**: `InspectorController().addNewRequest(RequestDetails(...))`
2. **Dio Interceptor**: `dio.interceptors.add(RequestsInspectorInterceptor())`
3. **GraphQL Link**: `GraphQLInspectorLink(HttpLink('...'))`

### File Organization
```
lib/
├── requests_inspector.dart          # Main library export file
└── src/
    ├── inspector_controller.dart    # Core controller logic
    ├── request_details.dart         # Request data model
    ├── requests_inspector_widget.dart # Main UI widget
    ├── requests_inspector_interceptor.dart # Dio interceptor
    ├── graphql_inspector_link.dart  # GraphQL integration
    ├── enums/                       # Enumeration definitions
    ├── helpers/                     # Utility functions
    └── shared_widgets/              # Reusable UI components
```

### Key Implementation Details

#### RequestDetails Class
- Automatically converts `requestName` to uppercase
- Extracts name from URL when `requestName` is null
- Generates unique IDs based on endpoint and timestamp
- Supports serialization to/from JSON and Map

#### InspectorController Features
- Shake detection for showing inspector (configurable)
- Request/response interception and editing
- Dark mode and tree view toggles
- Request sharing (normal log and cURL command formats)
- Request replay functionality

### Development Best Practices
1. **Always declare return types** for methods and functions
2. **Avoid unnecessary containers** in widget trees
3. **Use relative imports** only within the package (`./src/...`)
4. **Clean up unused imports** and variables
5. **Test singleton behavior** carefully in unit tests
6. **Handle disposal** properly to prevent memory leaks
7. **Use proper error handling** for network operations

### Debugging Tips
1. **Enable Inspector**: Set `enabled: true` when creating `InspectorController`
2. **Check Shake Detection**: Ensure `ShowInspectorOn.Shaking` is configured correctly
3. **Verify Interceptor**: Confirm `RequestsInspectorInterceptor` is added to Dio
4. **Test Network Connectivity**: Use `connectivity_plus` integration for network state
5. **Inspect Request Details**: Use the built-in sharing functionality to export request logs

### Platform Considerations
- **iOS**: Shake detection requires device motion permissions
- **Android**: Sensor permissions handled automatically
- **Web**: Shake detection not available, use `ShowInspectorOn.Both` or manual trigger
- **Desktop**: Limited shake detection, prefer manual inspector activation
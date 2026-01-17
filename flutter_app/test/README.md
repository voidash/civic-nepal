# Flutter Constitution App Tests

## Overview
Test infrastructure for the Flutter constitution app.

## Test Files

### Widget Tests
- `screens/constitution_screen_test.dart` - Constitution screen UI
- `screens/leaders_screen_test.dart` - Leaders screen UI
- `widgets/linked_text_test.dart - LinkedText component

### Unit Tests
- `providers/constitution_provider_test.dart` - Constitution state
- `services/dictionary_service_test.dart` - Dictionary lookup
- `services/storage_service_test.dart` - Local persistence

### Utilities
- `test_helpers.dart` - Shared test fixtures

## Running Tests

Once Flutter SDK is installed:
```bash
cd flutter_app
flutter test
```

## Status: PLACEHOLDER TESTS

Tests created but use placeholder assertions. Implementation needs:
- Actual asset loading setup
- Hive mocking for storage tests  
- Full widget rendering tests
- Integration test coverage

Created: January 2026

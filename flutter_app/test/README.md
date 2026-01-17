# Flutter Constitution App Tests

## Overview
Test infrastructure for the Flutter constitution app.

## Test Files

### Widget Tests
- `screens/constitution_screen_test.dart` - Constitution screen UI
- `screens/leaders_screen_test.dart` - Leaders screen UI
- `widgets/linked_text_test.dart` - LinkedText component

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

## Status: FUNCTIONAL TESTS (January 2026)

**Critical Bug Fixed**: All test files were corrupted with random garbage text (Chinese characters, random words, broken syntax). Fixed and replaced with proper test code.

**Current Test Coverage**:
- 7 test files covering core functionality
- Widget tests for Constitution and Leaders screens
- Unit tests for providers and services
- Helper utilities for consistent testing

**Limitations**:
- Tests verify API existence and basic functionality
- StorageService tests require Hive initialization for full testing
- Integration tests not yet implemented
- Asset loading tests require Flutter SDK

**Next Steps**:
1. Set up mock data for asset loading
2. Add Hive mocking for storage tests
3. Implement integration tests for user flows
4. Add golden tests for UI validation

Created: January 2026
Fixed: January 2026 (corrupted test files)

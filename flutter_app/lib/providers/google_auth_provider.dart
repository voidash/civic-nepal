import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/google_auth_service.dart';
import '../services/google_calendar_service.dart';

part 'google_auth_provider.g.dart';

/// Auth state exposed to UI.
class GoogleAuthState {
  final bool isSignedIn;
  final String? email;
  final String? displayName;
  final bool isLoading;
  final String? error;

  const GoogleAuthState({
    this.isSignedIn = false,
    this.email,
    this.displayName,
    this.isLoading = false,
    this.error,
  });

  GoogleAuthState copyWith({
    bool? isSignedIn,
    String? email,
    String? displayName,
    bool? isLoading,
    String? error,
  }) {
    return GoogleAuthState(
      isSignedIn: isSignedIn ?? this.isSignedIn,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

@riverpod
class GoogleAuth extends _$GoogleAuth {
  @override
  GoogleAuthState build() {
    _tryRestore();
    return const GoogleAuthState();
  }

  Future<void> _tryRestore() async {
    state = state.copyWith(isLoading: true);
    final success = await GoogleAuthService.instance.trySilentSignIn();
    if (success) {
      // Mark signed-in immediately; fetch calendars in background.
      state = GoogleAuthState(
        isSignedIn: true,
        email: GoogleAuthService.instance.userEmail,
        displayName: GoogleAuthService.instance.displayName,
      );

      try {
        await GoogleCalendarService.instance.fetchCalendarList();
      } catch (_) {
        // Avoid dropping signed-in state if calendar fetch fails (e.g. API disabled).
      }
    } else {
      state = const GoogleAuthState();
    }
  }

  Future<void> signIn() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await GoogleAuthService.instance.signIn();
      if (success) {
        // Mark signed-in immediately; fetch calendars in background.
        state = GoogleAuthState(
          isSignedIn: true,
          email: GoogleAuthService.instance.userEmail,
          displayName: GoogleAuthService.instance.displayName,
        );

        try {
          await GoogleCalendarService.instance.fetchCalendarList();
        } catch (_) {
          // Keep signed-in state even if calendar fetch fails.
        }
      } else {
        state = const GoogleAuthState(error: 'Sign-in cancelled');
      }
    } catch (e) {
      state = GoogleAuthState(error: e.toString());
    }
  }

  Future<void> signOut() async {
    await GoogleAuthService.instance.signOut();
    GoogleCalendarService.instance.clearCache();
    state = const GoogleAuthState();
  }
}

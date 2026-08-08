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

  /// The previous session expired (browser OAuth tokens last ~1h and carry no
  /// refresh token). The user is signed out, but reconnecting is one click and
  /// shows no consent screen — the UI should say so rather than look logged out.
  final bool needsReconnect;

  const GoogleAuthState({
    this.isSignedIn = false,
    this.email,
    this.displayName,
    this.isLoading = false,
    this.error,
    this.needsReconnect = false,
  });

  GoogleAuthState copyWith({
    bool? isSignedIn,
    String? email,
    String? displayName,
    bool? isLoading,
    String? error,
    bool? needsReconnect,
  }) {
    return GoogleAuthState(
      isSignedIn: isSignedIn ?? this.isSignedIn,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      needsReconnect: needsReconnect ?? this.needsReconnect,
    );
  }
}

@riverpod
class GoogleAuth extends _$GoogleAuth {
  bool _disposed = false;

  @override
  GoogleAuthState build() {
    ref.onDispose(() => _disposed = true);
    // `state` cannot be assigned while build() is still running, so the
    // restore attempt is deferred to the next microtask. Calling it inline
    // threw "Tried to read the state of an uninitialized provider" on every
    // launch, which meant the session was never restored at all.
    Future.microtask(_tryRestore);
    return const GoogleAuthState(isLoading: true);
  }

  /// Assign state only while the notifier is still alive.
  void _emit(GoogleAuthState next) {
    if (_disposed) return;
    state = next;
  }

  Future<void> _tryRestore() async {
    if (_disposed) return;
    final success = await GoogleAuthService.instance.trySilentSignIn();
    if (success) {
      // Mark signed-in immediately; fetch calendars in background.
      _emit(GoogleAuthState(
        isSignedIn: true,
        email: GoogleAuthService.instance.userEmail,
        displayName: GoogleAuthService.instance.displayName,
      ));

      try {
        await GoogleCalendarService.instance.fetchCalendarList();
      } catch (_) {
        // Avoid dropping signed-in state if calendar fetch fails (e.g. API disabled).
      }
    } else {
      _emit(GoogleAuthState(
        needsReconnect: GoogleAuthService.instance.needsReconnect,
      ));
    }
  }

  Future<void> signIn() async {
    _emit(state.copyWith(isLoading: true, error: null));
    try {
      final success = await GoogleAuthService.instance.signIn();
      if (success) {
        // Mark signed-in immediately; fetch calendars in background.
        _emit(GoogleAuthState(
          isSignedIn: true,
          email: GoogleAuthService.instance.userEmail,
          displayName: GoogleAuthService.instance.displayName,
        ));

        try {
          await GoogleCalendarService.instance.fetchCalendarList();
        } catch (_) {
          // Keep signed-in state even if calendar fetch fails.
        }
      } else {
        _emit(const GoogleAuthState(error: 'Sign-in cancelled'));
      }
    } catch (e) {
      _emit(GoogleAuthState(error: e.toString()));
    }
  }

  Future<void> signOut() async {
    await GoogleAuthService.instance.signOut();
    GoogleCalendarService.instance.clearCache();
    _emit(const GoogleAuthState());
  }
}

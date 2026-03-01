import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Scopes required for Google Calendar access.
const _calendarScopes = [
  gcal.CalendarApi.calendarEventsScope,
  gcal.CalendarApi.calendarReadonlyScope,
];

/// Manages Google Sign-In and provides an authenticated HTTP client
/// for Google Calendar API access.
///
/// Supports Android, iOS, macOS, and Web via `google_sign_in`.
/// Windows uses a manual OAuth2+PKCE flow (not yet implemented).
class GoogleAuthService {
  GoogleSignIn? _googleSignIn;
  GoogleSignInAccount? _currentUser;
  http.Client? _authClient;

  static final GoogleAuthService instance = GoogleAuthService._();
  GoogleAuthService._();

  /// Whether the user is currently signed in.
  bool get isSignedIn => _currentUser != null;

  /// The signed-in user's email, or null.
  String? get userEmail => _currentUser?.email;

  /// The signed-in user's display name, or null.
  String? get displayName => _currentUser?.displayName;

  /// Initialize the sign-in instance. Must be called before sign-in.
  /// Pass the web client ID for web platform, others use platform config.
  void initialize({String? webClientId}) {
    _googleSignIn = GoogleSignIn(
      scopes: _calendarScopes,
      // Web needs the client ID explicitly; mobile/macOS use GoogleService-Info.plist
      clientId: kIsWeb ? webClientId : null,
    );

    // Listen for sign-in state changes
    _googleSignIn!.onCurrentUserChanged.listen((account) {
      _currentUser = account;
    });
  }

  // SharedPreferences keys for persisting sign-in state.
  static const _keyWasSignedIn = 'google_auth_was_signed_in';
  static const _keyEmail = 'google_auth_email';
  static const _keyDisplayName = 'google_auth_display_name';

  /// Attempt to silently sign in (restores previous session).
  /// Falls back to interactive sign-in if the user was previously signed in
  /// but the native SDK lost the session (common on macOS across rebuilds).
  Future<bool> trySilentSignIn() async {
    if (_googleSignIn == null) return false;
    try {
      _currentUser = await _googleSignIn!.signInSilently();
      if (_currentUser != null) {
        _authClient = await _googleSignIn!.authenticatedClient();
        await _persistSignInState();
        return true;
      }

      // Silent restore failed — check if user was previously signed in.
      // If so, re-authenticate automatically. Since the app is already
      // authorized, the browser redirects back instantly (no consent screen).
      final prefs = await SharedPreferences.getInstance();
      final wasSignedIn = prefs.getBool(_keyWasSignedIn) ?? false;
      if (wasSignedIn) {
        _currentUser = await _googleSignIn!.signIn();
        if (_currentUser != null) {
          _authClient = await _googleSignIn!.authenticatedClient();
          await _persistSignInState();
          return true;
        }
      }

      return false;
    } catch (e) {
      _currentUser = null;
      return false;
    }
  }

  /// Interactive sign-in (shows Google consent screen).
  Future<bool> signIn() async {
    if (_googleSignIn == null) {
      throw StateError('GoogleAuthService not initialized. Call initialize() first.');
    }
    try {
      _currentUser = await _googleSignIn!.signIn();
      if (_currentUser != null) {
        _authClient = await _googleSignIn!.authenticatedClient();
        await _persistSignInState();
      }
      return _currentUser != null;
    } catch (e) {
      _currentUser = null;
      _authClient = null;
      rethrow;
    }
  }

  /// Sign out and clear cached credentials.
  Future<void> signOut() async {
    await _googleSignIn?.signOut();
    _currentUser = null;
    _authClient?.close();
    _authClient = null;
    await _clearSignInState();
  }

  /// Disconnect (revoke access) — removes all granted permissions.
  Future<void> disconnect() async {
    await _googleSignIn?.disconnect();
    _currentUser = null;
    _authClient?.close();
    _authClient = null;
    await _clearSignInState();
  }

  /// Persist sign-in state so we can auto-restore on next app launch.
  Future<void> _persistSignInState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWasSignedIn, true);
    if (_currentUser?.email != null) {
      await prefs.setString(_keyEmail, _currentUser!.email);
    }
    if (_currentUser?.displayName != null) {
      await prefs.setString(_keyDisplayName, _currentUser!.displayName!);
    }
  }

  /// Clear persisted sign-in state on sign-out.
  Future<void> _clearSignInState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyWasSignedIn);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyDisplayName);
  }

  /// Get an authenticated HTTP client for Google API calls.
  /// Returns null if not signed in.
  http.Client? get authClient => _authClient;

  /// Get a CalendarApi instance. Returns null if not signed in.
  gcal.CalendarApi? get calendarApi {
    if (_authClient == null) return null;
    return gcal.CalendarApi(_authClient!);
  }
}

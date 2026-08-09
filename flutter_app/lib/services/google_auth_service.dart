import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/googleapis_auth.dart' as gapis;
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
///
/// ## Restoring a session on the web
///
/// `google_sign_in_web` keeps the OAuth access token only in memory, so a page
/// reload loses it. `signInSilently()` on the web runs the One Tap flow, which
/// returns an *identity* (ID token) but never an access token — and modern
/// browsers suppress One Tap outright. Interactive `signIn()` cannot stand in
/// for it either: it opens a popup, which requires a user gesture and is
/// blocked when called during startup.
///
/// So the access token is persisted here and the API client is rebuilt from it
/// on launch. Google's browser tokens are short-lived (~1 hour) and the GIS
/// flow issues no refresh token, so once it expires the user must reconnect
/// with one click — [needsReconnect] reports that state instead of silently
/// appearing signed out.
class GoogleAuthService {
  GoogleSignIn? _googleSignIn;
  GoogleSignInAccount? _currentUser;
  http.Client? _authClient;

  /// Restored identity when the session came from persisted credentials
  /// rather than from a live [GoogleSignInAccount].
  String? _restoredEmail;
  String? _restoredDisplayName;

  /// True when the user was signed in before but the stored token has expired.
  bool _needsReconnect = false;

  static final GoogleAuthService instance = GoogleAuthService._();
  GoogleAuthService._();

  /// Whether the user is currently signed in.
  bool get isSignedIn => _currentUser != null || _restoredEmail != null;

  /// The signed-in user's email, or null.
  String? get userEmail => _currentUser?.email ?? _restoredEmail;

  /// The signed-in user's display name, or null.
  String? get displayName => _currentUser?.displayName ?? _restoredDisplayName;

  /// True when a previous session expired and a one-click reconnect is needed.
  bool get needsReconnect => _needsReconnect;

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
  static const _keyAccessToken = 'google_auth_access_token';
  static const _keyTokenExpiry = 'google_auth_token_expiry';

  /// Attempt to restore the previous session without any user interaction.
  ///
  /// Never triggers an interactive popup — that requires a user gesture and is
  /// blocked by the browser when called at startup.
  Future<bool> trySilentSignIn() async {
    if (_googleSignIn == null) return false;
    _needsReconnect = false;

    // 1. Ask the platform SDK. This works well on Android/iOS/macOS where the
    //    native SDK persists the session and can mint a fresh access token.
    //
    //    On the web this runs Google One Tap, whose future does not complete
    //    until a "prompt moment" arrives — often ~10s, sometimes never. Bound
    //    it so the sign-in button does not sit disabled behind a spinner.
    try {
      _currentUser = await _googleSignIn!
          .signInSilently()
          .timeout(const Duration(seconds: 4), onTimeout: () => null);
    } catch (e) {
      debugPrint('Google silent sign-in failed: $e');
      _currentUser = null;
    }

    if (_currentUser != null) {
      final client = await _googleSignIn!.authenticatedClient();
      if (client != null) {
        _authClient = client;
        await _persistSignInState();
        return true;
      }
      // Identity restored but no usable token (typical for web One Tap).
    }

    // 2. Fall back to credentials we persisted ourselves.
    return _restoreFromStoredToken();
  }

  /// Rebuild an API client from a previously stored access token.
  Future<bool> _restoreFromStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_keyWasSignedIn) ?? false)) return false;

    final token = prefs.getString(_keyAccessToken);
    final expiryMs = prefs.getInt(_keyTokenExpiry);

    if (token == null || expiryMs == null) {
      _needsReconnect = true;
      return false;
    }

    final expiry = DateTime.fromMillisecondsSinceEpoch(expiryMs, isUtc: true);
    // Treat a token about to expire as already expired.
    if (expiry.isBefore(DateTime.now().toUtc().add(const Duration(minutes: 2)))) {
      _needsReconnect = true;
      await _clearStoredToken();
      return false;
    }

    _authClient = gapis.authenticatedClient(
      http.Client(),
      gapis.AccessCredentials(
        gapis.AccessToken('Bearer', token, expiry),
        null, // GIS browser flow issues no refresh token
        _calendarScopes,
      ),
    );
    _restoredEmail = prefs.getString(_keyEmail);
    _restoredDisplayName = prefs.getString(_keyDisplayName);
    return true;
  }

  /// Interactive sign-in (shows Google consent screen).
  /// Must be called from a user gesture on the web.
  Future<bool> signIn() async {
    if (_googleSignIn == null) {
      throw StateError('GoogleAuthService not initialized. Call initialize() first.');
    }
    try {
      _currentUser = await _googleSignIn!.signIn();
      if (_currentUser != null) {
        _authClient = await _googleSignIn!.authenticatedClient();
        _needsReconnect = false;
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
    _resetSession();
    await _clearSignInState();
  }

  /// Disconnect (revoke access) — removes all granted permissions.
  Future<void> disconnect() async {
    await _googleSignIn?.disconnect();
    _resetSession();
    await _clearSignInState();
  }

  void _resetSession() {
    _currentUser = null;
    _restoredEmail = null;
    _restoredDisplayName = null;
    _needsReconnect = false;
    _authClient?.close();
    _authClient = null;
  }

  /// Persist sign-in state so we can auto-restore on next app launch.
  Future<void> _persistSignInState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWasSignedIn, true);

    final email = _currentUser?.email;
    if (email != null) await prefs.setString(_keyEmail, email);

    final name = _currentUser?.displayName;
    if (name != null) await prefs.setString(_keyDisplayName, name);

    // Store the OAuth access token so a page reload can rebuild the client.
    try {
      final auth = await _currentUser?.authentication;
      final token = auth?.accessToken;
      if (token != null) {
        await prefs.setString(_keyAccessToken, token);
        // Google browser tokens live ~1h; expire ours slightly early.
        await prefs.setInt(
          _keyTokenExpiry,
          DateTime.now()
              .toUtc()
              .add(const Duration(minutes: 55))
              .millisecondsSinceEpoch,
        );
      }
    } catch (e) {
      debugPrint('Could not persist Google access token: $e');
    }
  }

  Future<void> _clearStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyTokenExpiry);
  }

  /// Clear persisted sign-in state on sign-out.
  Future<void> _clearSignInState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyWasSignedIn);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyDisplayName);
    await _clearStoredToken();
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

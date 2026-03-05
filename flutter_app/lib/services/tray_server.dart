import 'dart:io';
import 'package:flutter/foundation.dart';
import 'popup_controller.dart';

/// Minimal HTTP server that the native tray apps talk to.
/// Listens on localhost:27182 (desktop only).
///
/// Endpoints:
///   GET  /health           → 200 "ok"
///   POST /popup/toggle     → show or hide the popup window
///   POST /popup/show       → show the popup window
///   POST /popup/hide       → hide the popup window
///   POST /popup/open-app   → expand to full-app mode
class TrayServer {
  static const int port = 27182;
  static HttpServer? _server;

  static Future<void> start() async {
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      _server!.listen(_handleRequest, onError: (e) {
        debugPrint('TrayServer error: $e');
      });
      debugPrint('TrayServer listening on port $port');
    } on SocketException catch (e) {
      // Port already in use — another instance is running. Not an error.
      debugPrint('TrayServer: port $port unavailable ($e)');
    }
  }

  static Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  static Future<void> _handleRequest(HttpRequest req) async {
    try {
      final key = '${req.method} ${req.uri.path}';
      switch (key) {
        case 'GET /health':
          _respond(req, 200, 'ok');

        case 'POST /popup/toggle':
          await PopupController.instance.toggle();
          _respond(req, 200, 'ok');

        case 'POST /popup/show':
          await PopupController.instance.showPopup();
          _respond(req, 200, 'ok');

        case 'POST /popup/hide':
          await PopupController.instance.hidePopup();
          _respond(req, 200, 'ok');

        case 'POST /popup/open-app':
          await PopupController.instance.expandToFullApp();
          _respond(req, 200, 'ok');

        default:
          _respond(req, 404, 'not found');
      }
    } catch (e) {
      debugPrint('TrayServer: handler error: $e');
      _respond(req, 500, 'error');
    }
  }

  static void _respond(HttpRequest req, int status, String body) {
    req.response
      ..statusCode = status
      ..headers.contentType = ContentType.text
      ..write(body);
    req.response.close();
  }
}

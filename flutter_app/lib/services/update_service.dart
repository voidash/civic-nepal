import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/leader.dart';

part 'update_service.g.dart';

/// Service for checking and downloading remote data updates
@riverpod
UpdateService updateService(UpdateServiceRef ref) {
  return const UpdateService();
}

class UpdateService {
  const UpdateService();

  static const String _manifestUrl =
      'https://cdn.example.com/nepal-civic/manifest.json';

  /// Check if a newer version of data is available
  Future<UpdateManifest?> checkUpdate(String currentVersion) async {
    try {
      final response = await http.get(Uri.parse(_manifestUrl));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return UpdateManifest.fromJson(json);
      }
    } catch (e) {
      // Silently fail on network errors
      return null;
    }
    return null;
  }

  /// Download updated leaders data
  Future<LeadersData?> downloadLeaders(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return LeadersData.fromJson(json);
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}

class UpdateManifest {
  final String version;
  final String? leadersUrl;
  final String? leadersImagesUrl;

  UpdateManifest({
    required this.version,
    this.leadersUrl,
    this.leadersImagesUrl,
  });

  factory UpdateManifest.fromJson(Map<String, dynamic> json) {
    return UpdateManifest(
      version: json['version'] as String,
      leadersUrl: json['leaders_url'] as String?,
      leadersImagesUrl: json['leaders_images_url'] as String?,
    );
  }

  /// Check if this version is newer than the given version
  bool isNewerThan(String currentVersion) {
    return version.compareTo(currentVersion) > 0;
  }
}

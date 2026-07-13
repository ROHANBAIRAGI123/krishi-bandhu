import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

enum SyncStatus {
  pending,
  uploading,
  synced,
  failed,
}

class PendingUpload {
  final String id;
  final String imagePath;
  final String cropType;
  final String? description;
  final double? latitude;
  final double? longitude;
  final DateTime capturedAt;
  final SyncStatus status;
  final int retryCount;
  final String? errorMessage;
  final String? cloudinaryUrl;

  PendingUpload({
    required this.id,
    required this.imagePath,
    required this.cropType,
    this.description,
    this.latitude,
    this.longitude,
    required this.capturedAt,
    this.status = SyncStatus.pending,
    this.retryCount = 0,
    this.errorMessage,
    this.cloudinaryUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'cropType': cropType,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'capturedAt': capturedAt.toIso8601String(),
      'status': status.name,
      'retryCount': retryCount,
      'errorMessage': errorMessage,
      'cloudinaryUrl': cloudinaryUrl,
    };
  }

  factory PendingUpload.fromJson(Map<String, dynamic> json) {
    return PendingUpload(
      id: json['id'] as String,
      imagePath: json['imagePath'] as String,
      cropType: json['cropType'] as String,
      description: json['description'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      status: SyncStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SyncStatus.pending,
      ),
      retryCount: json['retryCount'] as int? ?? 0,
      errorMessage: json['errorMessage'] as String?,
      cloudinaryUrl: json['cloudinaryUrl'] as String?,
    );
  }

  PendingUpload copyWith({
    String? id,
    String? imagePath,
    String? cropType,
    String? description,
    double? latitude,
    double? longitude,
    DateTime? capturedAt,
    SyncStatus? status,
    int? retryCount,
    String? errorMessage,
    String? cloudinaryUrl,
  }) {
    return PendingUpload(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      cropType: cropType ?? this.cropType,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      capturedAt: capturedAt ?? this.capturedAt,
      cloudinaryUrl: cloudinaryUrl ?? this.cloudinaryUrl,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class LocalStorageService {
  static const String _pendingUploadsKey = 'pending_uploads';
  static const String _lastSyncKey = 'last_sync_time';

  // Save pending upload to local storage
  Future<void> savePendingUpload(PendingUpload upload) async {
    final prefs = await SharedPreferences.getInstance();
    final uploads = await getPendingUploads();
    
    // Remove existing upload with same id if present
    uploads.removeWhere((u) => u.id == upload.id);
    
    // Add new upload
    uploads.add(upload);
    
    // Save to SharedPreferences
    final jsonList = uploads.map((u) => u.toJson()).toList();
    await prefs.setString(_pendingUploadsKey, jsonEncode(jsonList));
  }

  // Get all pending uploads
  Future<List<PendingUpload>> getPendingUploads() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_pendingUploadsKey);
    
    if (jsonString == null) {
      return [];
    }
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => PendingUpload.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error parsing pending uploads: $e');
      return [];
    }
  }

  // Get pending uploads count
  Future<int> getPendingUploadsCount() async {
    final uploads = await getPendingUploads();
    return uploads.where((u) => u.status == SyncStatus.pending || u.status == SyncStatus.failed).length;
  }

  // Update upload status
  Future<void> updateUploadStatus(String id, SyncStatus status, {String? errorMessage}) async {
    final uploads = await getPendingUploads();
    final index = uploads.indexWhere((u) => u.id == id);
    
    if (index != -1) {
      uploads[index] = uploads[index].copyWith(
        status: status,
        errorMessage: errorMessage,
        retryCount: status == SyncStatus.failed ? uploads[index].retryCount + 1 : uploads[index].retryCount,
      );
      
      final prefs = await SharedPreferences.getInstance();
      final jsonList = uploads.map((u) => u.toJson()).toList();
      await prefs.setString(_pendingUploadsKey, jsonEncode(jsonList));
    }
  }

  // Update Cloudinary URL for an upload
  Future<void> updateUploadUrl(String id, String cloudinaryUrl) async {
    final uploads = await getPendingUploads();
    final index = uploads.indexWhere((u) => u.id == id);
    
    if (index != -1) {
      uploads[index] = uploads[index].copyWith(
        cloudinaryUrl: cloudinaryUrl,
      );
      
      final prefs = await SharedPreferences.getInstance();
      final jsonList = uploads.map((u) => u.toJson()).toList();
      await prefs.setString(_pendingUploadsKey, jsonEncode(jsonList));
      
      print('✅ Cloudinary URL stored in local database: $cloudinaryUrl');
    }
  }

  // Remove synced upload
  Future<void> removeUpload(String id) async {
    final uploads = await getPendingUploads();
    uploads.removeWhere((u) => u.id == id);
    
    final prefs = await SharedPreferences.getInstance();
    final jsonList = uploads.map((u) => u.toJson()).toList();
    await prefs.setString(_pendingUploadsKey, jsonEncode(jsonList));
  }

  // Clear all synced uploads
  Future<void> clearSyncedUploads() async {
    final uploads = await getPendingUploads();
    final remainingUploads = uploads.where((u) => u.status != SyncStatus.synced).toList();
    
    final prefs = await SharedPreferences.getInstance();
    final jsonList = remainingUploads.map((u) => u.toJson()).toList();
    await prefs.setString(_pendingUploadsKey, jsonEncode(jsonList));
  }

  // Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_lastSyncKey);
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  // Update last sync time
  Future<void> updateLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  // Save image file locally
  Future<String> saveImageLocally(File imageFile, String id) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${directory.path}/crop_images');
    
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    
    final extension = imageFile.path.split('.').last;
    final localPath = '${imagesDir.path}/$id.$extension';
    
    await imageFile.copy(localPath);
    return localPath;
  }

  // Delete local image file
  Future<void> deleteLocalImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting local image: $e');
    }
  }

  // Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    final uploads = await getPendingUploads();
    final directory = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${directory.path}/crop_images');
    
    int totalSize = 0;
    if (await imagesDir.exists()) {
      final files = await imagesDir.list().toList();
      for (var file in files) {
        if (file is File) {
          final stat = await file.stat();
          totalSize += stat.size;
        }
      }
    }
    
    return {
      'totalUploads': uploads.length,
      'pendingUploads': uploads.where((u) => u.status == SyncStatus.pending).length,
      'failedUploads': uploads.where((u) => u.status == SyncStatus.failed).length,
      'syncedUploads': uploads.where((u) => u.status == SyncStatus.synced).length,
      'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
    };
  }

  // Generic data storage methods
  Future<String?> getData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> saveData(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> removeData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}

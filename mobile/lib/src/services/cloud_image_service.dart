import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Service for uploading images to cloud storage (Cloudinary)
class CloudImageService {
  // Cloudinary credentials (from .env file)
  static const String cloudName = 'dxahqsgwv';
  static const String apiKey = '916295378241238';
  static const String apiSecret = 'X2GoZB5cN3lnPSE4HEuOAby1m80';
  static const String uploadPreset = 'pmfby-app';

  static const String baseUrl = 'https://api.cloudinary.com/v1_1';
  static const String uploadFolder = 'pmfby_crops';

  /// Upload image to Cloudinary with compression
  Future<CloudinaryUploadResult> uploadImage(
    File imageFile, {
    required String farmerId,
    required String imageType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Step 1: Compress image
      debugPrint('Compressing image...');
      final compressedFile = await _compressImage(imageFile);

      // Step 2: Prepare upload data
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final publicId = '$uploadFolder/${farmerId}_${imageType}_$timestamp';

      // Step 3: Upload to Cloudinary
      debugPrint('Uploading to Cloudinary...');
      final uri = Uri.parse('$baseUrl/$cloudName/image/upload');
      
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = uploadFolder;
      request.fields['public_id'] = publicId;
      request.fields['timestamp'] = timestamp.toString();
      
      // Add metadata as context
      if (metadata != null) {
        request.fields['context'] = json.encode(metadata);
      }

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          compressedFile.path,
          filename: path.basename(compressedFile.path),
        ),
      );

      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonData = json.decode(responseData);
        debugPrint('Upload successful: ${jsonData['secure_url']}');
        
        return CloudinaryUploadResult(
          publicId: jsonData['public_id'],
          url: jsonData['secure_url'],
          thumbnailUrl: _generateThumbnailUrl(jsonData['secure_url']),
          width: jsonData['width'],
          height: jsonData['height'],
          format: jsonData['format'],
          bytes: jsonData['bytes'],
          createdAt: DateTime.parse(jsonData['created_at']),
        );
      } else {
        throw Exception('Upload failed: $responseData');
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  /// Compress image before upload
  Future<File> _compressImage(File file) async {
    try {
      final filePath = file.absolute.path;
      final lastIndex = filePath.lastIndexOf('.');
      final splitPath = filePath.substring(0, lastIndex);
      final outPath = '${splitPath}_compressed.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        outPath,
        quality: 85,
        minWidth: 1920,
        minHeight: 1080,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        final originalSize = await File(file.path).length();
        final compressedSize = await File(result.path).length();
        debugPrint('Image compressed: $originalSize -> $compressedSize bytes');
        return File(result.path);
      } else {
        debugPrint('Compression failed, using original file');
        return file;
      }
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return file;
    }
  }

  /// Generate thumbnail URL from Cloudinary URL
  String _generateThumbnailUrl(String originalUrl) {
    // Cloudinary URL transformation for thumbnail
    // Example: https://res.cloudinary.com/demo/image/upload/v123/sample.jpg
    // Becomes: https://res.cloudinary.com/demo/image/upload/c_thumb,w_300,h_300/v123/sample.jpg
    return originalUrl.replaceFirst(
      '/upload/',
      '/upload/c_thumb,w_300,h_300,q_auto/',
    );
  }

  /// Delete image from Cloudinary
  Future<bool> deleteImage(String publicId) async {
    try {
      final uri = Uri.parse('$baseUrl/$cloudName/image/destroy');
      
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'public_id': publicId,
          'api_key': apiKey,
          'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['result'] == 'ok';
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }

  /// Get optimized image URL with transformations
  String getOptimizedUrl(
    String originalUrl, {
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
  }) {
    final transformations = <String>[];
    
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    transformations.add('q_$quality');
    transformations.add('f_$format');
    
    final transformation = transformations.join(',');
    return originalUrl.replaceFirst('/upload/', '/upload/$transformation/');
  }
}

/// Result from Cloudinary upload
class CloudinaryUploadResult {
  final String publicId;
  final String url;
  final String thumbnailUrl;
  final int width;
  final int height;
  final String format;
  final int bytes;
  final DateTime createdAt;

  CloudinaryUploadResult({
    required this.publicId,
    required this.url,
    required this.thumbnailUrl,
    required this.width,
    required this.height,
    required this.format,
    required this.bytes,
    required this.createdAt,
  });

  // Alias for secure URL (same as url which is already HTTPS from Cloudinary)
  String get secureUrl => url;

  Map<String, dynamic> toMap() {
    return {
      'publicId': publicId,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'width': width,
      'height': height,
      'format': format,
      'bytes': bytes,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

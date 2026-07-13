import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

/// Service for handling multi-image uploads with compression and batch processing
class ImageUploadService extends ChangeNotifier {
  static const int maxImagesPerReport = 10;
  static const int batchSize = 2; // Upload 2 images at a time
  static const int maxImageSizeKB = 500; // Max 500KB per image
  static const Duration uploadDelay = Duration(milliseconds: 500); // Delay between batches
  
  final List<ImageUploadItem> _uploadQueue = [];
  bool _isUploading = false;
  int _totalImages = 0;
  int _uploadedImages = 0;
  
  bool get isUploading => _isUploading;
  int get totalImages => _totalImages;
  int get uploadedImages => _uploadedImages;
  double get uploadProgress => _totalImages > 0 ? _uploadedImages / _totalImages : 0.0;
  List<ImageUploadItem> get uploadQueue => List.unmodifiable(_uploadQueue);

  /// Add images to upload queue with compression
  Future<List<String>> addImagesToQueue({
    required List<File> images,
    required String reportId,
    required String userId,
  }) async {
    if (images.length > maxImagesPerReport) {
      throw Exception('Maximum $maxImagesPerReport images allowed per report');
    }

    final List<String> compressedPaths = [];
    
    for (int i = 0; i < images.length; i++) {
      try {
        // Compress image
        final compressedPath = await _compressImage(
          images[i],
          quality: 70,
        );
        
        if (compressedPath != null) {
          final item = ImageUploadItem(
            id: const Uuid().v4(),
            localPath: compressedPath,
            originalPath: images[i].path,
            reportId: reportId,
            userId: userId,
            imageNumber: i + 1,
            status: UploadStatus.pending,
          );
          
          _uploadQueue.add(item);
          compressedPaths.add(compressedPath);
        }
      } catch (e) {
        debugPrint('Error processing image ${i + 1}: $e');
      }
    }
    
    _totalImages = _uploadQueue.length;
    notifyListeners();
    
    return compressedPaths;
  }

  /// Compress image to reduce file size
  Future<String?> _compressImage(File file, {int quality = 70}) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}',
      );

      // Get original file size
      final originalSize = await file.length();
      debugPrint('Original image size: ${(originalSize / 1024).toStringAsFixed(2)} KB');

      // Compress image
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: 1920, // Max width
        minHeight: 1080, // Max height
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        final compressedSize = await result.length();
        debugPrint('Compressed image size: ${(compressedSize / 1024).toStringAsFixed(2)} KB');
        debugPrint('Compression ratio: ${((1 - compressedSize / originalSize) * 100).toStringAsFixed(1)}%');
        
        // If still too large, compress more aggressively
        if (compressedSize > maxImageSizeKB * 1024 && quality > 50) {
          debugPrint('Image still too large, compressing further...');
          return await _compressImage(File(result.path), quality: quality - 20);
        }
        
        return result.path;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return null;
    }
  }

  /// Start batch upload process
  Future<void> startBatchUpload({
    required Future<bool> Function(ImageUploadItem) uploadFunction,
    VoidCallback? onComplete,
    Function(String)? onError,
  }) async {
    if (_isUploading) {
      debugPrint('Upload already in progress');
      return;
    }

    if (_uploadQueue.isEmpty) {
      debugPrint('No images in queue');
      return;
    }

    _isUploading = true;
    _uploadedImages = 0;
    notifyListeners();

    try {
      // Process queue in batches
      for (int i = 0; i < _uploadQueue.length; i += batchSize) {
        final batch = _uploadQueue.skip(i).take(batchSize).toList();
        
        debugPrint('Uploading batch ${(i / batchSize + 1).toInt()} of ${(_uploadQueue.length / batchSize).ceil()}');
        
        // Upload batch in parallel
        await Future.wait(
          batch.map((item) => _uploadSingleImage(item, uploadFunction, onError)),
        );
        
        // Delay between batches to avoid overwhelming server
        if (i + batchSize < _uploadQueue.length) {
          await Future.delayed(uploadDelay);
        }
      }
      
      debugPrint('All images uploaded successfully');
      onComplete?.call();
      
    } catch (e) {
      debugPrint('Batch upload error: $e');
      onError?.call(e.toString());
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  /// Upload single image
  Future<void> _uploadSingleImage(
    ImageUploadItem item,
    Future<bool> Function(ImageUploadItem) uploadFunction,
    Function(String)? onError,
  ) async {
    try {
      item.status = UploadStatus.uploading;
      notifyListeners();
      
      final success = await uploadFunction(item);
      
      if (success) {
        item.status = UploadStatus.completed;
        item.uploadedAt = DateTime.now();
        _uploadedImages++;
        debugPrint('Image ${item.imageNumber} uploaded ($_uploadedImages/$_totalImages)');
      } else {
        item.status = UploadStatus.failed;
        item.errorMessage = 'Upload failed';
      }
    } catch (e) {
      item.status = UploadStatus.failed;
      item.errorMessage = e.toString();
      debugPrint('Error uploading image ${item.imageNumber}: $e');
      onError?.call('Image ${item.imageNumber}: ${e.toString()}');
    }
    
    notifyListeners();
  }

  /// Retry failed uploads
  Future<void> retryFailedUploads({
    required Future<bool> Function(ImageUploadItem) uploadFunction,
    VoidCallback? onComplete,
    Function(String)? onError,
  }) async {
    final failedItems = _uploadQueue.where((item) => item.status == UploadStatus.failed).toList();
    
    if (failedItems.isEmpty) {
      debugPrint('No failed uploads to retry');
      return;
    }

    debugPrint('Retrying ${failedItems.length} failed uploads');
    
    for (final item in failedItems) {
      item.status = UploadStatus.pending;
      item.errorMessage = null;
    }
    
    await startBatchUpload(
      uploadFunction: uploadFunction,
      onComplete: onComplete,
      onError: onError,
    );
  }

  /// Clear completed uploads from queue
  void clearCompleted() {
    _uploadQueue.removeWhere((item) => item.status == UploadStatus.completed);
    _totalImages = _uploadQueue.length;
    _uploadedImages = _uploadQueue.where((item) => item.status == UploadStatus.completed).length;
    notifyListeners();
  }

  /// Clear all from queue
  void clearAll() {
    _uploadQueue.clear();
    _totalImages = 0;
    _uploadedImages = 0;
    _isUploading = false;
    notifyListeners();
  }

  /// Get upload statistics
  Map<String, dynamic> getUploadStats() {
    final pending = _uploadQueue.where((item) => item.status == UploadStatus.pending).length;
    final uploading = _uploadQueue.where((item) => item.status == UploadStatus.uploading).length;
    final completed = _uploadQueue.where((item) => item.status == UploadStatus.completed).length;
    final failed = _uploadQueue.where((item) => item.status == UploadStatus.failed).length;
    
    return {
      'total': _uploadQueue.length,
      'pending': pending,
      'uploading': uploading,
      'completed': completed,
      'failed': failed,
      'progress': uploadProgress,
      'isUploading': _isUploading,
    };
  }

  /// Cancel ongoing upload
  void cancelUpload() {
    _isUploading = false;
    for (final item in _uploadQueue) {
      if (item.status == UploadStatus.uploading) {
        item.status = UploadStatus.pending;
      }
    }
    notifyListeners();
  }
}

/// Individual image upload item
class ImageUploadItem {
  final String id;
  final String localPath;
  final String originalPath;
  final String reportId;
  final String userId;
  final int imageNumber;
  
  UploadStatus status;
  String? remotePath;
  String? errorMessage;
  DateTime? uploadedAt;
  int retryCount;

  ImageUploadItem({
    required this.id,
    required this.localPath,
    required this.originalPath,
    required this.reportId,
    required this.userId,
    required this.imageNumber,
    this.status = UploadStatus.pending,
    this.remotePath,
    this.errorMessage,
    this.uploadedAt,
    this.retryCount = 0,
  });

  double get fileSizeMB {
    try {
      final file = File(localPath);
      final bytes = file.lengthSync();
      return bytes / (1024 * 1024);
    } catch (e) {
      return 0.0;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'localPath': localPath,
      'originalPath': originalPath,
      'reportId': reportId,
      'userId': userId,
      'imageNumber': imageNumber,
      'status': status.toString(),
      'remotePath': remotePath,
      'errorMessage': errorMessage,
      'uploadedAt': uploadedAt?.toIso8601String(),
      'retryCount': retryCount,
    };
  }
}

/// Upload status enum
enum UploadStatus {
  pending,
  uploading,
  completed,
  failed,
}

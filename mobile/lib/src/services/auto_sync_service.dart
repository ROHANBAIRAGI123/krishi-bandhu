import 'dart:async';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'local_storage_service.dart';
import 'connectivity_service.dart';
import 'cloud_image_service.dart';
import 'image_deduplication_service.dart';

class AutoSyncService {
  static const String syncTaskName = 'crop_image_sync';
  static const String syncTaskTag = 'sync_tag';
  
  final LocalStorageService _localStorageService = LocalStorageService();
  final CloudImageService _cloudImageService = CloudImageService();
  final ImageDeduplicationService _deduplicationService = ImageDeduplicationService();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  Timer? _syncTimer;
  bool _isSyncing = false;

  // Initialize notifications
  Future<void> initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(initSettings);
  }

  // Initialize background sync with WorkManager
  Future<void> initializeBackgroundSync() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
    
    // Register periodic sync task (runs every 15 minutes when constraints are met)
    await Workmanager().registerPeriodicTask(
      syncTaskName,
      syncTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      tag: syncTaskTag,
    );
  }

  // Start periodic sync (when app is in foreground)
  void startPeriodicSync(ConnectivityService connectivityService) {
    _syncTimer?.cancel();
    
    // Check every 30 seconds if online and has pending uploads
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (connectivityService.isOnline && !_isSyncing) {
        final pendingCount = await _localStorageService.getPendingUploadsCount();
        if (pendingCount > 0) {
          await syncPendingUploads();
        }
      }
    });
  }

  // Stop periodic sync
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  // Sync pending uploads
  Future<void> syncPendingUploads() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    
    try {
      final uploads = await _localStorageService.getPendingUploads();
      final pendingUploads = uploads.where((u) => 
        u.status == SyncStatus.pending || 
        (u.status == SyncStatus.failed && u.retryCount < 3)
      ).toList();
      
      if (pendingUploads.isEmpty) {
        _isSyncing = false;
        return;
      }
      
      // Show sync notification
      await _showSyncNotification(pendingUploads.length);
      
      int successCount = 0;
      int failCount = 0;
      
      for (var upload in pendingUploads) {
        try {
          // Update status to uploading
          await _localStorageService.updateUploadStatus(upload.id, SyncStatus.uploading);
          
          // Simulate upload to server (replace with actual API call)
          await _uploadToServer(upload);
          
          // Update status to synced
          await _localStorageService.updateUploadStatus(upload.id, SyncStatus.synced);
          successCount++;
          
          // Delete local image after successful upload (optional)
          // await _localStorageService.deleteLocalImage(upload.imagePath);
        } catch (e) {
          // Update status to failed
          await _localStorageService.updateUploadStatus(
            upload.id, 
            SyncStatus.failed,
            errorMessage: e.toString(),
          );
          failCount++;
        }
      }
      
      // Update last sync time
      await _localStorageService.updateLastSyncTime();
      
      // Show completion notification
      await _showSyncCompleteNotification(successCount, failCount);
      
    } finally {
      _isSyncing = false;
    }
  }

  // Upload to Cloudinary with deduplication
  Future<void> _uploadToServer(PendingUpload upload) async {
    final file = File(upload.imagePath);
    
    if (!await file.exists()) {
      throw Exception('Image file not found: ${upload.imagePath}');
    }
    
    // Check for duplicates
    final isDuplicate = await _deduplicationService.isImageDuplicate(file);
    if (isDuplicate) {
      print('⚠️ Duplicate image detected, skipping upload: ${upload.id}');
      return;
    }
    
    // Upload to Cloudinary
    final result = await _cloudImageService.uploadImage(
      file,
      farmerId: upload.id.split('_').first,
      imageType: upload.cropType,
      metadata: {
        'description': upload.description ?? '',
        'latitude': upload.latitude?.toString() ?? '',
        'longitude': upload.longitude?.toString() ?? '',
        'capturedAt': upload.capturedAt.toIso8601String(),
      },
    );
    
    // Mark image as uploaded to prevent future duplicates
    await _deduplicationService.markImageAsUploaded(file);
    
    // Update local storage with Cloudinary URL
    await _localStorageService.updateUploadUrl(upload.id, result.secureUrl);
    
    print('✅ Uploaded to Cloudinary: ${result.secureUrl}');
  }

  // Show sync notification
  Future<void> _showSyncNotification(int count) async {
    const androidDetails = AndroidNotificationDetails(
      'sync_channel',
      'Image Sync',
      channelDescription: 'Syncing crop images to server',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      indeterminate: true,
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(
      1,
      'Syncing Images',
      'Uploading $count crop image${count > 1 ? 's' : ''} to server...',
      details,
    );
  }

  // Show sync complete notification
  Future<void> _showSyncCompleteNotification(int success, int failed) async {
    const androidDetails = AndroidNotificationDetails(
      'sync_channel',
      'Image Sync',
      channelDescription: 'Syncing crop images to server',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    String message;
    if (failed == 0) {
      message = 'Successfully uploaded $success image${success > 1 ? 's' : ''}!';
    } else {
      message = 'Uploaded $success image${success > 1 ? 's' : ''}, $failed failed';
    }
    
    await _notifications.show(
      2,
      'Sync Complete',
      message,
      details,
    );
  }

  // Cancel all sync tasks
  Future<void> cancelBackgroundSync() async {
    await Workmanager().cancelByTag(syncTaskTag);
  }

  void dispose() {
    stopPeriodicSync();
  }
}

// Background callback for WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final autoSyncService = AutoSyncService();
      await autoSyncService.syncPendingUploads();
      return true;
    } catch (e) {
      print('Background sync failed: $e');
      return false;
    }
  });
}

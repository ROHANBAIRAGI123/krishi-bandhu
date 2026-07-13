import 'package:mongo_dart/mongo_dart.dart';
import '../models/mongodb/crop_image_model.dart';
import '../services/mongodb_service.dart';
import '../config/mongodb_config.dart';

/// Repository for managing crop images in MongoDB
class CropImageRepository {
  final MongoDBService _mongoService = MongoDBService.instance;

  DbCollection get _collection =>
      _mongoService.getCollection(MongoDBConfig.cropImagesCollection);

  /// Create a new crop image record
  Future<String> createCropImage(CropImageModel image) async {
    try {
      final result = await _collection.insertOne(image.toMap());
      return result.id.toString();
    } catch (e) {
      print('Error creating crop image: $e');
      rethrow;
    }
  }

  /// Get crop image by ID
  Future<CropImageModel?> getCropImageById(String imageId) async {
    try {
      final result = await _collection.findOne(where.eq('imageId', imageId));
      return result != null ? CropImageModel.fromMap(result) : null;
    } catch (e) {
      print('Error getting crop image: $e');
      return null;
    }
  }

  /// Get all images for a farmer
  Future<List<CropImageModel>> getFarmerImages(String farmerId) async {
    try {
      final results = await _collection
          .find(where.eq('farmerId', farmerId).sortBy('capturedAt', descending: true))
          .toList();
      return results.map((doc) => CropImageModel.fromMap(doc)).toList();
    } catch (e) {
      print('Error getting farmer images: $e');
      return [];
    }
  }

  /// Get images by status
  Future<List<CropImageModel>> getImagesByStatus(ImageStatus status) async {
    try {
      final results = await _collection
          .find(where.eq('status', status.name).sortBy('uploadedAt', descending: true))
          .toList();
      return results.map((doc) => CropImageModel.fromMap(doc)).toList();
    } catch (e) {
      print('Error getting images by status: $e');
      return [];
    }
  }

  /// Get images for a specific parcel
  Future<List<CropImageModel>> getParcelImages(
    String farmerId,
    String parcelId,
    {String? season,
    int? year}
  ) async {
    try {
      var query = where.eq('farmerId', farmerId).eq('parcelId', parcelId);
      
      if (season != null) {
        query = query.eq('season', season);
      }
      if (year != null) {
        query = query.eq('year', year);
      }
      
      final results = await _collection
          .find(query.sortBy('capturedAt', descending: true))
          .toList();
      return results.map((doc) => CropImageModel.fromMap(doc)).toList();
    } catch (e) {
      print('Error getting parcel images: $e');
      return [];
    }
  }

  /// Update ML verification for an image
  Future<bool> updateMLVerification(
    String imageId,
    MLVerification mlVerification,
  ) async {
    try {
      final result = await _collection.updateOne(
        where.eq('imageId', imageId),
        modify
            .set('mlVerification', mlVerification.toMap())
            .set('status', ImageStatus.mlVerified.name)
            .set('verifiedAt', DateTime.now()),
      );
      return result.isSuccess;
    } catch (e) {
      print('Error updating ML verification: $e');
      return false;
    }
  }

  /// Update officer verification for an image
  Future<bool> updateOfficerVerification(
    String imageId,
    OfficerVerification officerVerification,
    ImageStatus newStatus,
  ) async {
    try {
      final result = await _collection.updateOne(
        where.eq('imageId', imageId),
        modify
            .set('officerVerification', officerVerification.toMap())
            .set('status', newStatus.name)
            .set('verifiedAt', DateTime.now()),
      );
      return result.isSuccess;
    } catch (e) {
      print('Error updating officer verification: $e');
      return false;
    }
  }

  /// Update image status
  Future<bool> updateImageStatus(String imageId, ImageStatus status) async {
    try {
      final result = await _collection.updateOne(
        where.eq('imageId', imageId),
        modify.set('status', status.name),
      );
      return result.isSuccess;
    } catch (e) {
      print('Error updating image status: $e');
      return false;
    }
  }

  /// Get images pending ML verification
  Future<List<CropImageModel>> getImagesPendingMLVerification() async {
    return getImagesByStatus(ImageStatus.pendingMLVerification);
  }

  /// Get images pending officer review
  Future<List<CropImageModel>> getImagesPendingOfficerReview({
    int limit = 50,
  }) async {
    try {
      final results = await _collection
          .find(
            where
                .eq('status', ImageStatus.pendingOfficerReview.name)
                .sortBy('uploadedAt', descending: false)
                .limit(limit),
          )
          .toList();
      return results.map((doc) => CropImageModel.fromMap(doc)).toList();
    } catch (e) {
      print('Error getting images pending review: $e');
      return [];
    }
  }

  /// Get images with ML flags
  Future<List<CropImageModel>> getFlaggedImages() async {
    return getImagesByStatus(ImageStatus.flagged);
  }

  /// Get image statistics for a farmer
  Future<Map<String, int>> getFarmerImageStats(String farmerId) async {
    try {
      final pipeline = [
        {
          '\$match': {'farmerId': farmerId}
        },
        {
          '\$group': {
            '_id': '\$status',
            'count': {'\$sum': 1}
          }
        }
      ];

      final results = await _collection.aggregateToStream(pipeline).toList();
      
      final stats = <String, int>{};
      for (var doc in results) {
        stats[doc['_id'] as String] = doc['count'] as int;
      }
      
      return stats;
    } catch (e) {
      print('Error getting farmer image stats: $e');
      return {};
    }
  }

  /// Delete crop image
  Future<bool> deleteCropImage(String imageId) async {
    try {
      final result = await _collection.deleteOne(where.eq('imageId', imageId));
      return result.isSuccess;
    } catch (e) {
      print('Error deleting crop image: $e');
      return false;
    }
  }

  /// Get images by date range
  Future<List<CropImageModel>> getImagesByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? farmerId,
  }) async {
    try {
      var query = where
          .gte('capturedAt', startDate)
          .lte('capturedAt', endDate);
      
      if (farmerId != null) {
        query = query.eq('farmerId', farmerId);
      }
      
      final results = await _collection
          .find(query.sortBy('capturedAt', descending: true))
          .toList();
      return results.map((doc) => CropImageModel.fromMap(doc)).toList();
    } catch (e) {
      print('Error getting images by date range: $e');
      return [];
    }
  }
}

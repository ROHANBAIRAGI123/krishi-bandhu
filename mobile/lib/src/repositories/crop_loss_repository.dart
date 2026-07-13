import 'package:mongo_dart/mongo_dart.dart';
import '../models/mongodb/crop_loss_model.dart';
import '../services/mongodb_service.dart';
import '../config/mongodb_config.dart';

/// Repository for managing crop loss intimations in MongoDB
class CropLossRepository {
  final MongoDBService _mongoService = MongoDBService.instance;

  DbCollection get _collection =>
      _mongoService.getCollection('crop_loss_intimations');

  /// Create a new crop loss intimation
  Future<String> createCropLoss(CropLossModel cropLoss) async {
    try {
      final result = await _collection.insertOne(cropLoss.toMap());
      return result.id.toString();
    } catch (e) {
      print('Error creating crop loss: $e');
      rethrow;
    }
  }

  /// Get crop loss by ID
  Future<CropLossModel?> getCropLossById(String lossId) async {
    try {
      final result = await _collection.findOne(where.eq('lossId', lossId));
      return result != null ? CropLossModel.fromMap(result) : null;
    } catch (e) {
      print('Error getting crop loss: $e');
      return null;
    }
  }

  /// Get all crop losses for a farmer
  Future<List<CropLossModel>> getFarmerCropLosses(String farmerId) async {
    try {
      final results = await _collection
          .find(where.eq('farmerId', farmerId).sortBy('reportedAt', descending: true))
          .toList();
      return results.map((doc) => CropLossModel.fromMap(doc)).toList();
    } catch (e) {
      print('Error getting farmer crop losses: $e');
      return [];
    }
  }

  /// Get crop losses by status
  Future<List<CropLossModel>> getCropLossesByStatus(
    LossStatus status, {
    int limit = 100,
  }) async {
    try {
      final results = await _collection
          .find(
            where
                .eq('status', status.name)
                .sortBy('reportedAt', descending: false)
                .limit(limit),
          )
          .toList();
      return results.map((doc) => CropLossModel.fromMap(doc)).toList();
    } catch (e) {
      print('Error getting crop losses by status: $e');
      return [];
    }
  }

  /// Get pending crop loss assessments for officers
  Future<List<CropLossModel>> getPendingAssessments({
    String? district,
    int limit = 50,
  }) async {
    try {
      var query = where.eq('status', LossStatus.reported.name);
      
      // TODO: Add district filtering when address is included
      
      final results = await _collection
          .find(query.sortBy('reportedAt', descending: false).limit(limit))
          .toList();
      return results.map((doc) => CropLossModel.fromMap(doc)).toList();
    } catch (e) {
      print('Error getting pending assessments: $e');
      return [];
    }
  }

  /// Update crop loss status
  Future<bool> updateCropLossStatus(String lossId, LossStatus status) async {
    try {
      final result = await _collection.updateOne(
        where.eq('lossId', lossId),
        modify
            .set('status', status.name)
            .set('updatedAt', DateTime.now()),
      );
      return result.isSuccess;
    } catch (e) {
      print('Error updating crop loss status: $e');
      return false;
    }
  }

  /// Add officer assessment to crop loss
  Future<bool> addOfficerAssessment(
    String lossId,
    OfficerAssessment assessment,
  ) async {
    try {
      final result = await _collection.updateOne(
        where.eq('lossId', lossId),
        modify
            .set('officerAssessment', assessment.toMap())
            .set('status', LossStatus.assessed.name)
            .set('assessedAt', DateTime.now())
            .set('updatedAt', DateTime.now()),
      );
      return result.isSuccess;
    } catch (e) {
      print('Error adding officer assessment: $e');
      return false;
    }
  }

  /// Get crop losses by season and year
  Future<List<CropLossModel>> getCropLossesBySeason(
    String season,
    int year, {
    String? farmerId,
  }) async {
    try {
      var query = where.eq('season', season).eq('year', year);
      
      if (farmerId != null) {
        query = query.eq('farmerId', farmerId);
      }
      
      final results = await _collection
          .find(query.sortBy('reportedAt', descending: true))
          .toList();
      return results.map((doc) => CropLossModel.fromMap(doc)).toList();
    } catch (e) {
      print('Error getting crop losses by season: $e');
      return [];
    }
  }

  /// Get crop loss statistics
  Future<Map<String, dynamic>> getCropLossStats({
    String? farmerId,
    String? season,
    int? year,
  }) async {
    try {
      final matchStage = <String, dynamic>{};
      if (farmerId != null) matchStage['farmerId'] = farmerId;
      if (season != null) matchStage['season'] = season;
      if (year != null) matchStage['year'] = year;

      final pipeline = [
        if (matchStage.isNotEmpty) {'\$match': matchStage},
        {
          '\$group': {
            '_id': '\$status',
            'count': {'\$sum': 1},
            'totalAffectedArea': {'\$sum': '\$lossDetails.affectedArea'},
            'avgLossPercentage': {'\$avg': '\$lossDetails.estimatedLossPercentage'},
          }
        }
      ];

      final results = await _collection.aggregateToStream(pipeline).toList();
      
      return {
        'byStatus': results,
        'totalReports': results.fold<int>(0, (sum, doc) => sum + (doc['count'] as int)),
      };
    } catch (e) {
      print('Error getting crop loss stats: $e');
      return {};
    }
  }

  /// Get crop losses by loss cause
  Future<Map<String, int>> getCropLossesByLossCause() async {
    try {
      final pipeline = [
        {
          '\$group': {
            '_id': '\$lossDetails.lossCause',
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
      print('Error getting losses by cause: $e');
      return {};
    }
  }

  /// Update crop loss with additional image IDs
  Future<bool> addImagesToCropLoss(String lossId, List<String> imageIds) async {
    try {
      final result = await _collection.updateOne(
        where.eq('lossId', lossId),
        modify
            .push('imageIds', imageIds)
            .set('updatedAt', DateTime.now()),
      );
      return result.isSuccess;
    } catch (e) {
      print('Error adding images to crop loss: $e');
      return false;
    }
  }

  /// Delete crop loss intimation
  Future<bool> deleteCropLoss(String lossId) async {
    try {
      final result = await _collection.deleteOne(where.eq('lossId', lossId));
      return result.isSuccess;
    } catch (e) {
      print('Error deleting crop loss: $e');
      return false;
    }
  }

  /// Get crop losses by date range
  Future<List<CropLossModel>> getCropLossesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final results = await _collection
          .find(
            where
                .gte('reportedAt', startDate)
                .lte('reportedAt', endDate)
                .sortBy('reportedAt', descending: true),
          )
          .toList();
      return results.map((doc) => CropLossModel.fromMap(doc)).toList();
    } catch (e) {
      print('Error getting crop losses by date range: $e');
      return [];
    }
  }
}

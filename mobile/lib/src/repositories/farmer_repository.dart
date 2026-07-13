import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter/foundation.dart';
import '../services/mongodb_service.dart';
import '../services/security_service.dart';
import '../config/mongodb_config.dart';
import '../models/mongodb/farmer_model.dart';

class FarmerRepository {
  final MongoDBService _mongoService = MongoDBService.instance;
  
  // Create a new farmer
  Future<String> createFarmer({
    required String firstName,
    required String lastName,
    required String phone,
    required String aadhaarNumber,
    required String state,
    required String district,
    required String taluka,
    required String village,
    required String pincode,
  }) async {
    try {
      return await _mongoService.withRetry(() async {
        final collection = _mongoService.getCollection(MongoDBConfig.farmersCollection);
        
        // Generate unique farmer ID
        final farmerId = 'FRM_${DateTime.now().millisecondsSinceEpoch}';
        
        // Hash and mask sensitive data
        final hashedAadhaar = SecurityService.hashSensitiveData(aadhaarNumber);
        final maskedAadhaar = SecurityService.maskAadhaar(aadhaarNumber);
        final normalizedPhone = SecurityService.normalizePhone(phone);
        
        // Validate inputs
        if (!SecurityService.isValidAadhaar(aadhaarNumber)) {
          throw Exception('Invalid Aadhaar number format');
        }
        if (!SecurityService.isValidPhone(phone)) {
          throw Exception('Invalid phone number format');
        }
        
        // Check if farmer already exists
        final existing = await collection.findOne(where.eq('aadhaar.number', hashedAadhaar));
        if (existing != null) {
          throw Exception('Farmer with this Aadhaar already exists');
        }
        
        final farmer = FarmerModel(
          farmerId: farmerId,
          name: FarmerName(
            first: SecurityService.sanitizeInput(firstName),
            last: SecurityService.sanitizeInput(lastName),
          ),
          phone: normalizedPhone,
          aadhaar: AadhaarInfo(
            number: hashedAadhaar,
            displayNumber: maskedAadhaar,
            verified: false,
          ),
          address: FarmerAddress(
            state: SecurityService.sanitizeInput(state),
            district: SecurityService.sanitizeInput(district),
            taluka: SecurityService.sanitizeInput(taluka),
            village: SecurityService.sanitizeInput(village),
            pincode: SecurityService.sanitizeInput(pincode),
          ),
          landParcels: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await collection.insertOne(farmer.toMap());
        
        debugPrint('Farmer created successfully: $farmerId');
        return farmerId;
      });
    } catch (e) {
      debugPrint('Error creating farmer: $e');
      rethrow;
    }
  }
  
  // Get farmer by ID
  Future<FarmerModel?> getFarmerById(String farmerId) async {
    try {
      return await _mongoService.withRetry(() async {
        final collection = _mongoService.getCollection(MongoDBConfig.farmersCollection);
        final result = await collection.findOne(where.eq('farmerId', farmerId));
        
        if (result == null) return null;
        return FarmerModel.fromMap(result);
      });
    } catch (e) {
      debugPrint('Error getting farmer: $e');
      return null;
    }
  }
  
  // Get farmer by phone
  Future<FarmerModel?> getFarmerByPhone(String phone) async {
    try {
      final normalizedPhone = SecurityService.normalizePhone(phone);
      return await _mongoService.withRetry(() async {
        final collection = _mongoService.getCollection(MongoDBConfig.farmersCollection);
        final result = await collection.findOne(where.eq('phone', normalizedPhone));
        
        if (result == null) return null;
        return FarmerModel.fromMap(result);
      });
    } catch (e) {
      debugPrint('Error getting farmer by phone: $e');
      return null;
    }
  }
  
  // Update farmer profile
  Future<bool> updateFarmer(String farmerId, Map<String, dynamic> updates) async {
    try {
      return await _mongoService.withRetry(() async {
        final collection = _mongoService.getCollection(MongoDBConfig.farmersCollection);
        
        // Sanitize all string inputs
        final sanitizedUpdates = <String, dynamic>{};
        updates.forEach((key, value) {
          if (value is String) {
            sanitizedUpdates[key] = SecurityService.sanitizeInput(value);
          } else {
            sanitizedUpdates[key] = value;
          }
        });
        
        sanitizedUpdates['updatedAt'] = DateTime.now();
        
        final result = await collection.updateOne(
          where.eq('farmerId', farmerId),
          modify.set('updatedAt', DateTime.now()).set('updates', sanitizedUpdates),
        );
        
        return result.isSuccess;
      });
    } catch (e) {
      debugPrint('Error updating farmer: $e');
      return false;
    }
  }
  
  // Add land parcel to farmer
  Future<bool> addLandParcel(String farmerId, LandParcel parcel) async {
    try {
      return await _mongoService.withRetry(() async {
        final collection = _mongoService.getCollection(MongoDBConfig.farmersCollection);
        
        final result = await collection.updateOne(
          where.eq('farmerId', farmerId),
          modify.push('landParcels', parcel.toMap()).set('updatedAt', DateTime.now()),
        );
        
        return result.isSuccess;
      });
    } catch (e) {
      debugPrint('Error adding land parcel: $e');
      return false;
    }
  }
  
  // Get all farmers (with pagination)
  Future<List<FarmerModel>> getAllFarmers({
    int limit = 50,
    int skip = 0,
    String? district,
  }) async {
    try {
      return await _mongoService.withRetry(() async {
        final collection = _mongoService.getCollection(MongoDBConfig.farmersCollection);
        
        var selector = where;
        if (district != null) {
          selector = where.eq('address.district', district);
        }
        
        final results = await collection
            .find(selector.limit(limit).skip(skip).sortBy('createdAt', descending: true))
            .toList();
        
        return results.map((r) => FarmerModel.fromMap(r)).toList();
      });
    } catch (e) {
      debugPrint('Error getting all farmers: $e');
      return [];
    }
  }
  
  // Delete farmer (soft delete by marking as inactive)
  Future<bool> deleteFarmer(String farmerId) async {
    try {
      return await _mongoService.withRetry(() async {
        final collection = _mongoService.getCollection(MongoDBConfig.farmersCollection);
        
        final result = await collection.updateOne(
          where.eq('farmerId', farmerId),
          modify.set('active', false).set('updatedAt', DateTime.now()),
        );
        
        return result.isSuccess;
      });
    } catch (e) {
      debugPrint('Error deleting farmer: $e');
      return false;
    }
  }
}

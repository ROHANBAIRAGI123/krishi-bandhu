import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter/foundation.dart';
import '../services/mongodb_service.dart';
import '../services/security_service.dart';
import '../config/mongodb_config.dart';
import '../models/mongodb/official_model.dart';

class AuthRepository {
  final MongoDBService _mongoService = MongoDBService.instance;
  
  // Register a new official/user
  Future<String> registerOfficial({
    required String name,
    required String phone,
    required String password,
    required String role,
    String? assignedDistrict,
    List<String>? permissions,
  }) async {
    try {
      return await _mongoService.withRetry(() async {
        final collection = _mongoService.getCollection(MongoDBConfig.officialsCollection);
        
        // Generate unique user ID
        final userId = 'OFF_${DateTime.now().millisecondsSinceEpoch}';
        
        // Normalize and validate phone
        final normalizedPhone = SecurityService.normalizePhone(phone);
        if (!SecurityService.isValidPhone(normalizedPhone)) {
          throw Exception('Invalid phone number format');
        }
        
        // Check if user already exists
        final existing = await collection.findOne(where.eq('phone', normalizedPhone));
        if (existing != null) {
          throw Exception('User with this phone number already exists');
        }
        
        // Hash password
        final hashedPassword = SecurityService.hashPassword(password);
        
        // Set default permissions based on role
        final defaultPermissions = _getDefaultPermissions(role);
        
        final official = OfficialModel(
          userId: userId,
          role: role,
          name: SecurityService.sanitizeInput(name),
          phone: normalizedPhone,
          passwordHash: hashedPassword,
          assignedDistrict: assignedDistrict != null 
              ? SecurityService.sanitizeInput(assignedDistrict) 
              : null,
          permissions: permissions ?? defaultPermissions,
          createdAt: DateTime.now(),
        );
        
        await collection.insertOne(official.toMap());
        
        debugPrint('Official registered successfully: $userId');
        return userId;
      });
    } catch (e) {
      debugPrint('Error registering official: $e');
      rethrow;
    }
  }
  
  // Login with phone and password
  Future<OfficialModel?> loginOfficial(String phone, String password) async {
    try {
      return await _mongoService.withRetry(() async {
        final collection = _mongoService.getCollection(MongoDBConfig.officialsCollection);
        
        final normalizedPhone = SecurityService.normalizePhone(phone);
        final result = await collection.findOne(where.eq('phone', normalizedPhone));
        
        if (result == null) {
          debugPrint('User not found');
          return null;
        }
        
        final official = OfficialModel.fromMap(result);
        
        // Verify password
        if (!SecurityService.verifyPassword(password, official.passwordHash)) {
          debugPrint('Invalid password');
          return null;
        }
        
        // Update last login
        await collection.updateOne(
          where.eq('userId', official.userId),
          modify.set('lastLogin', DateTime.now()),
        );
        
        debugPrint('Official logged in successfully: ${official.userId}');
        return official;
      });
    } catch (e) {
      debugPrint('Error logging in: $e');
      return null;
    }
  }
  
  // Get official by user ID
  Future<OfficialModel?> getOfficialById(String userId) async {
    try {
      return await _mongoService.withRetry(() async {
        final collection = _mongoService.getCollection(MongoDBConfig.officialsCollection);
        final result = await collection.findOne(where.eq('userId', userId));
        
        if (result == null) return null;
        return OfficialModel.fromMap(result);
      });
    } catch (e) {
      debugPrint('Error getting official: $e');
      return null;
    }
  }
  
  // Change password
  Future<bool> changePassword(String userId, String oldPassword, String newPassword) async {
    try {
      return await _mongoService.withRetry(() async {
        final collection = _mongoService.getCollection(MongoDBConfig.officialsCollection);
        
        final result = await collection.findOne(where.eq('userId', userId));
        if (result == null) {
          throw Exception('User not found');
        }
        
        final official = OfficialModel.fromMap(result);
        
        // Verify old password
        if (!SecurityService.verifyPassword(oldPassword, official.passwordHash)) {
          throw Exception('Invalid old password');
        }
        
        // Hash new password
        final newHashedPassword = SecurityService.hashPassword(newPassword);
        
        // Update password
        final updateResult = await collection.updateOne(
          where.eq('userId', userId),
          modify.set('passwordHash', newHashedPassword),
        );
        
        return updateResult.isSuccess;
      });
    } catch (e) {
      debugPrint('Error changing password: $e');
      return false;
    }
  }
  
  // Reset password (generate temporary password)
  Future<String?> resetPassword(String phone) async {
    try {
      return await _mongoService.withRetry(() async {
        final collection = _mongoService.getCollection(MongoDBConfig.officialsCollection);
        
        final normalizedPhone = SecurityService.normalizePhone(phone);
        final result = await collection.findOne(where.eq('phone', normalizedPhone));
        
        if (result == null) {
          throw Exception('User not found');
        }
        
        // Generate temporary password
        final tempPassword = _generateTempPassword();
        final hashedTempPassword = SecurityService.hashPassword(tempPassword);
        
        // Update password
        await collection.updateOne(
          where.eq('phone', normalizedPhone),
          modify.set('passwordHash', hashedTempPassword)
              .set('requirePasswordChange', true),
        );
        
        debugPrint('Password reset successfully for: $phone');
        return tempPassword;
      });
    } catch (e) {
      debugPrint('Error resetting password: $e');
      return null;
    }
  }
  
  // Log audit event
  Future<void> logAudit({
    required String entity,
    required String entityId,
    required String action,
    required String actor,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _mongoService.withRetry(() async {
        final collection = _mongoService.getCollection(MongoDBConfig.auditLogsCollection);
        
        final auditLog = AuditLogModel(
          entity: entity,
          entityId: entityId,
          action: action,
          actor: actor,
          details: details ?? {},
          timestamp: DateTime.now(),
        );
        
        await collection.insertOne(auditLog.toMap());
      });
    } catch (e) {
      debugPrint('Error logging audit: $e');
    }
  }
  
  // Helper methods
  List<String> _getDefaultPermissions(String role) {
    switch (role) {
      case 'admin':
        return [
          'review_claims',
          'approve_claims',
          'manage_users',
          'view_analytics',
          'export_data',
        ];
      case 'field_officer':
        return [
          'review_claims',
          'approve_local',
          'view_farmers',
          'update_farmers',
        ];
      case 'data_annotator':
        return [
          'annotate_images',
          'view_images',
        ];
      default:
        return ['view_only'];
    }
  }
  
  String _generateTempPassword() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'TEMP_${timestamp.substring(timestamp.length - 6)}';
  }
}

import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter/foundation.dart';
import '../config/mongodb_config.dart';
import '../models/mongodb/feedback_model.dart';

class MongoDBService {
  static MongoDBService? _instance;
  static Db? _db;
  
  MongoDBService._();
  
  static MongoDBService get instance {
    _instance ??= MongoDBService._();
    return _instance!;
  }
  
  // Initialize MongoDB connection
  Future<void> connect() async {
    try {
      if (_db != null && _db!.isConnected) {
        if (kDebugMode) debugPrint('MongoDB already connected');
        return;
      }
      
      final connectionString = MongoDBConfig.connectionString;
      if (kDebugMode) debugPrint('Connecting to MongoDB Atlas...');
      
      _db = await Db.create(connectionString);
      await _db!.open();
      
      if (kDebugMode) debugPrint('✅ MongoDB connected to ${MongoDBConfig.databaseName}');
      
      // Create indexes for better performance
      await _createIndexes();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ MongoDB connection failed: $e');
      rethrow;
    }
  }
  
  // Create database indexes
  Future<void> _createIndexes() async {
    try {
      // Farmers collection indexes
      final farmersCollection = _db!.collection(MongoDBConfig.farmersCollection);
      await farmersCollection.createIndex(key: 'farmerId', unique: true);
      await farmersCollection.createIndex(key: 'phone');
      await farmersCollection.createIndex(key: 'aadhaar.number');
      
      // Crop images collection indexes
      final imagesCollection = _db!.collection(MongoDBConfig.cropImagesCollection);
      await imagesCollection.createIndex(key: 'imageId', unique: true);
      await imagesCollection.createIndex(key: 'farmerId');
      await imagesCollection.createIndex(key: 'parcelId');
      await imagesCollection.createIndex(keys: {'farmerId': 1, 'season': 1});
      
      // Claims collection indexes
      final claimsCollection = _db!.collection(MongoDBConfig.claimsCollection);
      await claimsCollection.createIndex(key: 'claimId', unique: true);
      await claimsCollection.createIndex(key: 'farmerId');
      await claimsCollection.createIndex(key: 'status');
      await claimsCollection.createIndex(keys: {'farmerId': 1, 'season': 1});
      
      // Officials collection indexes
      final officialsCollection = _db!.collection(MongoDBConfig.officialsCollection);
      await officialsCollection.createIndex(key: 'userId', unique: true);
      await officialsCollection.createIndex(key: 'phone');
      
      // Feedback collection indexes
      final feedbackCollection = _db!.collection('feedback_reports');
      await feedbackCollection.createIndex(key: 'farmerId');
      await feedbackCollection.createIndex(key: 'status');
      await feedbackCollection.createIndex(key: 'category');
      await feedbackCollection.createIndex(key: 'priority');
      await feedbackCollection.createIndex(key: 'createdAt');
      
      debugPrint('MongoDB indexes created successfully');
    } catch (e) {
      debugPrint('Error creating indexes: $e');
    }
  }
  
  // Disconnect from MongoDB
  Future<void> disconnect() async {
    try {
      if (_db != null && _db!.isConnected) {
        await _db!.close();
        debugPrint('MongoDB disconnected');
      }
    } catch (e) {
      debugPrint('MongoDB disconnection error: $e');
    }
  }
  
  // Get database instance
  Db? get database => _db;
  
  // Check if connected
  bool get isConnected => _db != null && _db!.isConnected;
  
  // Get collection
  DbCollection getCollection(String collectionName) {
    if (_db == null || !_db!.isConnected) {
      throw Exception('MongoDB not connected. Call connect() first.');
    }
    return _db!.collection(collectionName);
  }
  
  // Helper method to handle connection retry
  Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        if (!isConnected) {
          await connect();
        }
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          rethrow;
        }
        debugPrint('Operation failed, retrying... (attempt $attempts/$maxRetries)');
        await Future.delayed(retryDelay);
      }
    }
    
    throw Exception('Operation failed after $maxRetries attempts');
  }
  
  // === FEEDBACK METHODS ===
  
  // Insert feedback/report
  Future<ObjectId?> insertFeedback(FeedbackReport feedback) async {
    return withRetry(() async {
      final collection = getCollection('feedback_reports');
      final result = await collection.insertOne(feedback.toJson());
      return result.id as ObjectId?;
    });
  }
  
  // Get farmer's feedback reports
  Future<List<FeedbackReport>> getFarmerFeedback(String farmerId) async {
    return withRetry(() async {
      final collection = getCollection('feedback_reports');
      final results = await collection.find(
        where.eq('farmerId', farmerId).sortBy('createdAt', descending: true),
      ).toList();
      
      return results.map((doc) => FeedbackReport.fromJson(doc)).toList();
    });
  }
  
  // Get all feedback reports (for admin)
  Future<List<FeedbackReport>> getAllFeedbackReports({
    String? status,
    String? category,
    String? priority,
    int? limit,
    int? skip,
  }) async {
    return withRetry(() async {
      final collection = getCollection('feedback_reports');
      
      SelectorBuilder query = where;
      
      if (status != null) {
        query = query.eq('status', status);
      }
      if (category != null) {
        query = query.eq('category', category);
      }
      if (priority != null) {
        query = query.eq('priority', priority);
      }
      
      query = query.sortBy('createdAt', descending: true);
      
      if (limit != null) {
        query = query.limit(limit);
      }
      if (skip != null) {
        query = query.skip(skip);
      }
      
      final results = await collection.find(query).toList();
      return results.map((doc) => FeedbackReport.fromJson(doc)).toList();
    });
  }
  
  // Update feedback status and admin response
  Future<bool> updateFeedbackStatus(
    ObjectId feedbackId,
    String status, {
    String? adminResponse,
    String? adminId,
  }) async {
    return withRetry(() async {
      final collection = getCollection('feedback_reports');
      
      final updateDoc = {
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      if (adminResponse != null) {
        updateDoc['adminResponse'] = adminResponse;
      }
      if (adminId != null) {
        updateDoc['adminId'] = adminId;
      }
      if (status == 'resolved' || status == 'closed') {
        updateDoc['resolvedAt'] = DateTime.now().toIso8601String();
      }
      
      final result = await collection.updateOne(
        where.id(feedbackId),
        modify.set('status', status)
          ..set('adminResponse', adminResponse ?? '')
          ..set('adminId', adminId ?? '')
          ..set('respondedAt', DateTime.now().toIso8601String())
          ..set('updatedAt', DateTime.now().toIso8601String()),
      );
      
      return result.isSuccess;
    });
  }
  
  // Get feedback statistics (for admin dashboard)
  Future<Map<String, dynamic>> getFeedbackStatistics() async {
    return withRetry(() async {
      final collection = getCollection('feedback_reports');
      
      // Total count
      final total = await collection.count();
      
      // Count by status
      final openCount = await collection.count(where.eq('status', 'open'));
      final inProgressCount = await collection.count(where.eq('status', 'in_progress'));
      final resolvedCount = await collection.count(where.eq('status', 'resolved'));
      final closedCount = await collection.count(where.eq('status', 'closed'));
      
      // Count by category
      final feedbackCount = await collection.count(where.eq('category', 'feedback'));
      final bugReportCount = await collection.count(where.eq('category', 'bug_report'));
      final featureRequestCount = await collection.count(where.eq('category', 'feature_request'));
      final complaintCount = await collection.count(where.eq('category', 'complaint'));
      
      // Count by priority
      final urgentCount = await collection.count(where.eq('priority', 'urgent'));
      final highCount = await collection.count(where.eq('priority', 'high'));
      final mediumCount = await collection.count(where.eq('priority', 'medium'));
      final lowCount = await collection.count(where.eq('priority', 'low'));
      
      // Recent reports (last 7 days)
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final recentCount = await collection.count(
        where.gte('createdAt', weekAgo.toIso8601String()),
      );
      
      // Average rating for feedback
      final feedbackWithRating = await collection.find(
        where.eq('category', 'feedback').ne('rating', null),
      ).toList();
      
      double averageRating = 0;
      if (feedbackWithRating.isNotEmpty) {
        final totalRating = feedbackWithRating.fold<double>(
          0, 
          (sum, doc) => sum + (doc['rating'] ?? 0),
        );
        averageRating = totalRating / feedbackWithRating.length;
      }
      
      return {
        'total': total,
        'byStatus': {
          'open': openCount,
          'in_progress': inProgressCount,
          'resolved': resolvedCount,
          'closed': closedCount,
        },
        'byCategory': {
          'feedback': feedbackCount,
          'bug_report': bugReportCount,
          'feature_request': featureRequestCount,
          'complaint': complaintCount,
        },
        'byPriority': {
          'urgent': urgentCount,
          'high': highCount,
          'medium': mediumCount,
          'low': lowCount,
        },
        'recentCount': recentCount,
        'averageRating': averageRating,
      };
    });
  }
  
  // Get feedback by ID
  Future<FeedbackReport?> getFeedbackById(ObjectId feedbackId) async {
    return withRetry(() async {
      final collection = getCollection('feedback_reports');
      final result = await collection.findOne(where.id(feedbackId));
      
      if (result != null) {
        return FeedbackReport.fromJson(result);
      }
      return null;
    });
  }
  
  // Delete feedback (soft delete by changing status)
  Future<bool> deleteFeedback(ObjectId feedbackId) async {
    return withRetry(() async {
      final collection = getCollection('feedback_reports');
      final result = await collection.updateOne(
        where.id(feedbackId),
        modify.set('status', 'deleted')
          ..set('updatedAt', DateTime.now().toIso8601String()),
      );
      
      return result.isSuccess;
    });
  }

  // Create dummy feedback reports for testing
  Future<void> createDummyFeedbackReports() async {
    try {
      final collection = getCollection('feedback_reports');
      
      final dummyReports = [
        {
          'farmerId': 'FARMER001',
          'farmerName': 'राम कुमार',
          'category': 'complaint',
          'priority': 'high',
          'title': 'फसल बीमा क्लेम की समस्या',
          'description': 'मेरी फसल का बीमा क्लेम अभी तक नहीं मिला है। कृपया जल्दी से जल्दी इसका समाधान करें।',
          'rating': 2,
          'status': 'open',
          'isAnonymous': false,
          'village': 'रामपुर',
          'district': 'मेरठ',
          'state': 'उत्तर प्रदेश',
          'createdAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          'updatedAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        },
        {
          'farmerId': 'FARMER002',
          'farmerName': 'श्याम पटेल',
          'category': 'bug_report',
          'priority': 'critical',
          'title': 'ऐप में तकनीकी खराबी',
          'description': 'ऐप खुलते समय क्रैश हो जाता है। फोटो अपलोड नहीं हो रहे हैं।',
          'rating': 1,
          'status': 'in_progress',
          'isAnonymous': false,
          'village': 'सरसावा',
          'district': 'सहारनपुर',
          'state': 'उत्तर प्रदेश',
          'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'updatedAt': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
          'adminResponse': 'तकनीकी टीम इस समस्या पर काम कर रही है।',
          'adminId': 'ADMIN001',
        },
        {
          'farmerId': 'FARMER003',
          'farmerName': 'सुनीता देवी',
          'category': 'feature_request',
          'priority': 'medium',
          'title': 'हिंदी में आवाज सहायता चाहिए',
          'description': 'कृपया ऐप में हिंदी में आवाज सहायता की सुविधा जोड़ें ताकि निरक्षर किसान भी इसका उपयोग कर सकें।',
          'rating': 4,
          'status': 'resolved',
          'isAnonymous': false,
          'village': 'कल्याणपुर',
          'district': 'कानपुर',
          'state': 'उत्तर प्रदेश',
          'createdAt': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
          'updatedAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'adminResponse': 'यह सुविधा अगले अपडेट में जोड़ी जाएगी।',
          'adminId': 'ADMIN002',
          'resolvedAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        },
        {
          'farmerId': 'FARMER004',
          'farmerName': 'मोहन सिंह',
          'category': 'feedback',
          'priority': 'low',
          'title': 'ऐप बहुत अच्छा है',
          'description': 'यह ऐप बहुत उपयोगी है। इससे फसल की जानकारी आसानी से मिल जाती है।',
          'rating': 5,
          'status': 'resolved',
          'isAnonymous': false,
          'village': 'बड़गांव',
          'district': 'लखनऊ',
          'state': 'उत्तर प्रदेश',
          'createdAt': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
          'updatedAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          'adminResponse': 'आपके सुझाव के लिए धन्यवाद।',
          'adminId': 'ADMIN001',
          'resolvedAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        },
        {
          'farmerId': 'FARMER005',
          'farmerName': 'गीता शर्मा',
          'category': 'complaint',
          'priority': 'urgent',
          'title': 'ऑफिसर से संपर्क नहीं हो रहा',
          'description': 'कृषि अधिकारी का फोन नंबर गलत है। कृपया सही नंबर दें।',
          'rating': 2,
          'status': 'open',
          'isAnonymous': false,
          'village': 'मोहनपुर',
          'district': 'गाजियाबाद',
          'state': 'उत्तर प्रदेश',
          'createdAt': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
          'updatedAt': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
        },
        {
          'farmerId': 'FARMER006',
          'farmerName': 'Anonymous User',
          'category': 'bug_report',
          'priority': 'medium',
          'title': 'मौसम की जानकारी गलत',
          'description': 'ऐप में दिखाई जा रही मौसम की जानकारी वास्तविक मौसम से मेल नहीं खाती।',
          'rating': 3,
          'status': 'in_progress',
          'isAnonymous': true,
          'village': 'बुलंदशहर',
          'district': 'बुलंदशहर',
          'state': 'उत्तर प्रदेश',
          'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'updatedAt': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
        }
      ];
      
      for (var report in dummyReports) {
        await collection.insertOne(report);
      }
      
      if (kDebugMode) debugPrint('✅ Dummy feedback reports created successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error creating dummy feedback reports: $e');
    }
  }
}

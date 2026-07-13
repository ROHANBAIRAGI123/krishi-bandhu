import 'package:flutter/foundation.dart';

class MongoDBConfig {
  // MongoDB Atlas connection string
  // Format: mongodb+srv://<username>:<password>@<cluster>.mongodb.net/<database>
  static String get connectionString {
    // Load from environment variables (use --dart-define when running)
    const dbUser = String.fromEnvironment('MONGO_USER', defaultValue: 'rohanbairagi');
    const dbPassword = String.fromEnvironment('MONGO_PASSWORD', defaultValue: 'rohan123');
    const dbCluster = String.fromEnvironment('MONGO_CLUSTER', defaultValue: 'cluster0.erhip.mongodb.net');
    const dbName = String.fromEnvironment('MONGO_DB', defaultValue: 'pmfby-app');
    
    if (dbUser.isEmpty || dbPassword.isEmpty || dbCluster.isEmpty) {
      if (kDebugMode) debugPrint('⚠️ MongoDB credentials not configured properly');
      return 'mongodb://localhost:27017/$dbName'; // Fallback (won't connect)
    }
    
    return 'mongodb+srv://$dbUser:$dbPassword@$dbCluster/$dbName?retryWrites=true&w=majority';
  }
  
  static const String databaseName = 'pmfby-app';
  
  // Collection names
  static const String farmersCollection = 'farmers';
  static const String cropImagesCollection = 'crop_images';
  static const String claimsCollection = 'claims';
  static const String aiInferenceCollection = 'ai_inferences';
  static const String satelliteDataCollection = 'satellite_data';
  static const String auditLogsCollection = 'audit_logs';
  static const String officialsCollection = 'officials';
  
  // Connection pool settings
  static const int maxPoolSize = 10;
  static const int minPoolSize = 2;
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration socketTimeout = Duration(seconds: 30);
}

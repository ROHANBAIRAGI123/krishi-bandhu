class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000/api/v1',
  );

  static const String weatherApiKey = String.fromEnvironment(
    'WEATHER_API_KEY',
    defaultValue: '',
  );

  static const String weatherApiBaseUrl = String.fromEnvironment(
    'WEATHER_API_BASE_URL',
    defaultValue: 'https://api.openweathermap.org/data/2.5/',
  );

  static const String cloudinaryCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: '',
  );

  static const String cloudinaryApiKey = String.fromEnvironment(
    'CLOUDINARY_API_KEY',
    defaultValue: '',
  );

  static const String cloudinaryApiSecret = String.fromEnvironment(
    'CLOUDINARY_API_SECRET',
    defaultValue: '',
  );

  static const String cloudinaryUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: '',
  );

  static const String gmailEmail = String.fromEnvironment(
    'GMAIL_EMAIL',
    defaultValue: '',
  );

  static const String gmailAppPassword = String.fromEnvironment(
    'GMAIL_APP_PASSWORD',
    defaultValue: '',
  );

  static const String mongoUser = String.fromEnvironment(
    'MONGO_USER',
    defaultValue: '',
  );

  static const String mongoPassword = String.fromEnvironment(
    'MONGO_PASSWORD',
    defaultValue: '',
  );

  static const String mongoCluster = String.fromEnvironment(
    'MONGO_CLUSTER',
    defaultValue: '',
  );

  static const String mongoDb = String.fromEnvironment(
    'MONGO_DB',
    defaultValue: 'pmfby-app',
  );

  // Aliases used by mongodb_config.dart
  static const String mongodbUser = mongoUser;
  static const String mongodbPassword = mongoPassword;
  static const String mongodbCluster = mongoCluster;
  static const String mongodbDatabase = mongoDb;
}


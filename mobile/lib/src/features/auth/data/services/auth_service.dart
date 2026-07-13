import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:crypto/crypto.dart';
import '../../domain/models/user_model.dart';
import '../../../../services/mongodb_service.dart';
import '../../../../models/mongodb/farmer_model.dart';
import '../../../../models/mongodb/official_model.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class AuthService {
  static const String _userKey = 'krashi_bandhu_user';
  static const String _usersListKey = 'krashi_bandhu_users';
  static const String _isLoggedInKey = 'krashi_bandhu_is_logged_in';

  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Register a new user
  Future<bool> register(User user) async {
    developer.log('📝 AuthService: Starting registration for ${user.email}');
    
    try {
      // Check MongoDB first if connected
      try {
        final mongoService = MongoDBService.instance;
        if (mongoService.isConnected) {
          developer.log('🔍 Checking if user exists in MongoDB...');
          final existsInMongo = await _checkUserExistsInMongoDB(user.email, user.phone);
          if (existsInMongo) {
            developer.log('❌ User already exists in MongoDB: ${user.email}');
            return false; // User already exists in MongoDB
          }
          developer.log('✅ User does not exist in MongoDB');
        } else {
          developer.log('⚠️ MongoDB not connected, skipping MongoDB check');
        }
      } catch (mongoError) {
        developer.log('⚠️ MongoDB check failed (continuing): $mongoError');
        // Continue with local check if MongoDB fails
      }
      
      // Get existing users list from SharedPreferences
      final usersJson = _prefs.getStringList(_usersListKey) ?? [];
      
      // Check if user already exists in SharedPreferences
      for (var userJson in usersJson) {
        final existingUser = User.fromJson(jsonDecode(userJson));
        if (existingUser.email == user.email) {
          developer.log('❌ User already exists in SharedPreferences: ${user.email}');
          return false; // User already exists
        }
      }

      developer.log('✅ User does not exist in local storage, proceeding with registration');
      
      // Add new user to SharedPreferences list
      usersJson.add(jsonEncode(user.toJson()));
      await _prefs.setStringList(_usersListKey, usersJson);
      developer.log('💾 User saved to SharedPreferences');

      // Try to save to MongoDB
      try {
        developer.log('🗄️ Attempting to save to MongoDB...');
        await _saveToMongoDB(user);
        developer.log('✅ User saved to MongoDB successfully');
      } catch (mongoError) {
        developer.log('⚠️ MongoDB save failed (continuing with local storage): $mongoError');
        // Continue even if MongoDB fails - user is still saved locally
      }

      // Auto-login after registration
      await _loginUser(user);
      developer.log('✅ Registration completed successfully');
      return true;
    } catch (e, stackTrace) {
      developer.log('❌ Registration error: $e');
      developer.log('Stack trace: $stackTrace');
      return false;
    }
  }

  // Check if user exists in MongoDB
  Future<bool> _checkUserExistsInMongoDB(String email, String phone) async {
    try {
      final mongoService = MongoDBService.instance;
      final db = mongoService.database;
      
      if (db == null) {
        developer.log('⚠️ Database not available for user check');
        return false;
      }

      // Check in farmers collection
      final farmersCollection = db.collection('farmers');
      final farmerExists = await farmersCollection.findOne(
        mongo.where.eq('phone', phone)
      );
      
      if (farmerExists != null) {
        developer.log('📱 Found existing farmer with phone: $phone');
        return true;
      }

      // Check in officials collection
      final officialsCollection = db.collection('officials');
      final officialExists = await officialsCollection.findOne(
        mongo.where.eq('phone', phone)
      );
      
      if (officialExists != null) {
        developer.log('📱 Found existing official with phone: $phone');
        return true;
      }

      developer.log('✅ No existing user found in MongoDB');
      return false;
    } catch (e) {
      developer.log('⚠️ Error checking MongoDB for existing user: $e');
      return false; // Return false on error to allow registration to proceed
    }
  }

  // Save user to MongoDB
  Future<void> _saveToMongoDB(User user) async {
    final mongoService = MongoDBService.instance;
    
    // Check if MongoDB is connected
    if (!mongoService.isConnected) {
      developer.log('⚠️ MongoDB not connected, attempting to connect...');
      await mongoService.connect();
    }

    if (user.role == 'farmer') {
      developer.log('👨‍🌾 Saving farmer to MongoDB...');
      await _saveFarmerToMongo(user);
    } else if (user.role == 'official') {
      developer.log('👮 Saving official to MongoDB...');
      await _saveOfficialToMongo(user);
    }
  }

  // Save farmer to MongoDB
  Future<void> _saveFarmerToMongo(User user) async {
    final db = MongoDBService.instance.database;
    if (db == null) {
      developer.log('❌ Database not connected');
      throw Exception('Database not connected');
    }
    
    final collection = db.collection('farmers');
    
    // Split name into first and last
    final nameParts = user.name.split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    // Hash and mask Aadhar number
    final aadharHash = sha256.convert(utf8.encode(user.aadharNumber ?? '')).toString();
    final aadharDisplay = user.aadharNumber != null && user.aadharNumber!.length == 12
        ? 'xxxx-xxxx-${user.aadharNumber!.substring(8)}'
        : 'xxxx-xxxx-xxxx';

    final farmerModel = FarmerModel(
      farmerId: user.userId,
      name: FarmerName(first: firstName, last: lastName),
      phone: user.phone,
      aadhaar: AadhaarInfo(
        number: aadharHash,
        displayNumber: aadharDisplay,
        verified: true,
      ),
      address: FarmerAddress(
        state: user.state ?? '',
        district: user.district ?? '',
        taluka: '', // Not captured in registration
        village: user.village ?? '',
        pincode: '', // Not captured in registration
      ),
      landParcels: user.farmSize != null
          ? [
              LandParcel(
                parcelId: 'AUTO_${DateTime.now().millisecondsSinceEpoch}',
                area: user.farmSize!,
                geoBoundary: GeoBoundary(
                  type: 'Polygon',
                  coordinates: [], // Empty for now, can be added later
                ),
                cropHistory: (user.cropTypes ?? [])
                    .map((cropName) => CropHistory(
                          season: 'Kharif',
                          cropType: cropName,
                          sowingDate: DateTime.now(),
                          harvestDate: null,
                        ))
                    .toList(),
              )
            ]
          : [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    developer.log('💾 Inserting farmer document...');
    try {
      await collection.insertOne(farmerModel.toMap());
      developer.log('✅ Farmer document inserted');
    } catch (e) {
      if (e.toString().contains('E11000') || e.toString().contains('duplicate key')) {
        developer.log('⚠️ Duplicate farmer record in MongoDB (phone: ${user.phone})');
        throw Exception('User with this phone number already exists');
      }
      developer.log('❌ Error inserting farmer: $e');
      rethrow;
    }
  }

  // Save official to MongoDB
  Future<void> _saveOfficialToMongo(User user) async {
    final db = MongoDBService.instance.database;
    if (db == null) {
      developer.log('❌ Database not connected');
      throw Exception('Database not connected');
    }
    
    final collection = db.collection('officials');
    
    // Hash password
    final passwordHash = sha256.convert(utf8.encode(user.password ?? '')).toString();

    final officialModel = OfficialModel(
      userId: user.userId,
      role: user.designation ?? 'field_officer',
      name: user.name,
      phone: user.phone,
      passwordHash: passwordHash,
      assignedDistrict: user.assignedDistrict,
      permissions: ['verify_claims', 'inspect_fields', 'upload_reports'],
      createdAt: DateTime.now(),
      lastLogin: null,
    );

    developer.log('💾 Inserting official document...');
    try {
      await collection.insertOne(officialModel.toMap());
      developer.log('✅ Official document inserted');
    } catch (e) {
      if (e.toString().contains('E11000') || e.toString().contains('duplicate key')) {
        developer.log('⚠️ Duplicate official record in MongoDB (phone: ${user.phone})');
        throw Exception('User with this phone number already exists');
      }
      developer.log('❌ Error inserting official: $e');
      rethrow;
    }
  }

  // Login user
  Future<bool> login(String email, String password) async {
    developer.log('🔐 AuthService: Attempting login for $email');
    
    try {
      final usersJson = _prefs.getStringList(_usersListKey) ?? [];
      developer.log('📋 Found ${usersJson.length} registered users');

      for (var userJson in usersJson) {
        final user = User.fromJson(jsonDecode(userJson));
        if (user.email == email && user.password == password) {
          developer.log('✅ Credentials match! Logging in user...');
          await _loginUser(user);
          return true;
        }
      }
      
      developer.log('❌ Login failed - invalid credentials');
      return false; // User not found or password incorrect
    } catch (e, stackTrace) {
      developer.log('❌ Login error: $e');
      developer.log('Stack trace: $stackTrace');
      return false;
    }
  }

  // Private method to set user as logged in
  Future<void> _loginUser(User user) async {
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
    await _prefs.setBool(_isLoggedInKey, true);
  }

  // Get current logged-in user
  User? getCurrentUser() {
    try {
      final userJson = _prefs.getString(_userKey);
      if (userJson == null) return null;
      return User.fromJson(jsonDecode(userJson));
    } catch (e) {
      debugPrint('Get user error: $e');
      return null;
    }
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Logout
  Future<void> logout() async {
    await _prefs.remove(_userKey);
    await _prefs.setBool(_isLoggedInKey, false);
  }

  // Get all users (for debugging)
  List<User> getAllUsers() {
    try {
      final usersJson = _prefs.getStringList(_usersListKey) ?? [];
      return usersJson
          .map((userJson) => User.fromJson(jsonDecode(userJson)))
          .toList();
    } catch (e) {
      debugPrint('Get all users error: $e');
      return [];
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(User updatedUser) async {
    try {
      // Update in users list
      final usersJson = _prefs.getStringList(_usersListKey) ?? [];
      for (int i = 0; i < usersJson.length; i++) {
        final user = User.fromJson(jsonDecode(usersJson[i]));
        if (user.userId == updatedUser.userId) {
          usersJson[i] = jsonEncode(updatedUser.toJson());
          break;
        }
      }
      await _prefs.setStringList(_usersListKey, usersJson);

      // Update current user if it's the same
      final currentUser = getCurrentUser();
      if (currentUser?.userId == updatedUser.userId) {
        await _prefs.setString(_userKey, jsonEncode(updatedUser.toJson()));
      }

      return true;
    } catch (e) {
      debugPrint('Update user error: $e');
      return false;
    }
  }

  // Clear all data (for debugging/testing)
  Future<void> clearAll() async {
    await _prefs.remove(_userKey);
    await _prefs.remove(_usersListKey);
    await _prefs.remove(_isLoggedInKey);
  }
}

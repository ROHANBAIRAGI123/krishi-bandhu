import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🌱 Starting MongoDB Demo Data Seeding...\n');

  // Get credentials
  const mongoUser = String.fromEnvironment('MONGO_USER', defaultValue: 'rohanbairagi');
  const mongoPassword = String.fromEnvironment('MONGO_PASSWORD', defaultValue: 'rohan123');
  const mongoCluster = String.fromEnvironment('MONGO_CLUSTER', defaultValue: 'cluster0.erhip.mongodb.net');
  const mongoDb = String.fromEnvironment('MONGO_DB', defaultValue: 'pmfby-app');

  final connectionString = 'mongodb+srv://$mongoUser:$mongoPassword@$mongoCluster/$mongoDb?retryWrites=true&w=majority';
  
  print('📡 Connecting to MongoDB Atlas...');
  print('   Cluster: $mongoCluster');
  print('   Database: $mongoDb\n');

  late Db db;
  
  try {
    db = await Db.create(connectionString);
    await db.open();
    print('✅ Connected to MongoDB successfully!\n');

    // Clear existing collections
    print('🗑️  Clearing existing collections...');
    try { await db.collection('farmers').drop(); } catch (e) { print('  farmers not found (ok)'); }
    try { await db.collection('officials').drop(); } catch (e) { print('  officials not found (ok)'); }
    try { await db.collection('crop_images').drop(); } catch (e) { print('  crop_images not found (ok)'); }
    try { await db.collection('claims').drop(); } catch (e) { print('  claims not found (ok)'); }
    try { await db.collection('crop_loss_intimations').drop(); } catch (e) { print('  crop_loss_intimations not found (ok)'); }
    print('✅ Collections cleared\n');

    // Hash functions
    String hashPassword(String password) => sha256.convert(utf8.encode(password)).toString();
    String hashAadhaar(String aadhaar) => sha256.convert(utf8.encode(aadhaar)).toString();

    // Seed Farmers
    print('👨‍🌾 Seeding farmers...');
    final farmers = [
      {
        'userId': 'F001',
        'name': {'firstName': 'Ramesh', 'middleName': 'Kumar', 'lastName': 'Patel'},
        'aadhaarInfo': {
          'aadhaarHash': hashAadhaar('123456789012'),
          'isVerified': true,
          'verifiedAt': DateTime.now().subtract(const Duration(days: 90)).toIso8601String(),
        },
        'phoneNumber': '+919876543210',
        'address': {
          'village': 'Khedli',
          'taluka': 'Anand',
          'district': 'Anand',
          'state': 'Gujarat',
          'pincode': '388001',
        },
        'landParcels': [
          {
            'surveyNumber': '123/1',
            'area': 2.5,
            'geoBoundary': {
              'coordinates': [[72.9633, 22.5584], [72.9643, 22.5584], [72.9643, 22.5574], [72.9633, 22.5574]],
              'type': 'Polygon',
            },
            'cropHistory': [
              {'cropName': 'Wheat', 'season': 'Rabi 2023-24', 'survivalRate': 95.0}
            ],
          }
        ],
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      {
        'userId': 'F002',
        'name': {'firstName': 'Suresh', 'middleName': '', 'lastName': 'Desai'},
        'aadhaarInfo': {
          'aadhaarHash': hashAadhaar('234567890123'),
          'isVerified': true,
          'verifiedAt': DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
        },
        'phoneNumber': '+919876543211',
        'address': {
          'village': 'Vadtal',
          'taluka': 'Kheda',
          'district': 'Kheda',
          'state': 'Gujarat',
          'pincode': '387375',
        },
        'landParcels': [
          {
            'surveyNumber': '456/2',
            'area': 3.0,
            'geoBoundary': {
              'coordinates': [[72.9733, 22.5684], [72.9743, 22.5684], [72.9743, 22.5674], [72.9733, 22.5674]],
              'type': 'Polygon',
            },
            'cropHistory': [
              {'cropName': 'Cotton', 'season': 'Kharif 2023', 'survivalRate': 88.0}
            ],
          }
        ],
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      {
        'userId': 'F003',
        'name': {'firstName': 'Mahesh', 'middleName': 'Singh', 'lastName': 'Rathore'},
        'aadhaarInfo': {
          'aadhaarHash': hashAadhaar('345678901234'),
          'isVerified': false,
        },
        'phoneNumber': '+919876543212',
        'address': {
          'village': 'Borsad',
          'taluka': 'Borsad',
          'district': 'Anand',
          'state': 'Gujarat',
          'pincode': '388540',
        },
        'landParcels': [
          {
            'surveyNumber': '789/3',
            'area': 1.8,
            'geoBoundary': {
              'coordinates': [[72.9833, 22.5784], [72.9843, 22.5784], [72.9843, 22.5774], [72.9833, 22.5774]],
              'type': 'Polygon',
            },
            'cropHistory': [],
          }
        ],
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
    ];
    await db.collection('farmers').insertAll(farmers);
    print('✅ Inserted ${farmers.length} farmers\n');

    // Seed Officials
    print('👮 Seeding officials...');
    final officials = [
      {
        'userId': 'OFF001',
        'name': {'firstName': 'fuckram', 'middleName': '', 'lastName': 'Singh'},
        'role': 'Field Officer',
        'passwordHash': hashPassword('password123'),
        'email': 'vikram.singh@pmfby.gov.in',
        'phoneNumber': '+919123456789',
        'assignedDistrict': 'Anand',
        'permissions': ['verify_claims', 'inspect_fields', 'upload_reports'],
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      {
        'userId': 'OFF002',
        'name': {'firstName': 'anupriya', 'middleName': '', 'lastName': 'Sharma'},
        'role': 'Senior Officer',
        'passwordHash': hashPassword('password456'),
        'email': 'priya.sharma@pmfby.gov.in',
        'phoneNumber': '+919123456790',
        'assignedDistrict': 'Kheda',
        'permissions': ['verify_claims', 'inspect_fields', 'upload_reports', 'approve_payouts'],
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
    ];
    await db.collection('officials').insertAll(officials);
    print('✅ Inserted ${officials.length} officials\n');

    // Seed Crop Images
    print('📷 Seeding crop images...');
    final cropImages = [
      {
        'imageId': 'IMG001',
        'farmerId': 'F001',
        'surveyNumber': '123/1',
        'imageUrl': 'https://cloudinary.com/sample/wheat_field_001.jpg',
        'imageMetadata': {'width': 1920, 'height': 1080, 'format': 'jpg', 'sizeBytes': 524288},
        'geoLocation': {
          'latitude': 22.5584,
          'longitude': 72.9633,
          'accuracy': 5.0,
          'altitude': 45.5,
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        },
        'cropInfo': {'cropName': 'Wheat', 'growthStage': 'Flowering', 'estimatedHealth': 'Good'},
        'mlVerification': {
          'inferenceId': 'ML_${DateTime.now().millisecondsSinceEpoch}_001',
          'predictions': {'Wheat': 0.95, 'Barley': 0.03, 'Oats': 0.02},
          'confidenceScore': 0.95,
          'processedAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        },
        'officerVerification': {
          'officerId': 'OFF001',
          'verificationStatus': 'Verified',
          'decision': 'Approved',
          'remarks': 'Healthy wheat crop in flowering stage',
          'verifiedAt': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
        },
        'uploadedAt': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      },
    ];
    await db.collection('crop_images').insertAll(cropImages);
    print('✅ Inserted ${cropImages.length} crop images\n');

    // Seed Claims
    print('📋 Seeding claims...');
    final claims = [
      {
        'claimId': 'CLM001',
        'farmerId': 'F001',
        'surveyNumber': '123/1',
        'submission': {
          'submittedAt': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
          'cropName': 'Wheat',
          'claimAmount': 50000.0,
          'lossPercentage': 30.0,
          'reason': 'Unseasonal rainfall',
          'supportingImageIds': ['IMG001'],
        },
        'aiAssessment': {
          'assessmentScore': 0.78,
          'predictedLossPercentage': 28.5,
          'confidenceLevel': 0.82,
          'flaggedIssues': [],
          'processedAt': DateTime.now().subtract(const Duration(days: 14)).toIso8601String(),
        },
        'humanReview': {
          'required': true,
          'reviewedBy': 'OFF001',
          'reviewComments': 'Claim verified, loss percentage slightly adjusted',
          'reviewedAt': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
        },
        'payout': {
          'eligible': true,
          'approvedAmount': 47500.0,
          'adjustmentReason': 'AI predicted slightly lower loss',
          'processedAt': DateTime.now().subtract(const Duration(days: 8)).toIso8601String(),
          'paymentStatus': 'Completed',
          'paymentDate': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        },
        'status': 'Approved',
        'createdAt': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
        'updatedAt': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      },
    ];
    await db.collection('claims').insertAll(claims);
    print('✅ Inserted ${claims.length} claims\n');

    // Seed Crop Loss Intimations
    print('⚠️  Seeding crop loss intimations...');
    final cropLossIntimations = [
      {
        'intimationId': 'INT001',
        'farmerId': 'F001',
        'surveyNumber': '123/1',
        'lossDetails': {
          'lossCause': 'Unseasonal Rainfall',
          'lossDate': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
          'estimatedLossPercentage': 30.0,
          'affectedArea': 2.0,
          'cropName': 'Wheat',
          'cropStage': 'Flowering',
          'symptoms': ['Waterlogging', 'Stem lodging', 'Fungal growth'],
        },
        'geoLocation': {
          'latitude': 22.5584,
          'longitude': 72.9633,
          'accuracy': 5.0,
          'capturedAt': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
        },
        'weatherCondition': {'temperature': 28.5, 'humidity': 85.0, 'rainfall': 120.0, 'windSpeed': 15.5},
        'officerAssessment': {
          'officerId': 'OFF001',
          'officerName': 'Vikram Singh',
          'assessedLossPercentage': 28.0,
          'isEligibleForClaim': true,
          'assessmentRemarks': 'Unseasonal rain damage confirmed',
          'verifiedImageIds': ['IMG001'],
          'assessedAt': DateTime.now().subtract(const Duration(days: 18)).toIso8601String(),
        },
        'status': 'Verified',
        'createdAt': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
        'updatedAt': DateTime.now().subtract(const Duration(days: 18)).toIso8601String(),
      },
    ];
    await db.collection('crop_loss_intimations').insertAll(cropLossIntimations);
    print('✅ Inserted ${cropLossIntimations.length} crop loss intimations\n');

    // Create indexes
    print('🔍 Creating indexes...');
    await db.collection('farmers').createIndex(key: 'userId', unique: true);
    await db.collection('officials').createIndex(key: 'userId', unique: true);
    await db.collection('crop_images').createIndex(key: 'imageId', unique: true);
    await db.collection('claims').createIndex(key: 'claimId', unique: true);
    await db.collection('crop_loss_intimations').createIndex(key: 'intimationId', unique: true);
    print('✅ Indexes created\n');

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('✅ MongoDB Seeding Completed Successfully!\n');
    print('📊 Summary:');
    print('   • Farmers: ${farmers.length}');
    print('   • Officials: ${officials.length}');
    print('   • Crop Images: ${cropImages.length}');
    print('   • Claims: ${claims.length}');
    print('   • Crop Loss Intimations: ${cropLossIntimations.length}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    await db.close();
    
    // Give time for output to flush
    await Future.delayed(const Duration(seconds: 2));
    
  } catch (e, stackTrace) {
    print('❌ Error during seeding: $e');
    print('Stack trace: $stackTrace');
    try {
      await db.close();
    } catch (_) {}
  }
  
  // Don't run the app UI, just exit after seeding
  print('✅ Script completed. Exiting...');
}

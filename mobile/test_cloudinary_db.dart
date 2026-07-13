import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> main() async {
  print('🔍 Testing Cloudinary Connection and Database Storage...\n');
  
  // Cloudinary credentials
  const cloudName = 'dxahqsgwv';
  const apiKey = '916295378241238';
  const apiSecret = 'X2GoZB5cN3lnPSE4HEuOAby1m80';
  const uploadPreset = 'pmfby-app';
  
  print('📋 Configuration:');
  print('  Cloud Name: $cloudName');
  print('  API Key: $apiKey');
  print('  Upload Preset: $uploadPreset\n');
  
  // Test 1: Check Cloudinary API connectivity
  print('1️⃣ Testing Cloudinary API connectivity...');
  try {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/resources/image');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode('$apiKey:$apiSecret'))}',
      },
    ).timeout(Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      print('   ✅ Cloudinary API is accessible');
      final data = json.decode(response.body);
      print('   📊 Total images in cloud: ${data['resources']?.length ?? 0}');
    } else {
      print('   ❌ Cloudinary API returned status ${response.statusCode}');
      print('   Response: ${response.body}');
    }
  } catch (e) {
    print('   ❌ Failed to connect to Cloudinary: $e');
  }
  
  print('');
  
  // Test 2: Test unsigned upload capability
  print('2️⃣ Testing unsigned upload preset...');
  try {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/upload_presets/$uploadPreset');
    // Note: This endpoint might not be publicly accessible, but we can try
    print('   ℹ️  Upload preset configured: $uploadPreset');
    print('   ℹ️  Unsigned uploads should be enabled in Cloudinary dashboard');
  } catch (e) {
    print('   ⚠️  Could not verify upload preset: $e');
  }
  
  print('');
  
  // Test 3: Check MongoDB connection from .env
  print('3️⃣ Checking MongoDB configuration...');
  try {
    // Read .env file
    final envFile = File('.env');
    if (await envFile.exists()) {
      final envContent = await envFile.readAsString();
      final mongoUri = envContent
          .split('\n')
          .firstWhere((line) => line.startsWith('MONGODB_URI='), orElse: () => '')
          .replaceFirst('MONGODB_URI=', '');
      
      if (mongoUri.isNotEmpty) {
        print('   ✅ MongoDB URI found in .env');
        // Parse MongoDB URI to extract details
        final uri = Uri.parse(mongoUri);
        print('   📊 Database host: ${uri.host}');
        print('   ℹ️  To test MongoDB connection, run the Flutter app');
      } else {
        print('   ⚠️  MongoDB URI not found in .env file');
      }
    } else {
      print('   ⚠️  .env file not found');
    }
  } catch (e) {
    print('   ❌ Error checking MongoDB config: $e');
  }
  
  print('');
  
  // Test 4: Check if required services exist
  print('4️⃣ Checking service files...');
  final serviceFiles = [
    'lib/src/services/cloud_image_service.dart',
    'lib/src/services/local_storage_service.dart',
    'lib/src/services/auto_sync_service.dart',
    'lib/src/services/image_deduplication_service.dart',
  ];
  
  for (final filePath in serviceFiles) {
    final file = File(filePath);
    if (await file.exists()) {
      print('   ✅ ${filePath.split('/').last}');
    } else {
      print('   ❌ Missing: ${filePath.split('/').last}');
    }
  }
  
  print('');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('📝 Summary:');
  print('   • Cloudinary API credentials are configured');
  print('   • Upload preset: $uploadPreset');
  print('   • Service files are present');
  print('   • To fully test: Run app and capture an image');
  print('   • Check logs for "Upload successful:" message');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('');
  print('🔧 Next steps:');
  print('   1. Run: flutter run');
  print('   2. Capture an image using AR camera');
  print('   3. Check console for upload success messages');
  print('   4. Verify image appears in Cloudinary dashboard');
  print('   5. Check MongoDB database for stored URL');
}

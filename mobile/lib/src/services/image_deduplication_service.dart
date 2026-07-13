import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

/// Service to prevent duplicate image uploads using perceptual hashing
class ImageDeduplicationService {
  static const String _uploadedHashesKey = 'uploaded_image_hashes';
  static const int _maxHashCacheSize = 100; // Keep last 100 image hashes
  static const int _hammingDistanceThreshold = 5; // Similar if ≤5 bits different

  /// Check if an image is a duplicate or very similar to already uploaded images
  Future<bool> isImageDuplicate(File imageFile) async {
    try {
      final imageHash = await calculateImageHash(imageFile);
      final uploadedHashes = await _getUploadedHashes();
      
      // Check if this exact hash or similar hash exists
      for (final existingHash in uploadedHashes) {
        final distance = _calculateHammingDistance(imageHash, existingHash);
        if (distance <= _hammingDistanceThreshold) {
          return true; // Duplicate or very similar image found
        }
      }
      
      return false; // Unique image
    } catch (e) {
      print('Error checking image duplicate: $e');
      return false; // On error, allow upload
    }
  }

  /// Mark an image as uploaded by storing its hash
  Future<void> markImageAsUploaded(File imageFile) async {
    try {
      final imageHash = await calculateImageHash(imageFile);
      final hashes = await _getUploadedHashes();
      
      // Add new hash
      hashes.add(imageHash);
      
      // Limit cache size (remove oldest if exceeds limit)
      if (hashes.length > _maxHashCacheSize) {
        hashes.removeRange(0, hashes.length - _maxHashCacheSize);
      }
      
      // Save updated hashes
      await _saveUploadedHashes(hashes);
    } catch (e) {
      print('Error marking image as uploaded: $e');
    }
  }

  /// Calculate perceptual hash of an image (aHash algorithm)
  /// Returns a 64-bit hash as a string
  Future<String> calculateImageHash(File imageFile) async {
    // Read image file
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(Uint8List.fromList(bytes));
    
    if (image == null) {
      throw Exception('Failed to decode image');
    }
    
    // Step 1: Resize to 8x8 grayscale
    final resized = img.copyResize(image, width: 8, height: 8);
    final grayscale = img.grayscale(resized);
    
    // Step 2: Calculate average pixel value
    int sum = 0;
    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        final pixel = grayscale.getPixel(x, y);
        sum += pixel.r.toInt(); // In grayscale, r=g=b
      }
    }
    final average = sum / 64;
    
    // Step 3: Create hash - 1 if pixel > average, 0 otherwise
    final hashBits = StringBuffer();
    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        final pixel = grayscale.getPixel(x, y);
        hashBits.write(pixel.r > average ? '1' : '0');
      }
    }
    
    // Convert binary string to hexadecimal for compact storage
    final binaryString = hashBits.toString();
    final hexHash = StringBuffer();
    for (int i = 0; i < binaryString.length; i += 4) {
      final nibble = binaryString.substring(i, i + 4);
      hexHash.write(int.parse(nibble, radix: 2).toRadixString(16));
    }
    
    return hexHash.toString();
  }

  /// Calculate Hamming distance between two hashes
  /// (number of bit positions that differ)
  int _calculateHammingDistance(String hash1, String hash2) {
    if (hash1.length != hash2.length) {
      return 999; // Invalid comparison
    }
    
    int distance = 0;
    
    // Convert hex back to binary and compare
    for (int i = 0; i < hash1.length; i++) {
      final bits1 = int.parse(hash1[i], radix: 16);
      final bits2 = int.parse(hash2[i], radix: 16);
      final xor = bits1 ^ bits2;
      
      // Count number of 1s in XOR result
      distance += xor.bitLength > 0 ? _countSetBits(xor) : 0;
    }
    
    return distance;
  }

  /// Count number of set bits in an integer
  int _countSetBits(int n) {
    int count = 0;
    while (n > 0) {
      count += n & 1;
      n >>= 1;
    }
    return count;
  }

  /// Get list of uploaded image hashes from storage
  Future<List<String>> _getUploadedHashes() async {
    final prefs = await SharedPreferences.getInstance();
    final hashesJson = prefs.getString(_uploadedHashesKey);
    
    if (hashesJson == null) {
      return [];
    }
    
    try {
      final List<dynamic> decoded = List<String>.from(
        (hashesJson.split(',').where((s) => s.isNotEmpty).toList())
      );
      return decoded.cast<String>();
    } catch (e) {
      print('Error parsing uploaded hashes: $e');
      return [];
    }
  }

  /// Save list of uploaded image hashes to storage
  Future<void> _saveUploadedHashes(List<String> hashes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_uploadedHashesKey, hashes.join(','));
  }

  /// Clear all cached hashes (useful for testing or reset)
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_uploadedHashesKey);
  }
}

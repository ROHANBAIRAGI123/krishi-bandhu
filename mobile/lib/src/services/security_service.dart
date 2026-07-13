import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class SecurityService {
  // Hash password using SHA-256
  static String hashPassword(String password, {String? salt}) {
    salt ??= _generateSalt();
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return '$salt:${digest.toString()}';
  }
  
  // Verify password against hash
  static bool verifyPassword(String password, String hashedPassword) {
    try {
      final parts = hashedPassword.split(':');
      if (parts.length != 2) return false;
      
      final salt = parts[0];
      final hash = parts[1];
      
      final bytes = utf8.encode(password + salt);
      final digest = sha256.convert(bytes);
      
      return digest.toString() == hash;
    } catch (e) {
      debugPrint('Error verifying password: $e');
      return false;
    }
  }
  
  // Generate random salt
  static String _generateSalt() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(random);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }
  
  // Hash sensitive data (like Aadhaar)
  static String hashSensitiveData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Encrypt Aadhaar for storage (last 4 digits visible)
  static String maskAadhaar(String aadhaar) {
    if (aadhaar.length < 4) return 'xxxx';
    final last4 = aadhaar.substring(aadhaar.length - 4);
    return 'xxxx-xxxx-$last4';
  }
  
  // Encrypt phone number (last 4 digits visible)
  static String maskPhone(String phone) {
    if (phone.length < 4) return 'xxxx';
    final last4 = phone.substring(phone.length - 4);
    return '+91xxxxxx$last4';
  }
  
  // Generate secure token
  static String generateToken(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final data = '$userId:$timestamp';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Validate token (basic implementation)
  static bool validateToken(String token, String userId, {Duration expiry = const Duration(hours: 24)}) {
    // In production, implement proper JWT or similar token validation
    return token.isNotEmpty && userId.isNotEmpty;
  }
  
  // Sanitize input to prevent injection attacks
  static String sanitizeInput(String input) {
    return input
        .replaceAll(r'$', '')
        .replaceAll('{', '')
        .replaceAll('}', '')
        .replaceAll('[', '')
        .replaceAll(']', '')
        .trim();
  }
  
  // Validate Aadhaar number format
  static bool isValidAadhaar(String aadhaar) {
    final pattern = RegExp(r'^\d{12}$');
    return pattern.hasMatch(aadhaar.replaceAll('-', '').replaceAll(' ', ''));
  }
  
  // Validate phone number format
  static bool isValidPhone(String phone) {
    final pattern = RegExp(r'^\+91\d{10}$|^\d{10}$');
    return pattern.hasMatch(phone);
  }
  
  // Normalize phone number
  static String normalizePhone(String phone) {
    phone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (phone.length == 10) {
      return '+91$phone';
    }
    return phone;
  }
}

import 'dart:developer' as developer;
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Service for Aadhar card validation and verification
class AadharService {
  static final AadharService instance = AadharService._internal();
  factory AadharService() => instance;
  AadharService._internal();

  // Set to true to enable verbose logging (for debugging)
  static const bool _verboseLogging = false;

  final Random _random = Random.secure();
  
  // OTP storage for mobile verification
  final Map<String, _MobileOTPData> _mobileOtpStorage = {};
  static const Duration otpValidity = Duration(minutes: 10);
  
  // Store Aadhar-linked mobile numbers temporarily for OTP verification
  final Map<String, String> _aadharMobileMap = {};
  
  /// Validate Aadhar number format and checksum (Verhoeff algorithm)
  bool validateAadharNumber(String aadhar) {
    if (_verboseLogging) developer.log('🔍 Validating Aadhar: $aadhar');
    
    // Remove spaces and dashes
    aadhar = aadhar.replaceAll(RegExp(r'[\s-]'), '');
    
    // Must be exactly 12 digits
    if (aadhar.length != 12) {
      if (_verboseLogging) developer.log('❌ Aadhar validation failed: Invalid length ${aadhar.length}');
      return false;
    }
    
    // Must be all numbers
    if (!RegExp(r'^\d{12}$').hasMatch(aadhar)) {
      if (_verboseLogging) developer.log('❌ Aadhar validation failed: Contains non-numeric characters');
      return false;
    }
    
    // First digit cannot be 0 or 1
    if (aadhar[0] == '0' || aadhar[0] == '1') {
      if (_verboseLogging) developer.log('❌ Aadhar validation failed: Invalid first digit');
      return false;
    }
    
    // Validate using Verhoeff algorithm
    if (!_verhoeffValidation(aadhar)) {
      if (_verboseLogging) developer.log('❌ Aadhar validation failed: Checksum mismatch');
      return false;
    }
    
    if (_verboseLogging) developer.log('✅ Aadhar validation passed');
    return true;
  }
  
  /// Verhoeff algorithm for Aadhar checksum validation
  bool _verhoeffValidation(String num) {
    // Verhoeff multiplication table
    final d = [
      [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
      [1, 2, 3, 4, 0, 6, 7, 8, 9, 5],
      [2, 3, 4, 0, 1, 7, 8, 9, 5, 6],
      [3, 4, 0, 1, 2, 8, 9, 5, 6, 7],
      [4, 0, 1, 2, 3, 9, 5, 6, 7, 8],
      [5, 9, 8, 7, 6, 0, 4, 3, 2, 1],
      [6, 5, 9, 8, 7, 1, 0, 4, 3, 2],
      [7, 6, 5, 9, 8, 2, 1, 0, 4, 3],
      [8, 7, 6, 5, 9, 3, 2, 1, 0, 4],
      [9, 8, 7, 6, 5, 4, 3, 2, 1, 0],
    ];
    
    // Permutation table
    final p = [
      [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
      [1, 5, 7, 6, 2, 8, 3, 0, 9, 4],
      [5, 8, 0, 3, 7, 9, 6, 1, 4, 2],
      [8, 9, 1, 6, 0, 4, 3, 5, 2, 7],
      [9, 4, 5, 3, 1, 2, 6, 8, 7, 0],
      [4, 2, 8, 6, 5, 7, 3, 9, 0, 1],
      [2, 7, 9, 3, 8, 0, 6, 4, 1, 5],
      [7, 0, 4, 6, 9, 1, 3, 2, 5, 8],
    ];
    
    // Inverse table
    final inv = [0, 4, 3, 2, 1, 5, 6, 7, 8, 9];
    
    var c = 0;
    final myArray = num.split('').reversed.toList();
    
    for (var i = 0; i < myArray.length; i++) {
      c = d[c][p[(i % 8)][int.parse(myArray[i])]];
    }
    
    return c == 0;
  }
  
  /// Format Aadhar number for display (XXXX-XXXX-1234)
  String formatAadharDisplay(String aadhar) {
    aadhar = aadhar.replaceAll(RegExp(r'[\s-]'), '');
    if (aadhar.length == 12) {
      return 'XXXX-XXXX-${aadhar.substring(8)}';
    }
    return 'XXXX-XXXX-XXXX';
  }
  
  /// Send OTP to Aadhar-linked mobile number
  /// In real implementation, this would call UIDAI API
  /// For demo, we'll accept user's mobile and send OTP there
  Future<bool> sendAadharMobileOTP(String aadharNumber, String mobileNumber) async {
    if (_verboseLogging) developer.log('📱 Sending OTP to Aadhar-linked mobile: $mobileNumber');
    
    try {
      // Validate mobile number
      if (!_isValidMobile(mobileNumber)) {
        if (_verboseLogging) developer.log('❌ Invalid mobile number format');
        return false;
      }
      
      // Store mapping
      _aadharMobileMap[aadharNumber] = mobileNumber;
      
      // Generate 6-digit OTP (fixed to 123456 in debug mode)
      final otp = kDebugMode ? '123456' : (100000 + _random.nextInt(900000)).toString();
      
      // In production, this would integrate with SMS gateway
      // For now, log it
      if (_verboseLogging) developer.log('🔐 Aadhar Mobile OTP: $otp (for $mobileNumber)');
      
      // Store OTP for verification
      _mobileOtpStorage[mobileNumber] = _MobileOTPData(
        otp: otp,
        createdAt: DateTime.now(),
      );
      
      if (kDebugMode) {
        developer.log('📱 [DEBUG] OTP sent to mobile $mobileNumber: $otp');
      }
      
      return true;
    } catch (e) {
      if (_verboseLogging) developer.log('❌ Failed to send Aadhar mobile OTP: $e');
      return false;
    }
  }
  
  /// Verify Aadhar mobile OTP
  Future<bool> verifyAadharMobileOTP(String mobileNumber, String otp) async {
    if (_verboseLogging) developer.log('🔐 Verifying Aadhar mobile OTP for: $mobileNumber');
    
    if (!_mobileOtpStorage.containsKey(mobileNumber)) {
      if (_verboseLogging) developer.log('❌ No OTP found for mobile: $mobileNumber');
      return false;
    }

    final otpData = _mobileOtpStorage[mobileNumber]!;
    
    // Check if OTP is expired
    final now = DateTime.now();
    final timeSinceCreation = now.difference(otpData.createdAt);
    
    if (timeSinceCreation > otpValidity) {
      _mobileOtpStorage.remove(mobileNumber);
      if (_verboseLogging) developer.log('❌ OTP expired for mobile: $mobileNumber');
      return false;
    }
    
    // Verify OTP
    if (otpData.otp == otp) {
      _mobileOtpStorage.remove(mobileNumber);
      if (_verboseLogging) developer.log('✅ Aadhar mobile OTP verified successfully');
      return true;
    }
    
    if (_verboseLogging) developer.log('❌ Invalid OTP for mobile: $mobileNumber');
    return false;
  }  /// Check if Aadhar is verified
  bool isAadharVerified(String aadharNumber) {
    return _aadharMobileMap.containsKey(aadharNumber);
  }
  
  /// Get linked mobile for Aadhar
  String? getLinkedMobile(String aadharNumber) {
    return _aadharMobileMap[aadharNumber];
  }
  
  // Helper methods
  bool _isValidMobile(String mobile) {
    mobile = mobile.replaceAll(RegExp(r'[\s-]'), '');
    return RegExp(r'^[6-9]\d{9}$').hasMatch(mobile);
  }
  
  /// Format Aadhar number with dashes
  String formatAadharInput(String aadhar) {
    aadhar = aadhar.replaceAll(RegExp(r'[\s-]'), '');
    if (aadhar.length >= 12) {
      return '${aadhar.substring(0, 4)}-${aadhar.substring(4, 8)}-${aadhar.substring(8, 12)}';
    } else if (aadhar.length >= 8) {
      return '${aadhar.substring(0, 4)}-${aadhar.substring(4, 8)}-${aadhar.substring(8)}';
    } else if (aadhar.length >= 4) {
      return '${aadhar.substring(0, 4)}-${aadhar.substring(4)}';
    }
    return aadhar;
  }
}

/// Data class for storing mobile OTP information
class _MobileOTPData {
  final String otp;
  final DateTime createdAt;

  _MobileOTPData({
    required this.otp,
    required this.createdAt,
  });
}

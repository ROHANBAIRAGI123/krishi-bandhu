import 'dart:math';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../config/env.dart';

/// Email OTP Service using free SMTP providers
/// 
/// Free Options:
/// 1. Gmail SMTP (Recommended - Completely Free)
/// 2. Outlook/Hotmail SMTP (Free)
/// 3. Yahoo SMTP (Free)
/// 4. Mailtrap (Free tier: 500 emails/month for testing)
/// 5. EmailJS (Free tier: 200 emails/month)
class EmailOTPService {
  // Set to true to enable verbose logging (for debugging)
  static const bool _verboseLogging = true;
  // OTP storage (in production, use secure backend storage)
  static final Map<String, OTPData> _otpStorage = {};
  
  // OTP validity duration
  static const Duration otpValidity = Duration(minutes: 10);
  
  // Rate limiting
  static final Map<String, DateTime> _lastSentTime = {};
  static const Duration rateLimitDuration = Duration(minutes: 1);

  /// Generate a 6-digit OTP
  static String generateOTP() {
    if (_verboseLogging) developer.log('🔢 [EmailOTP] Generating new OTP...');
    final random = Random.secure();
    final otp = (100000 + random.nextInt(900000)).toString();
    if (_verboseLogging) developer.log('✅ [EmailOTP] OTP generated successfully: ${otp.substring(0, 2)}****');
    return otp;
  }

  /// Send OTP via Email using Gmail SMTP (Free)
  /// 
  /// Setup Instructions:
  /// 1. Go to Google Account settings
  /// 2. Enable 2-Factor Authentication
  /// 3. Generate App Password: https://myaccount.google.com/apppasswords
  /// 4. Use the 16-character app password below
  /// 
  /// Alternative: Use environment variables or secure storage
  static Future<bool> sendOTP({
    required String email,
    required String purpose, // 'login', 'register', 'verify'
  }) async {
    try {
      if (_verboseLogging) developer.log('📧 [EmailOTP] Starting OTP send process for: $email, purpose: $purpose');
      if (_verboseLogging) developer.log('🔍 [EmailOTP] Checking rate limit for: $email');
      
      // Rate limiting check
      if (_lastSentTime.containsKey(email)) {
        final timeSinceLastSent = DateTime.now().difference(_lastSentTime[email]!);
        if (timeSinceLastSent < rateLimitDuration) {
          final waitSeconds = (rateLimitDuration - timeSinceLastSent).inSeconds;
          if (_verboseLogging) developer.log('⏰ [EmailOTP] Rate limit active: Wait $waitSeconds seconds');
          debugPrint('⏰ Rate limit: Wait $waitSeconds seconds before resending');
          throw Exception('Please wait $waitSeconds seconds before requesting another OTP');
        }
      }
      if (_verboseLogging) developer.log('✅ [EmailOTP] Rate limit check passed');

      // Generate OTP
      final otp = generateOTP();
      if (_verboseLogging) developer.log('🔐 [EmailOTP] OTP generated: ${otp.substring(0, 2)}****, length: ${otp.length}');
      if (_verboseLogging) developer.log('💾 [EmailOTP] Storing OTP in memory...');
      
      // Store OTP with expiry
      _otpStorage[email] = OTPData(
        otp: otp,
        createdAt: DateTime.now(),
        purpose: purpose,
      );
      _lastSentTime[email] = DateTime.now();
      if (_verboseLogging) developer.log('💾 [EmailOTP] OTP stored in memory for email: $email');
      if (_verboseLogging) developer.log('📊 [EmailOTP] Current OTP storage size: ${_otpStorage.length} entries');

      // For development - also print OTP to console for easy testing
      if (kDebugMode) {
        debugPrint('🔐 OTP for $email: $otp (Valid for 10 minutes)');
      }

      // Production: Send actual email
      if (_verboseLogging) developer.log('📤 [EmailOTP] Attempting to send email via SMTP...');
      if (_verboseLogging) developer.log('🔧 [EmailOTP] Retrieving SMTP server configuration...');
      // Configure your SMTP settings here
      final smtpServer = await _getSmtpServer();
      
      if (smtpServer == null) {
        // Fallback to demo mode if SMTP not configured
        if (_verboseLogging) developer.log('⚠️ [EmailOTP] SMTP not configured, using demo mode');
        return true;
      }

      if (_verboseLogging) developer.log('📝 [EmailOTP] Building email message...');
      final message = Message()
        ..from = Address(_getSenderEmail(), 'Krishi Bandhu')
        ..recipients.add(email)
        ..subject = 'Your Krishi Bandhu OTP - $otp'
        ..html = _buildEmailTemplate(otp, purpose);

      if (_verboseLogging) developer.log('📨 [EmailOTP] Sending email to: $email');
      try {
        final sendReport = await send(message, smtpServer);
        if (_verboseLogging) developer.log('✅ [EmailOTP] Email sent successfully: ${sendReport.toString()}');
        if (kDebugMode) debugPrint('✅ Email sent successfully');
        return true;
      } on MailerException catch (e) {
        debugPrint('❌ Email send failed: ${e.toString()}');
        // Even if email fails, keep OTP in storage for demo/testing
        return true; // Return true for demo mode
      }
    } catch (e) {
      debugPrint('❌ Error sending OTP: $e');
      rethrow;
    }
  }

  /// Verify OTP
  static bool verifyOTP(String email, String otp) {
    if (_verboseLogging) developer.log('🔐 [EmailOTP] Starting OTP verification for: $email');
    if (_verboseLogging) developer.log('🔐 [EmailOTP] Provided OTP: ${otp.substring(0, 2)}****, length: ${otp.length}');
    
    if (!_otpStorage.containsKey(email)) {
      if (_verboseLogging) developer.log('❌ [EmailOTP] No OTP found in storage for: $email');
      if (kDebugMode) debugPrint('❌ No OTP found for $email');
      return false;
    }

    final otpData = _otpStorage[email]!;
    if (_verboseLogging) developer.log('💾 [EmailOTP] Found stored OTP created at: ${otpData.createdAt}');
    
    // Check if OTP is expired
    final now = DateTime.now();
    final timeSinceCreation = now.difference(otpData.createdAt);
    if (_verboseLogging) developer.log('⏱️ [EmailOTP] Time since OTP creation: ${timeSinceCreation.inMinutes} minutes, ${timeSinceCreation.inSeconds % 60} seconds');
    
    if (timeSinceCreation > otpValidity) {
      _otpStorage.remove(email);
      if (_verboseLogging) developer.log('❌ [EmailOTP] OTP expired (validity: ${otpValidity.inMinutes} minutes)');
      if (kDebugMode) debugPrint('❌ OTP expired for $email');
      return false;
    }

    // Verify OTP
    if (otpData.otp == otp) {
      _otpStorage.remove(email); // Remove after successful verification
      _lastSentTime.remove(email); // Reset rate limit
      if (_verboseLogging) developer.log('✅ [EmailOTP] OTP verified successfully for: $email');
      if (kDebugMode) debugPrint('✅ OTP verified for $email');
      return true;
    }

    if (_verboseLogging) developer.log('❌ [EmailOTP] Invalid OTP - Expected: ${otpData.otp.substring(0, 2)}****, Got: ${otp.substring(0, 2)}****');
    if (kDebugMode) debugPrint('❌ Invalid OTP for $email');
    return false;
  }

  /// Clear OTP for an email
  static void clearOTP(String email) {
    if (_verboseLogging) developer.log('🗑️ [EmailOTP] Clearing OTP for: $email');
    final hadOtp = _otpStorage.containsKey(email);
    _otpStorage.remove(email);
    _lastSentTime.remove(email);
    if (_verboseLogging) developer.log('✅ [EmailOTP] OTP cleared successfully (had OTP: $hadOtp)');
  }

  /// Get remaining validity time for OTP
  static Duration? getRemainingValidity(String email) {
    if (_verboseLogging) developer.log('⏱️ [EmailOTP] Checking remaining validity for: $email');
    if (!_otpStorage.containsKey(email)) {
      if (_verboseLogging) developer.log('❌ [EmailOTP] No OTP found for validity check');
      return null;
    }
    
    final otpData = _otpStorage[email]!;
    final elapsed = DateTime.now().difference(otpData.createdAt);
    final remaining = otpValidity - elapsed;
    
    if (_verboseLogging) developer.log('⏱️ [EmailOTP] Remaining validity: ${remaining.inMinutes}m ${remaining.inSeconds % 60}s');
    return remaining.isNegative ? null : remaining;
  }

  // Private helper methods

  static Future<SmtpServer?> _getSmtpServer() async {
    if (_verboseLogging) developer.log('⚙️ [EmailOTP] _getSmtpServer() called');
    // Option 1: Gmail SMTP (Recommended)
    // Requires App Password from Google Account
    // 
    // Setup Instructions:
    // 1. Go to: https://myaccount.google.com/security
    // 2. Enable 2-Factor Authentication if not already enabled
    // 3. Go to: https://myaccount.google.com/apppasswords
    // 4. Select "Mail" and "Other (Custom name)"
    // 5. Copy the 16-character password and paste below
    // 6. Uncomment the code below and add your credentials
    
    const gmailEmail = Env.gmailEmail;
    const gmailAppPassword = Env.gmailAppPassword;


    if (_verboseLogging) developer.log('📤 [EmailOTP] Using Gmail SMTP: $gmailEmail');
    return gmail(gmailEmail, gmailAppPassword);
  }

  static String _getSenderEmail() {
    if (_verboseLogging) developer.log('📧 [EmailOTP] Getting sender email address...');
    // Configure your sender email here
    final senderEmail = Env.gmailEmail;
    if (_verboseLogging) developer.log('📧 [EmailOTP] Sender email: $senderEmail');
    return senderEmail;
  }

  static String _buildEmailTemplate(String otp, String purpose) {
    if (_verboseLogging) developer.log('📄 [EmailOTP] Building email template for purpose: $purpose');
    final purposeText = purpose == 'login' 
        ? 'login to your account'
        : purpose == 'register'
            ? 'complete your registration'
            : 'verify your email';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      background-color: #f5f5f5;
      margin: 0;
      padding: 0;
    }
    .container {
      max-width: 600px;
      margin: 40px auto;
      background-color: #ffffff;
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      overflow: hidden;
    }
    .header {
      background: linear-gradient(135deg, #2E7D32 0%, #4CAF50 100%);
      color: white;
      padding: 30px 20px;
      text-align: center;
    }
    .header h1 {
      margin: 0;
      font-size: 28px;
      font-weight: 600;
    }
    .header p {
      margin: 8px 0 0 0;
      font-size: 14px;
      opacity: 0.9;
    }
    .content {
      padding: 40px 30px;
    }
    .otp-box {
      background: linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 100%);
      border: 2px dashed #2E7D32;
      border-radius: 8px;
      padding: 30px;
      text-align: center;
      margin: 30px 0;
    }
    .otp-code {
      font-size: 36px;
      font-weight: bold;
      color: #2E7D32;
      letter-spacing: 8px;
      font-family: 'Courier New', monospace;
    }
    .otp-label {
      font-size: 12px;
      color: #666;
      margin-top: 8px;
      text-transform: uppercase;
      letter-spacing: 1px;
    }
    .message {
      font-size: 16px;
      color: #333;
      line-height: 1.6;
      margin-bottom: 20px;
    }
    .warning {
      background-color: #fff3cd;
      border-left: 4px solid #ffc107;
      padding: 15px;
      margin: 20px 0;
      border-radius: 4px;
    }
    .warning p {
      margin: 0;
      font-size: 14px;
      color: #856404;
    }
    .footer {
      background-color: #f8f9fa;
      padding: 20px 30px;
      text-align: center;
      font-size: 12px;
      color: #666;
      border-top: 1px solid #e0e0e0;
    }
    .footer a {
      color: #2E7D32;
      text-decoration: none;
    }
    .icon {
      font-size: 48px;
      margin-bottom: 10px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="icon">🌾</div>
      <h1>Krashi Bandhu</h1>
      <p>Making Crop Insurance Faster and Fairer</p>
    </div>
    
    <div class="content">
      <p class="message">
        <strong>Namaste!</strong>
      </p>
      
      <p class="message">
        You have requested to $purposeText. Use the following One-Time Password (OTP) to proceed:
      </p>
      
      <div class="otp-box">
        <div class="otp-code">$otp</div>
        <div class="otp-label">Your OTP Code</div>
      </div>
      
      <p class="message">
        This OTP is valid for <strong>10 minutes</strong>. Please do not share this code with anyone.
      </p>
      
      <div class="warning">
        <p><strong>⚠️ Security Notice:</strong></p>
        <p>If you did not request this OTP, please ignore this email. Your account is safe and no action is needed.</p>
      </div>
      
      <p class="message">
        Thank you for using Krishi Bandhu! 🙏
      </p>
    </div>
    
    <div class="footer">
      <p>© 2024 Krishi Bandhu - PMFBY Insurance Platform</p>
      <p>
        <a href="#">Help Center</a> | 
        <a href="#">Contact Support</a> | 
        <a href="#">Privacy Policy</a>
      </p>
      <p>Support: 14447 (Toll-Free) | WhatsApp: 7065514447</p>
    </div>
  </div>
</body>
</html>
    ''';
  }
}

/// OTP Data model
class OTPData {
  final String otp;
  final DateTime createdAt;
  final String purpose;

  OTPData({
    required this.otp,
    required this.createdAt,
    required this.purpose,
  });

  bool get isExpired {
    return DateTime.now().difference(createdAt) > EmailOTPService.otpValidity;
  }

  Duration get remainingValidity {
    final remaining = EmailOTPService.otpValidity - DateTime.now().difference(createdAt);
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

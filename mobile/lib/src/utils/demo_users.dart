/// Demo users for testing the application
/// These are hardcoded test accounts that bypass authentication
library;

import '../features/auth/domain/models/user_model.dart';

class DemoUsers {
  // Farmer Test Accounts
  static const List<Map<String, String>> farmers = [
    {
      'name': 'Ramesh Patel',
      'phone': '9876543210',
      'email': 'ramesh@farmer.test',
      'password': 'test123',
      'role': 'farmer',
      'village': 'Khandala',
      'district': 'Nagpur',
      'state': 'Maharashtra',
    },
    {
      'name': 'Suresh Kumar',
      'phone': '9876543211',
      'email': 'suresh@farmer.test',
      'password': 'test123',
      'role': 'farmer',
      'village': 'Pipri',
      'district': 'Nagpur',
      'state': 'Maharashtra',
    },
    {
      'name': 'Anita Devi',
      'phone': '9876543212',
      'email': 'anita@farmer.test',
      'password': 'test123',
      'role': 'farmer',
      'village': 'Kamptee',
      'district': 'Nagpur',
      'state': 'Maharashtra',
    },
  ];

  // Officer Test Accounts
  static const List<Map<String, String>> officers = [
    {
      'name': 'Rajesh Kumar (District Officer)',
      'phone': '9876543220',
      'email': 'rajesh@officer.test',
      'password': 'admin123',
      'role': 'official',
      'designation': 'District Level Officer',
      'level': 'district',
      'district': 'Ludhiana',
      'state': 'Punjab',
    },
    {
      'name': 'Priya Sharma (State Officer)',
      'phone': '9876543221',
      'email': 'priya@officer.test',
      'password': 'admin123',
      'role': 'official',
      'designation': 'State Level Officer',
      'level': 'state',
      'state': 'Punjab',
    },
    {
      'name': 'Amit Verma (National Officer)',
      'phone': '9876543222',
      'email': 'amit@officer.test',
      'password': 'admin123',
      'role': 'official',
      'designation': 'National Level Officer',
      'level': 'national',
    },
    {
      'name': 'Sunita Rao (District Officer)',
      'phone': '9876543223',
      'email': 'sunita@officer.test',
      'password': 'admin123',
      'role': 'official',
      'designation': 'District Level Officer',
      'level': 'district',
      'district': 'Patiala',
      'state': 'Punjab',
    },
  ];

  // Check if phone number belongs to a demo user
  static Map<String, String>? findByPhone(String phone) {
    // Remove +91 prefix if present
    final cleanPhone = phone.replaceAll('+91', '').trim();
    
    for (var farmer in farmers) {
      if (farmer['phone'] == cleanPhone) {
        return farmer;
      }
    }
    
    for (var officer in officers) {
      if (officer['phone'] == cleanPhone) {
        return officer;
      }
    }
    
    return null;
  }

  // Check if email belongs to a demo user
  static Map<String, String>? findByEmail(String email) {
    for (var farmer in farmers) {
      if (farmer['email'] == email) {
        return farmer;
      }
    }
    
    for (var officer in officers) {
      if (officer['email'] == email) {
        return officer;
      }
    }
    
    return null;
  }

  // Validate demo user credentials
  static bool validateCredentials(String emailOrPhone, String password) {
    final user = findByEmail(emailOrPhone) ?? findByPhone(emailOrPhone);
    return user != null && user['password'] == password;
  }

  // Get all demo phone numbers for reference
  static List<String> getAllPhones() {
    return [
      ...farmers.map((f) => f['phone']!),
      ...officers.map((o) => o['phone']!),
    ];
  }

  // Demo OTP (always valid for testing)
  static const String demoOTP = '123456';
  
  // Check if OTP is valid (for demo, always accept 123456)
  static bool isValidOTP(String otp) {
    return otp == demoOTP;
  }

  // Convert demo user Map to User model
  static User? getUserFromDemoData(Map<String, String>? demoData) {
    if (demoData == null) return null;
    
    return User(
      userId: 'demo_${demoData['phone']}',
      name: demoData['name'] ?? 'Demo User',
      email: demoData['email'] ?? '',
      phone: demoData['phone'] ?? '',
      role: demoData['role'] ?? 'farmer',
      password: demoData['password'],
      village: demoData['village'],
      district: demoData['district'],
      state: demoData['state'],
      officialId: demoData['role'] == 'official' ? 'OFF-${demoData['phone']}' : null,
      designation: demoData['designation'],
      department: demoData['role'] == 'official' ? 'Agriculture Insurance' : null,
      assignedDistrict: demoData['district'],
    );
  }
}

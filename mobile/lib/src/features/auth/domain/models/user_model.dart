class User {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String role; // 'farmer' or 'official'
  final String? password;
  
  // Farmer specific fields
  final String? village;
  final String? district;
  final String? state;
  final double? farmSize;
  final String? aadharNumber;
  final List<String>? cropTypes;
  
  // Official specific fields
  final String? officialId;
  final String? designation;
  final String? department;
  final String? assignedDistrict;

  User({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.password,
    this.village,
    this.district,
    this.state,
    this.farmSize,
    this.aadharNumber,
    this.cropTypes,
    this.officialId,
    this.designation,
    this.department,
    this.assignedDistrict,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'password': password,
      'village': village,
      'district': district,
      'state': state,
      'farmSize': farmSize,
      'aadharNumber': aadharNumber,
      'cropTypes': cropTypes,
      'officialId': officialId,
      'designation': designation,
      'department': department,
      'assignedDistrict': assignedDistrict,
    };
  }

  // Create from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'farmer',
      password: json['password'],
      village: json['village'],
      district: json['district'],
      state: json['state'],
      farmSize: json['farmSize'] != null ? double.tryParse(json['farmSize'].toString()) : null,
      aadharNumber: json['aadharNumber'],
      cropTypes: json['cropTypes'] != null ? List<String>.from(json['cropTypes']) : null,
      officialId: json['officialId'],
      designation: json['designation'],
      department: json['department'],
      assignedDistrict: json['assignedDistrict'],
    );
  }

  User copyWith({
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? password,
    String? village,
    String? district,
    String? state,
    double? farmSize,
    String? aadharNumber,
    List<String>? cropTypes,
    String? officialId,
    String? designation,
    String? department,
    String? assignedDistrict,
  }) {
    return User(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      password: password ?? this.password,
      village: village ?? this.village,
      district: district ?? this.district,
      state: state ?? this.state,
      farmSize: farmSize ?? this.farmSize,
      aadharNumber: aadharNumber ?? this.aadharNumber,
      cropTypes: cropTypes ?? this.cropTypes,
      officialId: officialId ?? this.officialId,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      assignedDistrict: assignedDistrict ?? this.assignedDistrict,
    );
  }
}

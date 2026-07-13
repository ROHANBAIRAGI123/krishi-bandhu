class UserProfile {
  final String uid;
  final String name;
  final String phoneNumber;
  final String? email;
  final String? address;
  final String? village;
  final String? district;
  final String? state;
  final double? latitude;
  final double? longitude;
  final List<String> crops;
  final double? landAreaAcres;
  final String? aadhaarNumber;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.uid,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.address,
    this.village,
    this.district,
    this.state,
    this.latitude,
    this.longitude,
    this.crops = const [],
    this.landAreaAcres,
    this.aadhaarNumber,
    this.profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'village': village,
      'district': district,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
      'crops': crops,
      'landAreaAcres': landAreaAcres,
      'aadhaarNumber': aadhaarNumber,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'],
      address: map['address'],
      village: map['village'],
      district: map['district'],
      state: map['state'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      crops: List<String>.from(map['crops'] ?? []),
      landAreaAcres: map['landAreaAcres']?.toDouble(),
      aadhaarNumber: map['aadhaarNumber'],
      profileImageUrl: map['profileImageUrl'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  UserProfile copyWith({
    String? name,
    String? phoneNumber,
    String? email,
    String? address,
    String? village,
    String? district,
    String? state,
    double? latitude,
    double? longitude,
    List<String>? crops,
    double? landAreaAcres,
    String? aadhaarNumber,
    String? profileImageUrl,
  }) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      village: village ?? this.village,
      district: district ?? this.district,
      state: state ?? this.state,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      crops: crops ?? this.crops,
      landAreaAcres: landAreaAcres ?? this.landAreaAcres,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

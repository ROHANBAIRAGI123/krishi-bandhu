enum CropImageStatus {
  pending,
  analyzing,
  completed,
  failed,
}

enum DamageType {
  none,
  lodging,
  flood,
  waterStress,
  pest,
  disease,
  other,
}

class CropImage {
  final String id;
  final String farmerId;
  final String imageUrl;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String? locationName;
  final CropImageStatus status;
  final String? cropType;
  final String? growthStage;
  final bool? isHealthy;
  final DamageType? damageType;
  final double? confidenceScore;
  final String? aiAnalysisDetails;
  final DateTime createdAt;

  CropImage({
    required this.id,
    required this.farmerId,
    required this.imageUrl,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.status = CropImageStatus.pending,
    this.cropType,
    this.growthStage,
    this.isHealthy,
    this.damageType,
    this.confidenceScore,
    this.aiAnalysisDetails,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farmerId': farmerId,
      'imageUrl': imageUrl,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'status': status.name,
      'cropType': cropType,
      'growthStage': growthStage,
      'isHealthy': isHealthy,
      'damageType': damageType?.name,
      'confidenceScore': confidenceScore,
      'aiAnalysisDetails': aiAnalysisDetails,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CropImage.fromMap(Map<String, dynamic> map) {
    return CropImage(
      id: map['id'] ?? '',
      farmerId: map['farmerId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      locationName: map['locationName'],
      status: CropImageStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CropImageStatus.pending,
      ),
      cropType: map['cropType'],
      growthStage: map['growthStage'],
      isHealthy: map['isHealthy'],
      damageType: map['damageType'] != null
          ? DamageType.values.firstWhere((e) => e.name == map['damageType'])
          : null,
      confidenceScore: map['confidenceScore']?.toDouble(),
      aiAnalysisDetails: map['aiAnalysisDetails'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

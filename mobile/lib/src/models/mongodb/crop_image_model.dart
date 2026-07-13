import 'package:mongo_dart/mongo_dart.dart';

/// Model for crop images with ML verification metadata
class CropImageModel {
  final ObjectId? id;
  final String imageId;
  final String farmerId;
  final String parcelId;
  final ImageMetadata metadata;
  final GeoLocation location;
  final String imageUrl; // Cloudinary/Firebase URL
  final String thumbnailUrl;
  final ImageType imageType;
  final CropInfo cropInfo;
  final MLVerification? mlVerification;
  final OfficerVerification? officerVerification;
  final String season; // Kharif/Rabi
  final int year;
  final ImageStatus status;
  final DateTime capturedAt;
  final DateTime uploadedAt;
  final DateTime? verifiedAt;

  CropImageModel({
    this.id,
    required this.imageId,
    required this.farmerId,
    required this.parcelId,
    required this.metadata,
    required this.location,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.imageType,
    required this.cropInfo,
    this.mlVerification,
    this.officerVerification,
    required this.season,
    required this.year,
    required this.status,
    required this.capturedAt,
    required this.uploadedAt,
    this.verifiedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'imageId': imageId,
      'farmerId': farmerId,
      'parcelId': parcelId,
      'metadata': metadata.toMap(),
      'location': location.toMap(),
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'imageType': imageType.name,
      'cropInfo': cropInfo.toMap(),
      if (mlVerification != null) 'mlVerification': mlVerification!.toMap(),
      if (officerVerification != null) 'officerVerification': officerVerification!.toMap(),
      'season': season,
      'year': year,
      'status': status.name,
      'capturedAt': capturedAt,
      'uploadedAt': uploadedAt,
      if (verifiedAt != null) 'verifiedAt': verifiedAt,
    };
  }

  factory CropImageModel.fromMap(Map<String, dynamic> map) {
    return CropImageModel(
      id: map['_id'] as ObjectId?,
      imageId: map['imageId'] as String,
      farmerId: map['farmerId'] as String,
      parcelId: map['parcelId'] as String,
      metadata: ImageMetadata.fromMap(map['metadata'] as Map<String, dynamic>),
      location: GeoLocation.fromMap(map['location'] as Map<String, dynamic>),
      imageUrl: map['imageUrl'] as String,
      thumbnailUrl: map['thumbnailUrl'] as String,
      imageType: ImageType.values.firstWhere((e) => e.name == map['imageType']),
      cropInfo: CropInfo.fromMap(map['cropInfo'] as Map<String, dynamic>),
      mlVerification: map['mlVerification'] != null
          ? MLVerification.fromMap(map['mlVerification'] as Map<String, dynamic>)
          : null,
      officerVerification: map['officerVerification'] != null
          ? OfficerVerification.fromMap(map['officerVerification'] as Map<String, dynamic>)
          : null,
      season: map['season'] as String,
      year: map['year'] as int,
      status: ImageStatus.values.firstWhere((e) => e.name == map['status']),
      capturedAt: map['capturedAt'] as DateTime,
      uploadedAt: map['uploadedAt'] as DateTime,
      verifiedAt: map['verifiedAt'] as DateTime?,
    );
  }
}

enum ImageType {
  cropHealth,
  cropDamage,
  sowingProof,
  harvestProof,
  lossEvidence,
}

enum ImageStatus {
  uploaded,
  pendingMLVerification,
  mlVerified,
  pendingOfficerReview,
  approved,
  rejected,
  flagged,
}

class ImageMetadata {
  final int width;
  final int height;
  final String format; // jpg, png
  final int sizeBytes;
  final String? deviceModel;
  final String? appVersion;

  ImageMetadata({
    required this.width,
    required this.height,
    required this.format,
    required this.sizeBytes,
    this.deviceModel,
    this.appVersion,
  });

  Map<String, dynamic> toMap() {
    return {
      'width': width,
      'height': height,
      'format': format,
      'sizeBytes': sizeBytes,
      if (deviceModel != null) 'deviceModel': deviceModel,
      if (appVersion != null) 'appVersion': appVersion,
    };
  }

  factory ImageMetadata.fromMap(Map<String, dynamic> map) {
    return ImageMetadata(
      width: map['width'] as int,
      height: map['height'] as int,
      format: map['format'] as String,
      sizeBytes: map['sizeBytes'] as int,
      deviceModel: map['deviceModel'] as String?,
      appVersion: map['appVersion'] as String?,
    );
  }
}

class GeoLocation {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final DateTime timestamp;

  GeoLocation({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (altitude != null) 'altitude': altitude,
      if (accuracy != null) 'accuracy': accuracy,
      'timestamp': timestamp,
    };
  }

  factory GeoLocation.fromMap(Map<String, dynamic> map) {
    return GeoLocation(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      altitude: map['altitude'] != null ? (map['altitude'] as num).toDouble() : null,
      accuracy: map['accuracy'] != null ? (map['accuracy'] as num).toDouble() : null,
      timestamp: map['timestamp'] as DateTime,
    );
  }
}

class CropInfo {
  final String cropName;
  final String cropType; // Kharif/Rabi crop
  final String? variety;
  final DateTime? sowingDate;
  final DateTime? expectedHarvestDate;

  CropInfo({
    required this.cropName,
    required this.cropType,
    this.variety,
    this.sowingDate,
    this.expectedHarvestDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'cropName': cropName,
      'cropType': cropType,
      if (variety != null) 'variety': variety,
      if (sowingDate != null) 'sowingDate': sowingDate,
      if (expectedHarvestDate != null) 'expectedHarvestDate': expectedHarvestDate,
    };
  }

  factory CropInfo.fromMap(Map<String, dynamic> map) {
    return CropInfo(
      cropName: map['cropName'] as String,
      cropType: map['cropType'] as String,
      variety: map['variety'] as String?,
      sowingDate: map['sowingDate'] as DateTime?,
      expectedHarvestDate: map['expectedHarvestDate'] as DateTime?,
    );
  }
}

class MLVerification {
  final String inferenceId;
  final String modelVersion;
  final Map<String, dynamic> predictions;
  final double confidenceScore;
  final List<String> detectedIssues;
  final Map<String, double> classificationScores;
  final bool isAuthentic;
  final String? fraudIndicator;
  final DateTime processedAt;
  final int processingTimeMs;

  MLVerification({
    required this.inferenceId,
    required this.modelVersion,
    required this.predictions,
    required this.confidenceScore,
    required this.detectedIssues,
    required this.classificationScores,
    required this.isAuthentic,
    this.fraudIndicator,
    required this.processedAt,
    required this.processingTimeMs,
  });

  Map<String, dynamic> toMap() {
    return {
      'inferenceId': inferenceId,
      'modelVersion': modelVersion,
      'predictions': predictions,
      'confidenceScore': confidenceScore,
      'detectedIssues': detectedIssues,
      'classificationScores': classificationScores,
      'isAuthentic': isAuthentic,
      if (fraudIndicator != null) 'fraudIndicator': fraudIndicator,
      'processedAt': processedAt,
      'processingTimeMs': processingTimeMs,
    };
  }

  factory MLVerification.fromMap(Map<String, dynamic> map) {
    return MLVerification(
      inferenceId: map['inferenceId'] as String,
      modelVersion: map['modelVersion'] as String,
      predictions: Map<String, dynamic>.from(map['predictions'] as Map),
      confidenceScore: (map['confidenceScore'] as num).toDouble(),
      detectedIssues: List<String>.from(map['detectedIssues'] as List),
      classificationScores: Map<String, double>.from(
        (map['classificationScores'] as Map).map(
          (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
        ),
      ),
      isAuthentic: map['isAuthentic'] as bool,
      fraudIndicator: map['fraudIndicator'] as String?,
      processedAt: map['processedAt'] as DateTime,
      processingTimeMs: map['processingTimeMs'] as int,
    );
  }
}

class OfficerVerification {
  final String officerId;
  final String officerName;
  final VerificationDecision decision;
  final String? remarks;
  final List<String>? flags;
  final DateTime verifiedAt;

  OfficerVerification({
    required this.officerId,
    required this.officerName,
    required this.decision,
    this.remarks,
    this.flags,
    required this.verifiedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'officerId': officerId,
      'officerName': officerName,
      'decision': decision.name,
      if (remarks != null) 'remarks': remarks,
      if (flags != null) 'flags': flags,
      'verifiedAt': verifiedAt,
    };
  }

  factory OfficerVerification.fromMap(Map<String, dynamic> map) {
    return OfficerVerification(
      officerId: map['officerId'] as String,
      officerName: map['officerName'] as String,
      decision: VerificationDecision.values.firstWhere((e) => e.name == map['decision']),
      remarks: map['remarks'] as String?,
      flags: map['flags'] != null ? List<String>.from(map['flags'] as List) : null,
      verifiedAt: map['verifiedAt'] as DateTime,
    );
  }
}

enum VerificationDecision {
  approved,
  rejected,
  needsReview,
  fraudulent,
}

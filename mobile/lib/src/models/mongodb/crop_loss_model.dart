import 'package:mongo_dart/mongo_dart.dart';

/// Model for crop loss intimation
class CropLossModel {
  final ObjectId? id;
  final String lossId;
  final String farmerId;
  final String parcelId;
  final LossDetails lossDetails;
  final List<String> imageIds; // References to CropImageModel
  final GeoLocation location;
  final WeatherCondition weatherCondition;
  final String season;
  final int year;
  final LossStatus status;
  final OfficerAssessment? officerAssessment;
  final DateTime reportedAt;
  final DateTime? assessedAt;
  final DateTime updatedAt;

  CropLossModel({
    this.id,
    required this.lossId,
    required this.farmerId,
    required this.parcelId,
    required this.lossDetails,
    required this.imageIds,
    required this.location,
    required this.weatherCondition,
    required this.season,
    required this.year,
    required this.status,
    this.officerAssessment,
    required this.reportedAt,
    this.assessedAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'lossId': lossId,
      'farmerId': farmerId,
      'parcelId': parcelId,
      'lossDetails': lossDetails.toMap(),
      'imageIds': imageIds,
      'location': location.toMap(),
      'weatherCondition': weatherCondition.toMap(),
      'season': season,
      'year': year,
      'status': status.name,
      if (officerAssessment != null) 'officerAssessment': officerAssessment!.toMap(),
      'reportedAt': reportedAt,
      if (assessedAt != null) 'assessedAt': assessedAt,
      'updatedAt': updatedAt,
    };
  }

  factory CropLossModel.fromMap(Map<String, dynamic> map) {
    return CropLossModel(
      id: map['_id'] as ObjectId?,
      lossId: map['lossId'] as String,
      farmerId: map['farmerId'] as String,
      parcelId: map['parcelId'] as String,
      lossDetails: LossDetails.fromMap(map['lossDetails'] as Map<String, dynamic>),
      imageIds: List<String>.from(map['imageIds'] as List),
      location: GeoLocation.fromMap(map['location'] as Map<String, dynamic>),
      weatherCondition: WeatherCondition.fromMap(map['weatherCondition'] as Map<String, dynamic>),
      season: map['season'] as String,
      year: map['year'] as int,
      status: LossStatus.values.firstWhere((e) => e.name == map['status']),
      officerAssessment: map['officerAssessment'] != null
          ? OfficerAssessment.fromMap(map['officerAssessment'] as Map<String, dynamic>)
          : null,
      reportedAt: map['reportedAt'] as DateTime,
      assessedAt: map['assessedAt'] as DateTime?,
      updatedAt: map['updatedAt'] as DateTime,
    );
  }
}

enum LossStatus {
  reported,
  underInvestigation,
  assessed,
  claimGenerated,
  rejected,
}

class LossDetails {
  final String cropName;
  final LossCause lossCause;
  final double estimatedLossPercentage;
  final double affectedArea; // in hectares
  final DateTime lossOccurredDate;
  final String farmerDescription;
  final List<String> symptoms;

  LossDetails({
    required this.cropName,
    required this.lossCause,
    required this.estimatedLossPercentage,
    required this.affectedArea,
    required this.lossOccurredDate,
    required this.farmerDescription,
    required this.symptoms,
  });

  Map<String, dynamic> toMap() {
    return {
      'cropName': cropName,
      'lossCause': lossCause.name,
      'estimatedLossPercentage': estimatedLossPercentage,
      'affectedArea': affectedArea,
      'lossOccurredDate': lossOccurredDate,
      'farmerDescription': farmerDescription,
      'symptoms': symptoms,
    };
  }

  factory LossDetails.fromMap(Map<String, dynamic> map) {
    return LossDetails(
      cropName: map['cropName'] as String,
      lossCause: LossCause.values.firstWhere((e) => e.name == map['lossCause']),
      estimatedLossPercentage: (map['estimatedLossPercentage'] as num).toDouble(),
      affectedArea: (map['affectedArea'] as num).toDouble(),
      lossOccurredDate: map['lossOccurredDate'] as DateTime,
      farmerDescription: map['farmerDescription'] as String,
      symptoms: List<String>.from(map['symptoms'] as List),
    );
  }
}

enum LossCause {
  drought,
  flood,
  cyclone,
  hailstorm,
  landslide,
  pestAttack,
  disease,
  wildAnimalAttack,
  fire,
  other,
}

class GeoLocation {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime timestamp;

  GeoLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      'timestamp': timestamp,
    };
  }

  factory GeoLocation.fromMap(Map<String, dynamic> map) {
    return GeoLocation(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracy: map['accuracy'] != null ? (map['accuracy'] as num).toDouble() : null,
      timestamp: map['timestamp'] as DateTime,
    );
  }
}

class WeatherCondition {
  final double? temperature;
  final double? rainfall;
  final double? humidity;
  final double? windSpeed;
  final String? description;
  final DateTime recordedAt;

  WeatherCondition({
    this.temperature,
    this.rainfall,
    this.humidity,
    this.windSpeed,
    this.description,
    required this.recordedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (temperature != null) 'temperature': temperature,
      if (rainfall != null) 'rainfall': rainfall,
      if (humidity != null) 'humidity': humidity,
      if (windSpeed != null) 'windSpeed': windSpeed,
      if (description != null) 'description': description,
      'recordedAt': recordedAt,
    };
  }

  factory WeatherCondition.fromMap(Map<String, dynamic> map) {
    return WeatherCondition(
      temperature: map['temperature'] != null ? (map['temperature'] as num).toDouble() : null,
      rainfall: map['rainfall'] != null ? (map['rainfall'] as num).toDouble() : null,
      humidity: map['humidity'] != null ? (map['humidity'] as num).toDouble() : null,
      windSpeed: map['windSpeed'] != null ? (map['windSpeed'] as num).toDouble() : null,
      description: map['description'] as String?,
      recordedAt: map['recordedAt'] as DateTime,
    );
  }
}

class OfficerAssessment {
  final String officerId;
  final String officerName;
  final double assessedLossPercentage;
  final bool isEligibleForClaim;
  final String assessmentRemarks;
  final List<String> verifiedImageIds;
  final DateTime assessedAt;

  OfficerAssessment({
    required this.officerId,
    required this.officerName,
    required this.assessedLossPercentage,
    required this.isEligibleForClaim,
    required this.assessmentRemarks,
    required this.verifiedImageIds,
    required this.assessedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'officerId': officerId,
      'officerName': officerName,
      'assessedLossPercentage': assessedLossPercentage,
      'isEligibleForClaim': isEligibleForClaim,
      'assessmentRemarks': assessmentRemarks,
      'verifiedImageIds': verifiedImageIds,
      'assessedAt': assessedAt,
    };
  }

  factory OfficerAssessment.fromMap(Map<String, dynamic> map) {
    return OfficerAssessment(
      officerId: map['officerId'] as String,
      officerName: map['officerName'] as String,
      assessedLossPercentage: (map['assessedLossPercentage'] as num).toDouble(),
      isEligibleForClaim: map['isEligibleForClaim'] as bool,
      assessmentRemarks: map['assessmentRemarks'] as String,
      verifiedImageIds: List<String>.from(map['verifiedImageIds'] as List),
      assessedAt: map['assessedAt'] as DateTime,
    );
  }
}

import 'package:mongo_dart/mongo_dart.dart';

class ClaimModel {
  final ObjectId? id;
  final String claimId;
  final String farmerId;
  final String parcelId;
  final String season;
  final ClaimSubmission submission;
  final AIAssessment aiAssessment;
  final HumanReview humanReview;
  final Payout? payout;
  final String status; // "APPROVED" | "REJECTED" | "PENDING" | "REVIEW"
  final DateTime createdAt;
  final DateTime updatedAt;
  
  ClaimModel({
    this.id,
    required this.claimId,
    required this.farmerId,
    required this.parcelId,
    required this.season,
    required this.submission,
    required this.aiAssessment,
    required this.humanReview,
    this.payout,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  
  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'claimId': claimId,
      'farmerId': farmerId,
      'parcelId': parcelId,
      'season': season,
      'submission': submission.toMap(),
      'aiAssessment': aiAssessment.toMap(),
      'humanReview': humanReview.toMap(),
      if (payout != null) 'payout': payout!.toMap(),
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
  
  factory ClaimModel.fromMap(Map<String, dynamic> map) {
    return ClaimModel(
      id: map['_id'] as ObjectId?,
      claimId: map['claimId'] as String,
      farmerId: map['farmerId'] as String,
      parcelId: map['parcelId'] as String,
      season: map['season'] as String,
      submission: ClaimSubmission.fromMap(map['submission'] as Map<String, dynamic>),
      aiAssessment: AIAssessment.fromMap(map['aiAssessment'] as Map<String, dynamic>),
      humanReview: HumanReview.fromMap(map['humanReview'] as Map<String, dynamic>),
      payout: map['payout'] != null ? Payout.fromMap(map['payout'] as Map<String, dynamic>) : null,
      status: map['status'] as String,
      createdAt: map['createdAt'] as DateTime,
      updatedAt: map['updatedAt'] as DateTime,
    );
  }
}

class ClaimSubmission {
  final List<String> images; // Image IDs
  final DateTime submittedAt;
  final String submittedBy; // "farmer" | "official"
  
  ClaimSubmission({
    required this.images,
    required this.submittedAt,
    required this.submittedBy,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'images': images,
      'submittedAt': submittedAt,
      'submittedBy': submittedBy,
    };
  }
  
  factory ClaimSubmission.fromMap(Map<String, dynamic> map) {
    return ClaimSubmission(
      images: List<String>.from(map['images'] as List),
      submittedAt: map['submittedAt'] as DateTime,
      submittedBy: map['submittedBy'] as String,
    );
  }
}

class AIAssessment {
  final double lossPct;
  final String severity; // "low" | "moderate" | "severe"
  final String cropType;
  final String finalDecision; // "auto-eligible" | "needs-review" | "rejected"
  final List<String> reasons;
  
  AIAssessment({
    required this.lossPct,
    required this.severity,
    required this.cropType,
    required this.finalDecision,
    required this.reasons,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'lossPct': lossPct,
      'severity': severity,
      'cropType': cropType,
      'finalDecision': finalDecision,
      'reasons': reasons,
    };
  }
  
  factory AIAssessment.fromMap(Map<String, dynamic> map) {
    return AIAssessment(
      lossPct: (map['lossPct'] as num).toDouble(),
      severity: map['severity'] as String,
      cropType: map['cropType'] as String,
      finalDecision: map['finalDecision'] as String,
      reasons: List<String>.from(map['reasons'] as List),
    );
  }
}

class HumanReview {
  final bool required;
  final String? reviewerId;
  final String? notes;
  final DateTime? reviewedAt;
  
  HumanReview({
    required this.required,
    this.reviewerId,
    this.notes,
    this.reviewedAt,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'required': required,
      if (reviewerId != null) 'reviewerId': reviewerId,
      if (notes != null) 'notes': notes,
      if (reviewedAt != null) 'reviewedAt': reviewedAt,
    };
  }
  
  factory HumanReview.fromMap(Map<String, dynamic> map) {
    return HumanReview(
      required: map['required'] as bool,
      reviewerId: map['reviewerId'] as String?,
      notes: map['notes'] as String?,
      reviewedAt: map['reviewedAt'] as DateTime?,
    );
  }
}

class Payout {
  final bool eligible;
  final double approvedAmount;
  final DateTime approvedAt;
  final String? transactionId;
  
  Payout({
    required this.eligible,
    required this.approvedAmount,
    required this.approvedAt,
    this.transactionId,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'eligible': eligible,
      'approvedAmount': approvedAmount,
      'approvedAt': approvedAt,
      if (transactionId != null) 'transactionId': transactionId,
    };
  }
  
  factory Payout.fromMap(Map<String, dynamic> map) {
    return Payout(
      eligible: map['eligible'] as bool,
      approvedAmount: (map['approvedAmount'] as num).toDouble(),
      approvedAt: map['approvedAt'] as DateTime,
      transactionId: map['transactionId'] as String?,
    );
  }
}

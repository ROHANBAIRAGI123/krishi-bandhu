enum ClaimStatus {
  draft,
  submitted,
  underReview,
  approved,
  rejected,
  paid,
}

class InsuranceClaim {
  final String id;
  final String farmerId;
  final String farmerName;
  final String cropType;
  final String damageReason;
  final String description;
  final List<String> imageUrls;
  final double? estimatedLossPercentage;
  final double? claimAmount;
  final ClaimStatus status;
  final DateTime incidentDate;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewerComments;
  final String? approvedAmount;

  InsuranceClaim({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.cropType,
    required this.damageReason,
    required this.description,
    this.imageUrls = const [],
    this.estimatedLossPercentage,
    this.claimAmount,
    this.status = ClaimStatus.draft,
    required this.incidentDate,
    DateTime? submittedAt,
    this.reviewedAt,
    this.reviewerComments,
    this.approvedAmount,
  }) : submittedAt = submittedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'cropType': cropType,
      'damageReason': damageReason,
      'description': description,
      'imageUrls': imageUrls,
      'estimatedLossPercentage': estimatedLossPercentage,
      'claimAmount': claimAmount,
      'status': status.name,
      'incidentDate': incidentDate.toIso8601String(),
      'submittedAt': submittedAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewerComments': reviewerComments,
      'approvedAmount': approvedAmount,
    };
  }

  factory InsuranceClaim.fromMap(Map<String, dynamic> map) {
    return InsuranceClaim(
      id: map['id'] ?? '',
      farmerId: map['farmerId'] ?? '',
      farmerName: map['farmerName'] ?? '',
      cropType: map['cropType'] ?? '',
      damageReason: map['damageReason'] ?? '',
      description: map['description'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      estimatedLossPercentage: map['estimatedLossPercentage']?.toDouble(),
      claimAmount: map['claimAmount']?.toDouble(),
      status: ClaimStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ClaimStatus.draft,
      ),
      incidentDate: DateTime.parse(map['incidentDate']),
      submittedAt: DateTime.parse(map['submittedAt']),
      reviewedAt:
          map['reviewedAt'] != null ? DateTime.parse(map['reviewedAt']) : null,
      reviewerComments: map['reviewerComments'],
      approvedAmount: map['approvedAmount'],
    );
  }
}

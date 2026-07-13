class CropLossReport {
  final String id;
  final String farmerId;
  final String farmerName;
  final String cropType;
  final String season;
  final double affectedArea;
  final String lossType;
  final String lossPercentage;
  final DateTime incidentDate;
  final DateTime reportedDate;
  final String district;
  final String village;
  final double latitude;
  final double longitude;
  final String description;
  final List<String> imagePaths;
  final String status;
  final String? assessorComments;
  final DateTime? assessmentDate;
  final String? claimNumber;

  CropLossReport({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.cropType,
    required this.season,
    required this.affectedArea,
    required this.lossType,
    required this.lossPercentage,
    required this.incidentDate,
    required this.reportedDate,
    required this.district,
    required this.village,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.imagePaths,
    required this.status,
    this.assessorComments,
    this.assessmentDate,
    this.claimNumber,
  });

  factory CropLossReport.fromJson(Map<String, dynamic> json) {
    return CropLossReport(
      id: json['id'] as String,
      farmerId: json['farmerId'] as String,
      farmerName: json['farmerName'] as String,
      cropType: json['cropType'] as String,
      season: json['season'] as String,
      affectedArea: (json['affectedArea'] as num).toDouble(),
      lossType: json['lossType'] as String,
      lossPercentage: json['lossPercentage'] as String,
      incidentDate: DateTime.parse(json['incidentDate'] as String),
      reportedDate: DateTime.parse(json['reportedDate'] as String),
      district: json['district'] as String,
      village: json['village'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      description: json['description'] as String,
      imagePaths: List<String>.from(json['imagePaths'] as List),
      status: json['status'] as String,
      assessorComments: json['assessorComments'] as String?,
      assessmentDate: json['assessmentDate'] != null
          ? DateTime.parse(json['assessmentDate'] as String)
          : null,
      claimNumber: json['claimNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'cropType': cropType,
      'season': season,
      'affectedArea': affectedArea,
      'lossType': lossType,
      'lossPercentage': lossPercentage,
      'incidentDate': incidentDate.toIso8601String(),
      'reportedDate': reportedDate.toIso8601String(),
      'district': district,
      'village': village,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'imagePaths': imagePaths,
      'status': status,
      'assessorComments': assessorComments,
      'assessmentDate': assessmentDate?.toIso8601String(),
      'claimNumber': claimNumber,
    };
  }

  String getStatusColor() {
    switch (status.toLowerCase()) {
      case 'submitted':
        return 'blue';
      case 'under_review':
        return 'orange';
      case 'approved':
        return 'green';
      case 'rejected':
        return 'red';
      case 'pending_documents':
        return 'amber';
      default:
        return 'grey';
    }
  }

  String getStatusLabel() {
    switch (status.toLowerCase()) {
      case 'submitted':
        return 'Submitted';
      case 'under_review':
        return 'Under Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'pending_documents':
        return 'Pending Documents';
      default:
        return 'Unknown';
    }
  }
}

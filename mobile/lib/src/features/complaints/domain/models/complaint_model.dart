class Complaint {
  final String complaintId;
  final String cropType;
  final double damagePercentage;
  final String status; // 'pending', 'approved', 'rejected', 'resolved'
  final DateTime submissionDate;
  final DateTime? resolvedDate;
  final String description;
  final String insuredAmount;
  final String claimAmount;
  final String village;
  final String district;
  final double acreage;
  final String imageUrl;
  final List<String> attachments;
  final String officerComments;

  Complaint({
    required this.complaintId,
    required this.cropType,
    required this.damagePercentage,
    required this.status,
    required this.submissionDate,
    this.resolvedDate,
    required this.description,
    required this.insuredAmount,
    required this.claimAmount,
    required this.village,
    required this.district,
    required this.acreage,
    required this.imageUrl,
    this.attachments = const [],
    this.officerComments = '',
  });

  bool get isActive => status == 'pending' || status == 'approved';
  bool get isPast => status == 'resolved' || status == 'rejected';
  
  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Under Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'resolved':
        return 'Resolved';
      default:
        return status;
    }
  }

  int get daysOld => DateTime.now().difference(submissionDate).inDays;
}

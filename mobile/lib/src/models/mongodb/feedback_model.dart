import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter/material.dart';

class FeedbackReport {
  final ObjectId? id;
  final String farmerId;
  final String farmerName;
  final String farmerPhone;
  final String title;
  final String description;
  final String category; // 'feedback', 'bug_report', 'feature_request', 'complaint'
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final String status; // 'open', 'in_progress', 'resolved', 'closed'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final String? adminResponse;
  final String? adminId;
  final List<String> attachments;
  final Map<String, dynamic> metadata;
  final String village;
  final String district;
  final String state;
  final double? rating; // 1-5 for feedback
  final bool isAnonymous;

  FeedbackReport({
    this.id,
    required this.farmerId,
    required this.farmerName,
    required this.farmerPhone,
    required this.title,
    required this.description,
    required this.category,
    this.priority = 'medium',
    this.status = 'open',
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.adminResponse,
    this.adminId,
    this.attachments = const [],
    this.metadata = const {},
    required this.village,
    required this.district,
    required this.state,
    this.rating,
    this.isAnonymous = false,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'farmerPhone': farmerPhone,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'adminResponse': adminResponse,
      'adminId': adminId,
      'attachments': attachments,
      'metadata': metadata,
      'village': village,
      'district': district,
      'state': state,
      'rating': rating,
      'isAnonymous': isAnonymous,
    };
  }

  factory FeedbackReport.fromJson(Map<String, dynamic> json) {
    return FeedbackReport(
      id: json['_id'] as ObjectId?,
      farmerId: json['farmerId'] ?? '',
      farmerName: json['farmerName'] ?? '',
      farmerPhone: json['farmerPhone'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'feedback',
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'open',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
      adminResponse: json['adminResponse'],
      adminId: json['adminId'],
      attachments: List<String>.from(json['attachments'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      village: json['village'] ?? '',
      district: json['district'] ?? '',
      state: json['state'] ?? '',
      rating: json['rating']?.toDouble(),
      isAnonymous: json['isAnonymous'] ?? false,
    );
  }

  FeedbackReport copyWith({
    ObjectId? id,
    String? farmerId,
    String? farmerName,
    String? farmerPhone,
    String? title,
    String? description,
    String? category,
    String? priority,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    String? adminResponse,
    String? adminId,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
    String? village,
    String? district,
    String? state,
    double? rating,
    bool? isAnonymous,
  }) {
    return FeedbackReport(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      farmerPhone: farmerPhone ?? this.farmerPhone,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      adminResponse: adminResponse ?? this.adminResponse,
      adminId: adminId ?? this.adminId,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
      village: village ?? this.village,
      district: district ?? this.district,
      state: state ?? this.state,
      rating: rating ?? this.rating,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }

  // Getters for UI display
  String get categoryDisplayName {
    switch (category) {
      case 'feedback':
        return 'फीडबैक / Feedback';
      case 'bug_report':
        return 'तकनीकी समस्या / Bug Report';
      case 'feature_request':
        return 'नई सुविधा / Feature Request';
      case 'complaint':
        return 'शिकायत / Complaint';
      default:
        return category;
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case 'low':
        return 'कम / Low';
      case 'medium':
        return 'मध्यम / Medium';
      case 'high':
        return 'उच्च / High';
      case 'urgent':
        return 'तत्काल / Urgent';
      default:
        return priority;
    }
  }

  String get statusDisplayName {
    switch (status) {
      case 'open':
        return 'खुला / Open';
      case 'in_progress':
        return 'प्रगति में / In Progress';
      case 'resolved':
        return 'हल हो गया / Resolved';
      case 'closed':
        return 'बंद / Closed';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'open':
        return const Color(0xFF2196F3); // Blue
      case 'in_progress':
        return const Color(0xFFFF9800); // Orange
      case 'resolved':
        return const Color(0xFF4CAF50); // Green
      case 'closed':
        return const Color(0xFF757575); // Grey
      default:
        return const Color(0xFF757575);
    }
  }

  Color get priorityColor {
    switch (priority) {
      case 'low':
        return const Color(0xFF4CAF50); // Green
      case 'medium':
        return const Color(0xFFFF9800); // Orange
      case 'high':
        return const Color(0xFFFF5722); // Deep Orange
      case 'urgent':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF757575);
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case 'feedback':
        return Icons.feedback;
      case 'bug_report':
        return Icons.bug_report;
      case 'feature_request':
        return Icons.lightbulb;
      case 'complaint':
        return Icons.report_problem;
      default:
        return Icons.message;
    }
  }
}
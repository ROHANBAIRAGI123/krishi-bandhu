import 'package:mongo_dart/mongo_dart.dart';

class OfficialModel {
  final ObjectId? id;
  final String userId;
  final String role; // "field_officer" | "admin" | "data_annotator"
  final String name;
  final String phone;
  final String passwordHash; // Hashed password
  final String? assignedDistrict;
  final List<String> permissions;
  final DateTime createdAt;
  final DateTime? lastLogin;
  
  OfficialModel({
    this.id,
    required this.userId,
    required this.role,
    required this.name,
    required this.phone,
    required this.passwordHash,
    this.assignedDistrict,
    required this.permissions,
    required this.createdAt,
    this.lastLogin,
  });
  
  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'userId': userId,
      'role': role,
      'name': name,
      'phone': phone,
      'passwordHash': passwordHash,
      if (assignedDistrict != null) 'assignedDistrict': assignedDistrict,
      'permissions': permissions,
      'createdAt': createdAt,
      if (lastLogin != null) 'lastLogin': lastLogin,
    };
  }
  
  factory OfficialModel.fromMap(Map<String, dynamic> map) {
    return OfficialModel(
      id: map['_id'] as ObjectId?,
      userId: map['userId'] as String,
      role: map['role'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      passwordHash: map['passwordHash'] as String,
      assignedDistrict: map['assignedDistrict'] as String?,
      permissions: List<String>.from(map['permissions'] as List),
      createdAt: map['createdAt'] as DateTime,
      lastLogin: map['lastLogin'] as DateTime?,
    );
  }
}

class AuditLogModel {
  final ObjectId? id;
  final String entity; // "image" | "claim" | "farmer" | "official"
  final String entityId;
  final String action; // "AI_INFERENCE" | "MANUAL_REVIEW" | "UPDATE" | "CREATE" | "DELETE"
  final String actor; // "SYSTEM" | "USER_123"
  final Map<String, dynamic> details;
  final DateTime timestamp;
  
  AuditLogModel({
    this.id,
    required this.entity,
    required this.entityId,
    required this.action,
    required this.actor,
    required this.details,
    required this.timestamp,
  });
  
  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'entity': entity,
      'entityId': entityId,
      'action': action,
      'actor': actor,
      'details': details,
      'timestamp': timestamp,
    };
  }
  
  factory AuditLogModel.fromMap(Map<String, dynamic> map) {
    return AuditLogModel(
      id: map['_id'] as ObjectId?,
      entity: map['entity'] as String,
      entityId: map['entityId'] as String,
      action: map['action'] as String,
      actor: map['actor'] as String,
      details: Map<String, dynamic>.from(map['details'] as Map),
      timestamp: map['timestamp'] as DateTime,
    );
  }
}

import 'package:flutter/material.dart';

enum FeedbackType {
  newFeature,
  improvement,
  bugReport,
  generalFeedback;

  String get apiValue {
    switch (this) {
      case FeedbackType.newFeature:
        return 'feature';
      case FeedbackType.improvement:
        return 'improvement';
      case FeedbackType.bugReport:
        return 'bug';
      case FeedbackType.generalFeedback:
        return 'general';
    }
  }

  static FeedbackType fromApi(dynamic val) {
    if (val == null) return FeedbackType.newFeature;
    final str = val.toString().toLowerCase().trim();
    if (str == 'feature' || str == 'newfeature') return FeedbackType.newFeature;
    if (str == 'improvement') return FeedbackType.improvement;
    if (str == 'bug' || str == 'bugreport') return FeedbackType.bugReport;
    if (str == 'general' || str == 'generalfeedback') return FeedbackType.generalFeedback;
    return FeedbackType.newFeature;
  }
}

enum FeedbackPriority {
  low,
  medium,
  high;

  String get apiValue => name;

  static FeedbackPriority fromApi(dynamic val) {
    if (val == null) return FeedbackPriority.medium;
    final str = val.toString().toLowerCase().trim();
    if (str == 'low') return FeedbackPriority.low;
    if (str == 'high') return FeedbackPriority.high;
    return FeedbackPriority.medium;
  }
}

enum FeedbackStatus {
  pending,
  reviewed,
  inProgress,
  completed,
  rejected;

  String get apiValue {
    switch (this) {
      case FeedbackStatus.pending:
        return 'pending';
      case FeedbackStatus.reviewed:
        return 'reviewed';
      case FeedbackStatus.inProgress:
        return 'in_progress';
      case FeedbackStatus.completed:
        return 'completed';
      case FeedbackStatus.rejected:
        return 'rejected';
    }
  }

  static FeedbackStatus fromApi(dynamic val) {
    if (val == null) return FeedbackStatus.pending;
    final str = val.toString().toLowerCase().trim();
    if (str == 'pending') return FeedbackStatus.pending;
    if (str == 'reviewed') return FeedbackStatus.reviewed;
    if (str == 'in_progress' || str == 'inprogress') return FeedbackStatus.inProgress;
    if (str == 'completed') return FeedbackStatus.completed;
    if (str == 'rejected') return FeedbackStatus.rejected;
    return FeedbackStatus.pending;
  }
}

class SuggestionFeedbackModel {
  final String id;
  final int userId;
  final String userName;
  final String userDivision;
  final FeedbackType type;
  final String module;
  final String title;
  final String description;
  final FeedbackPriority priority;
  final String? attachmentPath;
  final String? attachmentUrl;
  final String? appVersion;
  final String? deviceInfo;
  final FeedbackStatus status;
  final String? adminNotes;
  final String? adminName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SuggestionFeedbackModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userDivision = '',
    required this.type,
    required this.module,
    required this.title,
    required this.description,
    this.priority = FeedbackPriority.medium,
    this.attachmentPath,
    this.attachmentUrl,
    this.appVersion,
    this.deviceInfo,
    this.status = FeedbackStatus.pending,
    this.adminNotes,
    this.adminName,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Helper getters for UI
  String get typeLabel {
    switch (type) {
      case FeedbackType.newFeature:
        return 'Fitur Baru';
      case FeedbackType.improvement:
        return 'Peningkatan';
      case FeedbackType.bugReport:
        return 'Lapor Kendala';
      case FeedbackType.generalFeedback:
        return 'Saran Umum';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case FeedbackType.newFeature:
        return Icons.lightbulb_rounded;
      case FeedbackType.improvement:
        return Icons.speed_rounded;
      case FeedbackType.bugReport:
        return Icons.bug_report_rounded;
      case FeedbackType.generalFeedback:
        return Icons.chat_bubble_outline_rounded;
    }
  }

  Color get typeColor {
    switch (type) {
      case FeedbackType.newFeature:
        return const Color(0xFF2563EB); // Royal Blue
      case FeedbackType.improvement:
        return const Color(0xFFD97706); // Amber
      case FeedbackType.bugReport:
        return const Color(0xFFE11D48); // Rose/Red
      case FeedbackType.generalFeedback:
        return const Color(0xFF7C3AED); // Violet
    }
  }

  Color get typeBgColor {
    return typeColor.withValues(alpha: 0.12);
  }

  String get priorityLabel {
    switch (priority) {
      case FeedbackPriority.low:
        return 'Rendah';
      case FeedbackPriority.medium:
        return 'Sedang';
      case FeedbackPriority.high:
        return 'Mendesak';
    }
  }

  Color get priorityColor {
    switch (priority) {
      case FeedbackPriority.low:
        return const Color(0xFF64748B);
      case FeedbackPriority.medium:
        return const Color(0xFFF59E0B);
      case FeedbackPriority.high:
        return const Color(0xFFEF4444);
    }
  }

  String get statusLabel {
    switch (status) {
      case FeedbackStatus.pending:
        return 'Menunggu Ditinjau';
      case FeedbackStatus.reviewed:
        return 'Sedang Ditinjau';
      case FeedbackStatus.inProgress:
        return 'Dalam Antrean Rilis';
      case FeedbackStatus.completed:
        return 'Selesai / Sudah Dirilis';
      case FeedbackStatus.rejected:
        return 'Ditunda / Diarsipkan';
    }
  }

  Color get statusColor {
    switch (status) {
      case FeedbackStatus.pending:
        return const Color(0xFFF59E0B); // Amber
      case FeedbackStatus.reviewed:
        return const Color(0xFF0284C7); // Sky Blue
      case FeedbackStatus.inProgress:
        return const Color(0xFF6366F1); // Indigo
      case FeedbackStatus.completed:
        return const Color(0xFF10B981); // Emerald Green
      case FeedbackStatus.rejected:
        return const Color(0xFF64748B); // Slate Gray
    }
  }

  Color get statusBgColor {
    switch (status) {
      case FeedbackStatus.pending:
        return const Color(0xFFFFFBEB);
      case FeedbackStatus.reviewed:
        return const Color(0xFFF0F9FF);
      case FeedbackStatus.inProgress:
        return const Color(0xFFEEF2FF);
      case FeedbackStatus.completed:
        return const Color(0xFFECFDF5);
      case FeedbackStatus.rejected:
        return const Color(0xFFF1F5F9);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_division': userDivision,
      'type': type.apiValue,
      'module': module,
      'title': title,
      'description': description,
      'priority': priority.apiValue,
      'attachment_path': attachmentPath,
      'attachment_url': attachmentUrl,
      'app_version': appVersion,
      'device_info': deviceInfo,
      'status': status.apiValue,
      'admin_notes': adminNotes,
      'admin_name': adminName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory SuggestionFeedbackModel.fromJson(Map<String, dynamic> json) {
    return SuggestionFeedbackModel(
      id: json['id']?.toString() ?? '',
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      userName: json['user_name'] ?? 'Pengguna',
      userDivision: json['user_division'] ?? '',
      type: FeedbackType.fromApi(json['type']),
      module: json['module'] ?? 'Umum',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: FeedbackPriority.fromApi(json['priority']),
      attachmentPath: json['attachment_path'],
      attachmentUrl: json['attachment_url'],
      appVersion: json['app_version'],
      deviceInfo: json['device_info'],
      status: FeedbackStatus.fromApi(json['status']),
      adminNotes: json['admin_notes'],
      adminName: json['admin_name'],
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString().replaceAll(' ', 'T')) ??
              DateTime.tryParse(json['created_at'].toString()) ??
              DateTime.now())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? (DateTime.tryParse(json['updated_at'].toString().replaceAll(' ', 'T')) ??
              DateTime.tryParse(json['updated_at'].toString()))
          : null,
    );
  }
}

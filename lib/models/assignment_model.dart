import 'package:flutter/foundation.dart';

class Assignment {
  final int id;
  final String title;
  final String description;
  final String? specialInstruction;
  final String priority;
  final String dueDate;
  final String status;
  final int assignedTo;
  final int createdBy;
  final String? creatorName;
  final String? creatorPosition;
  final String? creatorRole;
  final String? creatorAvatar;
  final String? assigneeName;
  final String? assigneePosition;
  final String? assigneeRole;
  final String? assigneeAvatar;
  final String? attachment;
  final String? reportAttachment;
  final String? reportNotes;
  final String createdAt;
  final int progress;

  Assignment({
    required this.id,
    required this.title,
    required this.description,
    this.specialInstruction,
    required this.priority,
    required this.dueDate,
    required this.status,
    required this.assignedTo,
    required this.createdBy,
    this.creatorName,
    this.creatorPosition,
    this.creatorRole,
    this.creatorAvatar,
    this.assigneeName,
    this.assigneePosition,
    this.assigneeRole,
    this.assigneeAvatar,
    this.attachment,
    this.reportAttachment,
    this.reportNotes,
    required this.createdAt,
    this.progress = 0,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    }

    return Assignment(
      id: toInt(json['id']),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      specialInstruction:
          json['special_instructions'] ?? json['special_instruction'],
      priority:
          (json['priority'] == null || json['priority'].toString().isEmpty)
              ? 'BIASA'
              : json['priority'].toString(),
      dueDate: json['due_date'] ?? '',
      status: json['status'] ?? 'Belum Dimulai',
      assignedTo: toInt(json['assigned_to']),
      createdBy: toInt(json['created_by']),
      creatorName: json['author_name'] ?? json['creator_name'],
      creatorPosition: json['author_position'] ?? json['creator_position'],
      creatorRole: json['author_position'] ?? json['creator_role'],
      creatorAvatar: json['author_avatar'] ?? json['creator_avatar'],
      assigneeName: json['assignee_name'] ?? json['nama_penerima'],
      assigneePosition: json['assignee_position'] ?? json['jabatan_penerima'],
      assigneeRole:
          json['assignee_position'] ??
          json['assignee_role'] ??
          json['jabatan_penerima'],
      assigneeAvatar: json['assignee_avatar'] ?? json['photo_penerima'],
      attachment: json['attachment'] ?? json['attachment_path'],
      reportAttachment:
          json['report_attachment_url'] ?? json['report_attachment'],
      reportNotes: json['report_notes'],
      createdAt: json['created_at'] ?? '',
      progress: toInt(json['progress']),
    ).also((a) {
      if (a.assigneeName == null && a.assigneeRole == null) {
        debugPrint(
          "⚠️ DEBUG: Data Penerima Kosong! Keys yang ada: ${json.keys.toList()}",
        );
      }
    });
  }
}

extension AlsoExtension<T> on T {
  T also(void Function(T) block) {
    block(this);
    return this;
  }
}

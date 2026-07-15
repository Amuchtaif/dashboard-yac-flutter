import '../config/api_config.dart';

class ActivityType {
  final int id;
  final String name;
  final String slug;
  final String type; // 'personal' or 'event'
  final String? description;
  final String? icon;
  final String? color;
  final int point;
  final int sortOrder;
  final bool isActive;

  ActivityType({
    required this.id,
    required this.name,
    required this.slug,
    required this.type,
    this.description,
    this.icon,
    this.color,
    required this.point,
    required this.sortOrder,
    required this.isActive,
  });

  factory ActivityType.fromJson(Map<String, dynamic> json) {
    return ActivityType(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      type: json['type'] ?? 'personal',
      description: json['description'],
      icon: json['icon'],
      color: json['color'],
      point: int.tryParse(json['point'].toString()) ?? 0,
      sortOrder: int.tryParse(json['sort_order'].toString()) ?? 0,
      isActive: (json['is_active']?.toString() == '1' || json['is_active'] == true),
    );
  }
}

class ActivityAttachment {
  final int id;
  final int activityId;
  final String filePath;
  final String? fileType;
  final String? caption;
  final int uploadedBy;
  final String createdAt;

  ActivityAttachment({
    required this.id,
    required this.activityId,
    required this.filePath,
    this.fileType,
    this.caption,
    required this.uploadedBy,
    required this.createdAt,
  });

  String get url {
    if (filePath.isEmpty) return '';
    if (filePath.startsWith('http')) return filePath;

    // Clean up base URL
    String rootUrl = ApiConfig.baseUrl.replaceAll('/api', '');
    if (rootUrl.endsWith('/')) {
      rootUrl = rootUrl.substring(0, rootUrl.length - 1);
    }
    return "$rootUrl/$filePath";
  }

  factory ActivityAttachment.fromJson(Map<String, dynamic> json) {
    return ActivityAttachment(
      id: int.tryParse(json['id'].toString()) ?? 0,
      activityId: int.tryParse(json['activity_id'].toString()) ?? 0,
      filePath: json['file_path'] ?? '',
      fileType: json['file_type'],
      caption: json['caption'],
      uploadedBy: int.tryParse(json['uploaded_by'].toString()) ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class StudentActivity {
  final int id;
  final int activityTypeId;
  final int studentId;
  final String activityDate;
  final String? startTime;
  final String? endTime;
  final String status; // 'completed', 'not_completed', 'excused'
  final String? note;
  final int createdBy;
  final int? updatedBy;
  final String createdAt;
  final String studentName;
  final String studentClass;
  final String studentUnit;
  final String activityName;
  final String activityType; // 'personal' or 'event'
  final String? icon;
  final String? color;
  final int point;
  final String? creatorName;
  final List<ActivityAttachment> attachments;

  StudentActivity({
    required this.id,
    required this.activityTypeId,
    required this.studentId,
    required this.activityDate,
    this.startTime,
    this.endTime,
    required this.status,
    this.note,
    required this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.studentName,
    required this.studentClass,
    required this.studentUnit,
    required this.activityName,
    required this.activityType,
    this.icon,
    this.color,
    required this.point,
    this.creatorName,
    required this.attachments,
  });

  // Get Indonesian status translation
  String get statusIndonesian {
    switch (status) {
      case 'completed':
        return 'Dilaksanakan';
      case 'not_completed':
        return 'Tidak Dilaksanakan';
      case 'excused':
        return 'Berhalangan';
      default:
        return status;
    }
  }

  factory StudentActivity.fromJson(Map<String, dynamic> json) {
    var attachmentsList = json['attachments'] as List? ?? [];
    List<ActivityAttachment> parsedAttachments = attachmentsList
        .map((item) => ActivityAttachment.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return StudentActivity(
      id: int.tryParse(json['id'].toString()) ?? 0,
      activityTypeId: int.tryParse(json['activity_type_id'].toString()) ?? 0,
      studentId: int.tryParse(json['student_id'].toString()) ?? 0,
      activityDate: json['activity_date'] ?? '',
      startTime: json['start_time'],
      endTime: json['end_time'],
      status: json['status'] ?? 'completed',
      note: json['note'],
      createdBy: int.tryParse(json['created_by'].toString()) ?? 0,
      updatedBy: json['updated_by'] != null ? int.tryParse(json['updated_by'].toString()) : null,
      createdAt: json['created_at'] ?? '',
      studentName: json['student_name'] ?? json['nama_siswa'] ?? '',
      studentClass: json['student_class'] ?? json['kelas'] ?? '',
      studentUnit: json['student_unit'] ?? json['tingkat'] ?? '',
      activityName: json['activity_name'] ?? json['name'] ?? '',
      activityType: json['activity_type'] ?? json['type'] ?? 'personal',
      icon: json['icon'],
      color: json['color'],
      point: int.tryParse(json['point']?.toString() ?? '0') ?? 0,
      creatorName: json['creator_name'],
      attachments: parsedAttachments,
    );
  }
}

class RppModel {
  final String? id;
  final String title;
  final String? academicYearId;
  final String? academicYearName;
  final String? semester;
  final String? educationUnitId;
  final String? levelName;
  final String? gradeLevelId;
  final String? gradeName;
  final String? subjectId;
  final String? subjectName;
  final String? sessionNo;
  final String? allocation;
  final String contentCp; // Previously content_sk
  final String contentAtp; // Previously content_kd
  final String contentPertanyaanPemantik; // Previously content_indicator
  final String learningGoal;
  final String teachingMaterial;
  final String teachingProfilPancasila; // Previously teaching_method
  final String contentSteps;
  final String? contentSummary;
  final String assessment;
  final bool isDraft;
  final String? createdAt;
  final String? teacherName;

  RppModel({
    this.id,
    required this.title,
    this.academicYearId,
    this.academicYearName,
    this.semester,
    this.educationUnitId,
    this.levelName,
    this.gradeLevelId,
    this.gradeName,
    this.subjectId,
    this.subjectName,
    this.sessionNo,
    this.allocation,
    required this.contentCp,
    required this.contentAtp,
    required this.contentPertanyaanPemantik,
    required this.learningGoal,
    required this.teachingMaterial,
    required this.teachingProfilPancasila,
    required this.contentSteps,
    this.contentSummary,
    required this.assessment,
    this.isDraft = false,
    this.createdAt,
    this.teacherName,
  });

  factory RppModel.fromMap(Map<String, dynamic> map) {
    return RppModel(
      id: map['id']?.toString(),
      title: map['title'] ?? '',
      academicYearId: map['academic_year_id']?.toString(),
      academicYearName: map['academic_year_name'] ?? map['academic_year'],
      semester: map['semester']?.toString(),
      educationUnitId: map['education_unit_id']?.toString(),
      levelName: map['level_name'] ?? map['unit_name'],
      gradeLevelId: map['grade_level_id']?.toString(),
      gradeName: map['grade_name'] ?? map['class_name'],
      subjectId: map['subject_id']?.toString(),
      subjectName: map['subject_name'],
      sessionNo: map['session_no'] ?? map['meeting_no'],
      allocation: map['allocation'] ?? map['time_allocation'],
      contentCp: map['content_cp'] ?? map['content_sk'] ?? '',
      contentAtp: map['content_atp'] ?? map['content_kd'] ?? '',
      contentPertanyaanPemantik:
          map['content_pertanyaan_pemantik'] ?? map['content_indicator'] ?? '',
      learningGoal: map['learning_goal'] ?? map['objectives'] ?? '',
      teachingMaterial: map['teaching_material'] ?? map['material'] ?? '',
      teachingProfilPancasila:
          map['teaching_profil_pancasila'] ?? map['teaching_method'] ?? '',
      contentSteps: map['content_steps'] ?? '',
      contentSummary: map['content_summary'],
      assessment: map['assessment'] ?? map['content_summary'] ?? '',
      isDraft: map['is_draft'] == 1 || map['is_draft'] == true,
      createdAt: map['created_at'],
      teacherName: map['teacher_name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'academic_year_id': academicYearId,
      'semester': semester,
      'education_unit_id': educationUnitId,
      'grade_level_id': gradeLevelId,
      'subject_id': subjectId,
      'session_no': sessionNo,
      'allocation': allocation,
      'content_cp': contentCp,
      'content_atp': contentAtp,
      'content_pertanyaan_pemantik': contentPertanyaanPemantik,
      'learning_goal': learningGoal,
      'teaching_material': teachingMaterial,
      'teaching_profil_pancasila': teachingProfilPancasila,
      'content_steps': contentSteps,
      'content_summary': contentSummary ?? '',
      'assessment': assessment,
      'is_draft': isDraft ? 1 : 0,
    };
  }
}

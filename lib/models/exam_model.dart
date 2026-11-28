/// Model untuk Daftar Paket Ujian / Soal
class ExamPackageModel {
  final int id;
  final String title;
  final int teacherId;
  final int gradeLevelId;
  final int subjectId;
  final int assessmentTypeId;
  final int? academicYearId;
  final int totalQuestions;
  final int optionCount;
  final List<String> optionLabels;
  final String scoringMode;
  final String? examDate;
  final String ljkTemplate;
  final String status; // 'published', 'draft', 'closed'
  final String subjectName;
  final String gradeName;
  final String unitName;
  final String assessmentTypeName;
  final String teacherName;
  final int filledQuestions;
  final int scannedCount;
  final int classStudentCount;

  ExamPackageModel({
    required this.id,
    required this.title,
    required this.teacherId,
    required this.gradeLevelId,
    required this.subjectId,
    required this.assessmentTypeId,
    this.academicYearId,
    required this.totalQuestions,
    required this.optionCount,
    required this.optionLabels,
    required this.scoringMode,
    this.examDate,
    this.ljkTemplate = 'v1',
    required this.status,
    required this.subjectName,
    required this.gradeName,
    required this.unitName,
    required this.assessmentTypeName,
    required this.teacherName,
    this.filledQuestions = 0,
    this.scannedCount = 0,
    this.classStudentCount = 0,
  });

  bool get isPublished => status.toLowerCase() == 'published';
  bool get isDraft => status.toLowerCase() == 'draft';
  bool get isClosed => status.toLowerCase() == 'closed';

  double get scanProgress => classStudentCount > 0 ? (scannedCount / classStudentCount).clamp(0.0, 1.0) : 0.0;

  factory ExamPackageModel.fromJson(Map<String, dynamic> json) {
    List<String> labels = [];
    if (json['option_labels'] is List) {
      labels = (json['option_labels'] as List).map((e) => e.toString()).toList();
    } else {
      final count = int.tryParse(json['option_count']?.toString() ?? '4') ?? 4;
      labels = ['A', 'B', 'C', 'D', 'E'].sublist(0, count.clamp(2, 5));
    }

    return ExamPackageModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      teacherId: int.tryParse(json['teacher_id']?.toString() ?? '0') ?? 0,
      gradeLevelId: int.tryParse(json['grade_level_id']?.toString() ?? '0') ?? 0,
      subjectId: int.tryParse(json['subject_id']?.toString() ?? '0') ?? 0,
      assessmentTypeId: int.tryParse(json['assessment_type_id']?.toString() ?? '0') ?? 0,
      academicYearId: json['academic_year_id'] != null ? int.tryParse(json['academic_year_id'].toString()) : null,
      totalQuestions: int.tryParse(json['total_questions']?.toString() ?? '0') ?? 0,
      optionCount: int.tryParse(json['option_count']?.toString() ?? '4') ?? 4,
      optionLabels: labels,
      scoringMode: json['scoring_mode']?.toString() ?? 'equal_100',
      examDate: json['exam_date']?.toString(),
      ljkTemplate: json['ljk_template']?.toString() ?? 'v1',
      status: json['status']?.toString() ?? 'draft',
      subjectName: json['subject_name']?.toString() ?? '',
      gradeName: json['grade_name']?.toString() ?? '',
      unitName: json['unit_name']?.toString() ?? '',
      assessmentTypeName: json['assessment_type_name']?.toString() ?? '',
      teacherName: json['teacher_name']?.toString() ?? '',
      filledQuestions: int.tryParse(json['filled_questions']?.toString() ?? '0') ?? 0,
      scannedCount: int.tryParse(json['scanned_count']?.toString() ?? '0') ?? 0,
      classStudentCount: int.tryParse(json['class_student_count']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'teacher_id': teacherId,
    'grade_level_id': gradeLevelId,
    'subject_id': subjectId,
    'assessment_type_id': assessmentTypeId,
    'academic_year_id': academicYearId,
    'total_questions': totalQuestions,
    'option_count': optionCount,
    'option_labels': optionLabels,
    'scoring_mode': scoringMode,
    'exam_date': examDate,
    'ljk_template': ljkTemplate,
    'status': status,
    'subject_name': subjectName,
    'grade_name': gradeName,
    'unit_name': unitName,
    'assessment_type_name': assessmentTypeName,
    'teacher_name': teacherName,
    'filled_questions': filledQuestions,
    'scanned_count': scannedCount,
    'class_student_count': classStudentCount,
  };
}

/// Kunci Jawaban Soal
class AnswerKeyModel {
  final int questionId;
  final int questionNumber;
  final String correctOption; // 'A', 'B', 'C', 'D', 'E'
  final double weight;

  AnswerKeyModel({
    required this.questionId,
    required this.questionNumber,
    required this.correctOption,
    this.weight = 1.0,
  });

  factory AnswerKeyModel.fromJson(Map<String, dynamic> json) {
    return AnswerKeyModel(
      questionId: int.tryParse(json['question_id']?.toString() ?? '0') ?? 0,
      questionNumber: int.tryParse(json['question_number']?.toString() ?? '0') ?? 0,
      correctOption: (json['correct_option']?.toString() ?? '').toUpperCase(),
      weight: double.tryParse(json['weight']?.toString() ?? '1.0') ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'question_number': questionNumber,
    'correct_option': correctOption,
    'weight': weight,
  };
}

/// Santri di Kelas Paket Ujian
class StudentExamModel {
  final int id;
  final String namaSiswa;
  final String nomorInduk;
  final bool isScanned;
  final double? lastScore;

  StudentExamModel({
    required this.id,
    required this.namaSiswa,
    required this.nomorInduk,
    this.isScanned = false,
    this.lastScore,
  });

  factory StudentExamModel.fromJson(Map<String, dynamic> json) {
    return StudentExamModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      namaSiswa: json['nama_siswa']?.toString() ?? '',
      nomorInduk: json['nomor_induk']?.toString() ?? '',
      isScanned: json['is_scanned'] == true || json['is_scanned'] == 1 || json['is_scanned'] == '1',
      lastScore: json['last_score'] != null ? double.tryParse(json['last_score'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama_siswa': namaSiswa,
    'nomor_induk': nomorInduk,
    'is_scanned': isScanned,
    'last_score': lastScore,
  };
}

/// Titik Koordinat Relatif (0.0 .. 1.0)
class OmrPointModel {
  final double x;
  final double y;

  const OmrPointModel({required this.x, required this.y});

  factory OmrPointModel.fromJson(Map<String, dynamic> json) {
    return OmrPointModel(
      x: double.tryParse(json['x']?.toString() ?? '0') ?? 0.0,
      y: double.tryParse(json['y']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
}

/// Layout Soal OMR
class OmrQuestionLayoutModel {
  final int questionNumber;
  final int col;
  final int row;
  final double numX;
  final double y;
  final Map<String, OmrPointModel> options;

  OmrQuestionLayoutModel({
    required this.questionNumber,
    required this.col,
    required this.row,
    required this.numX,
    required this.y,
    required this.options,
  });

  factory OmrQuestionLayoutModel.fromJson(Map<String, dynamic> json) {
    final opts = <String, OmrPointModel>{};
    if (json['options'] is Map) {
      (json['options'] as Map).forEach((k, v) {
        if (v is Map<String, dynamic>) {
          opts[k.toString()] = OmrPointModel.fromJson(v);
        } else if (v is Map) {
          opts[k.toString()] = OmrPointModel.fromJson(Map<String, dynamic>.from(v));
        }
      });
    }

    return OmrQuestionLayoutModel(
      questionNumber: int.tryParse(json['question_number']?.toString() ?? '0') ?? 0,
      col: int.tryParse(json['col']?.toString() ?? '1') ?? 1,
      row: int.tryParse(json['row']?.toString() ?? '1') ?? 1,
      numX: double.tryParse(json['num_x']?.toString() ?? '0') ?? 0.0,
      y: double.tryParse(json['y']?.toString() ?? '0') ?? 0.0,
      options: opts,
    );
  }

  Map<String, dynamic> toJson() => {
    'question_number': questionNumber,
    'col': col,
    'row': row,
    'num_x': numX,
    'y': y,
    'options': options.map((k, v) => MapEntry(k, v.toJson())),
  };
}

/// Konfigurasi Geometri OMR Lembar Jawaban Komputer
class OmrLayoutModel {
  final String template;
  final double boxWidthMm;
  final double boxHeightMm;
  final int columns;
  final int rowsPerCol;
  final int totalQuestions;
  final int optionCount;
  final List<String> optionLabels;
  final double bubbleRadiusX;
  final double bubbleDiameterMm;
  final List<OmrQuestionLayoutModel> questions;

  OmrLayoutModel({
    this.template = 'v1',
    this.boxWidthMm = 172.0,
    this.boxHeightMm = 185.0,
    this.columns = 2,
    this.rowsPerCol = 25,
    required this.totalQuestions,
    required this.optionCount,
    required this.optionLabels,
    this.bubbleRadiusX = 0.014,
    this.bubbleDiameterMm = 4.82,
    required this.questions,
  });

  factory OmrLayoutModel.fromJson(Map<String, dynamic> json) {
    final qList = <OmrQuestionLayoutModel>[];
    if (json['questions'] is List) {
      for (final item in json['questions']) {
        if (item is Map<String, dynamic>) {
          qList.add(OmrQuestionLayoutModel.fromJson(item));
        } else if (item is Map) {
          qList.add(OmrQuestionLayoutModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final labels = json['option_labels'] is List
        ? (json['option_labels'] as List).map((e) => e.toString()).toList()
        : ['A', 'B', 'C', 'D'];

    return OmrLayoutModel(
      template: json['template']?.toString() ?? 'v1',
      boxWidthMm: double.tryParse(json['box_width_mm']?.toString() ?? '172.0') ?? 172.0,
      boxHeightMm: double.tryParse(json['box_height_mm']?.toString() ?? '185.0') ?? 185.0,
      columns: int.tryParse(json['columns']?.toString() ?? '2') ?? 2,
      rowsPerCol: int.tryParse(json['rows_per_col']?.toString() ?? '25') ?? 25,
      totalQuestions: int.tryParse(json['total_questions']?.toString() ?? '0') ?? 0,
      optionCount: int.tryParse(json['option_count']?.toString() ?? '4') ?? 4,
      optionLabels: labels,
      bubbleRadiusX: double.tryParse(json['bubble_radius_x']?.toString() ?? '0.014') ?? 0.014,
      bubbleDiameterMm: double.tryParse(json['bubble_diameter_mm']?.toString() ?? '4.82') ?? 4.82,
      questions: qList,
    );
  }

  Map<String, dynamic> toJson() => {
    'template': template,
    'box_width_mm': boxWidthMm,
    'box_height_mm': boxHeightMm,
    'columns': columns,
    'rows_per_col': rowsPerCol,
    'total_questions': totalQuestions,
    'option_count': optionCount,
    'option_labels': optionLabels,
    'bubble_radius_x': bubbleRadiusX,
    'bubble_diameter_mm': bubbleDiameterMm,
    'questions': questions.map((e) => e.toJson()).toList(),
  };
}

/// Detail Paket Soal Lengkap dengan Kunci Jawaban & Daftar Santri
class ExamPackageDetailModel {
  final ExamPackageModel package;
  final List<AnswerKeyModel> answerKeys;
  final List<StudentExamModel> students;
  final OmrLayoutModel omrLayout;

  ExamPackageDetailModel({
    required this.package,
    required this.answerKeys,
    required this.students,
    required this.omrLayout,
  });

  /// Ambil kunci jawaban berdasarkan nomor soal
  AnswerKeyModel? getKeyFor(int questionNumber) {
    try {
      return answerKeys.firstWhere((k) => k.questionNumber == questionNumber);
    } catch (_) {
      return null;
    }
  }

  /// Ambil data santri berdasarkan ID
  StudentExamModel? getStudent(int studentId) {
    try {
      return students.firstWhere((s) => s.id == studentId);
    } catch (_) {
      return null;
    }
  }

  factory ExamPackageDetailModel.fromJson(Map<String, dynamic> json) {
    final pkg = ExamPackageModel.fromJson(
      json['package'] is Map ? Map<String, dynamic>.from(json['package']) : {},
    );

    final keys = <AnswerKeyModel>[];
    if (json['answer_keys'] is List) {
      for (final k in json['answer_keys']) {
        if (k is Map) keys.add(AnswerKeyModel.fromJson(Map<String, dynamic>.from(k)));
      }
    }

    final stus = <StudentExamModel>[];
    if (json['students'] is List) {
      for (final s in json['students']) {
        if (s is Map) stus.add(StudentExamModel.fromJson(Map<String, dynamic>.from(s)));
      }
    }

    final omr = OmrLayoutModel.fromJson(
      json['omr_layout'] is Map ? Map<String, dynamic>.from(json['omr_layout']) : {},
    );

    return ExamPackageDetailModel(
      package: pkg,
      answerKeys: keys,
      students: stus,
      omrLayout: omr,
    );
  }

  Map<String, dynamic> toJson() => {
    'package': package.toJson(),
    'answer_keys': answerKeys.map((e) => e.toJson()).toList(),
    'students': students.map((e) => e.toJson()).toList(),
    'omr_layout': omrLayout.toJson(),
  };
}

/// Payload QR Code LJK (Format: YAC|p:12|s:199|q:25|o:4|t:v1)
class OmrQrPayload {
  final int packageId;
  final int studentId;
  final int totalQuestions;
  final int optionCount;
  final String template;
  final String raw;

  OmrQrPayload({
    required this.packageId,
    required this.studentId,
    required this.totalQuestions,
    required this.optionCount,
    this.template = 'v1',
    required this.raw,
  });

  bool get isBlankLjk => studentId == 0;

  static OmrQrPayload? tryParse(String rawText) {
    final clean = rawText.trim();
    if (!clean.startsWith('YAC|')) return null;

    final parts = clean.split('|');
    int? pid;
    int? sid;
    int? q;
    int? o;
    String t = 'v1';

    for (final p in parts) {
      if (p.startsWith('p:')) pid = int.tryParse(p.substring(2));
      if (p.startsWith('s:')) sid = int.tryParse(p.substring(2));
      if (p.startsWith('q:')) q = int.tryParse(p.substring(2));
      if (p.startsWith('o:')) o = int.tryParse(p.substring(2));
      if (p.startsWith('t:')) t = p.substring(2);
    }

    if (pid != null && sid != null && q != null && o != null) {
      return OmrQrPayload(
        packageId: pid,
        studentId: sid,
        totalQuestions: q,
        optionCount: o,
        template: t,
        raw: clean,
      );
    }
    return null;
  }
}

/// Item Hasil Jawaban per Soal
class ExamAnswerItem {
  final int questionNumber;
  String selectedOption; // 'A', 'B', 'C', 'D', 'E', 'BLANK', 'DOUBLE'
  final String? correctOption;
  final bool? isCorrect;
  final Map<String, double>? fillRatios;

  ExamAnswerItem({
    required this.questionNumber,
    required this.selectedOption,
    this.correctOption,
    this.isCorrect,
    this.fillRatios,
  });

  bool get isBlank => selectedOption == 'BLANK';
  bool get isDouble => selectedOption == 'DOUBLE';

  factory ExamAnswerItem.fromJson(Map<String, dynamic> json) {
    return ExamAnswerItem(
      questionNumber: int.tryParse(json['question_number']?.toString() ?? '0') ?? 0,
      selectedOption: (json['selected_option']?.toString() ?? 'BLANK').toUpperCase(),
      correctOption: json['correct_option']?.toString().toUpperCase(),
      isCorrect: json['is_correct'] == 1 || json['is_correct'] == true,
      fillRatios: json['fill_ratios'] is Map ? Map<String, double>.from(json['fill_ratios']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'question_number': questionNumber,
    'selected_option': selectedOption,
    if (correctOption != null) 'correct_option': correctOption,
    if (isCorrect != null) 'is_correct': isCorrect,
    if (fillRatios != null) 'fill_ratios': fillRatios,
  };
}

/// Submission Payload untuk `POST /api/exams/submit_scan.php`
class ExamScanSubmission {
  final int packageId;
  int studentId;
  final int scannerUserId;
  final bool autoSync;
  final List<ExamAnswerItem> answers;
  final String? scanImagePath;

  ExamScanSubmission({
    required this.packageId,
    required this.studentId,
    required this.scannerUserId,
    this.autoSync = true,
    required this.answers,
    this.scanImagePath,
  });

  Map<String, dynamic> toJson() => {
    'package_id': packageId,
    'student_id': studentId,
    'scanner_user_id': scannerUserId,
    'auto_sync': autoSync ? 1 : 0,
    'answers': answers.map((a) => {
      'question_number': a.questionNumber,
      'selected_option': a.selectedOption,
    }).toList(),
  };
}

/// Rekap Nilai Scan per Santri dari `GET /api/exams/scan_results.php`
class ExamScanResultItem {
  final int id;
  final int packageId;
  final int studentId;
  final String namaSiswa;
  final String nomorInduk;
  final int correctCount;
  final int wrongCount;
  final int blankCount;
  final int doubleCount;
  final double score;
  final int? assessmentId;
  final String? scanImageUrl;
  final String? scannedAt;

  ExamScanResultItem({
    required this.id,
    required this.packageId,
    required this.studentId,
    required this.namaSiswa,
    required this.nomorInduk,
    required this.correctCount,
    required this.wrongCount,
    required this.blankCount,
    required this.doubleCount,
    required this.score,
    this.assessmentId,
    this.scanImageUrl,
    this.scannedAt,
  });

  factory ExamScanResultItem.fromJson(Map<String, dynamic> json) {
    return ExamScanResultItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      packageId: int.tryParse(json['package_id']?.toString() ?? '0') ?? 0,
      studentId: int.tryParse(json['student_id']?.toString() ?? '0') ?? 0,
      namaSiswa: json['nama_siswa']?.toString() ?? '',
      nomorInduk: json['nomor_induk']?.toString() ?? '',
      correctCount: int.tryParse(json['correct_count']?.toString() ?? '0') ?? 0,
      wrongCount: int.tryParse(json['wrong_count']?.toString() ?? '0') ?? 0,
      blankCount: int.tryParse(json['blank_count']?.toString() ?? '0') ?? 0,
      doubleCount: int.tryParse(json['double_count']?.toString() ?? '0') ?? 0,
      score: double.tryParse(json['score']?.toString() ?? '0') ?? 0.0,
      assessmentId: json['assessment_id'] != null ? int.tryParse(json['assessment_id'].toString()) : null,
      scanImageUrl: json['scan_image_url']?.toString(),
      scannedAt: json['scanned_at']?.toString(),
    );
  }
}

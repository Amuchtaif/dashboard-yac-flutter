class StaffAttendanceRecap {
  final String averagePercentage;
  final String currentMonthLabel;
  final int exactCount;
  final int lateCount;
  final int permitCount;
  final List<StaffAttendanceHistory> history;

  StaffAttendanceRecap({
    required this.averagePercentage,
    required this.currentMonthLabel,
    required this.exactCount,
    required this.lateCount,
    required this.permitCount,
    required this.history,
  });

  factory StaffAttendanceRecap.fromJson(Map<String, dynamic> json) {
    var historyList = json['history'] as List? ?? [];
    return StaffAttendanceRecap(
      averagePercentage: json['summary']['average_percentage'] ?? '0%',
      currentMonthLabel: json['summary']['current_month_label'] ?? '-',
      exactCount: json['summary']['exact_count'] ?? 0,
      lateCount: json['summary']['late_count'] ?? 0,
      permitCount: json['summary']['permit_count'] ?? 0,
      history: historyList.map((i) => StaffAttendanceHistory.fromJson(i)).toList(),
    );
  }
}

class StaffAttendanceHistory {
  final String month;
  final String percentage;

  StaffAttendanceHistory({
    required this.month,
    required this.percentage,
  });

  factory StaffAttendanceHistory.fromJson(Map<String, dynamic> json) {
    return StaffAttendanceHistory(
      month: json['month'] ?? '',
      percentage: json['percentage'] ?? '0%',
    );
  }
}

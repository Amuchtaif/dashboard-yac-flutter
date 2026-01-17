class NotificationModel {
  final String title;
  final String message;
  final String time;
  final String type; // check_in, reminder, report, worksite
  final bool isRead;
  final String date; // Today, Yesterday

  NotificationModel({
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.isRead = false,
    required this.date,
  });
}

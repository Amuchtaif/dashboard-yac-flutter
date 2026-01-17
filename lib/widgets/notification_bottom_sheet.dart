import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/notification_model.dart';

class NotificationBottomSheet extends StatelessWidget {
  const NotificationBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data
    final List<NotificationModel> notifications = [
      NotificationModel(
        title: "Successful Check-in",
        message: "You have successfully checked in at Headquarter Building.",
        time: "08:00 AM",
        type: "check_in",
        date: "TODAY",
        isRead: false,
      ),
      NotificationModel(
        title: "Shift Reminder",
        message: "Your afternoon shift starts in 15 minutes. Prepare for duty.",
        time: "07:45 AM",
        type: "reminder",
        date: "TODAY",
        isRead: false,
      ),
    ];

    // Group by date
    Map<String, List<NotificationModel>> grouped = {};
    for (var notif in notifications) {
      if (!grouped.containsKey(notif.date)) {
        grouped[notif.date] = [];
      }
      grouped[notif.date]!.add(notif);
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF3F4F6), // Light background
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Wrap content
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Notifications",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    "CLEAR ALL",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2563EB), // Blue
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List
          Flexible(
            fit: FlexFit.loose,
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children:
                  grouped.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Header
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key, // TODAY, YESTERDAY
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF9CA3AF),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              if (entry.key == "TODAY")
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.blueAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Items
                        ...entry.value.map(
                          (notif) => _buildNotificationItem(notif),
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notif) {
    Color iconBg;
    Color iconColor;
    IconData icon;

    switch (notif.type) {
      case 'check_in':
        iconBg = const Color(0xFFDCFCE7); // Green light
        iconColor = const Color(0xFF166534); // Green dark
        icon = Icons.check_circle_rounded;
        break;
      case 'reminder':
        iconBg = const Color(0xFFFEF3C7); // Yellow light
        iconColor = const Color(0xFFD97706); // Yellow dark
        icon = Icons.access_time_filled;
        break;
      case 'report':
        iconBg = const Color(0xFFE0E7FF); // Blue light
        iconColor = const Color(0xFF3730A3); // Blue dark
        icon = Icons.description;
        break;
      case 'worksite':
        iconBg = const Color(0xFFF3F4F6); // Grey light
        iconColor = const Color(0xFF4B5563); // Grey dark
        icon = Icons.location_on;
        break;
      default:
        iconBg = Colors.grey[200]!;
        iconColor = Colors.grey;
        icon = Icons.notifications;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notif.title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          notif.time,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                        if (!notif.isRead) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notif.message,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

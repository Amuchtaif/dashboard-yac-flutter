import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationPopupDialog extends StatelessWidget {
  final List<dynamic> notifications;
  final Function(Map<String, dynamic>) onNotificationTap;
  final VoidCallback onViewAll;
  final VoidCallback? onDismiss;

  const NotificationPopupDialog({
    super.key,
    required this.notifications,
    required this.onNotificationTap,
    required this.onViewAll,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final int count = notifications.length;
    // Show maximum 2 preview items to keep popup compact and clean
    final previewList = notifications.take(2).toList();
    final int remainingCount = count > 2 ? count - 2 : 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Badge Icon
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.notifications_active_rounded,
                      size: 38,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
                if (count > 0)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        count > 99 ? '99+' : count.toString(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              count == 1 ? "Pemberitahuan Baru!" : "Ada $count Notifikasi Baru!",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),

            // Subtitle
            Text(
              "Anda memiliki pemberitahuan yang belum dibuka pada menu lonceng:",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Notification Cards Preview
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...previewList.map((item) {
                      final notif = Map<String, dynamic>.from(item);
                      return _buildNotificationCard(context, notif);
                    }),
                    if (remainingCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        child: Text(
                          "+$remainingCount notifikasi lainnya",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (count == 1) {
                    onNotificationTap(
                      Map<String, dynamic>.from(notifications.first),
                    );
                  } else {
                    onViewAll();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      count == 1 ? "Lihat Detail" : "Buka Notifikasi",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Dismiss Button
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onDismiss?.call();
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF94A3B8),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(
                "Nanti Saja",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    Map<String, dynamic> notif,
  ) {
    final String title = notif['title'] ?? 'Pemberitahuan';
    final String body = notif['body'] ?? '';
    final String type = notif['type'] ?? '';
    final String status = notif['status'] ?? '';
    final String date = notif['created_at'] ?? '';

    Color iconBg = const Color(0xFFF1F5F9);
    Color iconColor = const Color(0xFF64748B);
    IconData icon = Icons.notifications_rounded;

    if (type == 'incoming' || status == 'Pending') {
      iconBg = const Color(0xFFFEF3C7);
      iconColor = const Color(0xFFD97706);
      icon = Icons.access_time_filled_rounded;
    } else if (status == 'Approved') {
      iconBg = const Color(0xFFDCFCE7);
      iconColor = const Color(0xFF166534);
      icon = Icons.check_circle_rounded;
    } else if (status == 'Rejected') {
      iconBg = const Color(0xFFFEE2E2);
      iconColor = const Color(0xFFDC2626);
      icon = Icons.cancel_rounded;
    } else if (type == 'assignment') {
      iconBg = const Color(0xFFDBEAFE);
      iconColor = const Color(0xFF2563EB);
      icon = Icons.assignment_rounded;
    } else if (type == 'meeting' || type == 'meeting_invitation') {
      iconBg = const Color(0xFFEDE9FE);
      iconColor = const Color(0xFF7C3AED);
      icon = Icons.groups_rounded;
    } else if (type == 'teaching_reminder') {
      iconBg = const Color(0xFFE0F2FE);
      iconColor = const Color(0xFF0284C7);
      icon = Icons.school_rounded;
    }

    String timeStr = "";
    if (date.contains(' ')) {
      final parts = date.split(' ');
      if (parts.length > 1 && parts[1].length >= 5) {
        timeStr = parts[1].substring(0, 5);
      }
    }

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onNotificationTap(notif);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timeStr.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          timeStr,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

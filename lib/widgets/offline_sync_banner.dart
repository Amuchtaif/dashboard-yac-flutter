import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/network_provider.dart';
import '../services/offline_sync_service.dart';

/// Banner status offline & sinkronisasi yang elegan, aman dari status bar,
/// dan dilengkapi tombol aksi sinkronkan / hubungkan di sebelah kanan.
class OfflineSyncBanner extends StatefulWidget {
  final EdgeInsetsGeometry? margin;
  final bool isCard;

  const OfflineSyncBanner({super.key, this.margin, this.isCard = true});

  @override
  State<OfflineSyncBanner> createState() => _OfflineSyncBannerState();
}

class _OfflineSyncBannerState extends State<OfflineSyncBanner> {
  bool _isAttemptingSync = false;

  Future<void> _handleSyncOrReconnect() async {
    if (_isAttemptingSync) return;
    setState(() => _isAttemptingSync = true);

    final network = context.read<NetworkProvider>();
    final syncService = OfflineSyncService();

    try {
      final isOnline = await network.checkConnectivity();
      if (!mounted) return;

      if (isOnline) {
        final res = await syncService.syncAll();
        if (!mounted) return;
        setState(() => _isAttemptingSync = false);

        final successCount = res['successCount'] ?? 0;
        final failCount = res['failCount'] ?? 0;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    successCount > 0
                        ? 'Terhubung! $successCount transaksi berhasil disinkronkan ke server.'
                        : (failCount > 0
                            ? 'Terhubung, namun $failCount data gagal dikirim. Akan dicoba ulang.'
                            : 'Koneksi online aktif. Semua data telah sinkron.'),
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        setState(() => _isAttemptingSync = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Koneksi internet belum terdeteksi. Silakan periksa sambungan Wi-Fi atau data seluler Anda.',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isAttemptingSync = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkProvider>(
      builder: (context, network, _) {
        final isOffline = network.isOffline;
        final syncService = OfflineSyncService();

        return ValueListenableBuilder<int>(
          valueListenable: syncService.pendingCountNotifier,
          builder: (context, pendingCount, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: syncService.isSyncingNotifier,
              builder: (context, isSyncing, _) {
                // Sembunyikan jika online, tidak ada antrean pending, dan tidak sedang sync
                if (!isOffline &&
                    pendingCount == 0 &&
                    !isSyncing &&
                    !_isAttemptingSync) {
                  return const SizedBox.shrink();
                }

                final isBusy = isSyncing || _isAttemptingSync;

                final Color bgColor =
                    isOffline
                        ? const Color(0xFFFFFBEB) // Amber 50
                        : const Color(0xFFEFF6FF); // Blue 50
                final Color borderColor =
                    isOffline
                        ? const Color(0xFFFDE68A) // Amber 200
                        : const Color(0xFFBFDBFE); // Blue 200
                final Color textColor =
                    isOffline
                        ? const Color(0xFF92400E) // Amber 800
                        : const Color(0xFF1E40AF); // Blue 800
                final Color iconBgColor =
                    isOffline
                        ? const Color(0xFFFEF3C7) // Amber 100
                        : const Color(0xFFDBEAFE); // Blue 100
                final Color buttonBgColor =
                    isOffline
                        ? const Color(0xFFD97706) // Amber 600
                        : const Color(0xFF2563EB); // Blue 600

                final IconData iconData =
                    isOffline
                        ? Icons.wifi_off_rounded
                        : (isBusy
                            ? Icons.sync_rounded
                            : Icons.cloud_upload_outlined);

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin:
                      widget.margin ??
                      (widget.isCard
                          ? const EdgeInsets.only(bottom: 14)
                          : EdgeInsets.zero),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius:
                        widget.isCard
                            ? BorderRadius.circular(14)
                            : BorderRadius.zero,
                    border: Border.all(color: borderColor, width: 1.2),
                    boxShadow:
                        widget.isCard
                            ? [
                              BoxShadow(
                                color: (isOffline
                                        ? const Color(0xFFD97706)
                                        : const Color(0xFF2563EB))
                                    .withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                            : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(iconData, size: 18, color: textColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isOffline
                                  ? 'Mode Offline Aktif'
                                  : (isBusy
                                      ? 'Sedang Menyinkronkan...'
                                      : 'Data Menunggu Sinkron'),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isOffline
                                  ? (pendingCount > 0
                                      ? '$pendingCount transaksi tersimpan di HP'
                                      : 'Pencatatan tetap disimpan di HP')
                                  : '$pendingCount data siap dikirim ke server',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: textColor.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Tombol aksi di sebelah kanan badge
                      if (isBusy)
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              textColor,
                            ),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: _handleSyncOrReconnect,
                          icon: Icon(
                            isOffline
                                ? Icons.sync_rounded
                                : Icons.cloud_upload_rounded,
                            size: 15,
                          ),
                          label: Text(
                            'Sinkronkan',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonBgColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'faq_detail_screen.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchWhatsApp() async {
    final Uri url = Uri.parse('https://wa.me/6289651804382');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'Bantuan & Dukungan',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apa yang bisa kami bantu?',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cari jawaban dari pertanyaan populer di bawah ini.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            _buildSearchBar(),
            const SizedBox(height: 32),
            Text(
              'Pertanyaan Sering Ditanyakan (FAQ)',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            _buildFaqItem(
              context,
              'Absensi tidak terdeteksi (GPS tidak akurat)',
              'Pelajari cara mengatasi masalah lokasi...',
              'Pastikan Anda berada di area terbuka dengan pandangan langit yang jelas. Bangunan tinggi atau pepohonan rimbun terkadang dapat menghalangi sinyal GPS, yang menyebabkan lokasi Anda tidak terdeteksi dengan akurat oleh sistem absensi.\n\nAnda juga dapat mencoba mengaktifkan mode \'Akurasi Tinggi\' di pengaturan lokasi perangkat Anda. Selain itu, menyalakan Wi-Fi (meskipun tidak terhubung ke jaringan) dapat membantu perangkat melakukan triangulasi posisi dengan lebih presisi menggunakan titik akses di sekitar.\n\nJika masalah berlanjut, silakan muat ulang aplikasi atau mulai ulang modul GPS pada ponsel Anda sebelum mencoba melakukan absensi kembali.',
            ),
            _buildFaqItem(
              context,
              'Cara mengubah profil & foto',
              'Panduan lengkap mengubah data diri...',
              'Untuk mengubah profil, buka menu Profil, ketuk tombol "Ubah" di pojok kanan atas. Di sana Anda dapat mengganti Nama, Nomor Telepon, dan Alamat. Untuk mengganti foto profil, ketuk ikon kamera biru pada lingkaran foto Anda, pilih file dari galeri, lalu tekan "Simpan Perubahan". Peringatan: Data Email tidak dapat diubah secara mandiri.',
            ),
            _buildFaqItem(
              context,
              'Lupa kata sandi?',
              'Langkah-langkah pemulihan akun Anda...',
              'Jika Anda lupa kata sandi, silakan hubungi Administrator atau Bagian Kepegawaian untuk melakukan reset kata sandi. Jika Anda masih memiliki akses namun ingin menggantinya, masuk ke menu Profil -> Keamanan -> Ubah Kata Sandi, masukkan kata sandi lama dan buat kata sandi baru yang kuat.',
            ),
            _buildFaqItem(
              context,
              'Poin kinerja tidak bertambah',
              'Penjelasan tentang sistem perhitungan poin...',
              'Poin kinerja dihitung setiap hari berdasarkan presensi Anda. Pastikan Anda melakukan check-in tepat waktu untuk mendapatkan +10 poin. Keterlambatan akan mengurangi poin Anda sebesar -5. Jika poin tidak masuk padahal sudah presensi, silakan cek riwayat aktivitas atau hubungi tim IT.',
            ),
            const SizedBox(height: 40),
            _buildContactCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cari bantuan...',
          hintStyle: GoogleFonts.poppins(
            color: const Color(0xFF94A3B8),
            fontSize: 14,
          ),
          icon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildFaqItem(
    BuildContext context,
    String title,
    String subtitle,
    String fullContent,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: ListTile(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      FaqDetailScreen(title: title, content: fullContent),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Masih punya pertanyaan?',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tim dukungan kami siap membantu Anda kapan saja.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _launchWhatsApp,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF3B82F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
            ),
            child: Text(
              'Hubungi CS via WhatsApp',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

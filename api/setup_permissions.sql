-- =====================================================
-- SQL untuk setup permission system (Tahfidz Menu)
-- Jalankan di phpMyAdmin pada database attendance_db
-- =====================================================

-- 1. Tambahkan kolom view_tahfidz_menu ke tabel positions (jika belum ada)
ALTER TABLE positions 
ADD COLUMN IF NOT EXISTS view_tahfidz_menu TINYINT(1) DEFAULT 0;

-- 2. Buat tabel user_permissions untuk override per-user (jika belum ada)
CREATE TABLE IF NOT EXISTS user_permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    permission_name VARCHAR(100) NOT NULL,
    is_granted TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_user_permission (user_id, permission_name)
);

-- =====================================================
-- CARA MENGAKTIFKAN TAHFIDZ MENU UNTUK USER
-- Pilih salah satu metode:
-- =====================================================

-- METODE A: Aktifkan untuk seluruh jabatan/posisi tertentu
-- UPDATE positions SET view_tahfidz_menu = 1 WHERE id = [POSITION_ID];
-- Contoh: Aktifkan untuk semua Guru Tahfidz (position_id = 5)
-- UPDATE positions SET view_tahfidz_menu = 1 WHERE id = 5;

-- METODE B: Aktifkan untuk user tertentu (override)
-- INSERT INTO user_permissions (user_id, permission_name, is_granted) 
-- VALUES ([USER_ID], 'view_tahfidz_menu', 1)
-- ON DUPLICATE KEY UPDATE is_granted = 1;
-- Contoh: Aktifkan untuk user_id = 1
-- INSERT INTO user_permissions (user_id, permission_name, is_granted) 
-- VALUES (1, 'view_tahfidz_menu', 1)
-- ON DUPLICATE KEY UPDATE is_granted = 1;

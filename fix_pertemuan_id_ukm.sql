-- =====================================================
-- FIX: Update id_ukm untuk pertemuan yang NULL
-- Jalankan script ini di Supabase SQL Editor
-- =====================================================

-- STEP 1: Lihat data pertemuan saat ini
SELECT id_pertemuan, id_ukm, topik 
FROM pertemuan;

-- STEP 2: Lihat daftar UKM yang tersedia
SELECT id_ukm, nama_ukm 
FROM ukm;

-- STEP 3: Lihat UKM yang user terdaftar (ganti USER_ID dengan ID user Anda)
-- User ID dari log: 6c43d2bd-5fe7-47b0-99d8-0381f0e6c225
SELECT uhu.id_ukm, u.nama_ukm, uhu.status
FROM user_halaman_ukm uhu
JOIN ukm u ON uhu.id_ukm = u.id_ukm
WHERE uhu.id_user = '6c43d2bd-5fe7-47b0-99d8-0381f0e6c225';

-- =====================================================
-- STEP 4: UPDATE pertemuan dengan id_ukm yang benar
-- =====================================================

-- OPSI A: Jika Anda tahu pertemuan mana untuk UKM mana, update satu per satu:
-- Contoh: Update pertemuan tertentu ke UKM Genshin Impact
-- UPDATE pertemuan 
-- SET id_ukm = 'd8ed93d6-e47a-4d17-add2-23aac95d73df'
-- WHERE id_pertemuan = 'ID_PERTEMUAN_DISINI';

-- OPSI B: Update SEMUA pertemuan yang NULL ke UKM Musik (untuk testing)
-- UKM Musik ID: 08737d8c-7459-4d40-a5d4-5547385ffd50
UPDATE pertemuan 
SET id_ukm = '08737d8c-7459-4d40-a5d4-5547385ffd50'
WHERE id_ukm IS NULL;

-- =====================================================
-- OPSI C: FIX GENSHIN IMPACT (Pindahkan dari Musik ke Genshin)
-- Gunakan ini jika pertemuan Genshin Impact tertukar ke Musik
-- =====================================================
-- Musik ID: 08737d8c-7459-4d40-a5d4-5547385ffd50
-- Genshin ID: d8ed93d6-e47a-4d17-add2-23aac95d73df

-- UPDATE pertemuan
-- SET id_ukm = 'd8ed93d6-e47a-4d17-add2-23aac95d73df'
-- WHERE id_ukm = '08737d8c-7459-4d40-a5d4-5547385ffd50';
-- NOTE: Hati-hati, ini akan memindahkan SEMUA pertemuan Musik ke Genshin.
-- Sebaiknya filter berdasarkan topik jika memungkinkan.

-- STEP 5: Verifikasi hasil update
SELECT id_pertemuan, id_ukm, topik 
FROM pertemuan;

-- =====================================================
-- SETELAH MENJALANKAN SCRIPT INI:
-- 1. Refresh halaman UKM di app
-- 2. Progress bar seharusnya menampilkan "X/8 Pertemuan"
-- =====================================================

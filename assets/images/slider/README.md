# Folder Slider Images

Letakkan gambar-gambar untuk slider "Informasi Terkini" di folder ini.

## Format yang didukung:
- `.jpg` / `.jpeg`
- `.png`
- `.webp`

## Rekomendasi ukuran:
- **Lebar**: 800px - 1920px
- **Tinggi**: 400px - 600px  
- **Aspect Ratio**: 16:9 atau 2:1

## Cara menambah gambar:
1. Simpan gambar di folder ini (`assets/images/slider/`)
2. Buka file `lib/user/dashboard_user.dart`
3. Tambahkan entry baru di `_sliderImages` list:

```dart
{
  'image': 'assets/images/slider/nama_gambar.jpg',
  'title': 'Judul Event',
  'subtitle': 'Nama UKM',
},
```

## Contoh penamaan file:
- `badminton_cup_2025.jpg`
- `esports_tournament.jpg`
- `music_festival.png`

## Catatan:
- Gambar akan berganti otomatis setiap 7 detik
- User juga bisa swipe manual untuk mengganti slide

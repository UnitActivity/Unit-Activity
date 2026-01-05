# Folder Event Images

Letakkan gambar-gambar untuk event di folder ini.

## Struktur Penamaan File:
Gunakan nama file yang sesuai dengan kegiatan:

### E-Sports / Gaming:
- `esports_sparing.jpg` - Untuk event sparing E-Sports
- `esports_tournament.jpg` - Untuk turnamen E-Sports

### Badminton:
- `badminton_sparing.jpg` - Untuk event sparing badminton
- `badminton_tournament.jpg` - Untuk turnamen badminton

### Music:
- `music_livein.jpg` - Untuk event Live In musik
- `music_concert.jpg` - Untuk konser musik

### Lainnya:
- `basketball_event.jpg` - Event basketball
- `dance_event.jpg` - Event dance
- `general_event.jpg` - Event umum

## Format yang didukung:
- `.jpg` / `.jpeg`
- `.png`
- `.webp`

## Rekomendasi ukuran:
- **Lebar**: 400px - 800px
- **Tinggi**: 300px - 600px  
- **Aspect Ratio**: 4:3 atau 16:9

## Cara menambah gambar ke event:
1. Simpan gambar di folder ini (`assets/images/events/`)
2. Buka file `lib/user/event.dart`
3. Tambahkan field 'image' di data event:

```dart
{
  'id': 1,
  'title': 'Nama Event',
  'image': 'assets/images/events/nama_gambar.jpg',
  ...
},
```

## Contoh gambar yang diperlukan saat ini:
1. `esports_sparing.jpg` - Gambar gaming/esports
2. `badminton_sparing.jpg` - Gambar badminton
3. `music_livein.jpg` - Gambar konser/musik

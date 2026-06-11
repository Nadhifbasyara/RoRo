# Requirements Document

## Introduction

Fitur IMU Rollator menambahkan kemampuan monitoring aktivitas berjalan berbasis sensor IMU (Inertial Measurement Unit) yang terpasang pada rollator pasien pasca-stroke. ESP32 di rollator membaca data IMU secara periodik, menentukan status gerak (`jalan`, `diam`, atau `offline`), lalu mengirim event ke Firebase Firestore. Flutter app RoRo kemudian membaca event tersebut secara real-time, menghitung durasi sesi berjalan per hari, dan menampilkan statusnya di dashboard.

Fitur ini tidak memindahkan logika kalkulasi ke perangkat keras — ESP32 hanya bertindak sebagai publisher event, sedangkan semua perhitungan durasi, sesi, dan statistik harian dikerjakan sepenuhnya di sisi mobile app.

---

## Glossary

- **IMU**: Inertial Measurement Unit — sensor akselerometer/giroskop yang terpasang pada rollator untuk mendeteksi gerakan.
- **IMU_Repository**: Komponen Flutter yang bertanggung jawab membaca dan mem-stream data IMU dari Firebase Firestore.
- **IMU_Calculator**: Komponen Flutter yang menghitung durasi sesi berjalan dan statistik harian dari riwayat event IMU.
- **IMU_Status**: Nilai string yang merepresentasikan kondisi IMU: `jalan`, `diam`, atau `offline`.
- **Rollator**: Alat bantu jalan pasien pasca-stroke yang dilengkapi ESP32 dan sensor IMU.
- **Dashboard**: Halaman utama Flutter app RoRo yang menampilkan ringkasan aktivitas pasien.
- **imuHistory**: Sub-koleksi Firestore di bawah dokumen rollator yang menyimpan riwayat perubahan status IMU.
- **Sesi_Berjalan**: Interval waktu berkesinambungan di mana IMU_Status bernilai `jalan`, dibatasi oleh transisi `diam → jalan` dan `jalan → diam`.
- **Durasi_Harian**: Total akumulasi durasi seluruh Sesi_Berjalan dalam satu hari kalender (zona waktu lokal perangkat).
- **motionScore**: Nilai numerik dari firmware yang merepresentasikan intensitas gerakan terdeteksi.
- **deviceMillis**: Timestamp fallback dalam milidetik sejak perangkat menyala, digunakan ketika NTP tidak tersedia.

---

## Requirements

### Requirement 1: Baca Status IMU Real-Time

**User Story:** Sebagai pengguna aplikasi RoRo, saya ingin melihat status IMU rollator secara real-time, agar saya dapat mengetahui apakah pasien sedang berjalan, diam, atau sensor sedang offline.

#### Acceptance Criteria

1. WHEN dokumen rollator di Firestore diperbarui, THE IMU_Repository SHALL mem-emit nilai terbaru dari field `imuStatus` ke semua subscriber aktif dalam 3 detik.
2. THE IMU_Repository SHALL memetakan nilai string `jalan`, `diam`, dan `offline` ke tipe enumerasi `ImuStatus` di Flutter app.
3. IF field `imuStatus` tidak ada atau bernilai selain `jalan`, `diam`, atau `offline`, THEN THE IMU_Repository SHALL mem-emit nilai `offline` sebagai default.
4. THE IMU_Repository SHALL mem-stream field `imuConnected` (boolean) secara bersamaan dengan `imuStatus` dalam satu model data yang sama.
5. THE IMU_Repository SHALL mem-stream field `imuBerjalan` (boolean) secara bersamaan dengan `imuStatus` dalam satu model data yang sama.
6. THE IMU_Repository SHALL mem-stream field `imuMotionScore` (number), `imuPitch` (number), `imuRoll` (number), dan `imuUpdatedAtMs` (number) sebagai bagian dari model data IMU.

---

### Requirement 2: Tampilkan Status IMU di Dashboard

**User Story:** Sebagai pengguna aplikasi RoRo, saya ingin melihat indikator status IMU di dashboard, agar saya bisa dengan cepat mengetahui kondisi sensor dan aktivitas rollator saat ini.

#### Acceptance Criteria

1. WHEN `imuStatus` bernilai `jalan`, THE Dashboard SHALL menampilkan indikator visual aktif dengan label "Berjalan".
2. WHEN `imuStatus` bernilai `diam`, THE Dashboard SHALL menampilkan indikator visual tidak aktif dengan label "Diam".
3. WHEN `imuStatus` bernilai `offline`, THE Dashboard SHALL menampilkan indikator error dengan label "Sensor Offline" dan pesan bahwa data belum tersedia.
4. WHILE `imuStatus` bernilai `jalan`, THE Dashboard SHALL menampilkan nilai `imuMotionScore` terkini.
5. IF `imuConnected` bernilai `false`, THEN THE Dashboard SHALL menampilkan pesan peringatan koneksi sensor terputus, terlepas dari nilai `imuStatus`.
6. THE Dashboard SHALL memperbarui tampilan status IMU tanpa memerlukan refresh manual oleh pengguna.

---

### Requirement 3: Baca Riwayat IMU dari Sub-Koleksi

**User Story:** Sebagai pengguna aplikasi RoRo, saya ingin aplikasi dapat mengambil riwayat event IMU, agar durasi berjalan harian dapat dihitung secara akurat.

#### Acceptance Criteria

1. WHEN dipanggil dengan `rollatorId` yang valid, THE IMU_Repository SHALL mengembalikan stream dokumen dari sub-koleksi `rollators/{rollatorId}/imuHistory` diurutkan berdasarkan `timestamp` secara ascending.
2. THE IMU_Repository SHALL memetakan setiap dokumen `imuHistory` ke model `ImuHistoryEntry` yang memuat field: `status`, `connected`, `walking`, `pitch`, `roll`, `motionScore`, `timestamp`, dan `deviceMillis`.
3. IF field `timestamp` pada dokumen `imuHistory` bernilai null, THEN THE IMU_Repository SHALL menggunakan field `deviceMillis` untuk merekonstruksi waktu relatif urutan event, namun operasi berbasis timestamp lainnya tetap diizinkan untuk berlanjut.
4. THE IMU_Repository SHALL membatasi query riwayat pada rentang satu hari kalender penuh berdasarkan parameter tanggal yang diberikan oleh pemanggil.
5. IF sub-koleksi `imuHistory` kosong untuk tanggal yang diminta, THEN THE IMU_Repository SHALL mem-emit list kosong tanpa error.
6. IF dokumen `imuHistory` ada tetapi gagal dipetakan akibat data korup atau format tidak sesuai, THEN THE IMU_Repository SHALL melewati dokumen tersebut dan mem-emit peringatan melalui log tanpa menghentikan stream.

---

### Requirement 4: Hitung Durasi Sesi Berjalan Per Hari

**User Story:** Sebagai pengguna aplikasi RoRo, saya ingin aplikasi menghitung total menit berjalan per hari dari riwayat IMU, agar saya dapat melacak progres rehabilitasi pasien secara akurat.

#### Acceptance Criteria

1. WHEN diberikan list `ImuHistoryEntry` untuk satu hari, THE IMU_Calculator SHALL menghitung total durasi berjalan dengan menjumlahkan selisih waktu setiap pasangan transisi `diam → jalan` (waktu mulai) dan `jalan → diam` (waktu selesai).
2. THE IMU_Calculator SHALL mengabaikan sesi berjalan dengan durasi kurang dari 30 detik untuk menghindari noise dari perubahan status yang sangat singkat.
3. IF list `ImuHistoryEntry` mengandung satu atau lebih sesi `jalan` yang belum memiliki transisi `jalan → diam` sebagai penutup, THEN THE IMU_Calculator SHALL menggunakan batas akhir hari kalender (23:59:59) sebagai waktu selesai untuk setiap sesi yang belum ditutup tersebut.
4. THE IMU_Calculator SHALL mengembalikan total durasi berjalan dalam satuan detik (integer) untuk satu hari kalender.
5. THE IMU_Calculator SHALL mengembalikan jumlah Sesi_Berjalan yang valid (setelah filter minimum durasi) untuk satu hari kalender.
6. WHEN list `ImuHistoryEntry` berisi event dengan status `offline`, THE IMU_Calculator SHALL mengabaikan jendela waktu interval tersebut sehingga durasi selama status `offline` tidak ikut dihitung dalam total durasi berjalan.
7. FOR ALL list `ImuHistoryEntry` yang valid dengan setidaknya satu pasangan transisi lengkap, total durasi berjalan yang dihitung oleh THE IMU_Calculator SHALL sama dengan selisih akumulasi antara setiap waktu mulai dan waktu selesai Sesi_Berjalan (invariant kalkulasi).

---

### Requirement 5: Tampilkan Statistik Harian Berjalan di Dashboard

**User Story:** Sebagai pengguna aplikasi RoRo, saya ingin melihat ringkasan durasi berjalan hari ini di dashboard, agar saya dapat dengan mudah memantau progres rehabilitasi pasien.

#### Acceptance Criteria

1. THE Dashboard SHALL menampilkan total durasi berjalan hari ini dalam format menit dan detik (contoh: "21 menit 30 detik").
2. THE Dashboard SHALL menampilkan jumlah sesi berjalan hari ini.
3. WHEN data `imuHistory` untuk hari ini belum tersedia atau kosong, THE Dashboard SHALL menampilkan "0 menit" sebagai nilai default.
4. WHEN `imuStatus` bernilai `offline`, THE Dashboard SHALL menampilkan pesan "Data tidak tersedia — sensor offline" di area statistik harian, menggantikan nilai numerik.
5. THE Dashboard SHALL memperbarui statistik harian secara otomatis ketika `imuHistory` mendapat dokumen baru tanpa memerlukan restart aplikasi.

---

### Requirement 6: Persistensi dan Penanganan Timestamp

**User Story:** Sebagai developer aplikasi RoRo, saya ingin sistem IMU menangani kondisi ketidaktersediaan NTP dengan benar, agar data riwayat tetap dapat diproses meski timestamp absolut tidak tersedia.

#### Acceptance Criteria

1. THE IMU_Repository SHALL menerima dan menyimpan field `deviceMillis` dari setiap dokumen `imuHistory` sebagai angka integer (milidetik sejak perangkat menyala).
2. IF field `timestamp` (Firestore Timestamp) tersedia pada dokumen `imuHistory`, THEN THE IMU_Repository SHALL menggunakan `timestamp` sebagai acuan waktu utama untuk kalkulasi.
3. IF field `timestamp` tidak tersedia, THEN THE IMU_Repository SHALL menggunakan selisih nilai `deviceMillis` antar-event untuk menghitung durasi relatif antar-event.
4. WHEN urutan `ImuHistoryEntry` dibangun dari `deviceMillis`, THE IMU_Calculator SHALL mempertahankan urutan kronologis berdasarkan nilai `deviceMillis` ascending; jika urutan kronologis tidak dapat dipertahankan, THE IMU_Calculator SHALL menolak segmen tersebut dari kalkulasi.
5. IF nilai `deviceMillis` pada dua event berurutan tidak monoton meningkat (indikasi perangkat restart), THEN THE IMU_Calculator SHALL memulai segmen kalkulasi baru dan tidak menggabungkan durasi lintas segmen tersebut.

---

### Requirement 7: Sinkronisasi IMU dengan Statistik Walking Time yang Ada

**User Story:** Sebagai developer aplikasi RoRo, saya ingin data durasi berjalan dari IMU dapat diintegrasikan dengan sistem `walkingTimeMinutes` yang sudah ada di dashboard, agar tidak terjadi duplikasi data di dua sumber yang berbeda.

#### Acceptance Criteria

1. THE IMU_Repository SHALL menyediakan method `watchImuWalkingTimeMinutesToday(String rollatorId)` yang mengembalikan `Stream<int>` berisi total menit berjalan hari ini yang dikalkulasi dari `imuHistory`.
2. WHEN IMU_Calculator berhasil menghitung durasi harian, THE IMU_Repository SHALL membulatkan nilai detik ke menit penuh (pembulatan ke bawah) untuk konsistensi dengan format `walkingTimeMinutes` yang sudah ada.
3. THE Dashboard SHALL menampilkan data dari IMU_Repository sebagai sumber utama jika field `imuStatus` tersedia di dokumen rollator.
4. IF `imuStatus` tidak tersedia di dokumen rollator, THEN THE Dashboard SHALL kembali menggunakan `walkingTimeMinutes` dari `DistanceRepository` sebagai fallback.

---

### Requirement 8: Penanganan Koneksi dan Error

**User Story:** Sebagai pengguna aplikasi RoRo, saya ingin aplikasi menangani kondisi error sensor atau koneksi dengan informatif, agar saya tidak bingung ketika data IMU tidak tampil.

#### Acceptance Criteria

1. IF koneksi Firestore terputus, THEN THE IMU_Repository SHALL mempertahankan nilai `imuStatus` terakhir yang berhasil dibaca dari Firestore sampai koneksi pulih, tanpa memperbarui status menjadi `offline` meskipun sensor IMU mengalami gangguan selama Firestore down.
2. WHEN koneksi Firestore pulih, THE IMU_Repository SHALL secara otomatis menyinkronkan ulang data tanpa intervensi pengguna.
3. IF `imuConnected` bernilai `false` dan `imuStatus` bernilai `offline`, THEN THE Dashboard SHALL menampilkan tombol atau panduan untuk memeriksa koneksi sensor pada rollator.
4. THE IMU_Repository SHALL menangkap semua exception dari Firestore dan mengubahnya menjadi event error pada stream, bukan throw exception yang tidak tertangkap.
5. WHEN stream IMU_Repository menerima event error dari Firestore, THE Dashboard SHALL menampilkan pesan error yang dapat dibaca pengguna dalam Bahasa Indonesia.

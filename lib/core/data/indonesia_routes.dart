import '../models/route_model.dart';

//  RUTE ANTAR-DAERAH DI INDONESIA
//  ~450 edge â€” mencakup koridor utama darat & penyeberangan antar-pulau.
//
//  Jarak (km), harga (IDR), durasi (menit) adalah ESTIMASI untuk tarif minibus.
//  Konvensi:
//    â€¢ Tarif â‰ˆ Rp 500â€“700 / km  (rata-rata Rp 600)
//    â€¢ Kecepatan â‰ˆ 40 km/jam  (â‰ˆ 1.5 mnt/km)
//    â€¢ Penyeberangan menambah flat cost & waktu.
//
//  Edge bersifat BIDIRECTIONAL â€” Dijkstra membangun dua arah otomatis.
//
//  TODO: Memuat dari JSON/API untuk produksi.
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class IndonesiaRoutes {
  IndonesiaRoutes._();

  static const List<RouteEdge> all = [
    //  DKI JAKARTA â€” internal
    RouteEdge(fromCityId: 'jkt_pusat', toCityId: 'jkt_utara', distance: 9, price: 12000, duration: 22),
    RouteEdge(fromCityId: 'jkt_pusat', toCityId: 'jkt_barat', distance: 10, price: 13000, duration: 25),
    RouteEdge(fromCityId: 'jkt_pusat', toCityId: 'jkt_selatan', distance: 10, price: 13000, duration: 25),
    RouteEdge(fromCityId: 'jkt_pusat', toCityId: 'jkt_timur', distance: 12, price: 15000, duration: 28),
    RouteEdge(fromCityId: 'jkt_utara', toCityId: 'jkt_barat', distance: 12, price: 15000, duration: 30),
    RouteEdge(fromCityId: 'jkt_utara', toCityId: 'jkt_timur', distance: 14, price: 16000, duration: 30),
    RouteEdge(fromCityId: 'jkt_selatan', toCityId: 'jkt_timur', distance: 12, price: 15000, duration: 28),

    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    //  BANTEN â€” internal & ke Jakarta
    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    RouteEdge(fromCityId: 'jkt_barat', toCityId: 'tangerang', distance: 20, price: 22000, duration: 40),
    RouteEdge(fromCityId: 'jkt_selatan', toCityId: 'tangerang_sel', distance: 15, price: 18000, duration: 30),
    RouteEdge(fromCityId: 'tangerang', toCityId: 'tangerang_sel', distance: 14, price: 16000, duration: 28),
    RouteEdge(fromCityId: 'tangerang', toCityId: 'tangerang_kab', distance: 18, price: 20000, duration: 35),
    RouteEdge(fromCityId: 'tangerang_kab', toCityId: 'serang_kab', distance: 55, price: 40000, duration: 80),
    RouteEdge(fromCityId: 'serang_kab', toCityId: 'serang_ko', distance: 8, price: 10000, duration: 18),
    RouteEdge(fromCityId: 'serang_ko', toCityId: 'cilegon', distance: 15, price: 16000, duration: 25),
    RouteEdge(fromCityId: 'serang_kab', toCityId: 'pandeglang', distance: 30, price: 25000, duration: 50),
    RouteEdge(fromCityId: 'pandeglang', toCityId: 'lebak', distance: 40, price: 32000, duration: 65),
    RouteEdge(fromCityId: 'lebak', toCityId: 'bogor_kab', distance: 80, price: 55000, duration: 120),

    //  JAWA BARAT â€” Jabodetabek â†’ Bandung â†’ Cirebon â†’ Tasik
    RouteEdge(fromCityId: 'jkt_timur', toCityId: 'bekasi', distance: 18, price: 20000, duration: 35),
    RouteEdge(fromCityId: 'jkt_selatan', toCityId: 'depok', distance: 15, price: 18000, duration: 30),
    RouteEdge(fromCityId: 'depok', toCityId: 'bogor', distance: 30, price: 28000, duration: 50),
    RouteEdge(fromCityId: 'bogor', toCityId: 'bogor_kab', distance: 10, price: 12000, duration: 20),
    RouteEdge(fromCityId: 'bekasi', toCityId: 'bekasi_kab', distance: 12, price: 14000, duration: 25),
    RouteEdge(fromCityId: 'bekasi_kab', toCityId: 'karawang', distance: 35, price: 30000, duration: 55),
    RouteEdge(fromCityId: 'karawang', toCityId: 'purwakarta', distance: 35, price: 30000, duration: 55),
    RouteEdge(fromCityId: 'karawang', toCityId: 'subang', distance: 45, price: 35000, duration: 65),
    RouteEdge(fromCityId: 'subang', toCityId: 'bandung', distance: 60, price: 45000, duration: 90),
    RouteEdge(fromCityId: 'purwakarta', toCityId: 'bandung_barat', distance: 55, price: 40000, duration: 80),
    RouteEdge(fromCityId: 'bogor', toCityId: 'cianjur', distance: 55, price: 40000, duration: 90),
    RouteEdge(fromCityId: 'bogor', toCityId: 'sukabumi', distance: 60, price: 45000, duration: 95),
    RouteEdge(fromCityId: 'sukabumi', toCityId: 'sukabumi_kab', distance: 10, price: 12000, duration: 18),
    RouteEdge(fromCityId: 'cianjur', toCityId: 'bandung', distance: 65, price: 50000, duration: 100),
    RouteEdge(fromCityId: 'bandung', toCityId: 'cimahi', distance: 10, price: 12000, duration: 20),
    RouteEdge(fromCityId: 'bandung', toCityId: 'bandung_kab', distance: 15, price: 16000, duration: 28),
    RouteEdge(fromCityId: 'bandung', toCityId: 'bandung_barat', distance: 20, price: 20000, duration: 35),
    RouteEdge(fromCityId: 'bandung', toCityId: 'sumedang', distance: 45, price: 35000, duration: 65),
    RouteEdge(fromCityId: 'bandung', toCityId: 'garut', distance: 65, price: 50000, duration: 90),
    RouteEdge(fromCityId: 'sumedang', toCityId: 'majalengka', distance: 35, price: 28000, duration: 55),
    RouteEdge(fromCityId: 'majalengka', toCityId: 'cirebon', distance: 45, price: 35000, duration: 65),
    RouteEdge(fromCityId: 'cirebon', toCityId: 'cirebon_kab', distance: 8, price: 10000, duration: 18),
    RouteEdge(fromCityId: 'cirebon', toCityId: 'kuningan', distance: 35, price: 28000, duration: 55),
    RouteEdge(fromCityId: 'cirebon', toCityId: 'indramayu', distance: 50, price: 38000, duration: 70),
    RouteEdge(fromCityId: 'subang', toCityId: 'indramayu', distance: 55, price: 40000, duration: 80),
    RouteEdge(fromCityId: 'garut', toCityId: 'tasikmalaya', distance: 65, price: 50000, duration: 95),
    RouteEdge(fromCityId: 'tasikmalaya', toCityId: 'tasikmalaya_kab', distance: 10, price: 12000, duration: 18),
    RouteEdge(fromCityId: 'tasikmalaya', toCityId: 'ciamis', distance: 30, price: 25000, duration: 45),
    RouteEdge(fromCityId: 'ciamis', toCityId: 'banjar', distance: 15, price: 15000, duration: 25),
    RouteEdge(fromCityId: 'ciamis', toCityId: 'pangandaran', distance: 50, price: 38000, duration: 75),
    RouteEdge(fromCityId: 'kuningan', toCityId: 'ciamis', distance: 40, price: 32000, duration: 60),

    //  JAWA TENGAH â€” Pantura, selatan, tengah
    // --- Pantura ---
    RouteEdge(fromCityId: 'cirebon', toCityId: 'brebes', distance: 30, price: 25000, duration: 45),
    RouteEdge(fromCityId: 'brebes', toCityId: 'tegal', distance: 15, price: 15000, duration: 25),
    RouteEdge(fromCityId: 'tegal', toCityId: 'tegal_kab', distance: 8, price: 10000, duration: 15),
    RouteEdge(fromCityId: 'tegal', toCityId: 'pemalang', distance: 20, price: 18000, duration: 30),
    RouteEdge(fromCityId: 'pemalang', toCityId: 'pekalongan', distance: 25, price: 22000, duration: 40),
    RouteEdge(fromCityId: 'pekalongan', toCityId: 'pekalongan_kab', distance: 8, price: 10000, duration: 15),
    RouteEdge(fromCityId: 'pekalongan', toCityId: 'batang', distance: 12, price: 12000, duration: 20),
    RouteEdge(fromCityId: 'batang', toCityId: 'kendal', distance: 50, price: 40000, duration: 70),
    RouteEdge(fromCityId: 'kendal', toCityId: 'semarang', distance: 25, price: 22000, duration: 35),
    RouteEdge(fromCityId: 'semarang', toCityId: 'demak', distance: 25, price: 22000, duration: 35),
    RouteEdge(fromCityId: 'demak', toCityId: 'kudus', distance: 25, price: 22000, duration: 35),
    RouteEdge(fromCityId: 'demak', toCityId: 'grobogan', distance: 40, price: 32000, duration: 55),
    RouteEdge(fromCityId: 'kudus', toCityId: 'jepara', distance: 30, price: 25000, duration: 45),
    RouteEdge(fromCityId: 'kudus', toCityId: 'pati', distance: 35, price: 28000, duration: 50),
    RouteEdge(fromCityId: 'pati', toCityId: 'rembang', distance: 40, price: 32000, duration: 55),
    RouteEdge(fromCityId: 'rembang', toCityId: 'blora', distance: 50, price: 38000, duration: 70),
    RouteEdge(fromCityId: 'rembang', toCityId: 'tuban', distance: 40, price: 32000, duration: 55),
    // --- Selatan Jawa Tengah ---
    RouteEdge(fromCityId: 'banjar', toCityId: 'cilacap', distance: 65, price: 50000, duration: 100),
    RouteEdge(fromCityId: 'cilacap', toCityId: 'banyumas', distance: 28, price: 24000, duration: 42),
    RouteEdge(fromCityId: 'banyumas', toCityId: 'purbalingga', distance: 20, price: 18000, duration: 30),
    RouteEdge(fromCityId: 'purbalingga', toCityId: 'banjarnegara', distance: 25, price: 22000, duration: 40),
    RouteEdge(fromCityId: 'banjarnegara', toCityId: 'wonosobo', distance: 30, price: 25000, duration: 48),
    RouteEdge(fromCityId: 'wonosobo', toCityId: 'temanggung', distance: 30, price: 25000, duration: 48),
    RouteEdge(fromCityId: 'kebumen', toCityId: 'purworejo', distance: 25, price: 22000, duration: 38),
    RouteEdge(fromCityId: 'cilacap', toCityId: 'kebumen', distance: 60, price: 45000, duration: 90),
    RouteEdge(fromCityId: 'purworejo', toCityId: 'kulon_progo', distance: 25, price: 22000, duration: 38),
    // --- Tengah Jawa Tengah ---
    RouteEdge(fromCityId: 'semarang', toCityId: 'semarang_kab', distance: 15, price: 15000, duration: 25),
    RouteEdge(fromCityId: 'semarang', toCityId: 'salatiga', distance: 50, price: 38000, duration: 65),
    RouteEdge(fromCityId: 'semarang_kab', toCityId: 'salatiga', distance: 18, price: 18000, duration: 30),
    RouteEdge(fromCityId: 'salatiga', toCityId: 'boyolali', distance: 30, price: 25000, duration: 45),
    RouteEdge(fromCityId: 'semarang', toCityId: 'kendal', distance: 25, price: 22000, duration: 35),
    RouteEdge(fromCityId: 'temanggung', toCityId: 'magelang', distance: 35, price: 28000, duration: 50),
    RouteEdge(fromCityId: 'magelang', toCityId: 'magelang_kab', distance: 5, price: 8000, duration: 12),
    RouteEdge(fromCityId: 'magelang', toCityId: 'yogyakarta', distance: 43, price: 35000, duration: 60),
    RouteEdge(fromCityId: 'boyolali', toCityId: 'surakarta', distance: 30, price: 25000, duration: 45),
    RouteEdge(fromCityId: 'surakarta', toCityId: 'sukoharjo', distance: 12, price: 14000, duration: 22),
    RouteEdge(fromCityId: 'surakarta', toCityId: 'karanganyar', distance: 18, price: 18000, duration: 28),
    RouteEdge(fromCityId: 'surakarta', toCityId: 'sragen', distance: 30, price: 25000, duration: 45),
    RouteEdge(fromCityId: 'surakarta', toCityId: 'klaten', distance: 30, price: 25000, duration: 45),
    RouteEdge(fromCityId: 'klaten', toCityId: 'yogyakarta', distance: 30, price: 25000, duration: 45),
    RouteEdge(fromCityId: 'sukoharjo', toCityId: 'wonogiri', distance: 32, price: 26000, duration: 48),
    RouteEdge(fromCityId: 'sragen', toCityId: 'ngawi', distance: 30, price: 25000, duration: 45),
    RouteEdge(fromCityId: 'grobogan', toCityId: 'blora', distance: 60, price: 45000, duration: 85),
    RouteEdge(fromCityId: 'grobogan', toCityId: 'sragen', distance: 50, price: 38000, duration: 70),
    RouteEdge(fromCityId: 'tegal_kab', toCityId: 'brebes', distance: 18, price: 18000, duration: 28),

    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    //  DI YOGYAKARTA â€” internal & ke Jateng
    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    RouteEdge(fromCityId: 'yogyakarta', toCityId: 'sleman', distance: 10, price: 12000, duration: 20),
    RouteEdge(fromCityId: 'yogyakarta', toCityId: 'bantul', distance: 12, price: 14000, duration: 22),
    RouteEdge(fromCityId: 'bantul', toCityId: 'gunung_kidul', distance: 40, price: 32000, duration: 60),
    RouteEdge(fromCityId: 'yogyakarta', toCityId: 'kulon_progo', distance: 28, price: 24000, duration: 42),
    RouteEdge(fromCityId: 'purworejo', toCityId: 'magelang', distance: 45, price: 35000, duration: 65),

    //  JAWA TIMUR â€” utara, selatan, Madura
    // --- Masuk dari Jateng ---
    RouteEdge(fromCityId: 'sragen', toCityId: 'ngawi', distance: 30, price: 25000, duration: 45),
    RouteEdge(fromCityId: 'ngawi', toCityId: 'madiun', distance: 30, price: 25000, duration: 45),
    RouteEdge(fromCityId: 'madiun', toCityId: 'madiun_kab', distance: 8, price: 10000, duration: 15),
    RouteEdge(fromCityId: 'madiun', toCityId: 'magetan', distance: 20, price: 18000, duration: 30),
    RouteEdge(fromCityId: 'madiun', toCityId: 'ponorogo', distance: 30, price: 25000, duration: 45),
    RouteEdge(fromCityId: 'madiun', toCityId: 'nganjuk', distance: 40, price: 32000, duration: 60),
    RouteEdge(fromCityId: 'ponorogo', toCityId: 'pacitan', distance: 55, price: 42000, duration: 85),
    RouteEdge(fromCityId: 'ponorogo', toCityId: 'trenggalek', distance: 50, price: 38000, duration: 75),
    RouteEdge(fromCityId: 'nganjuk', toCityId: 'kediri', distance: 28, price: 24000, duration: 42),
    RouteEdge(fromCityId: 'kediri', toCityId: 'kediri_kab', distance: 8, price: 10000, duration: 15),
    RouteEdge(fromCityId: 'kediri', toCityId: 'tulungagung', distance: 30, price: 25000, duration: 45),
    RouteEdge(fromCityId: 'tulungagung', toCityId: 'trenggalek', distance: 20, price: 18000, duration: 30),
    RouteEdge(fromCityId: 'kediri', toCityId: 'blitar', distance: 40, price: 32000, duration: 60),
    RouteEdge(fromCityId: 'blitar', toCityId: 'blitar_kab', distance: 8, price: 10000, duration: 15),
    RouteEdge(fromCityId: 'blitar', toCityId: 'malang', distance: 75, price: 55000, duration: 110),
    // --- Koridor Utara Jatim ---
    RouteEdge(fromCityId: 'tuban', toCityId: 'lamongan', distance: 50, price: 38000, duration: 70),
    RouteEdge(fromCityId: 'tuban', toCityId: 'bojonegoro', distance: 40, price: 32000, duration: 55),
    RouteEdge(fromCityId: 'bojonegoro', toCityId: 'lamongan', distance: 55, price: 42000, duration: 80),
    RouteEdge(fromCityId: 'lamongan', toCityId: 'gresik', distance: 30, price: 25000, duration: 45),
    RouteEdge(fromCityId: 'gresik', toCityId: 'surabaya', distance: 15, price: 15000, duration: 25),
    // --- Surabaya hub ---
    RouteEdge(fromCityId: 'surabaya', toCityId: 'sidoarjo', distance: 22, price: 20000, duration: 35),
    RouteEdge(fromCityId: 'sidoarjo', toCityId: 'mojokerto', distance: 40, price: 32000, duration: 55),
    RouteEdge(fromCityId: 'mojokerto', toCityId: 'mojokerto_kab', distance: 5, price: 8000, duration: 12),
    RouteEdge(fromCityId: 'mojokerto', toCityId: 'jombang', distance: 20, price: 18000, duration: 30),
    RouteEdge(fromCityId: 'jombang', toCityId: 'nganjuk', distance: 30, price: 25000, duration: 45),
    RouteEdge(fromCityId: 'jombang', toCityId: 'kediri', distance: 45, price: 35000, duration: 65),
    RouteEdge(fromCityId: 'surabaya', toCityId: 'bangkalan', distance: 35, price: 30000, duration: 50),
    RouteEdge(fromCityId: 'bangkalan', toCityId: 'sampang', distance: 45, price: 35000, duration: 65),
    RouteEdge(fromCityId: 'sampang', toCityId: 'pamekasan', distance: 28, price: 24000, duration: 42),
    RouteEdge(fromCityId: 'pamekasan', toCityId: 'sumenep', distance: 50, price: 38000, duration: 72),
    // --- Jalur selatan Jatim ---
    RouteEdge(fromCityId: 'surabaya', toCityId: 'pasuruan', distance: 60, price: 45000, duration: 85),
    RouteEdge(fromCityId: 'pasuruan', toCityId: 'pasuruan_kab', distance: 8, price: 10000, duration: 15),
    RouteEdge(fromCityId: 'pasuruan', toCityId: 'probolinggo', distance: 40, price: 32000, duration: 55),
    RouteEdge(fromCityId: 'probolinggo', toCityId: 'probolinggo_kab', distance: 8, price: 10000, duration: 15),
    RouteEdge(fromCityId: 'probolinggo', toCityId: 'lumajang', distance: 35, price: 28000, duration: 50),
    RouteEdge(fromCityId: 'lumajang', toCityId: 'jember', distance: 55, price: 42000, duration: 80),
    RouteEdge(fromCityId: 'jember', toCityId: 'bondowoso', distance: 32, price: 26000, duration: 48),
    RouteEdge(fromCityId: 'bondowoso', toCityId: 'situbondo', distance: 35, price: 28000, duration: 50),
    RouteEdge(fromCityId: 'jember', toCityId: 'banyuwangi', distance: 100, price: 70000, duration: 150),
    RouteEdge(fromCityId: 'malang', toCityId: 'malang_kab', distance: 8, price: 10000, duration: 15),
    RouteEdge(fromCityId: 'malang', toCityId: 'batu', distance: 15, price: 15000, duration: 25),
    RouteEdge(fromCityId: 'pasuruan', toCityId: 'malang', distance: 55, price: 42000, duration: 80),

    //  BALI â€” internal
    RouteEdge(fromCityId: 'denpasar', toCityId: 'badung', distance: 10, price: 12000, duration: 20),
    RouteEdge(fromCityId: 'denpasar', toCityId: 'gianyar', distance: 25, price: 22000, duration: 40),
    RouteEdge(fromCityId: 'gianyar', toCityId: 'bangli', distance: 20, price: 18000, duration: 35),
    RouteEdge(fromCityId: 'gianyar', toCityId: 'klungkung', distance: 22, price: 20000, duration: 35),
    RouteEdge(fromCityId: 'klungkung', toCityId: 'karangasem', distance: 25, price: 22000, duration: 40),
    RouteEdge(fromCityId: 'denpasar', toCityId: 'tabanan', distance: 22, price: 20000, duration: 35),
    RouteEdge(fromCityId: 'tabanan', toCityId: 'jembrana', distance: 45, price: 35000, duration: 65),
    RouteEdge(fromCityId: 'buleleng', toCityId: 'bangli', distance: 60, price: 45000, duration: 90),
    RouteEdge(fromCityId: 'buleleng', toCityId: 'tabanan', distance: 50, price: 38000, duration: 75),

    //  NTB â€” Lombok & Sumbawa
    RouteEdge(fromCityId: 'mataram', toCityId: 'lombok_barat', distance: 10, price: 12000, duration: 18),
    RouteEdge(fromCityId: 'mataram', toCityId: 'lombok_tengah', distance: 30, price: 25000, duration: 45),
    RouteEdge(fromCityId: 'lombok_tengah', toCityId: 'lombok_timur', distance: 25, price: 22000, duration: 38),
    RouteEdge(fromCityId: 'mataram', toCityId: 'lombok_utara', distance: 35, price: 28000, duration: 55),
    RouteEdge(fromCityId: 'lombok_timur', toCityId: 'sumbawa_barat', distance: 70, price: 55000, duration: 120),
    RouteEdge(fromCityId: 'sumbawa_barat', toCityId: 'sumbawa', distance: 50, price: 38000, duration: 75),
    RouteEdge(fromCityId: 'sumbawa', toCityId: 'dompu', distance: 60, price: 45000, duration: 90),
    RouteEdge(fromCityId: 'dompu', toCityId: 'bima', distance: 40, price: 32000, duration: 60),
    RouteEdge(fromCityId: 'bima', toCityId: 'bima_kab', distance: 8, price: 10000, duration: 15),

    //  NTT â€” Flores, Sumba, Timor
    // --- Timor ---
    RouteEdge(fromCityId: 'kupang', toCityId: 'kupang_kab', distance: 10, price: 12000, duration: 18),
    RouteEdge(fromCityId: 'kupang_kab', toCityId: 'tts', distance: 80, price: 60000, duration: 130),
    RouteEdge(fromCityId: 'tts', toCityId: 'ttu', distance: 55, price: 42000, duration: 90),
    RouteEdge(fromCityId: 'ttu', toCityId: 'belu', distance: 50, price: 38000, duration: 80),
    RouteEdge(fromCityId: 'belu', toCityId: 'malaka', distance: 30, price: 25000, duration: 50),
    // --- Flores spine ---
    RouteEdge(fromCityId: 'manggarai_barat', toCityId: 'manggarai', distance: 60, price: 48000, duration: 100),
    RouteEdge(fromCityId: 'manggarai', toCityId: 'manggarai_timur', distance: 35, price: 28000, duration: 60),
    RouteEdge(fromCityId: 'manggarai_timur', toCityId: 'ngada', distance: 50, price: 38000, duration: 85),
    RouteEdge(fromCityId: 'ngada', toCityId: 'nagekeo', distance: 30, price: 25000, duration: 50),
    RouteEdge(fromCityId: 'nagekeo', toCityId: 'ende', distance: 40, price: 32000, duration: 65),
    RouteEdge(fromCityId: 'ende', toCityId: 'sikka', distance: 50, price: 38000, duration: 80),
    RouteEdge(fromCityId: 'sikka', toCityId: 'flores_timur', distance: 60, price: 48000, duration: 100),
    RouteEdge(fromCityId: 'flores_timur', toCityId: 'lembata', distance: 40, price: 35000, duration: 80),
    RouteEdge(fromCityId: 'lembata', toCityId: 'alor', distance: 60, price: 50000, duration: 120),
    // --- Sumba ---
    RouteEdge(fromCityId: 'sumba_barat', toCityId: 'sumba_barat_daya', distance: 35, price: 28000, duration: 60),
    RouteEdge(fromCityId: 'sumba_barat', toCityId: 'sumba_tengah', distance: 25, price: 22000, duration: 45),
    RouteEdge(fromCityId: 'sumba_tengah', toCityId: 'sumba_timur', distance: 80, price: 60000, duration: 140),

    //  TRANS-SUMATERA â€” tulang punggung utaraâ†’selatan
    // --- Aceh ---
    RouteEdge(fromCityId: 'banda_aceh', toCityId: 'aceh_besar', distance: 20, price: 18000, duration: 32),
    RouteEdge(fromCityId: 'aceh_besar', toCityId: 'aceh_jaya', distance: 100, price: 70000, duration: 160),
    RouteEdge(fromCityId: 'banda_aceh', toCityId: 'pidie', distance: 95, price: 65000, duration: 140),
    RouteEdge(fromCityId: 'pidie', toCityId: 'pidie_jaya', distance: 30, price: 25000, duration: 45),
    RouteEdge(fromCityId: 'pidie_jaya', toCityId: 'bireuen', distance: 35, price: 28000, duration: 50),
    RouteEdge(fromCityId: 'bireuen', toCityId: 'lhokseumawe', distance: 40, price: 32000, duration: 60),
    RouteEdge(fromCityId: 'bireuen', toCityId: 'aceh_tengah', distance: 65, price: 50000, duration: 100),
    RouteEdge(fromCityId: 'aceh_tengah', toCityId: 'bener_meriah', distance: 30, price: 25000, duration: 48),
    RouteEdge(fromCityId: 'aceh_tengah', toCityId: 'gayo_lues', distance: 80, price: 60000, duration: 140),
    RouteEdge(fromCityId: 'lhokseumawe', toCityId: 'aceh_utara', distance: 15, price: 15000, duration: 25),
    RouteEdge(fromCityId: 'aceh_utara', toCityId: 'aceh_timur', distance: 80, price: 60000, duration: 120),
    RouteEdge(fromCityId: 'aceh_timur', toCityId: 'langsa', distance: 40, price: 32000, duration: 60),
    RouteEdge(fromCityId: 'langsa', toCityId: 'aceh_tamiang', distance: 50, price: 38000, duration: 75),
    RouteEdge(fromCityId: 'aceh_barat', toCityId: 'nagan_raya', distance: 35, price: 28000, duration: 55),
    RouteEdge(fromCityId: 'nagan_raya', toCityId: 'aceh_barat_daya', distance: 55, price: 42000, duration: 90),
    RouteEdge(fromCityId: 'aceh_barat_daya', toCityId: 'aceh_selatan', distance: 65, price: 50000, duration: 105),
    RouteEdge(fromCityId: 'aceh_selatan', toCityId: 'aceh_singkil', distance: 70, price: 55000, duration: 115),
    RouteEdge(fromCityId: 'aceh_selatan', toCityId: 'aceh_tenggara', distance: 80, price: 60000, duration: 130),
    RouteEdge(fromCityId: 'aceh_jaya', toCityId: 'aceh_barat', distance: 70, price: 55000, duration: 110),
    // --- Aceh â†’ Sumut ---
    RouteEdge(fromCityId: 'aceh_tamiang', toCityId: 'langkat', distance: 80, price: 60000, duration: 120),
    RouteEdge(fromCityId: 'aceh_tenggara', toCityId: 'karo', distance: 120, price: 85000, duration: 190),
    // --- Sumatera Utara ---
    RouteEdge(fromCityId: 'langkat', toCityId: 'binjai', distance: 35, price: 28000, duration: 50),
    RouteEdge(fromCityId: 'binjai', toCityId: 'medan', distance: 22, price: 20000, duration: 35),
    RouteEdge(fromCityId: 'medan', toCityId: 'deli_serdang', distance: 15, price: 15000, duration: 25),
    RouteEdge(fromCityId: 'deli_serdang', toCityId: 'serdang_bedagai', distance: 40, price: 32000, duration: 60),
    RouteEdge(fromCityId: 'serdang_bedagai', toCityId: 'tebing_tinggi', distance: 20, price: 18000, duration: 30),
    RouteEdge(fromCityId: 'tebing_tinggi', toCityId: 'simalungun', distance: 40, price: 32000, duration: 60),
    RouteEdge(fromCityId: 'simalungun', toCityId: 'pematang_siantar', distance: 20, price: 18000, duration: 30),
    RouteEdge(fromCityId: 'pematang_siantar', toCityId: 'toba', distance: 45, price: 35000, duration: 70),
    RouteEdge(fromCityId: 'toba', toCityId: 'samosir', distance: 35, price: 28000, duration: 55),
    RouteEdge(fromCityId: 'toba', toCityId: 'tapanuli_utara', distance: 25, price: 22000, duration: 40),
    RouteEdge(fromCityId: 'tapanuli_utara', toCityId: 'humbang_has', distance: 30, price: 25000, duration: 50),
    RouteEdge(fromCityId: 'tapanuli_utara', toCityId: 'tapanuli_tengah', distance: 70, price: 55000, duration: 110),
    RouteEdge(fromCityId: 'tapanuli_tengah', toCityId: 'sibolga', distance: 15, price: 15000, duration: 25),
    RouteEdge(fromCityId: 'tapanuli_utara', toCityId: 'tapanuli_selatan', distance: 60, price: 45000, duration: 90),
    RouteEdge(fromCityId: 'tapanuli_selatan', toCityId: 'padangsidimpuan', distance: 15, price: 15000, duration: 25),
    RouteEdge(fromCityId: 'padangsidimpuan', toCityId: 'mandailing_natal', distance: 65, price: 50000, duration: 100),
    RouteEdge(fromCityId: 'padangsidimpuan', toCityId: 'padang_lawas', distance: 50, price: 38000, duration: 80),
    RouteEdge(fromCityId: 'padang_lawas', toCityId: 'padang_lawas_utr', distance: 25, price: 22000, duration: 40),
    RouteEdge(fromCityId: 'medan', toCityId: 'karo', distance: 75, price: 55000, duration: 110),
    RouteEdge(fromCityId: 'karo', toCityId: 'dairi', distance: 50, price: 38000, duration: 80),
    RouteEdge(fromCityId: 'dairi', toCityId: 'pakpak_bharat', distance: 30, price: 25000, duration: 50),
    RouteEdge(fromCityId: 'serdang_bedagai', toCityId: 'batu_bara', distance: 30, price: 25000, duration: 45),
    RouteEdge(fromCityId: 'batu_bara', toCityId: 'asahan', distance: 25, price: 22000, duration: 38),
    RouteEdge(fromCityId: 'asahan', toCityId: 'tanjungbalai', distance: 20, price: 18000, duration: 30),
    RouteEdge(fromCityId: 'asahan', toCityId: 'labuhanbatu', distance: 55, price: 42000, duration: 80),
    RouteEdge(fromCityId: 'labuhanbatu', toCityId: 'labuhanbatu_sel', distance: 30, price: 25000, duration: 45),
    RouteEdge(fromCityId: 'labuhanbatu', toCityId: 'labuhanbatu_utr', distance: 25, price: 22000, duration: 38),
    // --- Sumut â†’ Sumbar via trans-Sumatera ---
    RouteEdge(fromCityId: 'mandailing_natal', toCityId: 'pasaman', distance: 80, price: 60000, duration: 130),
    RouteEdge(fromCityId: 'pasaman', toCityId: 'pasaman_barat', distance: 40, price: 32000, duration: 65),
    RouteEdge(fromCityId: 'pasaman', toCityId: 'bukittinggi', distance: 80, price: 58000, duration: 120),
    // --- Sumatera Barat ---
    RouteEdge(fromCityId: 'bukittinggi', toCityId: 'agam', distance: 10, price: 12000, duration: 18),
    RouteEdge(fromCityId: 'bukittinggi', toCityId: 'padang_panjang', distance: 15, price: 15000, duration: 25),
    RouteEdge(fromCityId: 'padang_panjang', toCityId: 'tanah_datar', distance: 12, price: 14000, duration: 22),
    RouteEdge(fromCityId: 'bukittinggi', toCityId: 'payakumbuh', distance: 35, price: 28000, duration: 50),
    RouteEdge(fromCityId: 'payakumbuh', toCityId: 'lima_puluh_kota', distance: 10, price: 12000, duration: 18),
    RouteEdge(fromCityId: 'padang_panjang', toCityId: 'padang', distance: 55, price: 42000, duration: 80),
    RouteEdge(fromCityId: 'padang', toCityId: 'pariaman', distance: 50, price: 38000, duration: 70),
    RouteEdge(fromCityId: 'pariaman', toCityId: 'padang_pariaman', distance: 10, price: 12000, duration: 18),
    RouteEdge(fromCityId: 'padang', toCityId: 'pesisir_selatan', distance: 70, price: 55000, duration: 110),
    RouteEdge(fromCityId: 'padang', toCityId: 'solok_ko', distance: 55, price: 42000, duration: 80),
    RouteEdge(fromCityId: 'solok_ko', toCityId: 'solok_kab', distance: 15, price: 15000, duration: 25),
    RouteEdge(fromCityId: 'solok_kab', toCityId: 'solok_selatan', distance: 45, price: 35000, duration: 70),
    RouteEdge(fromCityId: 'solok_ko', toCityId: 'sawahlunto', distance: 30, price: 25000, duration: 48),
    RouteEdge(fromCityId: 'sawahlunto', toCityId: 'sijunjung', distance: 25, price: 22000, duration: 40),
    RouteEdge(fromCityId: 'sijunjung', toCityId: 'dharmasraya', distance: 55, price: 42000, duration: 85),
    // --- Sumbar â†’ Riau ---
    RouteEdge(fromCityId: 'bukittinggi', toCityId: 'pekanbaru', distance: 210, price: 140000, duration: 300),
    RouteEdge(fromCityId: 'lima_puluh_kota', toCityId: 'rokan_hulu', distance: 100, price: 70000, duration: 150),
    // --- Riau ---
    RouteEdge(fromCityId: 'pekanbaru', toCityId: 'kampar', distance: 55, price: 42000, duration: 80),
    RouteEdge(fromCityId: 'pekanbaru', toCityId: 'siak', distance: 80, price: 60000, duration: 120),
    RouteEdge(fromCityId: 'pekanbaru', toCityId: 'pelalawan', distance: 70, price: 55000, duration: 105),
    RouteEdge(fromCityId: 'kampar', toCityId: 'rokan_hulu', distance: 65, price: 50000, duration: 100),
    RouteEdge(fromCityId: 'rokan_hulu', toCityId: 'rokan_hilir', distance: 90, price: 65000, duration: 140),
    RouteEdge(fromCityId: 'rokan_hilir', toCityId: 'dumai', distance: 50, price: 38000, duration: 75),
    RouteEdge(fromCityId: 'siak', toCityId: 'bengkalis', distance: 60, price: 45000, duration: 90),
    RouteEdge(fromCityId: 'bengkalis', toCityId: 'kep_meranti', distance: 40, price: 35000, duration: 80),
    RouteEdge(fromCityId: 'pelalawan', toCityId: 'indragiri_hulu', distance: 75, price: 55000, duration: 115),
    RouteEdge(fromCityId: 'indragiri_hulu', toCityId: 'indragiri_hilir', distance: 100, price: 70000, duration: 150),
    RouteEdge(fromCityId: 'indragiri_hulu', toCityId: 'kuantan_singingi', distance: 60, price: 45000, duration: 90),
    // --- Riau â†’ Jambi ---
    RouteEdge(fromCityId: 'kuantan_singingi', toCityId: 'bungo', distance: 90, price: 65000, duration: 140),
    // --- Jambi ---
    RouteEdge(fromCityId: 'jambi', toCityId: 'muaro_jambi', distance: 25, price: 22000, duration: 38),
    RouteEdge(fromCityId: 'jambi', toCityId: 'batanghari', distance: 55, price: 42000, duration: 80),
    RouteEdge(fromCityId: 'batanghari', toCityId: 'tebo', distance: 55, price: 42000, duration: 85),
    RouteEdge(fromCityId: 'tebo', toCityId: 'bungo', distance: 50, price: 38000, duration: 75),
    RouteEdge(fromCityId: 'jambi', toCityId: 'tanjab_timur', distance: 65, price: 50000, duration: 100),
    RouteEdge(fromCityId: 'jambi', toCityId: 'tanjab_barat', distance: 75, price: 55000, duration: 110),
    RouteEdge(fromCityId: 'bungo', toCityId: 'merangin', distance: 55, price: 42000, duration: 85),
    RouteEdge(fromCityId: 'merangin', toCityId: 'sarolangun', distance: 50, price: 38000, duration: 75),
    RouteEdge(fromCityId: 'merangin', toCityId: 'kerinci', distance: 70, price: 55000, duration: 110),
    RouteEdge(fromCityId: 'kerinci', toCityId: 'sungai_penuh', distance: 10, price: 12000, duration: 18),
    // --- Jambi â†’ Sumsel ---
    RouteEdge(fromCityId: 'sarolangun', toCityId: 'musi_rawas', distance: 100, price: 70000, duration: 155),
    // --- Sumatera Selatan ---
    RouteEdge(fromCityId: 'palembang', toCityId: 'ogan_ilir', distance: 35, price: 28000, duration: 50),
    RouteEdge(fromCityId: 'palembang', toCityId: 'banyuasin', distance: 40, price: 32000, duration: 58),
    RouteEdge(fromCityId: 'palembang', toCityId: 'oki', distance: 70, price: 55000, duration: 105),
    RouteEdge(fromCityId: 'ogan_ilir', toCityId: 'oku', distance: 85, price: 62000, duration: 125),
    RouteEdge(fromCityId: 'oku', toCityId: 'prabumulih', distance: 25, price: 22000, duration: 38),
    RouteEdge(fromCityId: 'oku', toCityId: 'oku_timur', distance: 55, price: 42000, duration: 80),
    RouteEdge(fromCityId: 'oku', toCityId: 'oku_selatan', distance: 70, price: 55000, duration: 110),
    RouteEdge(fromCityId: 'prabumulih', toCityId: 'muara_enim', distance: 30, price: 25000, duration: 45),
    RouteEdge(fromCityId: 'muara_enim', toCityId: 'lahat', distance: 40, price: 32000, duration: 60),
    RouteEdge(fromCityId: 'lahat', toCityId: 'empat_lawang', distance: 55, price: 42000, duration: 85),
    RouteEdge(fromCityId: 'lahat', toCityId: 'pagar_alam', distance: 45, price: 35000, duration: 70),
    RouteEdge(fromCityId: 'empat_lawang', toCityId: 'lubuklinggau', distance: 45, price: 35000, duration: 70),
    RouteEdge(fromCityId: 'lubuklinggau', toCityId: 'musi_rawas', distance: 40, price: 32000, duration: 60),
    RouteEdge(fromCityId: 'musi_rawas', toCityId: 'musi_rawas_utr', distance: 35, price: 28000, duration: 55),
    RouteEdge(fromCityId: 'banyuasin', toCityId: 'musi_banyuasin', distance: 65, price: 50000, duration: 95),
    RouteEdge(fromCityId: 'muara_enim', toCityId: 'pali', distance: 40, price: 32000, duration: 60),
    // --- Sumsel â†’ Bengkulu ---
    RouteEdge(fromCityId: 'lubuklinggau', toCityId: 'rejang_lebong', distance: 55, price: 42000, duration: 85),
    RouteEdge(fromCityId: 'pagar_alam', toCityId: 'kaur', distance: 80, price: 60000, duration: 130),
    // --- Bengkulu ---
    RouteEdge(fromCityId: 'bengkulu', toCityId: 'bengkulu_tengah', distance: 20, price: 18000, duration: 30),
    RouteEdge(fromCityId: 'bengkulu', toCityId: 'seluma', distance: 40, price: 32000, duration: 60),
    RouteEdge(fromCityId: 'bengkulu_tengah', toCityId: 'bengkulu_utara', distance: 45, price: 35000, duration: 68),
    RouteEdge(fromCityId: 'bengkulu_utara', toCityId: 'mukomuko', distance: 90, price: 65000, duration: 140),
    RouteEdge(fromCityId: 'bengkulu', toCityId: 'kepahiang', distance: 60, price: 45000, duration: 90),
    RouteEdge(fromCityId: 'kepahiang', toCityId: 'rejang_lebong', distance: 25, price: 22000, duration: 40),
    RouteEdge(fromCityId: 'rejang_lebong', toCityId: 'lebong', distance: 30, price: 25000, duration: 50),
    RouteEdge(fromCityId: 'seluma', toCityId: 'bengkulu_selatan', distance: 50, price: 38000, duration: 75),
    RouteEdge(fromCityId: 'bengkulu_selatan', toCityId: 'kaur', distance: 50, price: 38000, duration: 80),
    // --- Sumsel â†’ Lampung ---
    RouteEdge(fromCityId: 'oku_timur', toCityId: 'way_kanan', distance: 80, price: 60000, duration: 120),
    RouteEdge(fromCityId: 'oki', toCityId: 'mesuji', distance: 90, price: 65000, duration: 140),
    // --- Lampung ---
    RouteEdge(fromCityId: 'bandar_lampung', toCityId: 'pesawaran', distance: 20, price: 18000, duration: 30),
    RouteEdge(fromCityId: 'bandar_lampung', toCityId: 'lampung_selatan', distance: 25, price: 22000, duration: 38),
    RouteEdge(fromCityId: 'bandar_lampung', toCityId: 'pringsewu', distance: 35, price: 28000, duration: 50),
    RouteEdge(fromCityId: 'pringsewu', toCityId: 'tanggamus', distance: 20, price: 18000, duration: 30),
    RouteEdge(fromCityId: 'pringsewu', toCityId: 'lampung_tengah', distance: 40, price: 32000, duration: 60),
    RouteEdge(fromCityId: 'lampung_tengah', toCityId: 'metro', distance: 20, price: 18000, duration: 30),
    RouteEdge(fromCityId: 'metro', toCityId: 'lampung_timur', distance: 25, price: 22000, duration: 38),
    RouteEdge(fromCityId: 'lampung_tengah', toCityId: 'lampung_utara', distance: 50, price: 38000, duration: 75),
    RouteEdge(fromCityId: 'lampung_utara', toCityId: 'way_kanan', distance: 45, price: 35000, duration: 68),
    RouteEdge(fromCityId: 'lampung_utara', toCityId: 'tulang_bawang', distance: 40, price: 32000, duration: 60),
    RouteEdge(fromCityId: 'tulang_bawang', toCityId: 'tulang_bawang_bar', distance: 30, price: 25000, duration: 45),
    RouteEdge(fromCityId: 'tulang_bawang', toCityId: 'mesuji', distance: 45, price: 35000, duration: 68),
    RouteEdge(fromCityId: 'bandar_lampung', toCityId: 'lampung_barat', distance: 100, price: 70000, duration: 155),
    RouteEdge(fromCityId: 'lampung_barat', toCityId: 'pesisir_barat', distance: 55, price: 42000, duration: 85),

    //  KEP. BANGKA BELITUNG â€” internal
    RouteEdge(fromCityId: 'pangkalpinang', toCityId: 'bangka', distance: 20, price: 18000, duration: 30),
    RouteEdge(fromCityId: 'pangkalpinang', toCityId: 'bangka_tengah', distance: 25, price: 22000, duration: 38),
    RouteEdge(fromCityId: 'bangka', toCityId: 'bangka_barat', distance: 55, price: 42000, duration: 80),
    RouteEdge(fromCityId: 'bangka_tengah', toCityId: 'bangka_selatan', distance: 40, price: 32000, duration: 60),
    RouteEdge(fromCityId: 'belitung', toCityId: 'belitung_timur', distance: 35, price: 28000, duration: 50),
    // Bangka â†” Belitung ferry
    RouteEdge(fromCityId: 'bangka_selatan', toCityId: 'belitung', distance: 90, price: 75000, duration: 150),

    //  KEP. RIAU â€” internal
    RouteEdge(fromCityId: 'batam', toCityId: 'tanjungpinang', distance: 40, price: 55000, duration: 90),
    RouteEdge(fromCityId: 'batam', toCityId: 'karimun', distance: 60, price: 70000, duration: 120),
    RouteEdge(fromCityId: 'tanjungpinang', toCityId: 'bintan', distance: 15, price: 15000, duration: 25),
    RouteEdge(fromCityId: 'tanjungpinang', toCityId: 'lingga', distance: 80, price: 75000, duration: 160),

    //  KALIMANTAN BARAT
    RouteEdge(fromCityId: 'pontianak', toCityId: 'kubu_raya', distance: 15, price: 15000, duration: 25),
    RouteEdge(fromCityId: 'pontianak', toCityId: 'mempawah', distance: 60, price: 45000, duration: 85),
    RouteEdge(fromCityId: 'mempawah', toCityId: 'bengkayang', distance: 55, price: 42000, duration: 80),
    RouteEdge(fromCityId: 'mempawah', toCityId: 'landak', distance: 50, price: 38000, duration: 75),
    RouteEdge(fromCityId: 'bengkayang', toCityId: 'sambas', distance: 80, price: 60000, duration: 120),
    RouteEdge(fromCityId: 'bengkayang', toCityId: 'singkawang', distance: 40, price: 32000, duration: 60),
    RouteEdge(fromCityId: 'sambas', toCityId: 'singkawang', distance: 50, price: 38000, duration: 75),
    RouteEdge(fromCityId: 'landak', toCityId: 'sanggau', distance: 90, price: 65000, duration: 140),
    RouteEdge(fromCityId: 'sanggau', toCityId: 'sekadau', distance: 55, price: 42000, duration: 85),
    RouteEdge(fromCityId: 'sekadau', toCityId: 'sintang', distance: 65, price: 50000, duration: 100),
    RouteEdge(fromCityId: 'sintang', toCityId: 'melawi', distance: 70, price: 55000, duration: 110),
    RouteEdge(fromCityId: 'sintang', toCityId: 'kapuas_hulu', distance: 180, price: 120000, duration: 280),
    RouteEdge(fromCityId: 'kubu_raya', toCityId: 'kayong_utara', distance: 120, price: 85000, duration: 190),
    RouteEdge(fromCityId: 'kayong_utara', toCityId: 'ketapang', distance: 90, price: 65000, duration: 140),

    //  KALIMANTAN TENGAH
    RouteEdge(fromCityId: 'palangkaraya', toCityId: 'pulang_pisau', distance: 80, price: 60000, duration: 120),
    RouteEdge(fromCityId: 'palangkaraya', toCityId: 'gunung_mas', distance: 90, price: 65000, duration: 140),
    RouteEdge(fromCityId: 'palangkaraya', toCityId: 'katingan', distance: 100, price: 70000, duration: 155),
    RouteEdge(fromCityId: 'palangkaraya', toCityId: 'kapuas', distance: 110, price: 78000, duration: 170),
    RouteEdge(fromCityId: 'kapuas', toCityId: 'barito_selatan', distance: 80, price: 60000, duration: 125),
    RouteEdge(fromCityId: 'barito_selatan', toCityId: 'barito_timur', distance: 70, price: 55000, duration: 110),
    RouteEdge(fromCityId: 'barito_timur', toCityId: 'barito_utara', distance: 80, price: 60000, duration: 125),
    RouteEdge(fromCityId: 'barito_utara', toCityId: 'murung_raya', distance: 100, price: 70000, duration: 160),
    RouteEdge(fromCityId: 'katingan', toCityId: 'seruyan', distance: 90, price: 65000, duration: 140),
    RouteEdge(fromCityId: 'seruyan', toCityId: 'kotim', distance: 80, price: 60000, duration: 125),
    RouteEdge(fromCityId: 'kotim', toCityId: 'kobar', distance: 110, price: 78000, duration: 170),
    RouteEdge(fromCityId: 'kobar', toCityId: 'lamandau', distance: 70, price: 55000, duration: 110),
    RouteEdge(fromCityId: 'kobar', toCityId: 'sukamara', distance: 55, price: 42000, duration: 85),

    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    //  KALIMANTAN SELATAN
    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    RouteEdge(fromCityId: 'banjarmasin', toCityId: 'banjarbaru', distance: 35, price: 28000, duration: 50),
    RouteEdge(fromCityId: 'banjarmasin', toCityId: 'barito_kuala', distance: 30, price: 25000, duration: 45),
    RouteEdge(fromCityId: 'banjarbaru', toCityId: 'banjar_kab', distance: 35, price: 28000, duration: 50),
    RouteEdge(fromCityId: 'banjarbaru', toCityId: 'tanah_laut', distance: 40, price: 32000, duration: 60),
    RouteEdge(fromCityId: 'banjar_kab', toCityId: 'tapin', distance: 40, price: 32000, duration: 60),
    RouteEdge(fromCityId: 'tapin', toCityId: 'hss', distance: 30, price: 25000, duration: 45),
    RouteEdge(fromCityId: 'hss', toCityId: 'hst', distance: 25, price: 22000, duration: 38),
    RouteEdge(fromCityId: 'hst', toCityId: 'hsu', distance: 20, price: 18000, duration: 30),
    RouteEdge(fromCityId: 'hsu', toCityId: 'balangan', distance: 25, price: 22000, duration: 38),
    RouteEdge(fromCityId: 'balangan', toCityId: 'tabalong', distance: 30, price: 25000, duration: 45),
    RouteEdge(fromCityId: 'tanah_laut', toCityId: 'tanah_bumbu', distance: 80, price: 60000, duration: 120),
    RouteEdge(fromCityId: 'tanah_bumbu', toCityId: 'kotabaru', distance: 60, price: 50000, duration: 100),
    // Kalsel â†” Kalteng
    RouteEdge(fromCityId: 'banjarmasin', toCityId: 'palangkaraya', distance: 200, price: 135000, duration: 300),
    RouteEdge(fromCityId: 'barito_kuala', toCityId: 'kapuas', distance: 90, price: 65000, duration: 140),
    RouteEdge(fromCityId: 'tabalong', toCityId: 'barito_utara', distance: 80, price: 60000, duration: 125),

    //  KALIMANTAN TIMUR
    RouteEdge(fromCityId: 'samarinda', toCityId: 'kutai_kartanegara', distance: 15, price: 15000, duration: 25),
    RouteEdge(fromCityId: 'samarinda', toCityId: 'balikpapan', distance: 115, price: 80000, duration: 170),
    RouteEdge(fromCityId: 'samarinda', toCityId: 'bontang', distance: 110, price: 78000, duration: 165),
    RouteEdge(fromCityId: 'bontang', toCityId: 'kutai_timur', distance: 45, price: 35000, duration: 70),
    RouteEdge(fromCityId: 'kutai_kartanegara', toCityId: 'kutai_barat', distance: 160, price: 110000, duration: 250),
    RouteEdge(fromCityId: 'kutai_timur', toCityId: 'berau', distance: 250, price: 165000, duration: 380),
    RouteEdge(fromCityId: 'balikpapan', toCityId: 'penajam', distance: 25, price: 25000, duration: 45),
    RouteEdge(fromCityId: 'penajam', toCityId: 'paser', distance: 90, price: 65000, duration: 140),
    RouteEdge(fromCityId: 'kutai_barat', toCityId: 'mahakam_ulu', distance: 150, price: 100000, duration: 240),
    // Kaltim â†” Kalsel
    RouteEdge(fromCityId: 'paser', toCityId: 'tanah_bumbu', distance: 130, price: 90000, duration: 200),
    RouteEdge(fromCityId: 'balikpapan', toCityId: 'banjarmasin', distance: 350, price: 230000, duration: 520),

    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    //  KALIMANTAN UTARA
    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    RouteEdge(fromCityId: 'tarakan', toCityId: 'bulungan', distance: 50, price: 45000, duration: 90),
    RouteEdge(fromCityId: 'bulungan', toCityId: 'malinau', distance: 130, price: 90000, duration: 210),
    RouteEdge(fromCityId: 'bulungan', toCityId: 'tana_tidung', distance: 80, price: 60000, duration: 130),
    RouteEdge(fromCityId: 'tana_tidung', toCityId: 'nunukan', distance: 110, price: 78000, duration: 175),
    RouteEdge(fromCityId: 'berau', toCityId: 'bulungan', distance: 200, price: 135000, duration: 310),

    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    //  SULAWESI UTARA
    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    RouteEdge(fromCityId: 'manado', toCityId: 'minahasa', distance: 20, price: 18000, duration: 30),
    RouteEdge(fromCityId: 'manado', toCityId: 'minahasa_utara', distance: 25, price: 22000, duration: 38),
    RouteEdge(fromCityId: 'manado', toCityId: 'bitung', distance: 35, price: 28000, duration: 50),
    RouteEdge(fromCityId: 'manado', toCityId: 'tomohon', distance: 22, price: 20000, duration: 35),
    RouteEdge(fromCityId: 'minahasa', toCityId: 'minahasa_sel', distance: 30, price: 25000, duration: 45),
    RouteEdge(fromCityId: 'minahasa_sel', toCityId: 'minahasa_tenggara', distance: 25, price: 22000, duration: 40),
    RouteEdge(fromCityId: 'minahasa_sel', toCityId: 'bolmong_tim', distance: 55, price: 42000, duration: 80),
    RouteEdge(fromCityId: 'bolmong_tim', toCityId: 'bolmong', distance: 45, price: 35000, duration: 68),
    RouteEdge(fromCityId: 'bolmong', toCityId: 'kotamobagu', distance: 15, price: 15000, duration: 25),
    RouteEdge(fromCityId: 'bolmong', toCityId: 'bolmong_sel', distance: 30, price: 25000, duration: 48),
    RouteEdge(fromCityId: 'bolmong', toCityId: 'bolmong_utr', distance: 40, price: 32000, duration: 60),

    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    //  GORONTALO â€” Sulut â†’ Gorontalo â†’ Sulteng
    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    RouteEdge(fromCityId: 'bolmong_utr', toCityId: 'gorontalo_utr', distance: 80, price: 60000, duration: 125),
    RouteEdge(fromCityId: 'gorontalo', toCityId: 'gorontalo_kab', distance: 10, price: 12000, duration: 18),
    RouteEdge(fromCityId: 'gorontalo', toCityId: 'bone_bolango', distance: 20, price: 18000, duration: 30),
    RouteEdge(fromCityId: 'gorontalo_kab', toCityId: 'boalemo', distance: 60, price: 45000, duration: 90),
    RouteEdge(fromCityId: 'boalemo', toCityId: 'pohuwato', distance: 55, price: 42000, duration: 85),
    RouteEdge(fromCityId: 'gorontalo', toCityId: 'gorontalo_utr', distance: 35, price: 28000, duration: 50),

    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    //  SULAWESI TENGAH
    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    RouteEdge(fromCityId: 'pohuwato', toCityId: 'buol', distance: 100, price: 70000, duration: 160),
    RouteEdge(fromCityId: 'buol', toCityId: 'toli_toli', distance: 75, price: 55000, duration: 120),
    RouteEdge(fromCityId: 'toli_toli', toCityId: 'parigi_moutong', distance: 150, price: 100000, duration: 240),
    RouteEdge(fromCityId: 'parigi_moutong', toCityId: 'palu', distance: 80, price: 60000, duration: 120),
    RouteEdge(fromCityId: 'palu', toCityId: 'donggala', distance: 30, price: 25000, duration: 45),
    RouteEdge(fromCityId: 'palu', toCityId: 'sigi', distance: 25, price: 22000, duration: 38),
    RouteEdge(fromCityId: 'parigi_moutong', toCityId: 'poso', distance: 100, price: 70000, duration: 155),
    RouteEdge(fromCityId: 'poso', toCityId: 'tojo_una_una', distance: 80, price: 60000, duration: 125),
    RouteEdge(fromCityId: 'poso', toCityId: 'morowali_utara', distance: 110, price: 78000, duration: 175),
    RouteEdge(fromCityId: 'morowali_utara', toCityId: 'morowali', distance: 65, price: 50000, duration: 100),
    RouteEdge(fromCityId: 'tojo_una_una', toCityId: 'banggai', distance: 120, price: 85000, duration: 190),
    RouteEdge(fromCityId: 'banggai', toCityId: 'banggai_kep', distance: 60, price: 55000, duration: 120),
    RouteEdge(fromCityId: 'banggai_kep', toCityId: 'banggai_laut', distance: 30, price: 30000, duration: 60),

    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    //  SULAWESI BARAT
    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    RouteEdge(fromCityId: 'mamuju', toCityId: 'mamuju_tengah', distance: 65, price: 50000, duration: 100),
    RouteEdge(fromCityId: 'mamuju_tengah', toCityId: 'pasangkayu', distance: 55, price: 42000, duration: 85),
    RouteEdge(fromCityId: 'mamuju', toCityId: 'majene', distance: 80, price: 60000, duration: 125),
    RouteEdge(fromCityId: 'majene', toCityId: 'polewali_mandar', distance: 45, price: 35000, duration: 70),
    RouteEdge(fromCityId: 'polewali_mandar', toCityId: 'mamasa', distance: 90, price: 65000, duration: 145),

    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    //  SULAWESI SELATAN
    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    RouteEdge(fromCityId: 'makassar', toCityId: 'gowa', distance: 12, price: 14000, duration: 22),
    RouteEdge(fromCityId: 'makassar', toCityId: 'maros', distance: 30, price: 25000, duration: 42),
    RouteEdge(fromCityId: 'gowa', toCityId: 'takalar', distance: 25, price: 22000, duration: 38),
    RouteEdge(fromCityId: 'takalar', toCityId: 'jeneponto', distance: 35, price: 28000, duration: 55),
    RouteEdge(fromCityId: 'jeneponto', toCityId: 'bantaeng', distance: 40, price: 32000, duration: 60),
    RouteEdge(fromCityId: 'bantaeng', toCityId: 'bulukumba', distance: 35, price: 28000, duration: 50),
    RouteEdge(fromCityId: 'bulukumba', toCityId: 'sinjai', distance: 30, price: 25000, duration: 45),
    RouteEdge(fromCityId: 'sinjai', toCityId: 'bone', distance: 55, price: 42000, duration: 80),
    RouteEdge(fromCityId: 'maros', toCityId: 'pangkep', distance: 20, price: 18000, duration: 30),
    RouteEdge(fromCityId: 'pangkep', toCityId: 'barru', distance: 55, price: 42000, duration: 80),
    RouteEdge(fromCityId: 'barru', toCityId: 'parepare', distance: 40, price: 32000, duration: 58),
    RouteEdge(fromCityId: 'parepare', toCityId: 'pinrang', distance: 30, price: 25000, duration: 45),
    RouteEdge(fromCityId: 'parepare', toCityId: 'sidrap', distance: 35, price: 28000, duration: 50),
    RouteEdge(fromCityId: 'sidrap', toCityId: 'soppeng', distance: 40, price: 32000, duration: 60),
    RouteEdge(fromCityId: 'soppeng', toCityId: 'wajo', distance: 35, price: 28000, duration: 50),
    RouteEdge(fromCityId: 'soppeng', toCityId: 'bone', distance: 45, price: 35000, duration: 65),
    RouteEdge(fromCityId: 'wajo', toCityId: 'bone', distance: 50, price: 38000, duration: 70),
    RouteEdge(fromCityId: 'pinrang', toCityId: 'enrekang', distance: 50, price: 38000, duration: 75),
    RouteEdge(fromCityId: 'enrekang', toCityId: 'tana_toraja', distance: 45, price: 35000, duration: 70),
    RouteEdge(fromCityId: 'tana_toraja', toCityId: 'toraja_utara', distance: 20, price: 18000, duration: 30),
    RouteEdge(fromCityId: 'toraja_utara', toCityId: 'luwu', distance: 50, price: 38000, duration: 75),
    RouteEdge(fromCityId: 'luwu', toCityId: 'palopo', distance: 20, price: 18000, duration: 30),
    RouteEdge(fromCityId: 'palopo', toCityId: 'luwu_utara', distance: 45, price: 35000, duration: 65),
    RouteEdge(fromCityId: 'luwu_utara', toCityId: 'luwu_timur', distance: 60, price: 45000, duration: 90),
    RouteEdge(fromCityId: 'bulukumba', toCityId: 'selayar', distance: 70, price: 60000, duration: 130),
    // Sulsel â†” Sulbar
    RouteEdge(fromCityId: 'pinrang', toCityId: 'polewali_mandar', distance: 85, price: 62000, duration: 130),
    // Sulsel â†” Sultra
    RouteEdge(fromCityId: 'luwu_timur', toCityId: 'kolaka_utr', distance: 120, price: 85000, duration: 190),
    // Sulsel â†” Sulteng
    RouteEdge(fromCityId: 'palopo', toCityId: 'poso', distance: 200, price: 135000, duration: 310),
    RouteEdge(fromCityId: 'mamuju', toCityId: 'palu', distance: 280, price: 185000, duration: 430),

    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    //  SULAWESI TENGGARA
    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    RouteEdge(fromCityId: 'kendari', toCityId: 'konawe', distance: 30, price: 25000, duration: 45),
    RouteEdge(fromCityId: 'kendari', toCityId: 'konawe_sel', distance: 40, price: 32000, duration: 60),
    RouteEdge(fromCityId: 'konawe', toCityId: 'konawe_utr', distance: 55, price: 42000, duration: 85),
    RouteEdge(fromCityId: 'konawe_sel', toCityId: 'bombana', distance: 80, price: 60000, duration: 125),
    RouteEdge(fromCityId: 'kolaka', toCityId: 'kolaka_tim', distance: 35, price: 28000, duration: 55),
    RouteEdge(fromCityId: 'kolaka', toCityId: 'kolaka_utr', distance: 65, price: 50000, duration: 100),
    RouteEdge(fromCityId: 'konawe_utr', toCityId: 'morowali', distance: 120, price: 85000, duration: 190),
    RouteEdge(fromCityId: 'kendari', toCityId: 'kolaka', distance: 150, price: 100000, duration: 230),
    RouteEdge(fromCityId: 'baubau', toCityId: 'buton', distance: 15, price: 15000, duration: 25),
    RouteEdge(fromCityId: 'buton', toCityId: 'buton_sel', distance: 30, price: 25000, duration: 48),
    RouteEdge(fromCityId: 'buton', toCityId: 'buton_teng', distance: 20, price: 18000, duration: 35),
    RouteEdge(fromCityId: 'buton_teng', toCityId: 'buton_utr', distance: 25, price: 22000, duration: 40),
    RouteEdge(fromCityId: 'buton_utr', toCityId: 'muna', distance: 40, price: 35000, duration: 70),
    RouteEdge(fromCityId: 'muna', toCityId: 'muna_barat', distance: 25, price: 22000, duration: 40),
    RouteEdge(fromCityId: 'kendari', toCityId: 'konawe_kep', distance: 60, price: 55000, duration: 120),
    RouteEdge(fromCityId: 'baubau', toCityId: 'wakatobi', distance: 80, price: 70000, duration: 150),

    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    //  MALUKU
    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    RouteEdge(fromCityId: 'ambon', toCityId: 'maluku_tengah', distance: 35, price: 30000, duration: 55),
    RouteEdge(fromCityId: 'ambon', toCityId: 'sbb', distance: 45, price: 40000, duration: 80),
    RouteEdge(fromCityId: 'sbb', toCityId: 'sbt', distance: 130, price: 95000, duration: 220),
    RouteEdge(fromCityId: 'ambon', toCityId: 'buru', distance: 80, price: 70000, duration: 150),
    RouteEdge(fromCityId: 'buru', toCityId: 'buru_selatan', distance: 40, price: 35000, duration: 65),
    RouteEdge(fromCityId: 'tual', toCityId: 'maluku_tenggara', distance: 10, price: 12000, duration: 20),
    RouteEdge(fromCityId: 'maluku_tenggara', toCityId: 'kep_aru', distance: 100, price: 85000, duration: 180),
    RouteEdge(fromCityId: 'maluku_tenggara', toCityId: 'mtb', distance: 150, price: 110000, duration: 260),
    RouteEdge(fromCityId: 'mtb', toCityId: 'kep_tanimbar', distance: 40, price: 35000, duration: 70),

    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    //  MALUKU UTARA
    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    RouteEdge(fromCityId: 'ternate', toCityId: 'tidore_kep', distance: 12, price: 15000, duration: 25),
    RouteEdge(fromCityId: 'ternate', toCityId: 'halbar', distance: 30, price: 30000, duration: 55),
    RouteEdge(fromCityId: 'halbar', toCityId: 'halteng', distance: 55, price: 45000, duration: 90),
    RouteEdge(fromCityId: 'halteng', toCityId: 'haltim', distance: 70, price: 55000, duration: 115),
    RouteEdge(fromCityId: 'halbar', toCityId: 'halut', distance: 90, price: 65000, duration: 150),
    RouteEdge(fromCityId: 'halut', toCityId: 'pulau_morotai', distance: 60, price: 55000, duration: 110),
    RouteEdge(fromCityId: 'halteng', toCityId: 'halsel', distance: 80, price: 60000, duration: 130),
    RouteEdge(fromCityId: 'halsel', toCityId: 'kep_sula', distance: 120, price: 90000, duration: 210),
    RouteEdge(fromCityId: 'kep_sula', toCityId: 'pulau_taliabu', distance: 50, price: 45000, duration: 90),

    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    //  PAPUA
    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    RouteEdge(fromCityId: 'jayapura', toCityId: 'jayapura_kab', distance: 30, price: 28000, duration: 50),
    RouteEdge(fromCityId: 'jayapura_kab', toCityId: 'keerom', distance: 55, price: 45000, duration: 90),
    RouteEdge(fromCityId: 'jayapura_kab', toCityId: 'sarmi', distance: 200, price: 140000, duration: 330),
    RouteEdge(fromCityId: 'sarmi', toCityId: 'mamberamo_raya', distance: 100, price: 80000, duration: 180),
    RouteEdge(fromCityId: 'biak_numfor', toCityId: 'supiori', distance: 40, price: 40000, duration: 75),
    RouteEdge(fromCityId: 'biak_numfor', toCityId: 'kep_yapen', distance: 60, price: 55000, duration: 110),
    RouteEdge(fromCityId: 'kep_yapen', toCityId: 'waropen', distance: 90, price: 70000, duration: 155),

    // Papua Pegunungan
    RouteEdge(fromCityId: 'jayawijaya', toCityId: 'lanny_jaya', distance: 50, price: 45000, duration: 90),
    RouteEdge(fromCityId: 'jayawijaya', toCityId: 'yahukimo', distance: 70, price: 60000, duration: 130),
    RouteEdge(fromCityId: 'lanny_jaya', toCityId: 'tolikara', distance: 40, price: 38000, duration: 75),
    RouteEdge(fromCityId: 'tolikara', toCityId: 'mamberamo_teng', distance: 45, price: 42000, duration: 85),
    RouteEdge(fromCityId: 'mamberamo_teng', toCityId: 'yalimo', distance: 35, price: 32000, duration: 65),
    RouteEdge(fromCityId: 'lanny_jaya', toCityId: 'nduga', distance: 60, price: 50000, duration: 110),
    RouteEdge(fromCityId: 'yahukimo', toCityId: 'pegunungan_bintang', distance: 80, price: 65000, duration: 145),

    // Papua Tengah
    RouteEdge(fromCityId: 'mimika', toCityId: 'paniai', distance: 100, price: 80000, duration: 180),
    RouteEdge(fromCityId: 'nabire', toCityId: 'paniai', distance: 80, price: 65000, duration: 140),
    RouteEdge(fromCityId: 'nabire', toCityId: 'dogiyai', distance: 70, price: 58000, duration: 125),
    RouteEdge(fromCityId: 'paniai', toCityId: 'deiyai', distance: 30, price: 28000, duration: 55),
    RouteEdge(fromCityId: 'paniai', toCityId: 'intan_jaya', distance: 60, price: 50000, duration: 110),
    RouteEdge(fromCityId: 'intan_jaya', toCityId: 'puncak', distance: 45, price: 42000, duration: 85),
    RouteEdge(fromCityId: 'puncak', toCityId: 'puncak_jaya', distance: 35, price: 32000, duration: 65),
    RouteEdge(fromCityId: 'puncak_jaya', toCityId: 'tolikara', distance: 50, price: 45000, duration: 90),

    // Papua Selatan
    RouteEdge(fromCityId: 'merauke', toCityId: 'boven_digoel', distance: 250, price: 170000, duration: 400),
    RouteEdge(fromCityId: 'merauke', toCityId: 'mappi', distance: 200, price: 140000, duration: 330),
    RouteEdge(fromCityId: 'mappi', toCityId: 'asmat', distance: 120, price: 90000, duration: 210),
    RouteEdge(fromCityId: 'asmat', toCityId: 'mimika', distance: 180, price: 130000, duration: 300),

    // Papua Barat
    RouteEdge(fromCityId: 'manokwari', toCityId: 'manokwari_sel', distance: 50, price: 42000, duration: 85),
    RouteEdge(fromCityId: 'manokwari', toCityId: 'peg_arfak', distance: 65, price: 55000, duration: 110),
    RouteEdge(fromCityId: 'manokwari', toCityId: 'teluk_wondama', distance: 110, price: 80000, duration: 185),
    RouteEdge(fromCityId: 'manokwari_sel', toCityId: 'teluk_bintuni', distance: 80, price: 65000, duration: 135),
    RouteEdge(fromCityId: 'teluk_bintuni', toCityId: 'fakfak', distance: 120, price: 90000, duration: 200),
    RouteEdge(fromCityId: 'fakfak', toCityId: 'kaimana', distance: 100, price: 75000, duration: 170),

    // Papua Barat Daya
    RouteEdge(fromCityId: 'sorong', toCityId: 'sorong_kab', distance: 10, price: 12000, duration: 20),
    RouteEdge(fromCityId: 'sorong_kab', toCityId: 'sorong_selatan', distance: 120, price: 85000, duration: 200),
    RouteEdge(fromCityId: 'sorong_kab', toCityId: 'tambrauw', distance: 130, price: 95000, duration: 220),
    RouteEdge(fromCityId: 'sorong_selatan', toCityId: 'maybrat', distance: 80, price: 65000, duration: 135),
    RouteEdge(fromCityId: 'sorong_kab', toCityId: 'raja_ampat', distance: 60, price: 55000, duration: 110),
    // Papua Barat Daya â†” Papua Barat
    RouteEdge(fromCityId: 'sorong', toCityId: 'manokwari', distance: 270, price: 180000, duration: 430),

    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    //  PENYEBERANGAN ANTARâ€‘PULAU (ferry / cross-strait)
    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    // Jawa â†” Sumatera (Merakâ€“Bakauheni)
    RouteEdge(fromCityId: 'cilegon', toCityId: 'lampung_selatan', distance: 30, price: 50000, duration: 120),
    // Jawa â†” Bali (Ketapangâ€“Gilimanuk)
    RouteEdge(fromCityId: 'banyuwangi', toCityId: 'jembrana', distance: 10, price: 25000, duration: 45),
    // Bali â†” NTB (Padangbaiâ€“Lembar)
    RouteEdge(fromCityId: 'karangasem', toCityId: 'lombok_barat', distance: 40, price: 55000, duration: 120),
    // NTB â†” NTT (Sapeâ€“Labuan Bajo via ferry)
    RouteEdge(fromCityId: 'bima', toCityId: 'manggarai_barat', distance: 60, price: 80000, duration: 240),
    // Sumba â†” Flores ferry
    RouteEdge(fromCityId: 'sumba_barat', toCityId: 'ende', distance: 150, price: 120000, duration: 360),
    // Timor â†” Flores ferry
    RouteEdge(fromCityId: 'kupang', toCityId: 'ende', distance: 250, price: 180000, duration: 480),
    // Sumatera â†” Kep. Riau
    RouteEdge(fromCityId: 'dumai', toCityId: 'batam', distance: 150, price: 120000, duration: 300),
    // Sumatera â†” Bangka
    RouteEdge(fromCityId: 'palembang', toCityId: 'pangkalpinang', distance: 180, price: 130000, duration: 300),
    // Sulsel â†” Sultra ferry (Makassar-Kendari / Bajoe-Kolaka)
    RouteEdge(fromCityId: 'bone', toCityId: 'kolaka', distance: 120, price: 100000, duration: 300),
    // Kalimantan â†” Sulawesi (Balikpapan-Makassar, long-distance ferry)
    RouteEdge(fromCityId: 'balikpapan', toCityId: 'makassar', distance: 500, price: 350000, duration: 900),
    // Maluku â†” Sulawesi
    RouteEdge(fromCityId: 'ambon', toCityId: 'baubau', distance: 400, price: 280000, duration: 720),
    // Papua â†” Maluku
    RouteEdge(fromCityId: 'sorong', toCityId: 'ternate', distance: 350, price: 250000, duration: 640),
    // Nias link
    RouteEdge(fromCityId: 'sibolga', toCityId: 'gunungsitoli', distance: 100, price: 80000, duration: 240),
    RouteEdge(fromCityId: 'gunungsitoli', toCityId: 'nias', distance: 15, price: 15000, duration: 25),
    RouteEdge(fromCityId: 'nias', toCityId: 'nias_utara', distance: 35, price: 28000, duration: 55),
    RouteEdge(fromCityId: 'nias', toCityId: 'nias_barat', distance: 30, price: 25000, duration: 50),
    RouteEdge(fromCityId: 'nias', toCityId: 'nias_selatan', distance: 70, price: 55000, duration: 120),
    // Simeulue link
    RouteEdge(fromCityId: 'aceh_barat', toCityId: 'simeulue', distance: 140, price: 110000, duration: 360),
    // Rote Ndao / Sabu Raijua link
    RouteEdge(fromCityId: 'kupang', toCityId: 'rote_ndao', distance: 50, price: 50000, duration: 120),
    RouteEdge(fromCityId: 'kupang', toCityId: 'sabu_raijua', distance: 200, price: 150000, duration: 360),
    // Sangihe / Talaud / Sitaro links
    RouteEdge(fromCityId: 'manado', toCityId: 'sitaro', distance: 120, price: 95000, duration: 240),
    RouteEdge(fromCityId: 'sitaro', toCityId: 'kep_sangihe', distance: 60, price: 55000, duration: 120),
    RouteEdge(fromCityId: 'kep_sangihe', toCityId: 'kep_talaud', distance: 100, price: 80000, duration: 200),
    // Mentawai link
    RouteEdge(fromCityId: 'padang', toCityId: 'kep_mentawai', distance: 130, price: 100000, duration: 300),
    // Natuna / Anambas links
    RouteEdge(fromCityId: 'tanjungpinang', toCityId: 'natuna', distance: 350, price: 250000, duration: 600),
    RouteEdge(fromCityId: 'natuna', toCityId: 'kep_anambas', distance: 120, price: 90000, duration: 200),
    // Kep. Seribu link
    RouteEdge(fromCityId: 'jkt_utara', toCityId: 'kep_seribu', distance: 45, price: 55000, duration: 120),
    // Selayar link (also in Sulsel section, but via sea)
    // (already covered above)
  ];
}

import 'package:avatar_glow/avatar_glow.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// MODEL & DATA DUMMY
// ---------------------------------------------------------------------------
const List<String> kategoriList = ['Keluarga', 'Teman', 'Kerja'];

class Kontak {
  final String nama;
  final String telepon;
  final String email;
  final String kategori;
  final DateTime ditambahkan;

  Kontak({
    required this.nama,
    required this.telepon,
    required this.email,
    required this.kategori,
    required this.ditambahkan,
  });
}

// Dibuat sekali saja supaya data tidak berubah-ubah saat pindah tab.
final List<Kontak> daftarKontak = _buatKontakDummy(20);

List<Kontak> _buatKontakDummy(int jumlah) {
  final faker = Faker();
  return List.generate(jumlah, (i) {
    return Kontak(
      nama: faker.person.name(),
      telepon: faker.phoneNumber.us(),
      email: faker.internet.email(),
      kategori: kategoriList[i % kategoriList.length],
      ditambahkan: faker.date.dateTime(minYear: 2024, maxYear: 2026),
    );
  });
}

// ---------------------------------------------------------------------------
// MAIN
// ---------------------------------------------------------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Wajib dipanggil agar DateFormat bisa memakai locale Indonesia.
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daftar Kontak',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}

// ---------------------------------------------------------------------------
// SHELL + NAVIGASI (ConvexAppBar)
// ---------------------------------------------------------------------------
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final List<Widget> _pages = const [KontakPage(), CariPage(), ProfilPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: ConvexAppBar(
        style: TabStyle.reactCircle,
        backgroundColor: Theme.of(context).colorScheme.primary,
        items: const [
          TabItem(icon: Icons.contacts, title: 'Kontak'),
          TabItem(icon: Icons.search, title: 'Cari'),
          TabItem(icon: Icons.person, title: 'Profil'),
        ],
        initialActiveIndex: 0,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// WIDGET ITEM KONTAK (dipakai di halaman Kontak & Cari)
// ---------------------------------------------------------------------------
class KontakTile extends StatelessWidget {
  final Kontak kontak;
  const KontakTile({super.key, required this.kontak});

  @override
  Widget build(BuildContext context) {
    // Contoh hasil: "05 September 2026"
    final tanggal = DateFormat(
      'dd MMMM yyyy',
      'id_ID',
    ).format(kontak.ditambahkan);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(kontak.nama.isNotEmpty ? kontak.nama[0] : '?'),
        ),
        title: Text(
          kontak.nama,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(kontak.telepon),
            Text(kontak.email),
            const SizedBox(height: 4),
            Text(
              'Ditambahkan pada $tanggal',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HALAMAN 1: KONTAK (ListView.builder)
// ---------------------------------------------------------------------------
class KontakPage extends StatelessWidget {
  const KontakPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kontak')),
      body: ListView.builder(
        itemCount: daftarKontak.length,
        itemBuilder: (context, index) =>
            KontakTile(kontak: daftarKontak[index]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HALAMAN 2: CARI (DropdownSearch)
// ---------------------------------------------------------------------------
class CariPage extends StatefulWidget {
  const CariPage({super.key});

  @override
  State<CariPage> createState() => _CariPageState();
}

class _CariPageState extends State<CariPage> {
  String? _kategoriDipilih;

  @override
  Widget build(BuildContext context) {
    final hasil = _kategoriDipilih == null
        ? <Kontak>[]
        : daftarKontak.where((k) => k.kategori == _kategoriDipilih).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Cari')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownSearch<String>(
              items: kategoriList, // daftar offline
              selectedItem: _kategoriDipilih,
              popupProps: const PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: 'Cari kategori...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: 'Kategori Kontak',
                  hintText: 'Pilih kategori',
                  border: OutlineInputBorder(),
                ),
              ),
              onChanged: (value) => setState(() => _kategoriDipilih = value),
            ),
          ),
          Expanded(
            child: _kategoriDipilih == null
                ? const Center(
                    child: Text('Pilih kategori untuk melihat kontak'),
                  )
                : ListView.builder(
                    itemCount: hasil.length,
                    itemBuilder: (context, i) => KontakTile(kontak: hasil[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HALAMAN 3: PROFIL (AvatarGlow)
// ---------------------------------------------------------------------------
class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AvatarGlow(
              glowColor: Colors.blueAccent,
              glowRadiusFactor: 0.8,
              glowCount: 3,
              duration: const Duration(milliseconds: 2000),
              repeat: true,
              animate: true,
              child: const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 60),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Zaqi', // <- ganti dengan nama & NIM kamu
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('Sistem Informasi'),
          ],
        ),
      ),
    );
  }
}

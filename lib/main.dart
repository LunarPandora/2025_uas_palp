import 'package:flutter/material.dart';
import 'package:flutter_application_1/history_pesanan_screen.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(FlatNavApp());
}

class NyuciHelmApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nyuci Helm Express',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: HelmServiceList(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HelmServiceList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final helmShops = FirebaseFirestore.instance.collection('services');

    return Scaffold(
        appBar: AppBar(title: Text('Layanan Cuci Helm')),
        body: StreamBuilder<QuerySnapshot>(
          stream: helmShops.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('Tidak ada services.'));
            }

            return ListView(
                children: snapshot.data!.docs.map((DocumentSnapshot doc) {
              final shop = doc.data()! as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  title: Text(shop['nama']),
                  subtitle: Text(
                      'Jenis: ${shop['keterangan']} \nRp ${shop['harga']}'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => PemesananForm(
                            shopRef: doc.reference, shopData: doc),
                      );
                    },
                    child: Text('Pesan'),
                  ),
                ),
              );
            }).toList());
          },
        ));
  }
}

class PemesananForm extends StatefulWidget {
  final DocumentReference shopRef;
  final DocumentSnapshot shopData;

  PemesananForm({required this.shopRef, required this.shopData});

  @override
  _PemesananFormState createState() => _PemesananFormState();
}

class _PemesananFormState extends State<PemesananForm> {
  final _formKey = GlobalKey<FormState>();
  int jumlahHelm = 1;
  DateTime? tanggalAmbil;
  String nama = '';
  String kontak = '';
  String tipePembayaran = 'Tunai';

  Future<void> _submitPemesanan() async {
    print('Memasukkan pemesanan...');

    if (_formKey.currentState!.validate() && tanggalAmbil != null) {
      _formKey.currentState!.save();

      await FirebaseFirestore.instance.collection('pemesanan').add({
        'jlh_helm': jumlahHelm,
        'tgl_ambil': tanggalAmbil,
        'nama': nama,
        'no_hp': kontak,
        'tipe_pembayaran': tipePembayaran,
        'services_ref': widget.shopRef
      });

      Navigator.pop(context);
    }
    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //   content: Text(
    //       'Pesanan ke ${widget.shopName} disimpan!\nJumlah Helm: $jumlahHelm\nTgl Ambil: ${tanggalAmbil!.toLocal()}'
    //           .split(' ')[0]),
    // ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Pesan - ${widget.shopData['nama']}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Jumlah Helm'),
                keyboardType: TextInputType.number,
                onSaved: (value) =>
                    jumlahHelm = int.tryParse(value ?? '1') ?? 1,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Wajib diisi' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 30)),
                  );
                  if (picked != null) {
                    setState(() => tanggalAmbil = picked);
                  }
                },
                child: Text(
                  tanggalAmbil == null
                      ? 'Pilih Tanggal Ambil'
                      : 'Ambil: ${DateFormat('yyyy-MM-dd').format(tanggalAmbil!)}',
                ),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Nama'),
                onSaved: (value) => nama = value ?? '',
                validator: (value) =>
                    value == null || value.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'No Hp'),
                onSaved: (value) => kontak = value ?? '',
                validator: (value) =>
                    value == null || value.isEmpty ? 'Wajib diisi' : null,
              ),
              DropdownButtonFormField<String>(
                value: tipePembayaran,
                items: ['Tunai', 'Transfer', 'QRIS']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => tipePembayaran = val!),
                decoration: InputDecoration(labelText: 'Tipe Pembayaran'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text('Batal')),
        ElevatedButton(
            onPressed: () => _submitPemesanan(), child: Text('Kirim')),
      ],
    );
  }
}

class FlatNavApp extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Main Menu",
      home: MainScreen()
    );
  }
}

class MainScreen extends StatefulWidget{
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>{
  int _currentIndex = 0;

  final List<Widget> _screens = [
    NyuciHelmApp(),
    FetchHistoryPesananScreen(),
    // ResponsiveExample()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.build_circle_outlined),
            label: "Services"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: "History"
          ),
        ],
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index){
          setState(() {
            _currentIndex = index;
          });
        }
      ),
    );
  }
}

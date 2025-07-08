import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FetchHistoryPesananScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pesanan = FirebaseFirestore.instance.collection(
      'pemesanan',
    );

    return Scaffold(
      appBar: AppBar(title: Text("History Pemesanan")),
      body: StreamBuilder<QuerySnapshot>(
        stream: pesanan.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Belum ada catatan."));
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              final data = document.data()! as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                    title: Text(data['nama'] ?? '-'),
                    subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Jlh Helm: " + data['jlh_helm'].toString() ?? '-'),
                          // Text("Tgl Ambil: " + data['tgl_ambil'] ?? '-'),
                          Text("Nama: " + data['nama'] ?? '-'),
                          Text("No HP:" + data['no_hp'] ?? '-'),
                          Text("Tipe Pembayaran:" + data['tipe_pembayaran'] ?? '-'),
                        ]),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      data['synced'] == true
                          ? Icon(Icons.cloud_done, color: Colors.green)
                          : Icon(Icons.cloud_off, color: Colors.grey),
                      IconButton(
                          hoverColor: Colors.transparent,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => EditPemesananForm(
                                  shopRef: document.reference,
                                  shopData: document),
                            );
                          },
                          icon:
                              Icon(Icons.edit, color: Colors.yellow.shade800)),
                      IconButton(
                          hoverColor: Colors.transparent,
                          onPressed: () async {
                            bool confirm = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Hapus catatan'),
                                content: Text(
                                    'Apakah anda yakin ingin menghapus pesanan ini?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text('Hapus'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm) {
                              await FirebaseFirestore.instance
                                  .collection('pemesanan')
                                  .doc(document.id)
                                  .delete();
                            }
                          },
                          icon: Icon(Icons.delete, color: Colors.red.shade500))
                    ])),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class EditPemesananForm extends StatefulWidget {
  final DocumentReference shopRef;
  final DocumentSnapshot shopData;

  EditPemesananForm({required this.shopRef, required this.shopData});

  @override
  _EditPemesananFormState createState() => _EditPemesananFormState();
}

class _EditPemesananFormState extends State<EditPemesananForm> {
  final _formKey = GlobalKey<FormState>();
  int jumlahHelm = 1;
  DateTime? tanggalAmbil;
  String nama = '';
  String kontak = '';
  String tipePembayaran = 'Tunai';

  @override
  void initState() {
    super.initState();
    jumlahHelm = widget.shopData['jlh_helm'] ?? '';
    tanggalAmbil = widget.shopData['tgl_ambil'] ?? '';
    nama = widget.shopData['nama'] ?? '';
    kontak = widget.shopData['no_hp'] ?? '';
    tipePembayaran = widget.shopData['tipe_pembayaran'] ?? '';
  }

  Future<void> _updatePemesanan() async {
    print('Mengupdate pemesanan...');

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
            onPressed: () => _updatePemesanan(), child: Text('Update')),
      ],
    );
  }
}

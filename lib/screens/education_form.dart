import 'package:flutter/material.dart';
import 'package:myportofolio_mobile/utils/url_validator.dart';
import 'package:myportofolio_mobile/widgets/left_drawer.dart';

/// Halaman formulir untuk menambah satu riwayat pendidikan (Education).
///
/// Field dan aturannya mengikuti model `Education` dan `EducationForm` di
/// proyek Django `myportofolio`:
/// - `institution`: wajib, maksimal 255 karakter.
/// - `description`: opsional, maksimal 255 karakter.
/// - `started_at`: tanggal, wajib.
/// - `ended_at`: tanggal, opsional (kosong berarti masih berlangsung), dan
///   tidak boleh sebelum `started_at`.
/// - `certificate_url`: URL http/https, opsional, maksimal 200 karakter
///   (panjang bawaan `URLField` Django).
class EducationFormPage extends StatefulWidget {
  const EducationFormPage({super.key});

  @override
  State<EducationFormPage> createState() => _EducationFormPageState();
}

class _EducationFormPageState extends State<EducationFormPage> {
  final _formKey = GlobalKey<FormState>();

  static const int _maxTextLength = 255;
  static const int _maxUrlLength = 200;

  // Rentang tanggal yang bisa dipilih pada date picker.
  static final DateTime _firstDate = DateTime(1950);
  static final DateTime _lastDate = DateTime(DateTime.now().year + 10, 12, 31);

  String _institution = "";
  String _description = "";
  DateTime? _startDate;
  DateTime? _endDate;
  String _certificateUrl = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Add Education Form')),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      drawer: const LeftDrawer(),
      body: Form(
        key: _formKey,
        // SingleChildScrollView membuat semua field dan tombol Simpan tetap
        // bisa digulir ke layar, termasuk di ponsel sempit atau saat papan
        // ketik tampil (Scaffold mengecilkan body ketika papan ketik muncul).
        child: SingleChildScrollView(
          child: Center(
            // Di layar lebar (Chrome), lebar form dibatasi agar tetap
            // nyaman dibaca; di ponsel form tetap memakai lebar penuh.
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === Institusi ===
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      maxLength: _maxTextLength,
                      textInputAction: TextInputAction.next,
                      decoration: _decoration(
                        label: "Institusi",
                        hint: "Universitas Indonesia",
                      ),
                      onChanged: (String? value) {
                        setState(() {
                          _institution = value!;
                        });
                      },
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Institusi tidak boleh kosong!";
                        }
                        if (value.trim().length > _maxTextLength) {
                          return "Institusi maksimal $_maxTextLength karakter.";
                        }
                        return null;
                      },
                    ),
                  ),

                  // === Deskripsi ===
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      maxLength: _maxTextLength,
                      maxLines: 3,
                      decoration: _decoration(
                        label: "Deskripsi (opsional)",
                        hint: "S1 Sistem Informasi, Fakultas Ilmu Komputer",
                      ),
                      onChanged: (String? value) {
                        setState(() {
                          _description = value!;
                        });
                      },
                      validator: (String? value) {
                        if (value != null &&
                            value.trim().length > _maxTextLength) {
                          return "Deskripsi maksimal $_maxTextLength karakter.";
                        }
                        return null;
                      },
                    ),
                  ),

                  // === Tanggal Mulai & Tanggal Selesai ===
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _DateField(
                      label: "Tanggal Mulai",
                      value: _startDate,
                      onTap: () => _pickDate(isStart: true),
                      validator: (DateTime? value) {
                        if (value == null) {
                          return "Tanggal mulai wajib dipilih!";
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _DateField(
                      label: "Tanggal Selesai (opsional)",
                      helperText: "Kosongkan jika masih berlangsung.",
                      value: _endDate,
                      onTap: () => _pickDate(isStart: false),
                      onClear: () => setState(() => _endDate = null),
                      validator: (DateTime? value) {
                        if (value != null &&
                            _startDate != null &&
                            value.isBefore(_startDate!)) {
                          return "Tanggal selesai tidak boleh sebelum tanggal mulai.";
                        }
                        return null;
                      },
                    ),
                  ),

                  // === URL Sertifikat/Ijazah ===
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.done,
                      decoration: _decoration(
                        label: "URL Sertifikat/Ijazah (opsional)",
                        hint: "https://drive.google.com/...",
                      ),
                      onChanged: (String? value) {
                        setState(() {
                          _certificateUrl = value!;
                        });
                      },
                      validator: (String? value) {
                        final url = value?.trim() ?? "";
                        if (url.isEmpty) return null;
                        if (url.length > _maxUrlLength) {
                          return "URL maksimal $_maxUrlLength karakter.";
                        }
                        if (!isValidHttpUrl(url)) {
                          return "Masukkan URL lengkap yang diawali http:// atau https://.";
                        }
                        return null;
                      },
                    ),
                  ),

                  // === Tombol Simpan ===
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(
                            Colors.indigo,
                          ),
                        ),
                        onPressed: _save,
                        child: const Text(
                          "Simpan",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Dekorasi field yang sama dengan formulir proyek di Tutorial 09.
  InputDecoration _decoration({required String label, String? hint}) {
    return InputDecoration(
      hintText: hint,
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0)),
    );
  }

  /// Membuka date picker untuk tanggal mulai atau tanggal selesai.
  Future<void> _pickDate({required bool isStart}) async {
    // Tanggal selesai tidak bisa dipilih sebelum tanggal mulai.
    final first = isStart ? _firstDate : (_startDate ?? _firstDate);
    var initial =
        (isStart ? _startDate : _endDate ?? _startDate) ?? DateTime.now();
    // initialDate wajib berada di antara firstDate dan lastDate, misalnya
    // saat tanggal mulai diubah menjadi setelah tanggal selesai yang lama.
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(_lastDate)) initial = _lastDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: _lastDate,
      helpText: isStart ? "Pilih tanggal mulai" : "Pilih tanggal selesai",
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  /// Memvalidasi form, lalu menampilkan ringkasan isian dalam dialog.
  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final description = _description.trim();
    final url = _certificateUrl.trim();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edukasi berhasil ditambahkan!'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Institusi: ${_institution.trim()}'),
                Text('Deskripsi: ${description.isEmpty ? "-" : description}'),
                Text('Tanggal Mulai: ${formatTanggal(_startDate!)}'),
                Text(
                  'Tanggal Selesai: ${_endDate == null ? "Masih berlangsung" : formatTanggal(_endDate!)}',
                ),
                Text('URL Sertifikat: ${url.isEmpty ? "-" : url}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context);
                _formKey.currentState!.reset();
                // reset() mengosongkan field teks (dan memanggil onChanged
                // dengan string kosong), tetapi tanggal disimpan di state
                // halaman ini, jadi tanggal dikosongkan secara manual.
                setState(() {
                  _startDate = null;
                  _endDate = null;
                });
              },
            ),
          ],
        );
      },
    );
  }
}

const _namaBulan = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// Memformat tanggal menjadi bentuk Indonesia, misalnya `23 November 2026`.
String formatTanggal(DateTime date) {
  return '${date.day} ${_namaBulan[date.month - 1]} ${date.year}';
}

/// Field tanggal yang ikut divalidasi oleh [Form]. Nilainya dipilih lewat
/// date picker, bukan diketik, sehingga formatnya selalu benar.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.validator,
    this.helperText,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final FormFieldValidator<DateTime> validator;
  final String? helperText;

  /// Bila diisi, tombol hapus muncul saat field punya nilai.
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      // Key berubah ketika nilai berubah, sehingga FormField dibuat ulang
      // dengan initialValue terbaru dan validator membaca nilai yang benar.
      key: ValueKey(value),
      initialValue: value,
      validator: validator,
      builder: (field) {
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(5.0),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              helperText: helperText,
              errorText: field.errorText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
              suffixIcon: value != null && onClear != null
                  ? IconButton(
                      tooltip: 'Hapus $label',
                      icon: const Icon(Icons.clear),
                      onPressed: onClear,
                    )
                  : const Icon(Icons.calendar_today),
            ),
            isEmpty: value == null,
            child: Text(value == null ? '' : formatTanggal(value!)),
          ),
        );
      },
    );
  }
}

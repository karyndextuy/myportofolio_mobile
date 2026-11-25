import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:myportofolio_mobile/models/project.dart';
import 'package:myportofolio_mobile/services/api_client.dart';
import 'package:myportofolio_mobile/services/auth_state.dart';
import 'package:myportofolio_mobile/utils/url_validator.dart';
import 'package:myportofolio_mobile/widgets/auth_guard.dart';
import 'package:myportofolio_mobile/widgets/left_drawer.dart';
import 'package:provider/provider.dart';

/// Formulir tambah proyek yang mengirim data ke `POST /api/v1/projects/`.
///
/// Field dan batasnya mengikuti `ProjectSerializer` dan model `Project` di
/// Django: `title` dan `tech_stack` maksimal 255 karakter, `project_url` dan
/// `project_image_url` berupa URL maksimal 500 karakter.
class ProjectFormPage extends StatefulWidget {
  const ProjectFormPage({super.key});

  @override
  State<ProjectFormPage> createState() => _ProjectFormPageState();
}

class _ProjectFormPageState extends State<ProjectFormPage> {
  final _formKey = GlobalKey<FormState>();

  static const int _maxTextLength = 255;
  static const int _maxUrlLength = 500;

  String _title = "";
  String _description = "";
  String _techStack = "";
  String _projectUrl = "";
  String _projectImageUrl = "";
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Add Project Form')),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      drawer: const LeftDrawer(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === Title ===
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  maxLength: _maxTextLength,
                  decoration: _decoration(
                    label: "Title",
                    hint: "MyPortfolio Mobile",
                  ),
                  onChanged: (String? value) {
                    setState(() {
                      _title = value!;
                    });
                  },
                  validator: (String? value) =>
                      _required(value, "Title tidak boleh kosong!"),
                ),
              ),

              // === Description ===
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  maxLines: 5,
                  decoration: _decoration(
                    label: "Description",
                    hint: "Deskripsi singkat proyek",
                  ),
                  onChanged: (String? value) {
                    setState(() {
                      _description = value!;
                    });
                  },
                  validator: (String? value) =>
                      _required(value, "Description tidak boleh kosong!"),
                ),
              ),

              // === Tech Stack ===
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  maxLength: _maxTextLength,
                  decoration: _decoration(
                    label: "Tech Stack",
                    hint: "Contoh: Flutter, Django, Figma",
                  ),
                  onChanged: (String? value) {
                    setState(() {
                      _techStack = value!;
                    });
                  },
                  validator: (String? value) =>
                      _required(value, "Tech Stack tidak boleh kosong!"),
                ),
              ),

              // === Project URL ===
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  keyboardType: TextInputType.url,
                  decoration: _decoration(
                    label: "Project URL",
                    hint: "https://github.com/...",
                  ),
                  onChanged: (String? value) {
                    setState(() {
                      _projectUrl = value!;
                    });
                  },
                  validator: (String? value) =>
                      _url(value, required: true, label: "Project URL"),
                ),
              ),

              // === Project Image URL (Optional) ===
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  keyboardType: TextInputType.url,
                  decoration: _decoration(
                    label: "Project Image URL (Optional)",
                    hint: "https://.../screenshot.png",
                  ),
                  onChanged: (String? value) {
                    setState(() {
                      _projectImageUrl = value!;
                    });
                  },
                  validator: (String? value) =>
                      _url(value, required: false, label: "Project Image URL"),
                ),
              ),

              // === Tombol Simpan ===
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.indigo),
                    ),
                    // Dinonaktifkan selama request berjalan agar proyek
                    // tidak terkirim dua kali.
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Save",
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration({required String label, String? hint}) {
    return InputDecoration(
      hintText: hint,
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0)),
    );
  }

  /// Menolak isian kosong atau yang hanya berisi spasi.
  String? _required(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  /// Memvalidasi format URL (http/https) dan panjang maksimalnya.
  String? _url(String? value, {required bool required, required String label}) {
    final url = value?.trim() ?? "";
    if (url.isEmpty) {
      return required ? "$label tidak boleh kosong!" : null;
    }
    if (url.length > _maxUrlLength) {
      return "$label maksimal $_maxUrlLength karakter.";
    }
    if (!isValidHttpUrl(url)) {
      return "Masukkan URL lengkap yang diawali http:// atau https://.";
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Form hanya bisa dikirim oleh pengguna yang sudah login.
    final loggedIn = await ensureLoggedIn(context);
    if (!loggedIn || !mounted) return;

    final authState = context.read<AuthState>();
    final apiClient = context.read<ApiClient>();
    final newProject = Project(
      title: _title.trim(),
      description: _description.trim(),
      techStack: _techStack.trim(),
      projectUrl: _projectUrl.trim(),
      projectImageUrl: _projectImageUrl.trim(),
    );

    setState(() {
      _isSubmitting = true;
    });

    Project? created;
    var sessionExpired = false;
    try {
      created = await apiClient.createProject(
        newProject,
        token: authState.token!,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // Token sudah tidak berlaku (mis. dicabut lewat logout di perangkat
        // lain): logout lokal, lalu minta login ulang di bawah.
        await authState.logout();
        sessionExpired = true;
      } else if (mounted) {
        _showSnackBar(_errorMessage(e));
      }
    } on Exception {
      if (mounted) {
        _showSnackBar('Tidak dapat terhubung ke server. Coba lagi.');
      }
    } finally {
      // Request sudah selesai, jadi spinner dihentikan sebelum dialog atau
      // halaman login ditampilkan.
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }

    if (!mounted) return;
    if (created != null) {
      await _showCreatedDialog(created);
    } else if (sessionExpired) {
      _showSnackBar('Sesi login berakhir. Silakan login ulang.');
      final loggedInAgain = await ensureLoggedIn(context);
      if (!loggedInAgain || !mounted) return;
      // Isian form masih ada, jadi proyek langsung dikirim ulang dengan
      // token baru tanpa pengguna perlu menekan Save lagi.
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      await _submit();
    }
  }

  /// Pesan yang ramah pengguna untuk tiap status, tanpa menampilkan body
  /// mentah (yang bisa berupa halaman error HTML dari Django).
  String _errorMessage(ApiException e) {
    switch (e.statusCode) {
      case 400:
        final details = _validationMessages(e.message);
        return details.isEmpty
            ? 'Data proyek tidak valid (400).'
            : 'Data proyek tidak valid: $details';
      case 403:
        return 'Akun ini tidak boleh menambah proyek (403). '
            'Hanya pemilik portofolio yang bisa.';
      default:
        return 'Gagal menyimpan proyek (${e.statusCode}).';
    }
  }

  /// Mengambil pesan validasi dari body JSON DRF, mis.
  /// `{"project_url": ["Enter a valid URL."]}`.
  String _validationMessages(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return '';
      return decoded.values
          .expand((value) => value is List ? value : [value])
          .whereType<String>()
          .join(' ');
    } on FormatException {
      return '';
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showCreatedDialog(Project project) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Proyek berhasil ditambahkan!'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Title: ${project.title}'),
                Text('Description: ${project.description}'),
                Text('Tech Stack: ${project.techStack}'),
                Text('Project URL: ${project.projectUrl}'),
                Text(
                  'Project Image URL: ${project.projectImageUrl.isEmpty ? "-" : project.projectImageUrl}',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context);
                _formKey.currentState!.reset();
              },
            ),
          ],
        );
      },
    );
  }
}

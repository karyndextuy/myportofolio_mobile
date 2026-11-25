import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myportofolio_mobile/screens/login_screen.dart';
import 'package:myportofolio_mobile/screens/project_form.dart';

import 'helpers.dart';

Future<void> tapSave(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Save'));
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

Future<void> fillValidProject(WidgetTester tester) async {
  await tester.enterText(field('Title'), '  Karyn Mobile App  ');
  await tester.enterText(field('Description'), 'Aplikasi Flutter');
  await tester.enterText(field('Tech Stack'), 'Flutter, DRF');
  await tester.enterText(
    field('Project URL'),
    'https://github.com/karyndextuy/myportofolio_mobile',
  );
}

int postCount(FakeBackend backend) => backend.requests
    .where((r) => r.method == 'POST' && r.url.path == '/api/v1/projects/')
    .length;

void main() {
  group('Validasi form proyek', () {
    testWidgets('Field wajib yang kosong atau hanya spasi ditolak', (
      WidgetTester tester,
    ) async {
      final backend = FakeBackend();
      await pumpPage(tester, const ProjectFormPage(), backend: backend);

      await tester.enterText(field('Title'), '   ');
      await tapSave(tester);

      expect(find.text('Title tidak boleh kosong!'), findsOneWidget);
      expect(find.text('Description tidak boleh kosong!'), findsOneWidget);
      expect(find.text('Tech Stack tidak boleh kosong!'), findsOneWidget);
      expect(find.text('Project URL tidak boleh kosong!'), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      expect(postCount(backend), 0);
    });

    testWidgets('URL tanpa http(s) ditolak, Image URL boleh kosong', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, const ProjectFormPage(), token: ownerToken);

      await fillValidProject(tester);
      await tester.enterText(field('Project URL'), 'github.com/karyn');
      await tester.enterText(
        field('Project Image URL (Optional)'),
        'ftp://files.example.com/a.png',
      );
      await tapSave(tester);

      expect(
        find.text('Masukkan URL lengkap yang diawali http:// atau https://.'),
        findsNWidgets(2),
      );
    });
  });

  group('Simpan ke API', () {
    testWidgets('Belum login: Save membuka Login, lalu proyek terkirim', (
      WidgetTester tester,
    ) async {
      final backend = FakeBackend();
      final auth = await pumpPage(
        tester,
        const ProjectFormPage(),
        backend: backend,
      );

      await fillValidProject(tester);
      await tapSave(tester);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(postCount(backend), 0);

      await submitLogin(tester);

      expect(auth.token, ownerToken);
      expect(find.text('Proyek berhasil ditambahkan!'), findsOneWidget);
      expect(postCount(backend), 1);
    });

    testWidgets('201: dialog berisi data dari server, OK me-reset form', (
      WidgetTester tester,
    ) async {
      final backend = FakeBackend();
      await pumpPage(
        tester,
        const ProjectFormPage(),
        backend: backend,
        token: ownerToken,
      );

      await fillValidProject(tester);
      await tapSave(tester);

      final post = backend.requests.last;
      expect(post.headers['Authorization'], 'Token $ownerToken');
      expect(post.headers['Content-Type'], startsWith('application/json'));
      final body = jsonDecode(post.body) as Map<String, dynamic>;
      expect(body, {
        'title': 'Karyn Mobile App',
        'description': 'Aplikasi Flutter',
        'tech_stack': 'Flutter, DRF',
        'project_url': 'https://github.com/karyndextuy/myportofolio_mobile',
        'project_image_url': '',
      });

      expect(find.text('Proyek berhasil ditambahkan!'), findsOneWidget);
      expect(find.text('Title: Karyn Mobile App'), findsOneWidget);
      expect(find.text('Project Image URL: -'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Karyn Mobile App'), findsNothing);
    });

    testWidgets('401: token dicabut, aplikasi logout dan meminta login ulang', (
      WidgetTester tester,
    ) async {
      final backend = FakeBackend();
      // Token sudah dicabut di server (mis. logout dari perangkat lain).
      backend.validTokens.remove(ownerToken);
      final auth = await pumpPage(
        tester,
        const ProjectFormPage(),
        backend: backend,
        token: ownerToken,
      );

      await fillValidProject(tester);
      await tapSave(tester);

      expect(auth.isLoggedIn, isFalse);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(postCount(backend), 1);

      // Setelah login ulang, proyek langsung dikirim ulang dengan token baru.
      await submitLogin(tester);
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.text('Proyek berhasil ditambahkan!'), findsOneWidget);
      expect(postCount(backend), 2);
      expect(
        backend.requests.last.headers['Authorization'],
        'Token $ownerToken',
      );
    });

    testWidgets('403: akun bukan pemilik mendapat SnackBar', (
      WidgetTester tester,
    ) async {
      final backend = FakeBackend();
      final auth = await pumpPage(
        tester,
        const ProjectFormPage(),
        backend: backend,
        token: visitorToken,
      );

      await fillValidProject(tester);
      await tapSave(tester);

      expect(find.textContaining('(403)'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(auth.isLoggedIn, isTrue);
    });

    testWidgets('400: pesan validasi dari server ditampilkan di SnackBar', (
      WidgetTester tester,
    ) async {
      final backend = FakeBackend()
        ..projectValidationErrors = {
          'title': ['Title cannot be empty.'],
        };
      await pumpPage(
        tester,
        const ProjectFormPage(),
        backend: backend,
        token: ownerToken,
      );

      await fillValidProject(tester);
      await tapSave(tester);

      expect(
        find.text('Data proyek tidak valid: Title cannot be empty.'),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Server tidak terjangkau menampilkan SnackBar', (
      WidgetTester tester,
    ) async {
      final backend = FakeBackend();
      await pumpPage(
        tester,
        const ProjectFormPage(),
        backend: backend,
        token: ownerToken,
      );
      // Request apa pun gagal di tingkat jaringan.
      backend.failNetwork = true;

      await fillValidProject(tester);
      await tapSave(tester);

      expect(
        find.text('Tidak dapat terhubung ke server. Coba lagi.'),
        findsOneWidget,
      );
      // Tombol kembali aktif setelah request gagal.
      final save = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text('Save'),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(save.onPressed, isNotNull);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myportofolio_mobile/main.dart';
import 'package:myportofolio_mobile/screens/education_form.dart';
import 'package:myportofolio_mobile/screens/menu.dart';
import 'package:myportofolio_mobile/screens/project_form.dart';

/// Field teks pada form yang berlabel [label].
Finder field(String label) => find.widgetWithText(TextFormField, label);

/// Isi teks yang sedang tertulis di field berlabel [label].
String fieldText(WidgetTester tester, String label) {
  final editable = find.descendant(
    of: field(label),
    matching: find.byType(EditableText),
  );
  return tester.widget<EditableText>(editable).controller.text;
}

Future<void> openDrawer(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Open navigation menu'));
  await tester.pumpAndSettle();
}

/// Font test Flutter menggambar tiap huruf sebagai kotak selebar ukuran
/// font, jadi teks header drawer jauh lebih lebar daripada di aplikasi asli.
/// Skala teks diperkecil agar header drawer tidak overflow di test.
void shrinkTextForDrawer(WidgetTester tester) {
  tester.platformDispatcher.textScaleFactorTestValue = 0.5;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// Memilih tanggal [day] pada bulan yang sedang ditampilkan date picker.
Future<void> pickDay(WidgetTester tester, String fieldLabel, int day) async {
  // Area yang bisa diketuk adalah InkWell yang membungkus field tanggal.
  final dateField = find.ancestor(
    of: find.text(fieldLabel),
    matching: find.byType(InkWell),
  );
  await tester.ensureVisible(dateField.first);
  await tester.tap(dateField.first);
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(DatePickerDialog),
      matching: find.text('$day'),
    ),
  );
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

Future<void> tapSimpan(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Simpan'));
  await tester.tap(find.text('Simpan'));
  await tester.pumpAndSettle();
}

Future<void> openForm(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: EducationFormPage()));
}

/// Tanggal pada bulan berjalan, karena date picker dibuka di bulan ini.
DateTime thisMonth(int day) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, day);
}

void main() {
  group('Navigasi ke formulir Education', () {
    testWidgets('Kartu Tambah Education membuka form dengan push', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());

      await tester.ensureVisible(find.text('Tambah Education'));
      await tester.tap(find.text('Tambah Education'));
      await tester.pumpAndSettle();

      expect(find.text('Add Education Form'), findsOneWidget);
      expect(
        find.text('Kamu telah menekan tombol Tambah Education!'),
        findsOneWidget,
      );

      // Tombol Back perangkat/browser kembali ke menu yang masih ada di stack.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(EducationFormPage), findsNothing);
      expect(find.byType(MyHomePage), findsOneWidget);
    });

    testWidgets('Drawer punya Home, Add Project, dan Add Education', (
      WidgetTester tester,
    ) async {
      shrinkTextForDrawer(tester);
      await tester.pumpWidget(const MyApp());

      await openDrawer(tester);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Add Project'), findsOneWidget);
      expect(find.text('Add Education'), findsOneWidget);

      await tester.tap(find.text('Add Education'));
      await tester.pumpAndSettle();
      expect(find.byType(EducationFormPage), findsOneWidget);
      expect(find.byType(MyHomePage), findsNothing);

      // Drawer yang sama juga dipakai di halaman form Education.
      await openDrawer(tester);
      await tester.tap(find.text('Add Project'));
      await tester.pumpAndSettle();
      expect(find.byType(ProjectFormPage), findsOneWidget);

      await openDrawer(tester);
      await tester.tap(find.text('Add Education'));
      await tester.pumpAndSettle();
      expect(find.byType(EducationFormPage), findsOneWidget);
    });

    testWidgets('Opsi Home dari form Education kembali ke halaman utama', (
      WidgetTester tester,
    ) async {
      shrinkTextForDrawer(tester);
      await tester.pumpWidget(const MyApp());

      await tester.ensureVisible(find.text('Tambah Education'));
      await tester.tap(find.text('Tambah Education'));
      await tester.pumpAndSettle();

      await openDrawer(tester);
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(find.byType(MyHomePage), findsOneWidget);
      expect(find.byType(EducationFormPage), findsNothing);
      expect(find.text('Karyn Isabelle Dexter'), findsOneWidget);
    });
  });

  group('Validasi formulir Education', () {
    testWidgets(
      'Field wajib kosong menampilkan error dan tidak membuka dialog',
      (WidgetTester tester) async {
        await openForm(tester);

        await tapSimpan(tester);

        expect(find.text('Institusi tidak boleh kosong!'), findsOneWidget);
        expect(find.text('Tanggal mulai wajib dipilih!'), findsOneWidget);
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets('Institusi yang hanya berisi spasi ditolak', (
      WidgetTester tester,
    ) async {
      await openForm(tester);

      await tester.enterText(field('Institusi'), '    ');
      await pickDay(tester, 'Tanggal Mulai', 10);
      await tapSimpan(tester);

      expect(find.text('Institusi tidak boleh kosong!'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Institusi dibatasi 255 karakter', (WidgetTester tester) async {
      await openForm(tester);

      await tester.enterText(field('Institusi'), 'a' * 300);
      await tester.pump();

      final text = tester
          .widget<EditableText>(
            find.descendant(
              of: field('Institusi'),
              matching: find.byType(EditableText),
            ),
          )
          .controller
          .text;
      expect(text.length, 255);
    });

    for (final badUrl in [
      'drive.google.com/file',
      'ftp://files.example.com/ijazah.pdf',
      'https://ijazah',
      'https://ijazah saya.com',
    ]) {
      testWidgets('URL tidak valid ditolak: "$badUrl"', (
        WidgetTester tester,
      ) async {
        await openForm(tester);

        await tester.enterText(field('Institusi'), 'Universitas Indonesia');
        await pickDay(tester, 'Tanggal Mulai', 10);
        await tester.enterText(
          field('URL Sertifikat/Ijazah (opsional)'),
          badUrl,
        );
        await tapSimpan(tester);

        expect(
          find.text('Masukkan URL lengkap yang diawali http:// atau https://.'),
          findsOneWidget,
        );
        expect(find.byType(AlertDialog), findsNothing);
      });
    }

    testWidgets('Tanggal selesai sebelum tanggal mulai ditolak', (
      WidgetTester tester,
    ) async {
      await openForm(tester);

      await tester.enterText(field('Institusi'), 'Universitas Indonesia');
      await pickDay(tester, 'Tanggal Mulai', 10);
      await pickDay(tester, 'Tanggal Selesai (opsional)', 20);
      // Tanggal mulai diubah menjadi setelah tanggal selesai yang lama.
      await pickDay(tester, 'Tanggal Mulai', 25);
      await tapSimpan(tester);

      expect(
        find.text('Tanggal selesai tidak boleh sebelum tanggal mulai.'),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('Dialog ringkasan', () {
    testWidgets(
      'Input valid menampilkan semua isian, OK menutup dan me-reset',
      (WidgetTester tester) async {
        await openForm(tester);

        await tester.enterText(field('Institusi'), '  Universitas Indonesia  ');
        await tester.enterText(
          field('Deskripsi (opsional)'),
          'S1 Sistem Informasi, Fakultas Ilmu Komputer',
        );
        await pickDay(tester, 'Tanggal Mulai', 10);
        await pickDay(tester, 'Tanggal Selesai (opsional)', 20);
        await tester.enterText(
          field('URL Sertifikat/Ijazah (opsional)'),
          'https://drive.google.com/ijazah',
        );
        await tapSimpan(tester);

        expect(find.text('Edukasi berhasil ditambahkan!'), findsOneWidget);
        expect(find.text('Institusi: Universitas Indonesia'), findsOneWidget);
        expect(
          find.text('Deskripsi: S1 Sistem Informasi, Fakultas Ilmu Komputer'),
          findsOneWidget,
        );
        expect(
          find.text('Tanggal Mulai: ${formatTanggal(thisMonth(10))}'),
          findsOneWidget,
        );
        expect(
          find.text('Tanggal Selesai: ${formatTanggal(thisMonth(20))}'),
          findsOneWidget,
        );
        expect(
          find.text('URL Sertifikat: https://drive.google.com/ijazah'),
          findsOneWidget,
        );

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        // Dialog tertutup, pengguna kembali ke form yang sudah kosong.
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(EducationFormPage), findsOneWidget);
        // ("Universitas Indonesia" tetap terlihat sebagai hint field.)
        expect(fieldText(tester, 'Institusi'), isEmpty);
        expect(fieldText(tester, 'Deskripsi (opsional)'), isEmpty);
        expect(fieldText(tester, 'URL Sertifikat/Ijazah (opsional)'), isEmpty);
        expect(find.text(formatTanggal(thisMonth(10))), findsNothing);

        // Setelah reset, isian lama tidak ikut terkirim lagi.
        await tapSimpan(tester);
        expect(find.text('Institusi tidak boleh kosong!'), findsOneWidget);
        expect(find.text('Tanggal mulai wajib dipilih!'), findsOneWidget);
      },
    );

    testWidgets('Field opsional kosong ditampilkan sebagai "-" dan '
        '"Masih berlangsung"', (WidgetTester tester) async {
      await openForm(tester);

      await tester.enterText(field('Institusi'), 'SMA Negeri 8 Jakarta');
      await pickDay(tester, 'Tanggal Mulai', 10);
      await tapSimpan(tester);

      expect(find.text('Deskripsi: -'), findsOneWidget);
      expect(find.text('Tanggal Selesai: Masih berlangsung'), findsOneWidget);
      expect(find.text('URL Sertifikat: -'), findsOneWidget);
    });

    testWidgets('Tanggal selesai bisa dikosongkan lagi dengan tombol hapus', (
      WidgetTester tester,
    ) async {
      await openForm(tester);

      await tester.enterText(field('Institusi'), 'Universitas Indonesia');
      await pickDay(tester, 'Tanggal Mulai', 10);
      await pickDay(tester, 'Tanggal Selesai (opsional)', 20);
      await tester.tap(find.byTooltip('Hapus Tanggal Selesai (opsional)'));
      await tester.pumpAndSettle();
      await tapSimpan(tester);

      expect(find.text('Tanggal Selesai: Masih berlangsung'), findsOneWidget);
    });

    testWidgets(
      'Simpan tetap terjangkau di layar ponsel saat papan ketik tampil',
      (WidgetTester tester) async {
        // Layar 360 x 640 (ponsel kecil) dengan papan ketik setinggi 300.
        tester.view.devicePixelRatio = 3.0;
        tester.view.physicalSize = const Size(360 * 3, 640 * 3);
        tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
        addTearDown(tester.view.reset);

        await openForm(tester);

        await tester.enterText(field('Institusi'), 'Universitas Indonesia');
        await pickDay(tester, 'Tanggal Mulai', 10);
        await tapSimpan(tester);

        expect(find.text('Edukasi berhasil ditambahkan!'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}

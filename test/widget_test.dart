import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myportofolio_mobile/main.dart';
import 'package:myportofolio_mobile/screens/menu.dart';
import 'package:myportofolio_mobile/screens/project_form.dart';
import 'package:myportofolio_mobile/widgets/project_card.dart';

const buttonNames = [
  'Lihat Proyek',
  'Tambah Proyek',
  'Lihat Education',
  'Tambah Education',
  'Logout',
];

/// Warna latar Material milik ItemCard yang berlabel [name].
Color? cardColor(WidgetTester tester, String name) {
  final card = find.widgetWithText(ItemCard, name);
  final material = find.descendant(of: card, matching: find.byType(Material));
  return tester.widget<Material>(material.first).color;
}

/// Field teks pada form yang berlabel [label].
Finder field(String label) => find.widgetWithText(TextFormField, label);

/// Membuka drawer lewat ikon hamburger di AppBar.
Future<void> openDrawer(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Open navigation menu'));
  await tester.pumpAndSettle();
}

void main() {
  group('Halaman menu', () {
    testWidgets('InfoCard menampilkan NPM, nama, dan kelas pemilik', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());

      expect(find.text('MyPortfolio'), findsOneWidget);
      expect(find.byType(InfoCard), findsNWidgets(3));
      expect(find.widgetWithText(InfoCard, '2506656860'), findsOneWidget);
      expect(
        find.widgetWithText(InfoCard, 'Karyn Isabelle Dexter'),
        findsOneWidget,
      );
      expect(find.widgetWithText(InfoCard, 'PBP A'), findsOneWidget);
    });

    testWidgets('Setiap ItemCard punya warna latar yang berbeda', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());

      expect(find.byType(ItemCard), findsNWidgets(buttonNames.length));
      final colors = buttonNames.map((name) => cardColor(tester, name)).toSet();
      expect(colors.length, buttonNames.length);
    });

    testWidgets('Tombol tanpa navigasi menampilkan SnackBar sesuai namanya', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());

      for (final name in buttonNames.where((n) => n != 'Tambah Proyek')) {
        await tester.ensureVisible(find.text(name));
        await tester.tap(find.text(name));
        // SnackBar lama ditutup dulu (animasi), baru SnackBar baru muncul.
        await tester.pumpAndSettle();

        expect(find.text('Kamu telah menekan tombol $name!'), findsOneWidget);
        expect(find.byType(ProjectFormPage), findsNothing);
      }
    });
  });

  group('Navigasi', () {
    testWidgets(
      'Tambah Proyek membuka form dengan push, Back kembali ke menu',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MyApp());

        await tester.tap(find.text('Tambah Proyek'));
        await tester.pumpAndSettle();

        expect(
          find.text('Kamu telah menekan tombol Tambah Proyek!'),
          findsOneWidget,
        );
        expect(find.text('Add Project Form'), findsOneWidget);

        // Tombol Back sistem/browser: route menu masih ada di bawah form.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.byType(ProjectFormPage), findsNothing);
        expect(find.byType(MyHomePage), findsOneWidget);
      },
    );

    testWidgets('Drawer berpindah antara Home dan Add Project', (
      WidgetTester tester,
    ) async {
      // Font test Flutter menggambar tiap huruf sebagai kotak selebar ukuran
      // font, jadi teks header drawer jauh lebih lebar daripada di aplikasi
      // asli. Skala teks diperkecil agar header tidak overflow di test.
      tester.platformDispatcher.textScaleFactorTestValue = 0.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(const MyApp());

      await openDrawer(tester);
      expect(find.text('My Portfolio'), findsOneWidget);
      expect(
        find.text('Explore personal projects and experiences!'),
        findsOneWidget,
      );

      await tester.tap(find.text('Add Project'));
      await tester.pumpAndSettle();
      expect(find.text('Add Project Form'), findsOneWidget);
      expect(find.byType(MyHomePage), findsNothing);

      // Drawer juga tersedia di halaman form.
      await openDrawer(tester);
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.byType(MyHomePage), findsOneWidget);
      expect(find.byType(ProjectFormPage), findsNothing);
    });
  });

  group('Form tambah proyek', () {
    Future<void> openForm(WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProjectFormPage()));
    }

    Future<void> tapSave(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
    }

    testWidgets('Field wajib yang kosong menampilkan pesan error', (
      WidgetTester tester,
    ) async {
      await openForm(tester);

      await tapSave(tester);

      expect(find.text('Nama proyek tidak boleh kosong!'), findsOneWidget);
      expect(find.text('Deskripsi proyek tidak boleh kosong!'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Isi spasi saja tetap dianggap kosong', (
      WidgetTester tester,
    ) async {
      await openForm(tester);

      await tester.enterText(field('Nama Proyek'), '   ');
      await tester.enterText(field('Deskripsi Proyek'), '   ');
      await tapSave(tester);

      expect(find.text('Nama proyek tidak boleh kosong!'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets(
      'Save menampilkan seluruh isian, OK menutup dan me-reset form',
      (WidgetTester tester) async {
        await openForm(tester);

        await tester.enterText(field('Nama Proyek'), 'MyPortfolio Mobile');
        await tester.enterText(
          field('Deskripsi Proyek'),
          'Aplikasi portofolio',
        );
        await tester.tap(find.text('Web Development'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mobile Development').last);
        await tester.pumpAndSettle();
        await tester.enterText(
          field('Teknologi yang Digunakan'),
          'Flutter, Django',
        );
        await tester.enterText(
          field('Tautan Proyek'),
          'https://github.com/karyndextuy',
        );
        await tapSave(tester);

        expect(find.text('Proyek berhasil ditambahkan!'), findsOneWidget);
        expect(find.text('Nama Proyek: MyPortfolio Mobile'), findsOneWidget);
        expect(find.text('Deskripsi: Aplikasi portofolio'), findsOneWidget);
        expect(find.text('Kategori: Mobile Development'), findsOneWidget);
        expect(find.text('Teknologi: Flutter, Django'), findsOneWidget);
        expect(
          find.text('Tautan: https://github.com/karyndextuy'),
          findsOneWidget,
        );

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text('MyPortfolio Mobile'), findsNothing);
        expect(find.text('Flutter, Django'), findsNothing);
      },
    );

    testWidgets('Setelah reset, nilai lama tidak muncul lagi di pop-up', (
      WidgetTester tester,
    ) async {
      await openForm(tester);

      await tester.enterText(field('Nama Proyek'), 'Proyek Lama');
      await tester.enterText(field('Deskripsi Proyek'), 'Deskripsi lama');
      await tester.enterText(field('Teknologi yang Digunakan'), 'Django');
      await tester.enterText(field('Tautan Proyek'), 'https://lama.example');
      await tapSave(tester);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Isi ulang hanya field wajib; teknologi dan tautan dibiarkan kosong.
      await tester.enterText(field('Nama Proyek'), 'Proyek Baru');
      await tester.enterText(field('Deskripsi Proyek'), 'Deskripsi baru');
      await tapSave(tester);

      expect(find.text('Nama Proyek: Proyek Baru'), findsOneWidget);
      expect(find.text('Teknologi: '), findsOneWidget);
      expect(find.text('Tautan: '), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('Django'),
        ),
        findsNothing,
      );
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myportofolio_mobile/screens/login_screen.dart';
import 'package:myportofolio_mobile/screens/menu.dart';
import 'package:myportofolio_mobile/screens/project_form.dart';
import 'package:myportofolio_mobile/screens/project_list_screen.dart';
import 'package:myportofolio_mobile/widgets/project_card.dart';

import 'helpers.dart';

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

Future<void> tapCard(WidgetTester tester, String name) async {
  await tester.ensureVisible(find.text(name));
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

void main() {
  group('Halaman menu', () {
    testWidgets('InfoCard menampilkan NPM, nama, dan kelas pemilik', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, FakeBackend());

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
      await pumpApp(tester, FakeBackend());

      expect(find.byType(ItemCard), findsNWidgets(buttonNames.length));
      final colors = buttonNames.map((name) => cardColor(tester, name)).toSet();
      expect(colors.length, buttonNames.length);
    });

    testWidgets('Tombol tanpa navigasi menampilkan SnackBar sesuai namanya', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, FakeBackend());

      // Logout saat belum login tidak melakukan apa-apa selain SnackBar.
      for (final name in ['Lihat Education', 'Logout']) {
        await tapCard(tester, name);

        expect(find.text('Kamu telah menekan tombol $name!'), findsOneWidget);
        expect(find.byType(MyHomePage), findsOneWidget);
      }
    });
  });

  group('Navigasi dan route guard', () {
    testWidgets('Lihat Proyek membuka daftar proyek tanpa login', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, FakeBackend());

      await tapCard(tester, 'Lihat Proyek');

      expect(find.byType(ProjectListScreen), findsOneWidget);
      expect(find.text('MyPortfolio Web'), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets(
      'Tambah Proyek saat belum login membuka Login, lalu form setelah login',
      (WidgetTester tester) async {
        await pumpApp(tester, FakeBackend());

        await tapCard(tester, 'Tambah Proyek');
        expect(
          find.text('Kamu telah menekan tombol Tambah Proyek!'),
          findsOneWidget,
        );
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(ProjectFormPage), findsNothing);

        await submitLogin(tester);

        expect(find.byType(LoginScreen), findsNothing);
        expect(find.text('Add Project Form'), findsOneWidget);

        // Form dibuka dengan push, jadi Back kembali ke menu.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(MyHomePage), findsOneWidget);

        // Sudah login: form langsung terbuka tanpa halaman Login.
        await tapCard(tester, 'Tambah Proyek');
        expect(find.byType(LoginScreen), findsNothing);
        expect(find.text('Add Project Form'), findsOneWidget);
      },
    );

    testWidgets('Menutup halaman Login tanpa login tidak membuka form', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, FakeBackend());

      await tapCard(tester, 'Tambah Proyek');
      expect(find.byType(LoginScreen), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(ProjectFormPage), findsNothing);
      expect(find.byType(MyHomePage), findsOneWidget);
    });

    testWidgets('Drawer: Projects publik, Add Project perlu login', (
      WidgetTester tester,
    ) async {
      shrinkTextForDrawer(tester);
      await pumpApp(tester, FakeBackend());

      await openDrawer(tester);
      expect(find.text('My Portfolio'), findsOneWidget);
      expect(
        find.text('Explore personal projects and experiences!'),
        findsOneWidget,
      );

      await tester.tap(find.text('Projects'));
      await tester.pumpAndSettle();
      expect(find.byType(ProjectListScreen), findsOneWidget);

      await openDrawer(tester);
      await tester.tap(find.text('Add Project'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);

      await submitLogin(tester);
      expect(find.text('Add Project Form'), findsOneWidget);
      expect(find.byType(ProjectListScreen), findsNothing);

      // Drawer juga tersedia di halaman form.
      await openDrawer(tester);
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.byType(MyHomePage), findsOneWidget);
      expect(find.byType(ProjectFormPage), findsNothing);
    });
  });
}

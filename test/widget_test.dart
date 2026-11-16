import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myportofolio_mobile/main.dart';
import 'package:myportofolio_mobile/menu.dart';

const buttonNames = ['Lihat Education', 'Tambah Education', 'Logout'];

/// Warna latar Material milik ItemCard yang berlabel [name].
Color? cardColor(WidgetTester tester, String name) {
  final card = find.widgetWithText(ItemCard, name);
  final material = find.descendant(of: card, matching: find.byType(Material));
  return tester.widget<Material>(material.first).color;
}

void main() {
  testWidgets('InfoCard menampilkan NPM, nama, dan kelas pemilik',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('MyPortfolio'), findsOneWidget);
    expect(find.byType(InfoCard), findsNWidgets(3));
    expect(find.widgetWithText(InfoCard, '2506656860'), findsOneWidget);
    expect(find.widgetWithText(InfoCard, 'Karyn Isabelle Dexter'), findsOneWidget);
    expect(find.widgetWithText(InfoCard, 'PBP A'), findsOneWidget);
    expect(find.text('Burhan'), findsNothing);
  });

  testWidgets('Setiap ItemCard punya warna latar yang berbeda',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(ItemCard), findsNWidgets(buttonNames.length));

    final colors = buttonNames.map((name) => cardColor(tester, name)).toList();
    expect(colors, [
      Colors.blue.shade700,
      Colors.green.shade700,
      Colors.red.shade700,
    ]);
    expect(colors.toSet().length, buttonNames.length);
  });

  testWidgets('Menekan tombol menampilkan SnackBar sesuai nama tombol',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    for (final name in buttonNames) {
      await tester.tap(find.text(name));
      // SnackBar lama ditutup dulu (animasi), baru SnackBar baru muncul.
      await tester.pumpAndSettle();

      expect(find.text('Kamu telah menekan tombol $name!'), findsOneWidget);
    }

    // hideCurrentSnackBar() memastikan hanya satu SnackBar yang tampil.
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Kamu telah menekan tombol Logout!'), findsOneWidget);
  });
}

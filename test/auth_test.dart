import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myportofolio_mobile/screens/login_screen.dart';
import 'package:myportofolio_mobile/screens/menu.dart';
import 'package:myportofolio_mobile/services/api_client.dart';
import 'package:myportofolio_mobile/services/auth_state.dart';

import 'helpers.dart';

void main() {
  group('AuthState', () {
    test('login menyimpan token dan memberi tahu listener', () async {
      final backend = FakeBackend();
      final auth = AuthState(backend.apiClient);
      var notified = 0;
      auth.addListener(() => notified++);

      await auth.login('owner', 'test-password');

      expect(auth.isLoggedIn, isTrue);
      expect(auth.token, ownerToken);
      expect(notified, 1);
    });

    test('login gagal tidak menyimpan token', () async {
      final auth = AuthState(FakeBackend().apiClient);

      await expectLater(
        auth.login('owner', 'wrong'),
        throwsA(isA<ApiException>()),
      );
      expect(auth.isLoggedIn, isFalse);
    });

    test('logout mencabut token di server dan menghapus token lokal', () async {
      final backend = FakeBackend();
      final auth = AuthState(backend.apiClient, initialToken: ownerToken);

      await auth.logout();

      expect(auth.isLoggedIn, isFalse);
      expect(backend.validTokens.contains(ownerToken), isFalse);
    });

    test('logout tetap menghapus token lokal walau server menolak', () async {
      final backend = FakeBackend()..validTokens.clear();
      final auth = AuthState(backend.apiClient, initialToken: ownerToken);

      await auth.logout();

      expect(auth.isLoggedIn, isFalse);
    });

    test('logout tetap menghapus token lokal walau server mati', () async {
      final backend = FakeBackend()..failNetwork = true;
      final auth = AuthState(backend.apiClient, initialToken: ownerToken);

      await auth.logout();

      expect(auth.isLoggedIn, isFalse);
    });

    test('logout saat belum login tidak mengirim request', () async {
      final backend = FakeBackend();
      await AuthState(backend.apiClient).logout();
      expect(backend.requests, isEmpty);
    });
  });

  group('LoginScreen', () {
    testWidgets('Field kosong ditolak tanpa request ke server', (
      WidgetTester tester,
    ) async {
      final backend = FakeBackend();
      await pumpPage(tester, const LoginScreen(), backend: backend);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      expect(find.text('Username cannot be empty!'), findsOneWidget);
      expect(find.text('Password cannot be empty!'), findsOneWidget);
      expect(backend.requests, isEmpty);
    });

    testWidgets('Password salah menampilkan SnackBar dengan status code', (
      WidgetTester tester,
    ) async {
      final auth = await pumpPage(tester, const LoginScreen());

      await submitLogin(tester, password: 'wrong');

      expect(
        find.text('Login failed (400): wrong username or password.'),
        findsOneWidget,
      );
      expect(auth.isLoggedIn, isFalse);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('Login dan Logout di drawer dan kartu', () {
    testWidgets('Drawer menampilkan Login, lalu Logout setelah login', (
      WidgetTester tester,
    ) async {
      shrinkTextForDrawer(tester);
      final backend = FakeBackend();
      await pumpApp(tester, backend);

      await openDrawer(tester);
      expect(find.widgetWithText(ListTile, 'Login'), findsOneWidget);
      // (Teks "Logout" juga ada di kartu menu di belakang drawer.)
      expect(find.widgetWithText(ListTile, 'Logout'), findsNothing);

      await tester.tap(find.widgetWithText(ListTile, 'Login'));
      await tester.pumpAndSettle();
      await submitLogin(tester);
      expect(find.byType(MyHomePage), findsOneWidget);

      await openDrawer(tester);
      expect(find.widgetWithText(ListTile, 'Login'), findsNothing);
      await tester.tap(find.widgetWithText(ListTile, 'Logout'));
      await tester.pumpAndSettle();

      expect(find.text('Logout berhasil.'), findsOneWidget);
      expect(backend.validTokens.contains(ownerToken), isFalse);

      await openDrawer(tester);
      expect(find.widgetWithText(ListTile, 'Login'), findsOneWidget);
    });

    testWidgets('Kartu Logout mencabut token saat sudah login', (
      WidgetTester tester,
    ) async {
      final backend = FakeBackend();
      final auth = await pumpPage(
        tester,
        MyHomePage(),
        backend: backend,
        token: ownerToken,
      );

      await tester.ensureVisible(find.text('Logout'));
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      expect(auth.isLoggedIn, isFalse);
      expect(backend.validTokens.contains(ownerToken), isFalse);
      expect(find.text('Logout berhasil.'), findsOneWidget);
    });
  });
}

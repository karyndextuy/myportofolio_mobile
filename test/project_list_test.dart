import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myportofolio_mobile/models/project.dart';
import 'package:myportofolio_mobile/screens/project_detail_screen.dart';
import 'package:myportofolio_mobile/screens/project_list_screen.dart';

import 'helpers.dart';

void main() {
  group('ProjectListScreen', () {
    testWidgets('Menampilkan loading lalu daftar proyek dari API', (
      WidgetTester tester,
    ) async {
      final backend = FakeBackend(
        projects: [
          projectJson(),
          projectJson(
            id: '2',
            title: 'Toko Online',
            techStack: 'Flutter',
            description: 'Aplikasi belanja',
          ),
        ],
      );
      await pumpPage(tester, const ProjectListScreen(), backend: backend);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();

      expect(find.text('MyPortfolio Web'), findsOneWidget);
      expect(find.text('Toko Online'), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Aplikasi belanja'), findsOneWidget);
    });

    testWidgets('Request hanya dikirim sekali walau widget dibangun ulang', (
      WidgetTester tester,
    ) async {
      final backend = FakeBackend();
      await pumpPage(tester, const ProjectListScreen(), backend: backend);
      await tester.pumpAndSettle();

      // Memaksa rebuild (mis. ukuran layar berubah).
      tester.view.physicalSize = const Size(1000, 1600);
      addTearDown(tester.view.reset);
      await tester.pumpAndSettle();

      expect(backend.requests, hasLength(1));
    });

    testWidgets('Daftar kosong menampilkan pesan dan tetap bisa di-refresh', (
      WidgetTester tester,
    ) async {
      final backend = FakeBackend(projects: []);
      await pumpPage(tester, const ProjectListScreen(), backend: backend);
      await tester.pumpAndSettle();

      expect(find.text('No projects found.'), findsOneWidget);

      backend.projects.add(projectJson(title: 'Proyek Baru'));
      await tester.fling(
        find.text('No projects found.'),
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text('Proyek Baru'), findsOneWidget);
      expect(backend.requests, hasLength(2));
    });

    testWidgets('Error menampilkan pesan dan tombol Retry', (
      WidgetTester tester,
    ) async {
      final backend = FakeBackend()..projectsErrorStatus = 500;
      await pumpPage(tester, const ProjectListScreen(), backend: backend);
      await tester.pumpAndSettle();

      expect(find.textContaining('Failed to load projects'), findsOneWidget);

      backend.projectsErrorStatus = null;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('MyPortfolio Web'), findsOneWidget);
    });

    testWidgets('Mengetuk proyek membuka halaman detail', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, const ProjectListScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('MyPortfolio Web'));
      await tester.pumpAndSettle();

      expect(find.byType(ProjectDetailScreen), findsOneWidget);
      expect(find.text('Website portofolio dengan Django'), findsOneWidget);
      expect(
        find.text('https://github.com/karyndextuy/myportofolio'),
        findsOneWidget,
      );
    });
  });

  group('ProjectDetailScreen', () {
    Project project({String imageUrl = ''}) =>
        Project.fromJson(projectJson(projectImageUrl: imageUrl));

    testWidgets('Tanpa URL gambar, widget gambar tidak ditampilkan', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: ProjectDetailScreen(project: project())),
      );

      expect(find.byType(Image), findsNothing);
      expect(find.text('Django, DRF'), findsOneWidget);
    });

    testWidgets('Dengan URL gambar, widget gambar ditampilkan', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProjectDetailScreen(
            project: project(imageUrl: 'https://example.com/shot.png'),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as NetworkImage).url, 'https://example.com/shot.png');
    });
  });
}

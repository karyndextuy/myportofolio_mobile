import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myportofolio_mobile/main.dart';
import 'package:myportofolio_mobile/services/api_client.dart';
import 'package:myportofolio_mobile/services/auth_state.dart';
import 'package:provider/provider.dart';

const ownerToken = 'owner-token';
const visitorToken = 'visitor-token';

/// Contoh satu proyek seperti yang dikirim `GET /api/v1/projects/`.
Map<String, dynamic> projectJson({
  String id = '1f549f92-50b7-4f06-979f-77f6d9914a80',
  String title = 'MyPortfolio Web',
  String description = 'Website portofolio dengan Django',
  String techStack = 'Django, DRF',
  String projectUrl = 'https://github.com/karyndextuy/myportofolio',
  String? projectImageUrl = '',
}) => {
  'id': id,
  'title': title,
  'description': description,
  'tech_stack': techStack,
  'project_url': projectUrl,
  'project_image_url': projectImageUrl,
  // Field tambahan dari serializer yang tidak dipakai model Flutter.
  'star_count': 0,
  'is_starred': false,
  'starred_by_names': <String>[],
};

/// Backend Django tiruan untuk test, meniru perilaku endpoint yang sudah
/// diuji di `main/tests_api.py` (Tutorial 10, Bagian 1).
class FakeBackend {
  FakeBackend({List<Map<String, dynamic>>? projects})
    : projects = projects ?? [projectJson()];

  final List<Map<String, dynamic>> projects;

  /// Semua request yang diterima, untuk diperiksa di test.
  final List<http.Request> requests = [];

  /// Token yang masih berlaku di "server".
  final Set<String> validTokens = {ownerToken, visitorToken};

  /// Jika diisi, `GET /api/v1/projects/` membalas dengan status ini.
  int? projectsErrorStatus;

  /// Jika diisi, `POST /api/v1/projects/` membalas 400 dengan body ini
  /// (pesan validasi DRF).
  Map<String, dynamic>? projectValidationErrors;

  /// Jika true, setiap request gagal di tingkat jaringan (server mati).
  bool failNetwork = false;

  late final ApiClient apiClient = ApiClient(
    client: MockClient(_handle),
    baseUrl: 'http://test.local',
  );

  Future<http.Response> _handle(http.Request request) async {
    requests.add(request);
    if (failNetwork) {
      throw http.ClientException('Connection refused', request.url);
    }
    final path = request.url.path;
    final auth = request.headers['Authorization'];
    final token = auth?.startsWith('Token ') == true
        ? auth!.substring(6)
        : null;

    if (path == '/api/v1/projects/' && request.method == 'GET') {
      if (projectsErrorStatus != null) {
        return http.Response('{"detail":"error"}', projectsErrorStatus!);
      }
      return _json(projects, 200);
    }

    if (path == '/api/v1/projects/' && request.method == 'POST') {
      if (token == null || !validTokens.contains(token)) {
        return _json({'detail': 'Invalid token.'}, 401);
      }
      if (token != ownerToken) {
        return _json({
          'detail': 'You do not have permission to perform this action.',
        }, 403);
      }
      if (projectValidationErrors != null) {
        return _json(projectValidationErrors!, 400);
      }
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final created = projectJson(
        id: 'new-${projects.length}',
        title: body['title'] as String,
        description: body['description'] as String,
        techStack: body['tech_stack'] as String,
        projectUrl: body['project_url'] as String,
        projectImageUrl: body['project_image_url'] as String,
      );
      projects.add(created);
      return _json(created, 201);
    }

    if (path == '/api/v1/auth/token/' && request.method == 'POST') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      if (body['password'] != 'test-password') {
        return _json({
          'non_field_errors': ['Unable to log in with provided credentials.'],
        }, 400);
      }
      final key = body['username'] == 'owner' ? ownerToken : visitorToken;
      validTokens.add(key);
      return _json({'token': key}, 200);
    }

    if (path == '/api/v1/auth/logout/' && request.method == 'POST') {
      if (token == null || !validTokens.remove(token)) {
        return _json({'detail': 'Invalid token.'}, 401);
      }
      return http.Response('', 204);
    }

    return http.Response('Not found', 404);
  }

  http.Response _json(Object body, int status) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );
}

/// Menjalankan aplikasi lengkap ([MyApp]) dengan backend tiruan.
Future<void> pumpApp(WidgetTester tester, FakeBackend backend) async {
  await tester.pumpWidget(MyApp(apiClient: backend.apiClient));
}

/// Menampilkan satu halaman dengan provider yang sama seperti di [MyApp].
/// Bila [token] diisi, pengguna dianggap sudah login.
Future<AuthState> pumpPage(
  WidgetTester tester,
  Widget page, {
  FakeBackend? backend,
  String? token,
}) async {
  final api = (backend ?? FakeBackend()).apiClient;
  final authState = AuthState(api, initialToken: token);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider.value(value: api),
        ChangeNotifierProvider.value(value: authState),
      ],
      child: MaterialApp(home: page),
    ),
  );
  return authState;
}

/// Field teks pada form yang berlabel [label].
Finder field(String label) => find.widgetWithText(TextFormField, label);

/// Membuka drawer lewat ikon hamburger di AppBar.
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

/// Mengisi form login lalu menekan tombol Login.
Future<void> submitLogin(
  WidgetTester tester, {
  String username = 'owner',
  String password = 'test-password',
}) async {
  await tester.enterText(field('Username'), username);
  await tester.enterText(field('Password'), password);
  await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
  await tester.pumpAndSettle();
}

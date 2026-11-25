import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:myportofolio_mobile/models/project.dart';
import 'package:myportofolio_mobile/services/api_client.dart';

import 'helpers.dart';

void main() {
  group('Project (json_serializable)', () {
    test('fromJson memetakan snake_case ke camelCase', () {
      final project = Project.fromJson(projectJson());

      expect(project.id, '1f549f92-50b7-4f06-979f-77f6d9914a80');
      expect(project.title, 'MyPortfolio Web');
      expect(project.techStack, 'Django, DRF');
      expect(project.projectUrl, 'https://github.com/karyndextuy/myportofolio');
    });

    test('project_image_url null atau tidak ada menjadi string kosong', () {
      expect(
        Project.fromJson(projectJson(projectImageUrl: null)).projectImageUrl,
        '',
      );
      final withoutKey = projectJson()..remove('project_image_url');
      expect(Project.fromJson(withoutKey).projectImageUrl, '');
    });

    test('toJson memakai snake_case dan tidak mengirim id', () {
      final json = Project.fromJson(projectJson()).toJson();

      expect(json.containsKey('id'), isFalse);
      expect(json['tech_stack'], 'Django, DRF');
      expect(json.keys, {
        'title',
        'description',
        'tech_stack',
        'project_url',
        'project_image_url',
      });
    });
  });

  group('ApiClient', () {
    test('getProjects mengambil daftar proyek tanpa token', () async {
      final backend = FakeBackend(
        projects: [
          projectJson(),
          projectJson(id: '2', title: 'Second'),
        ],
      );

      final projects = await backend.apiClient.getProjects();

      expect(projects.map((p) => p.title), ['MyPortfolio Web', 'Second']);
      final request = backend.requests.single;
      expect(request.url.toString(), 'http://test.local/api/v1/projects/');
      expect(request.headers['Accept'], 'application/json');
      expect(request.headers.containsKey('Authorization'), isFalse);
    });

    test('obtainToken mengirim username dan password sebagai JSON', () async {
      final backend = FakeBackend();

      final token = await backend.apiClient.obtainToken(
        'owner',
        'test-password',
      );

      expect(token, ownerToken);
      final request = backend.requests.single;
      expect(request.url.path, '/api/v1/auth/token/');
      expect(jsonDecode(request.body), {
        'username': 'owner',
        'password': 'test-password',
      });
    });

    test('obtainToken dengan password salah melempar ApiException 400', () {
      final backend = FakeBackend();

      expect(
        backend.apiClient.obtainToken('owner', 'wrong'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 400),
        ),
      );
    });

    test('createProject mengirim header Token dan mengembalikan id', () async {
      final backend = FakeBackend(projects: []);
      const project = Project(
        title: 'Baru',
        description: 'Deskripsi',
        techStack: 'Flutter',
        projectUrl: 'https://example.com',
      );

      final created = await backend.apiClient.createProject(
        project,
        token: ownerToken,
      );

      expect(created.id, isNotNull);
      expect(created.title, 'Baru');
      final request = backend.requests.single;
      expect(request.method, 'POST');
      expect(request.headers['Authorization'], 'Token $ownerToken');
      expect(
        request.headers['Content-Type'],
        'application/json; charset=UTF-8',
      );
      expect(jsonDecode(request.body), project.toJson());
    });

    test('logout mencabut token di server', () async {
      final backend = FakeBackend();

      await backend.apiClient.logout(token: ownerToken);

      expect(backend.validTokens.contains(ownerToken), isFalse);
      expect(
        backend.requests.single.headers['Authorization'],
        'Token $ownerToken',
      );
    });

    test('status selain 2xx melempar ApiException berisi body', () {
      final backend = FakeBackend()..projectsErrorStatus = 500;

      expect(
        backend.apiClient.getProjects(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.message, 'message', contains('error')),
        ),
      );
    });
  });
}

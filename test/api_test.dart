import 'dart:convert';
import 'dart:typed_data';

import 'package:bacheca_app/api/api_client.dart';
import 'package:bacheca_app/api/models.dart';
import 'package:bacheca_app/state/session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Session session;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    session = await Session.load();
    await session.setBaseUrl('192.168.1.10:8080/');
  });

  http.Response json(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)), status,
      headers: {'content-type': 'application/json; charset=utf-8'});

  test('normalizza l\'indirizzo del server', () {
    expect(session.baseUrl, 'http://192.168.1.10:8080');
    expect(Session.normalizeUrl(' https://x.it// '), 'https://x.it');
  });

  test('senza porta viene usata la 8080 del server', () {
    expect(Session.normalizeUrl('192.168.1.109'), 'http://192.168.1.109:8080');
    expect(Session.normalizeUrl('http://192.168.1.109/'), 'http://192.168.1.109:8080');
    expect(Session.normalizeUrl('192.168.1.109:9000'), 'http://192.168.1.109:9000');
  });

  test('Job e JobApplication dal JSON del server', () {
    final job = Job.fromJson({
      'id': 3, 'title': 'Dev', 'description': 'Desc', 'location': 'Salerno',
      'company_name': 'Acme', 'created_at': '2026-11-25T17:24:05.056707Z',
      'applications_count': 2,
    });
    expect(job.companyName, 'Acme');
    expect(job.applicationsCount, 2);
    expect(job.createdAt, isNotNull);

    final app = JobApplication.fromJson({
      'id': 1, 'job_id': 3, 'first_name': 'Niccolò', 'last_name': 'Rossi',
      'email': 'n@x.it', 'phone': '', 'cv_original_name': 'cv.pdf',
      'created_at': '2026-11-25T17:24:05Z',
    });
    expect(app.fullName, 'Niccolò Rossi');
  });

  test('login salva token e azienda; le richieste successive usano il token', () async {
    final seen = <String?>[];
    final client = MockClient((req) async {
      seen.add(req.headers['authorization']);
      if (req.url.path == '/api/auth/login') {
        return json({'token': 'abc', 'company': {'id': 1, 'name': 'Acme', 'email': 'hr@acme.it'}});
      }
      return json([]);
    });
    final api = ApiClient(session, client);
    await api.login('hr@acme.it', 'segreta1');
    expect(session.isLoggedIn, isTrue);
    expect(session.companyName, 'Acme');
    await api.myJobs();
    expect(seen.last, 'Bearer abc');
  });

  test('errore del server → ApiException con il messaggio in italiano', () async {
    final api = ApiClient(session,
        MockClient((_) async => json({'error': 'Email o password non corretti.'}, 401)));
    await expectLater(
        api.login('a@b.it', 'x'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Email o password non corretti.')
            .having((e) => e.isUnauthorized, '401', isTrue)));
  });

  test('401 con sessione attiva → la sessione viene chiusa', () async {
    await session.signIn('vecchio', const Company(id: 1, name: 'Acme', email: 'a@b.it'));
    final api = ApiClient(session, MockClient((_) async => json({'error': 'Sessione scaduta'}, 401)));
    await expectLater(api.myJobs(), throwsA(isA<ApiException>()));
    expect(session.isLoggedIn, isFalse);
  });

  test('server irraggiungibile → messaggio che rimanda alle Impostazioni', () async {
    final api = ApiClient(session, MockClient((_) async => throw http.ClientException('down')));
    await expectLater(api.jobs(),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('Impostazioni'))));
  });

  test('logout cancella la sessione anche se il server non risponde', () async {
    await session.signIn('t', const Company(id: 1, name: 'Acme', email: 'a@b.it'));
    final api = ApiClient(session, MockClient((_) async => throw http.ClientException('down')));
    await api.logout();
    expect(session.isLoggedIn, isFalse);
  });

  test('candidatura inviata come multipart con il file cv', () async {
    late http.BaseRequest captured;
    final client = MockClient.streaming((req, body) async {
      captured = req;
      final bytes = await body.toBytes();
      expect(utf8.decode(bytes, allowMalformed: true), contains('filename="cv.pdf"'));
      return http.StreamedResponse(Stream.value(utf8.encode('{"id":1}')), 201);
    });
    await ApiClient(session, client).apply(3,
        firstName: 'Mario', lastName: 'Rossi', email: 'm@x.it',
        cvFileName: 'cv.pdf', cvBytes: Uint8List.fromList(utf8.encode('%PDF-1.4')));
    expect(captured.url.toString(), 'http://192.168.1.10:8080/api/jobs/3/applications');
    expect(captured.headers['content-type'], startsWith('multipart/form-data'));
  });
}

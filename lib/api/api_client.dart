import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../state/session.dart';
import 'models.dart';

class ApiException implements Exception {
  final String message;

  /// Status HTTP, oppure 0 se il server non è raggiungibile.
  final int status;

  ApiException(this.message, [this.status = 0]);

  bool get isUnauthorized => status == 401;

  @override
  String toString() => message;
}

/// Client per le API del server della bacheca.
class ApiClient {
  final Session session;
  final http.Client _http;
  static const _timeout = Duration(seconds: 20);

  ApiClient(this.session, [http.Client? client]) : _http = client ?? http.Client();

  Uri _uri(String path) => Uri.parse('${session.baseUrl}/api$path');

  Map<String, String> _headers({bool json = false}) => {
        if (json) 'content-type': 'application/json',
        if (session.token != null) 'authorization': 'Bearer ${session.token}',
      };

  /// Esegue la richiesta e restituisce la risposta se lo status è 2xx,
  /// altrimenti lancia [ApiException] con il messaggio del server.
  Future<http.Response> _send(Future<http.Response> Function() request) async {
    http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on TimeoutException {
      throw ApiException('Il server non risponde. Controlla l\'indirizzo in Impostazioni.');
    } catch (_) {
      throw ApiException(
          'Impossibile contattare il server (${session.baseUrl}). Controlla l\'indirizzo in Impostazioni.');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return response;

    var message = 'Errore del server (${response.statusCode}).';
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map && body['error'] is String) message = body['error'] as String;
    } catch (_) {}

    // Token scaduto o non più valido: la sessione locale non serve più.
    if (response.statusCode == 401 && session.isLoggedIn) await session.signOut();
    throw ApiException(message, response.statusCode);
  }

  dynamic _json(http.Response r) => jsonDecode(utf8.decode(r.bodyBytes));

  Future<http.Response> _get(String path) =>
      _send(() => _http.get(_uri(path), headers: _headers()));

  Future<http.Response> _post(String path, [Map<String, dynamic>? body]) => _send(() =>
      _http.post(_uri(path), headers: _headers(json: true), body: jsonEncode(body ?? {})));

  /// Verifica che il server sia raggiungibile.
  Future<void> health() => _get('/health');

  /// R1 — crea l'account dell'azienda. Non effettua il login.
  Future<Company> register(String name, String email, String password) async {
    final r = await _post('/auth/register', {'name': name, 'email': email, 'password': password});
    return Company.fromJson(_json(r)['company'] as Map<String, dynamic>);
  }

  /// R2 — login: salva token e dati dell'azienda nella sessione.
  Future<void> login(String email, String password) async {
    final r = await _post('/auth/login', {'email': email, 'password': password});
    final data = _json(r) as Map<String, dynamic>;
    await session.signIn(
        data['token'] as String, Company.fromJson(data['company'] as Map<String, dynamic>));
  }

  /// R3 — logout: invalida il token sul server e lo cancella dal dispositivo.
  Future<void> logout() async {
    try {
      if (session.isLoggedIn) await _post('/auth/logout');
    } on ApiException {
      // Anche se il server non risponde, l'utente deve uscire comunque.
    } finally {
      await session.signOut();
    }
  }

  /// R5 — elenco annunci pubblicati.
  Future<List<Job>> jobs() async => _jobList(await _get('/jobs'));

  /// R5 — dettaglio di un annuncio.
  Future<Job> job(int id) async =>
      Job.fromJson(_json(await _get('/jobs/$id')) as Map<String, dynamic>);

  /// R4 — pubblica un annuncio.
  Future<Job> createJob({
    required String title,
    required String description,
    String location = '',
  }) async {
    final r = await _post(
        '/jobs', {'title': title, 'description': description, 'location': location});
    return Job.fromJson(_json(r) as Map<String, dynamic>);
  }

  /// R6 — invia una candidatura con il curriculum.
  Future<void> apply(
    int jobId, {
    required String firstName,
    required String lastName,
    required String email,
    String phone = '',
    required String cvFileName,
    required Uint8List cvBytes,
  }) async {
    await _send(() async {
      final request = http.MultipartRequest('POST', _uri('/jobs/$jobId/applications'))
        ..fields.addAll({
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'phone': phone,
        })
        ..files.add(http.MultipartFile.fromBytes('cv', cvBytes, filename: cvFileName));
      return http.Response.fromStream(await _http.send(request));
    });
  }

  /// R7 — annunci dell'azienda autenticata, con il numero di candidature.
  Future<List<Job>> myJobs() async => _jobList(await _get('/my/jobs'));

  /// R7 — candidature ricevute per un annuncio.
  Future<List<JobApplication>> applications(int jobId) async {
    final list = _json(await _get('/my/jobs/$jobId/applications')) as List;
    return list.map((e) => JobApplication.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// R7 — scarica il curriculum di una candidatura.
  Future<Uint8List> downloadCv(int applicationId) async =>
      (await _get('/applications/$applicationId/cv')).bodyBytes;

  List<Job> _jobList(http.Response r) =>
      (_json(r) as List).map((e) => Job.fromJson(e as Map<String, dynamic>)).toList();
}

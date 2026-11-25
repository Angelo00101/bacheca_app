import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/models.dart';

/// Stato condiviso dell'app: indirizzo del server e sessione dell'azienda.
/// Viene salvato sul dispositivo, così resta valido alla riapertura dell'app.
class Session extends ChangeNotifier {
  static const _kBaseUrl = 'base_url';
  static const _kToken = 'token';
  static const _kCompanyName = 'company_name';
  static const _kCompanyEmail = 'company_email';

  final SharedPreferences _prefs;
  String _baseUrl;
  String? _token;
  String? _companyName;
  String? _companyEmail;

  late final ApiClient api = ApiClient(this);

  Session._(this._prefs)
      : _baseUrl = _prefs.getString(_kBaseUrl) ?? defaultBaseUrl,
        _token = _prefs.getString(_kToken),
        _companyName = _prefs.getString(_kCompanyName),
        _companyEmail = _prefs.getString(_kCompanyEmail);

  static Future<Session> load() async => Session._(await SharedPreferences.getInstance());

  /// Emulatore Android: 10.0.2.2 è il computer host. Altrove: localhost.
  static String get defaultBaseUrl =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? 'http://10.0.2.2:8080'
          : 'http://localhost:8080';

  String get baseUrl => _baseUrl;
  String? get token => _token;
  String? get companyName => _companyName;
  String? get companyEmail => _companyEmail;
  bool get isLoggedIn => _token != null;

  /// Porta del server usata quando l'indirizzo inserito non ne specifica una.
  static const defaultPort = 8080;

  /// Aggiunge "http://" e la porta 8080 se mancano e toglie la "/" finale.
  static String normalizeUrl(String input) {
    var url = input.trim();
    if (url.isEmpty) return url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) url = 'http://$url';
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    final uri = Uri.tryParse(url);
    if (uri != null && uri.scheme == 'http' && uri.host.isNotEmpty && !uri.hasPort) {
      url = uri.replace(port: defaultPort).toString();
    }
    return url;
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = normalizeUrl(url);
    await _prefs.setString(_kBaseUrl, _baseUrl);
    notifyListeners();
  }

  Future<void> signIn(String token, Company company) async {
    _token = token;
    _companyName = company.name;
    _companyEmail = company.email;
    await _prefs.setString(_kToken, token);
    await _prefs.setString(_kCompanyName, company.name);
    await _prefs.setString(_kCompanyEmail, company.email);
    notifyListeners();
  }

  Future<void> signOut() async {
    _token = null;
    _companyName = null;
    _companyEmail = null;
    await _prefs.remove(_kToken);
    await _prefs.remove(_kCompanyName);
    await _prefs.remove(_kCompanyEmail);
    notifyListeners();
  }
}

/// Rende disponibile la [Session] a tutte le schermate.
class SessionScope extends InheritedNotifier<Session> {
  const SessionScope({super.key, required Session session, required super.child})
      : super(notifier: session);

  static Session of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SessionScope>()!.notifier!;

  /// Come [of], ma senza ricostruire il widget quando la sessione cambia.
  static Session read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<SessionScope>()!.notifier!;
}

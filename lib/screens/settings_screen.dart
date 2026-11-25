import 'package:material_ui/material_ui.dart';

import '../state/session.dart';
import '../widgets/common.dart';

/// Impostazioni: indirizzo del server da raggiungere.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _url;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _url = TextEditingController(text: SessionScope.read(context).baseUrl);
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _saveAndTest() async {
    final session = SessionScope.read(context);
    final url = Session.normalizeUrl(_url.text);
    if (Uri.tryParse(url)?.host.isEmpty ?? true) {
      showMessage(context, 'Indirizzo non valido.', error: true);
      return;
    }
    await session.setBaseUrl(url);
    _url.text = session.baseUrl;
    setState(() => _testing = true);
    try {
      await session.api.health();
      if (mounted) showMessage(context, 'Connessione riuscita! Indirizzo salvato.');
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Indirizzo del server', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Inserisci l\'indirizzo mostrato dal server all\'avvio, ad esempio '
            'http://192.168.1.10:8080. Telefono e computer devono essere sulla stessa rete Wi-Fi.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _url,
            decoration: const InputDecoration(
              labelText: 'Indirizzo server',
              prefixIcon: Icon(Icons.dns_outlined),
            ),
            keyboardType: TextInputType.url,
            autocorrect: false,
            onSubmitted: (_) => _saveAndTest(),
          ),
          const SizedBox(height: 16),
          BusyButton(
            label: 'Salva e verifica connessione',
            icon: Icons.wifi_tethering,
            busy: _testing,
            onPressed: _saveAndTest,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _url.text = Session.defaultBaseUrl,
            child: Text('Ripristina predefinito (${Session.defaultBaseUrl})'),
          ),
        ],
      ),
    );
  }
}

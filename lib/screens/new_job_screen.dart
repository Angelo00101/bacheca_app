import 'package:material_ui/material_ui.dart';

import '../state/session.dart';
import '../widgets/common.dart';

/// Pubblicazione di un nuovo annuncio (R4). Restituisce true se pubblicato.
class NewJobScreen extends StatefulWidget {
  const NewJobScreen({super.key});

  @override
  State<NewJobScreen> createState() => _NewJobScreenState();
}

class _NewJobScreenState extends State<NewJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_title, _location, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await SessionScope.read(context).api.createJob(
            title: _title.text.trim(),
            description: _description.text.trim(),
            location: _location.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) handleError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuovo annuncio')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Titolo *',
                hintText: 'Es. Sviluppatore Flutter junior',
              ),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              validator: requiredField('Inserisci il titolo'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'Sede (facoltativa)',
                hintText: 'Es. Salerno / Da remoto',
              ),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Descrizione *',
                hintText: 'Mansioni, requisiti, tipo di contratto…',
                alignLabelWithHint: true,
              ),
              textCapitalization: TextCapitalization.sentences,
              minLines: 6,
              maxLines: 12,
              validator: requiredField('Inserisci la descrizione'),
            ),
            const SizedBox(height: 24),
            BusyButton(
              label: 'Pubblica annuncio',
              icon: Icons.publish,
              busy: _busy,
              onPressed: _publish,
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../api/models.dart';
import '../state/session.dart';
import '../widgets/common.dart';

const _maxCvBytes = 10 * 1024 * 1024;

/// Form di candidatura del candidato (R6).
class ApplyScreen extends StatefulWidget {
  final Job job;

  const ApplyScreen({super.key, required this.job});

  @override
  State<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends State<ApplyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  String? _cvName;
  Uint8List? _cvBytes;
  bool _cvMissing = false;
  bool _sending = false;

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _email, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickCv() async {
    try {
      final files = await FilePicker.pickFiles(
        dialogTitle: 'Seleziona il curriculum (PDF)',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (files.isEmpty) return;
      final file = files.first;
      if (!file.name.toLowerCase().endsWith('.pdf')) {
        if (mounted) showMessage(context, 'Seleziona un file PDF.', error: true);
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.length > _maxCvBytes) {
        showMessage(context, 'Il file supera i 10 MB.', error: true);
        return;
      }
      setState(() {
        _cvName = file.name;
        _cvBytes = bytes;
        _cvMissing = false;
      });
    } catch (e) {
      if (mounted) showMessage(context, 'Impossibile leggere il file selezionato.', error: true);
    }
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState!.validate();
    setState(() => _cvMissing = _cvBytes == null);
    if (!formOk || _cvBytes == null) return;

    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    try {
      await SessionScope.read(context).api.apply(
            widget.job.id,
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            email: _email.text.trim(),
            phone: _phone.text.trim(),
            cvFileName: _cvName!,
            cvBytes: _cvBytes!,
          );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text('Candidatura inviata'),
          content: Text(
              'Grazie ${_firstName.text.trim()}! La tua candidatura per "${widget.job.title}" '
              'è stata registrata e verrà valutata da ${widget.job.companyName}.'),
          actions: [
            FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Candidatura')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(widget.job.title, style: theme.textTheme.titleLarge),
            Text(widget.job.companyName, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            TextFormField(
              controller: _firstName,
              decoration: const InputDecoration(labelText: 'Nome *'),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: requiredField('Inserisci il nome'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastName,
              decoration: const InputDecoration(labelText: 'Cognome *'),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: requiredField('Inserisci il cognome'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email *'),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              validator: validateEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Telefono (facoltativo)'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            Text('Curriculum *', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Card(
              color: _cvMissing ? theme.colorScheme.errorContainer : null,
              child: ListTile(
                leading: Icon(
                  _cvBytes == null ? Icons.upload_file : Icons.picture_as_pdf,
                  color: _cvBytes == null ? null : Colors.red.shade700,
                ),
                title: Text(_cvName ?? 'Nessun file selezionato'),
                subtitle: Text(_cvBytes == null
                    ? (_cvMissing ? 'Allega il curriculum per continuare' : 'Formato PDF, max 10 MB')
                    : '${(_cvBytes!.length / 1024).ceil()} KB'),
                trailing: TextButton(
                  onPressed: _sending ? null : _pickCv,
                  child: Text(_cvBytes == null ? 'Allega CV' : 'Cambia'),
                ),
                onTap: _sending ? null : _pickCv,
              ),
            ),
            const SizedBox(height: 32),
            BusyButton(
              label: 'Invia candidatura',
              icon: Icons.send,
              busy: _sending,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

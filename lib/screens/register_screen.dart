import 'package:material_ui/material_ui.dart';

import '../state/session.dart';
import '../widgets/common.dart';

/// Registrazione dell'azienda (R1). Al termine torna al login con l'email.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final company = await SessionScope.read(context)
          .api
          .register(_name.text.trim(), _email.text.trim(), _password.text);
      if (mounted) Navigator.of(context).pop(company.email);
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrazione azienda')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Nome azienda',
                prefixIcon: Icon(Icons.business),
              ),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: requiredField('Inserisci il nome dell\'azienda'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              validator: validateEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              decoration: const InputDecoration(
                labelText: 'Password',
                helperText: 'Almeno 6 caratteri',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v ?? '').length < 6 ? 'La password deve avere almeno 6 caratteri' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirm,
              decoration: const InputDecoration(
                labelText: 'Conferma password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
              onFieldSubmitted: (_) => _register(),
              validator: (v) => v != _password.text ? 'Le password non coincidono' : null,
            ),
            const SizedBox(height: 24),
            BusyButton(
              label: 'Crea account',
              icon: Icons.person_add_alt_1,
              busy: _busy,
              onPressed: _register,
            ),
          ],
        ),
      ),
    );
  }
}

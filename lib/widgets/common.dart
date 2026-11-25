import 'package:material_ui/material_ui.dart';

import '../api/api_client.dart';

void showMessage(BuildContext context, String message, {bool error = false}) {
  final scheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? scheme.error : null,
      behavior: SnackBarBehavior.floating,
    ));
}

String errorText(Object error) =>
    error is ApiException ? error.message : 'Si è verificato un errore imprevisto.';

/// Se la sessione è scaduta torna alla bacheca, altrimenti mostra l'errore.
void handleError(BuildContext context, Object error) {
  if (error is ApiException && error.isUnauthorized) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
  showMessage(context, errorText(error), error: true);
}

/// Messaggio a tutta pagina con pulsante "Riprova".
class MessageView extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;
  final Widget? extra;

  const MessageView({
    super.key,
    required this.icon,
    required this.message,
    this.onRetry,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ListView per permettere il pull-to-refresh anche quando la lista è vuota.
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 48),
        Icon(icon, size: 64, color: theme.colorScheme.outline),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
            ),
          ),
        ],
        if (extra != null) ...[const SizedBox(height: 8), Center(child: extra)],
      ],
    );
  }
}

/// Pulsante principale che mostra un indicatore di caricamento.
class BusyButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool busy;
  final VoidCallback onPressed;

  const BusyButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      onPressed: busy ? null : onPressed,
      icon: busy
          ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(icon ?? Icons.check),
      label: Text(label),
    );
  }
}

/// Riga "etichetta: valore" usata nei dettagli.
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoRow({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(label, style: theme.textTheme.labelMedium),
      subtitle: SelectableText(value, style: theme.textTheme.bodyLarge),
    );
  }
}

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Inserisci l\'email';
  if (!_emailRe.hasMatch(v)) return 'Email non valida';
  return null;
}

String? Function(String?) requiredField(String message) =>
    (value) => (value?.trim().isEmpty ?? true) ? message : null;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../api/models.dart';
import '../state/session.dart';
import '../widgets/common.dart';

/// Dati del candidato e apertura del curriculum (R7).
class ApplicationDetailScreen extends StatefulWidget {
  final JobApplication application;
  final Job job;

  const ApplicationDetailScreen({super.key, required this.application, required this.job});

  @override
  State<ApplicationDetailScreen> createState() => _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  bool _opening = false;

  Future<void> _openCv() async {
    if (kIsWeb) {
      showMessage(context, 'L\'apertura del curriculum è disponibile nell\'app per smartphone.');
      return;
    }
    setState(() => _opening = true);
    try {
      final bytes = await SessionScope.read(context).api.downloadCv(widget.application.id);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}cv_${widget.application.id}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      final result = await OpenFilex.open(file.path, type: 'application/pdf');
      if (!mounted) return;
      if (result.type == ResultType.noAppToOpen) {
        showMessage(context, 'Nessuna app per aprire i PDF è installata sul dispositivo.',
            error: true);
      } else if (result.type != ResultType.done) {
        showMessage(context, 'Impossibile aprire il curriculum: ${result.message}', error: true);
      }
    } catch (e) {
      if (mounted) handleError(context, e);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.application;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Candidatura')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(a.fullName, style: theme.textTheme.headlineSmall),
          Text('Candidato per: ${widget.job.title}', style: theme.textTheme.bodyMedium),
          const Divider(height: 32),
          InfoRow(icon: Icons.person_outline, label: 'Nome', value: a.firstName),
          InfoRow(icon: Icons.badge_outlined, label: 'Cognome', value: a.lastName),
          InfoRow(icon: Icons.email_outlined, label: 'Email', value: a.email),
          if (a.phone.isNotEmpty)
            InfoRow(icon: Icons.phone_outlined, label: 'Telefono', value: a.phone),
          InfoRow(
            icon: Icons.schedule,
            label: 'Ricevuta il',
            value: formatDateTime(a.createdAt),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(Icons.picture_as_pdf, color: Colors.red.shade700, size: 36),
              title: const Text('Curriculum allegato'),
              subtitle: Text(a.cvOriginalName),
            ),
          ),
          const SizedBox(height: 16),
          BusyButton(
            label: 'Apri curriculum',
            icon: Icons.open_in_new,
            busy: _opening,
            onPressed: _openCv,
          ),
        ],
      ),
    );
  }
}

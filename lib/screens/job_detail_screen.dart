import 'package:material_ui/material_ui.dart';

import '../api/models.dart';
import '../state/session.dart';
import '../widgets/common.dart';
import 'apply_screen.dart';

/// Dettaglio di un annuncio (R5) con il pulsante per candidarsi (R6).
class JobDetailScreen extends StatefulWidget {
  final int jobId;

  const JobDetailScreen({super.key, required this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  Job? _job;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final job = await SessionScope.read(context).api.job(widget.jobId);
      if (mounted) setState(() => _job = job);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = _job;
    return Scaffold(
      appBar: AppBar(title: const Text('Dettaglio annuncio')),
      body: job == null
          ? (_error == null
              ? const Center(child: CircularProgressIndicator())
              : MessageView(icon: Icons.error_outline, message: _error!, onRetry: _load))
          : _details(job),
      bottomNavigationBar: job == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.all(16),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                icon: const Icon(Icons.send),
                label: const Text('Candidati'),
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => ApplyScreen(job: job))),
              ),
            ),
    );
  }

  Widget _details(Job job) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(job.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(avatar: const Icon(Icons.business, size: 18), label: Text(job.companyName)),
            if (job.location.isNotEmpty)
              Chip(avatar: const Icon(Icons.place_outlined, size: 18), label: Text(job.location)),
            if (job.createdAt != null)
              Chip(
                avatar: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text('Pubblicato il ${formatDate(job.createdAt)}'),
              ),
          ],
        ),
        const Divider(height: 32),
        Text('Descrizione', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SelectableText(job.description, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}

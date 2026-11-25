import 'package:material_ui/material_ui.dart';

import '../api/models.dart';
import '../state/session.dart';
import '../widgets/common.dart';
import 'application_detail_screen.dart';

/// Candidature ricevute per un annuncio dell'azienda (R7).
class JobApplicationsScreen extends StatefulWidget {
  final Job job;

  const JobApplicationsScreen({super.key, required this.job});

  @override
  State<JobApplicationsScreen> createState() => _JobApplicationsScreenState();
}

class _JobApplicationsScreenState extends State<JobApplicationsScreen> {
  List<JobApplication>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final items = await SessionScope.read(context).api.applications(widget.job.id);
      if (mounted) {
        setState(() {
          _items = items;
          _error = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = errorText(e));
      handleError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Candidature ricevute'),
            Text(widget.job.title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      body: RefreshIndicator(onRefresh: _load, child: _body()),
    );
  }

  Widget _body() {
    final items = _items;
    if (items == null) {
      return _error == null
          ? const Center(child: CircularProgressIndicator())
          : MessageView(icon: Icons.cloud_off, message: _error!, onRetry: _load);
    }
    if (items.isEmpty) {
      return const MessageView(
        icon: Icons.inbox_outlined,
        message: 'Nessuna candidatura ricevuta per questo annuncio.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final a = items[i];
        final initials =
            '${a.firstName.isEmpty ? '' : a.firstName[0]}${a.lastName.isEmpty ? '' : a.lastName[0]}'
                .toUpperCase();
        return ListTile(
          leading: CircleAvatar(child: Text(initials)),
          title: Text(a.fullName),
          subtitle: Text('${a.email}\nRicevuta il ${formatDateTime(a.createdAt)}'),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ApplicationDetailScreen(application: a, job: widget.job))),
        );
      },
    );
  }
}

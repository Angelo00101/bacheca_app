import 'package:material_ui/material_ui.dart';

import '../api/models.dart';
import '../state/session.dart';
import '../widgets/common.dart';
import 'board_screen.dart';
import 'job_applications_screen.dart';
import 'new_job_screen.dart';

/// Area riservata dell'azienda: i propri annunci, nuovo annuncio, logout.
class CompanyHomeScreen extends StatefulWidget {
  const CompanyHomeScreen({super.key});

  @override
  State<CompanyHomeScreen> createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends State<CompanyHomeScreen> {
  List<Job>? _jobs;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final jobs = await SessionScope.read(context).api.myJobs();
      if (mounted) {
        setState(() {
          _jobs = jobs;
          _error = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = errorText(e));
      handleError(context, e);
    }
  }

  Future<void> _newJob() async {
    final created = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const NewJobScreen()));
    if (created == true && mounted) {
      showMessage(context, 'Annuncio pubblicato in bacheca.');
      _load();
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vuoi uscire?'),
        content: const Text('Dovrai accedere di nuovo per gestire i tuoi annunci.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Esci')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await SessionScope.read(context).api.logout();
    navigator.popUntil((route) => route.isFirst);
    messenger.showSnackBar(const SnackBar(
      content: Text('Sei uscito dall\'area riservata.'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Area riservata'),
            if (session.companyName != null)
              Text(session.companyName!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Esci'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newJob,
        icon: const Icon(Icons.add),
        label: const Text('Nuovo annuncio'),
      ),
      body: RefreshIndicator(onRefresh: _load, child: _body()),
    );
  }

  Widget _body() {
    final jobs = _jobs;
    if (jobs == null) {
      return _error == null
          ? const Center(child: CircularProgressIndicator())
          : MessageView(icon: Icons.cloud_off, message: _error!, onRetry: _load);
    }
    if (jobs.isEmpty) {
      return const MessageView(
        icon: Icons.post_add,
        message: 'Non hai ancora pubblicato annunci.\nTocca "Nuovo annuncio" per iniziare.',
      );
    }
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      itemCount: jobs.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.all(4),
            child: Text('I miei annunci', style: theme.textTheme.titleMedium),
          );
        }
        final job = jobs[i - 1];
        final count = job.applicationsCount ?? 0;
        return JobCard(
          job: job,
          trailing: Badge.count(
            count: count,
            isLabelVisible: count > 0,
            child: const Icon(Icons.people_outline),
          ),
          onTap: () async {
            await Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => JobApplicationsScreen(job: job)));
            if (mounted) _load();
          },
        );
      },
    );
  }
}

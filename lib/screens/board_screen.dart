import 'package:material_ui/material_ui.dart';

import '../api/models.dart';
import '../navigation.dart';
import '../state/session.dart';
import '../widgets/common.dart';
import 'company_home_screen.dart';
import 'job_detail_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

/// Schermata pubblica: elenco degli annunci pubblicati (R5).
class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> with RouteAware {
  List<Job>? _jobs;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// La bacheca torna visibile (es. dopo aver pubblicato un annuncio): si aggiorna.
  @override
  void didPopNext() => _load();

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final jobs = await SessionScope.read(context).api.jobs();
      if (!mounted) return;
      setState(() {
        _jobs = jobs;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _open(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bacheca Lavoro'),
        actions: [
          IconButton(
            tooltip: 'Impostazioni',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _open(const SettingsScreen()),
          ),
        ],
      ),
      // Accesso all'area aziende: login se non autenticati, area riservata altrimenti.
      floatingActionButton: session.isLoggedIn
          ? FloatingActionButton.extended(
              heroTag: 'company',
              onPressed: () => _open(const CompanyHomeScreen()),
              icon: const Icon(Icons.business),
              label: const Text('Area riservata'),
            )
          : FloatingActionButton.extended(
              heroTag: 'company',
              onPressed: () => _open(const LoginScreen()),
              icon: const Icon(Icons.login),
              label: const Text('Area aziende'),
            ),
      body: RefreshIndicator(onRefresh: _load, child: _body()),
    );
  }

  Widget _body() {
    if (_jobs == null && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && (_jobs == null || _jobs!.isEmpty)) {
      return MessageView(
        icon: Icons.cloud_off,
        message: _error!,
        onRetry: _loading ? null : _load,
        extra: TextButton(
          onPressed: () => _open(const SettingsScreen()),
          child: const Text('Apri Impostazioni'),
        ),
      );
    }
    final jobs = _jobs!;
    if (jobs.isEmpty) {
      return const MessageView(
        icon: Icons.work_off_outlined,
        message: 'Non ci sono ancora annunci pubblicati.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      itemCount: jobs.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              jobs.length == 1 ? '1 annuncio disponibile' : '${jobs.length} annunci disponibili',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          );
        }
        final job = jobs[i - 1];
        return JobCard(job: job, onTap: () => _open(JobDetailScreen(jobId: job.id)));
      },
    );
  }
}

class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  final Widget? trailing;

  const JobCard({super.key, required this.job, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [
      job.companyName,
      if (job.location.isNotEmpty) job.location,
      formatDate(job.createdAt),
    ].where((s) => s.isNotEmpty).join(' · ');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.work_outline, color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    Text(
                      job.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              trailing ?? const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

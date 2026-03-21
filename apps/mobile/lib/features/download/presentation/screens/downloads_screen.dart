import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musio/shared/utils/app_toast.dart';

import '../providers/download_session_provider.dart';
import '../widgets/active_downloads_section.dart';

/// Page dédiée : téléchargements en cours (file + pause) et historique.
class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    listenDownloadSessionBanner(context, ref);

    final session = ref.watch(downloadSessionProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Téléchargements'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('En cours'),
                  if (session.activeTasks.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${session.activeTasks.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Historique'),
                  if (session.history.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${session.history.length}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ActiveDownloadsTab(session: session),
          _HistoryTab(session: session),
        ],
      ),
    );
  }
}

class _ActiveDownloadsTab extends ConsumerWidget {
  const _ActiveDownloadsTab({required this.session});

  final DownloadSessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (session.activeTasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.download_done_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun téléchargement en cours',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Ajoute des morceaux ou albums depuis Découvrir.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: session.activeTasks.length,
      itemBuilder: (context, i) {
        final t = session.activeTasks[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DownloadActiveTaskCard(task: t),
        );
      },
    );
  }
}

/// Carte tâche active (partagée logique avec l’ancienne section).
class DownloadActiveTaskCard extends ConsumerWidget {
  const DownloadActiveTaskCard({required this.task, super.key});

  final DownloadSessionTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final notifier = ref.read(downloadSessionProvider.notifier);

    final statusLabel = _statusLabel(task.status);
    final showBar = task.status == DownloadTaskUiStatus.downloading ||
        task.status == DownloadTaskUiStatus.paused;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  task.item.isAlbum ? Icons.album_rounded : Icons.music_note_rounded,
                  size: 24,
                  color: scheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        task.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _ActiveTaskActions(task: task, notifier: notifier),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
            if (showBar) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: task.status == DownloadTaskUiStatus.downloading && task.progress <= 0
                      ? null
                      : task.progress.clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
              if (task.progress > 0 && task.progress < 1)
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${(task.progress * 100).round()}%',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  static String _statusLabel(DownloadTaskUiStatus s) {
    switch (s) {
      case DownloadTaskUiStatus.queued:
        return 'En attente';
      case DownloadTaskUiStatus.downloading:
        return 'En cours';
      case DownloadTaskUiStatus.paused:
        return 'En pause';
      case DownloadTaskUiStatus.completed:
        return 'Terminé';
      case DownloadTaskUiStatus.failed:
        return 'Échec';
      case DownloadTaskUiStatus.cancelled:
        return 'Annulé';
    }
  }
}

class _ActiveTaskActions extends StatelessWidget {
  const _ActiveTaskActions({
    required this.task,
    required this.notifier,
  });

  final DownloadSessionTask task;
  final DownloadSessionNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget b(IconData i, String tip, VoidCallback? on) {
      return Tooltip(
        message: tip,
        child: IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: Icon(i, size: 22),
          color: scheme.onSurfaceVariant,
          onPressed: on,
        ),
      );
    }

    switch (task.status) {
      case DownloadTaskUiStatus.downloading:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            b(Icons.pause_rounded, 'Pause', () => notifier.pauseTask(task.id)),
            b(Icons.close_rounded, 'Annuler', () => notifier.cancelTask(task.id)),
          ],
        );
      case DownloadTaskUiStatus.paused:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            b(Icons.play_arrow_rounded, 'Reprendre', () => notifier.resumeTask(task.id)),
            b(Icons.delete_outline_rounded, 'Retirer', () => notifier.removeTask(task.id)),
          ],
        );
      case DownloadTaskUiStatus.queued:
        return b(Icons.close_rounded, 'Retirer de la file', () => notifier.cancelTask(task.id));
      case DownloadTaskUiStatus.completed:
      case DownloadTaskUiStatus.failed:
      case DownloadTaskUiStatus.cancelled:
        return const SizedBox.shrink();
    }
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab({required this.session});

  final DownloadSessionState session;

  String _formatTime(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year} $h:$m';
  }

  String _outcomeLabel(DownloadTaskUiStatus o) {
    switch (o) {
      case DownloadTaskUiStatus.completed:
        return 'Réussi';
      case DownloadTaskUiStatus.failed:
        return 'Échec';
      case DownloadTaskUiStatus.cancelled:
        return 'Annulé';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final notifier = ref.read(downloadSessionProvider.notifier);

    if (session.history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'L’historique des téléchargements apparaîtra ici.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (session.history.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Vider l’historique ?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Non')),
                      FilledButton(
                        onPressed: () {
                          notifier.clearHistory();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Vider'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Tout effacer'),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: session.history.length,
            itemBuilder: (context, i) {
              final e = session.history[i];
              final ok = e.outcome == DownloadTaskUiStatus.completed;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              e.isAlbum ? Icons.album_rounded : Icons.music_note_rounded,
                              size: 22,
                              color: ok ? scheme.primary : scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  Text(
                                    e.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(e.at),
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: scheme.outline,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Supprimer',
                                  icon: const Icon(Icons.delete_outline_rounded, size: 22),
                                  onPressed: () => notifier.removeHistoryEntry(e.id),
                                ),
                                IconButton(
                                  tooltip: 'Relancer',
                                  icon: Icon(Icons.replay_rounded, size: 22, color: scheme.primary),
                                  onPressed: () => notifier.retryFromHistory(e),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Chip(
                              label: Text(_outcomeLabel(e.outcome)),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: ok
                                  ? scheme.primaryContainer.withValues(alpha: 0.5)
                                  : scheme.errorContainer.withValues(alpha: 0.35),
                            ),
                            if (e.trackCount != null && e.trackCount! > 1)
                              Chip(
                                label: Text('${e.trackCount} pistes'),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                        if (e.errorMessage != null && e.errorMessage!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              e.errorMessage!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.error,
                                  ),
                            ),
                          ),
                        if (ok && e.filePath != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: e.filePath!));
                                AppToast.showCopied(context);
                              },
                              icon: const Icon(Icons.copy_rounded, size: 18),
                              label: const Text('Copier le chemin'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

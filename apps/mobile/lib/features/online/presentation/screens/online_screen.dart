import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musio/core/routing/app_router.dart';
import 'package:musio/features/download/data/models/deezer_search_result.dart';
import 'package:musio/features/download/data/telegramusic_api_client.dart';
import 'package:musio/features/download/presentation/providers/download_provider.dart';
import 'package:musio/features/download/presentation/providers/download_session_provider.dart';
import 'package:musio/features/download/presentation/widgets/active_downloads_section.dart';
import 'package:musio/shared/widgets/mini_player.dart';

/// Écran « Découvrir » — recherche Deezer + téléchargement (design LKM unifié).
class OnlineScreen extends ConsumerStatefulWidget {
  const OnlineScreen({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  ConsumerState<OnlineScreen> createState() => _OnlineScreenState();
}

class _OnlineScreenState extends ConsumerState<OnlineScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  static const double _albumArt = 124;
  static const double _albumStripHeight = 196;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    listenDownloadSessionBanner(context, ref);

    final searchState = ref.watch(onlineSearchStateProvider);
    final apiClient = ref.watch(downloadApiClientProvider);
    final downloadingTrackId = ref.watch(downloadingTrackIdProvider);
    final downloadingAlbumId = ref.watch(downloadingAlbumIdProvider);
    final downloadProgress = ref.watch(downloadProgressProvider);

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => context.pop(),
              )
            : null,
        automaticallyImplyLeading: widget.showBackButton,
        title: Text(
          'Découvrir',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final n = ref.watch(downloadSessionProvider).activeTasks.length;
              final label = n > 99 ? '99+' : '$n';
              return IconButton(
                tooltip: 'Téléchargements${n > 0 ? ' ($n)' : ''}',
                onPressed: () => context.push(AppRouter.downloads),
                // Le badge doit envelopper l’icône (pas tout le bouton) pour un placement correct en AppBar.
                icon: Badge(
                  isLabelVisible: n > 0,
                  label: Text(
                    label,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, height: 1),
                  ),
                  padding: n > 9
                      ? const EdgeInsets.symmetric(horizontal: 5, vertical: 2)
                      : const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: const Icon(Icons.downloading_rounded),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _SearchBar(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: () => setState(() {}),
              onClear: () {
                _searchController.clear();
                ref.read(onlineSearchStateProvider.notifier).clear();
                setState(() {});
              },
              onSubmit: (value) {
                if (value.trim().isNotEmpty) {
                  ref.read(onlineSearchStateProvider.notifier).search(value.trim());
                }
              },
            ),
          ),
        ),
      ),
      body: _buildBody(
        context,
        ref,
        apiClient,
        searchState,
        downloadingTrackId,
        downloadingAlbumId,
        downloadProgress,
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    TelegramusicApiClient? apiClient,
    OnlineSearchState searchState,
    String? downloadingTrackId,
    String? downloadingAlbumId,
    double? downloadProgress,
  ) {
    if (apiClient == null || !apiClient.isConfigured) {
      return _StatePage(
        icon: Icons.cloud_off_rounded,
        iconGradient: true,
        title: 'Connexion au serveur',
        subtitle:
            'Dans Paramètres, renseignez l’URL du serveur de téléchargement (ex. l’API Telegramusic).',
      );
    }

    if (searchState.isLoading) {
      return const _StatePage(
        icon: Icons.hourglass_top_rounded,
        title: 'Recherche…',
        subtitle: 'Interrogation de Deezer',
        showProgress: true,
      );
    }

    if (searchState.error != null) {
      return _StatePage(
        icon: Icons.wifi_tethering_error_rounded,
        title: 'Impossible de chercher',
        subtitle: searchState.error!,
        isError: true,
      );
    }

    if (searchState.results.isEmpty && searchState.albumResults.isEmpty) {
      final session = ref.watch(downloadSessionProvider);
      if (session.hasActiveWork) {
        return CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 120),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.downloading_rounded,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.65),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Téléchargements en cours',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ouvre la file pour mettre en pause, annuler ou voir l’historique.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.tonalIcon(
                      onPressed: () => context.push(AppRouter.downloads),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Voir les téléchargements'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ou lance une recherche pour ajouter d’autres titres.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }
      return _StatePage(
        icon: Icons.explore_rounded,
        iconGradient: true,
        title: 'Trouve ta musique',
        subtitle: 'Tape un titre, un artiste ou un album puis valide avec Entrée.',
      );
    }

    final tracks = searchState.results.where((r) => r.isTrack).toList();
    final albums = searchState.albumResults.where((r) => r.isAlbum).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        if (albums.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionTitle(
              label: 'Albums',
              count: albums.length,
              icon: Icons.album_rounded,
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: _albumStripHeight,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                scrollDirection: Axis.horizontal,
                itemCount: albums.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final album = albums[index];
                  final isDl = downloadingAlbumId == album.id;
                  return _AlbumCard(
                    album: album,
                    artSize: _albumArt,
                    isDownloading: isDl,
                    progress: isDl ? downloadProgress : null,
                    onOpenDetails: () => _openAlbumTracksSheet(context, ref, apiClient, album),
                    onDownloadAlbum: () => _downloadAlbum(context, album),
                  );
                },
              ),
            ),
          ),
        ],
        if (tracks.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: albums.isNotEmpty ? 8 : 16),
              child: _SectionTitle(
                label: 'Morceaux',
                count: tracks.length,
                icon: Icons.music_note_rounded,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            sliver: SliverList.separated(
              itemCount: tracks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final track = tracks[index];
                final isDl = downloadingTrackId == track.id;
                return _TrackCard(
                  track: track,
                  isDownloading: isDl,
                  progress: isDl ? downloadProgress : null,
                  onDownload: () => _downloadTrack(context, track),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _downloadTrack(BuildContext context, DeezerSearchResult track) async {
    await ref.read(downloadSessionProvider.notifier).enqueue(track);
  }

  Future<void> _downloadAlbum(BuildContext context, DeezerSearchResult album) async {
    await ref.read(downloadSessionProvider.notifier).enqueue(album);
  }

  void _openAlbumTracksSheet(
    BuildContext context,
    WidgetRef ref,
    TelegramusicApiClient client,
    DeezerSearchResult album,
  ) {
    final tracksFuture = client.albumTracks(album.id);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.68,
          minChildSize: 0.35,
          maxChildSize: 0.94,
          expand: false,
          builder: (ctx, scrollController) {
            final scheme = Theme.of(ctx).colorScheme;
            final textTheme = Theme.of(ctx).textTheme;
            return DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 76,
                            height: 76,
                            child: album.imgUrl != null && album.imgUrl!.isNotEmpty
                                ? Image.network(
                                    album.imgUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _AlbumPlaceholder(scheme: scheme),
                                  )
                                : _AlbumPlaceholder(scheme: scheme),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                album.displayTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                album.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 10),
                              FilledButton.tonalIcon(
                                onPressed: () {
                                  Navigator.of(sheetContext).pop();
                                  _downloadAlbum(context, album);
                                },
                                icon: const Icon(Icons.folder_zip_rounded, size: 20),
                                label: const Text('Télécharger l’album (ZIP)'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.35)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                    child: Text(
                      'Pistes',
                      style: textTheme.labelLarge?.copyWith(
                        letterSpacing: 0.6,
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<List<DeezerSearchResult>>(
                      future: tracksFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(28),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                '${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: textTheme.bodyMedium?.copyWith(color: scheme.error),
                              ),
                            ),
                          );
                        }
                        final tracks = snapshot.data ?? [];
                        if (tracks.isEmpty) {
                          return Center(
                            child: Text(
                              'Aucune piste',
                              style: textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }
                        return Consumer(
                          builder: (context, ref, _) {
                            final downloadingTrackId = ref.watch(downloadingTrackIdProvider);
                            final dlProgress = ref.watch(downloadProgressProvider);
                            return ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 28),
                              itemCount: tracks.length,
                              itemBuilder: (context, i) {
                                final track = tracks[i];
                                final isDl = downloadingTrackId == track.id;
                                return _AlbumTrackSheetRow(
                                  track: track,
                                  isDownloading: isDl,
                                  progress: isDl ? dlProgress : null,
                                  onDownload: () {
                                    ref.read(downloadSessionProvider.notifier).enqueue(track);
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Ligne piste dans la bottom sheet album.
class _AlbumTrackSheetRow extends StatelessWidget {
  const _AlbumTrackSheetRow({
    required this.track,
    required this.isDownloading,
    required this.progress,
    required this.onDownload,
  });

  final DeezerSearchResult track;
  final bool isDownloading;
  final double? progress;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final p = progress?.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: isDownloading ? null : onDownload,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: track.imgUrl != null && track.imgUrl!.isNotEmpty
                        ? Image.network(
                            track.imgUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _TrackThumbMini(scheme: scheme),
                          )
                        : _TrackThumbMini(scheme: scheme),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      if (isDownloading) ...[
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: p != null && p > 0 ? p : null,
                            minHeight: 4,
                            backgroundColor: scheme.surfaceContainerHighest,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isDownloading)
                  IconButton.filledTonal(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: scheme.primaryContainer.withValues(alpha: 0.65),
                    ),
                  )
                else
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: p != null && p > 0
                          ? Text(
                              '${(p * 100).round()}%',
                              style: textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.primary,
                              ),
                            )
                          : const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackThumbMini extends StatelessWidget {
  const _TrackThumbMini({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Icon(Icons.music_note_rounded, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
    );
  }
}

// ——— Barre de recherche ———

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onChanged;
  final VoidCallback onClear;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: TextInputAction.search,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Artiste, morceau ou album…',
            hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.65)),
            prefixIcon: Icon(Icons.search_rounded, color: scheme.primary, size: 26),
            suffixIcon: value.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded, color: scheme.onSurfaceVariant),
                    onPressed: onClear,
                  )
                : null,
            filled: true,
            fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.35)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: scheme.primary, width: 2),
            ),
          ),
          onChanged: (_) => onChanged(),
          onSubmitted: onSubmit,
        );
      },
    );
  }
}

// ——— Section ———

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.label,
    required this.count,
    required this.icon,
  });

  final String label;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Text(
              '$count',
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ——— Album ———

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({
    required this.album,
    required this.artSize,
    required this.isDownloading,
    required this.progress,
    required this.onOpenDetails,
    required this.onDownloadAlbum,
  });

  final DeezerSearchResult album;
  final double artSize;
  final bool isDownloading;
  final double? progress;
  final VoidCallback onOpenDetails;
  final VoidCallback onDownloadAlbum;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final p = progress?.clamp(0.0, 1.0);

    return SizedBox(
      width: artSize + 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            child: InkWell(
              onTap: isDownloading ? null : onOpenDetails,
              child: SizedBox(
                width: artSize + 8,
                height: artSize + 8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: album.imgUrl != null && album.imgUrl!.isNotEmpty
                              ? Image.network(
                                  album.imgUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _AlbumPlaceholder(scheme: scheme),
                                )
                              : _AlbumPlaceholder(scheme: scheme),
                        ),
                      ),
                    ),
                    if (isDownloading)
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: ColoredBox(
                              color: Colors.black.withValues(alpha: 0.45),
                              child: Center(
                                child: Text(
                                  p != null && p > 0 ? '${(p * 100).round()}%' : '…',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (isDownloading)
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 14,
                        child: _LinearDownloadBar(progress: p, brightTrack: true),
                      ),
                    if (!isDownloading)
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Material(
                          color: scheme.primary,
                          shape: const CircleBorder(),
                          elevation: 3,
                          shadowColor: Colors.black38,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onDownloadAlbum,
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(Icons.download_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            album.displayTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            album.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumPlaceholder extends StatelessWidget {
  const _AlbumPlaceholder({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.album_rounded, size: 44, color: scheme.onSurfaceVariant.withValues(alpha: 0.45)),
      ),
    );
  }
}

// ——— Morceau ———

class _TrackCard extends StatelessWidget {
  const _TrackCard({
    required this.track,
    required this.isDownloading,
    required this.progress,
    required this.onDownload,
  });

  final DeezerSearchResult track;
  final bool isDownloading;
  final double? progress;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final p = progress?.clamp(0.0, 1.0);

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isDownloading ? null : onDownload,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                ),
                clipBehavior: Clip.antiAlias,
                child: track.imgUrl != null && track.imgUrl!.isNotEmpty
                    ? Image.network(
                        track.imgUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _TrackThumbFallback(scheme: scheme),
                      )
                    : _TrackThumbFallback(scheme: scheme),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    if (isDownloading) ...[
                      const SizedBox(height: 8),
                      _LinearDownloadBar(progress: p, brightTrack: false),
                      if (p != null && p > 0)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${(p * 100).round()}%',
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
              if (!isDownloading)
                IconButton.filledTonal(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download_rounded, size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: scheme.primaryContainer.withValues(alpha: 0.65),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackThumbFallback extends StatelessWidget {
  const _TrackThumbFallback({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Icon(Icons.music_note_rounded, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
    );
  }
}

// ——— Progress ———

class _LinearDownloadBar extends StatelessWidget {
  const _LinearDownloadBar({required this.progress, required this.brightTrack});

  final double? progress;
  final bool brightTrack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = progress;
    final bg = brightTrack ? Colors.white24 : scheme.surfaceContainerHighest;
    final fg = brightTrack ? scheme.primaryContainer : scheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 5,
        child: p == null || p <= 0
            ? LinearProgressIndicator(minHeight: 5, backgroundColor: bg, color: fg)
            : LinearProgressIndicator(
                value: p,
                minHeight: 5,
                backgroundColor: bg,
                color: fg,
              ),
      ),
    );
  }
}

// ——— États vides / erreur ———

class _StatePage extends StatelessWidget {
  const _StatePage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconGradient = false,
    this.isError = false,
    this.showProgress = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool iconGradient;
  final bool isError;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconGradient)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary.withValues(alpha: 0.25),
                      scheme.tertiary.withValues(alpha: 0.2),
                    ],
                  ),
                ),
                child: Icon(icon, size: 52, color: scheme.primary),
              )
            else
              Icon(
                icon,
                size: 56,
                color: isError ? scheme.error : scheme.onSurfaceVariant.withValues(alpha: 0.75),
              ),
            const SizedBox(height: 24),
            Text(
              title,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
            if (showProgress) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: scheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

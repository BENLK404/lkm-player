import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musio/features/download/data/models/deezer_search_result.dart';
import 'package:musio/features/download/data/telegramusic_api_client.dart';
import 'package:musio/features/download/presentation/providers/download_provider.dart';
import 'package:musio/shared/utils/app_toast.dart';
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
    TelegramusicApiClient? apiClient,
    OnlineSearchState searchState,
    String? downloadingTrackId,
    String? downloadingAlbumId,
    double? downloadProgress,
  ) {
    if (apiClient == null || !apiClient.isConfigured) {
      return const _StatePage(
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
      return const _StatePage(
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
                    onDownload: () => _downloadAlbum(context, album),
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
    final result = await downloadTrackAndAddToLibrary(ref, track);
    if (!context.mounted) return;
    if (result.isSuccess && result.filePath != null) {
      final filePath = result.filePath!;
      AppToast.showSuccess(
        context,
        message: '« ${track.title} » ajouté',
        actionLabel: 'Copier',
        onAction: () {
          Clipboard.setData(ClipboardData(text: filePath));
          if (context.mounted) AppToast.showCopied(context);
        },
      );
    } else {
      AppToast.showError(context, result.error ?? 'Échec du téléchargement');
    }
  }

  Future<void> _downloadAlbum(BuildContext context, DeezerSearchResult album) async {
    final result = await downloadAlbumAndAddToLibrary(ref, album);
    if (!context.mounted) return;
    if (result.isSuccess && result.filePath != null) {
      final filePath = result.filePath!;
      final count = result.trackCount ?? 0;
      final msg = count > 1
          ? '« ${album.displayTitle} » · $count pistes ajoutées'
          : '« ${album.displayTitle} » ajouté';
      AppToast.showSuccess(
        context,
        message: msg,
        actionLabel: 'Copier',
        onAction: () {
          Clipboard.setData(ClipboardData(text: filePath));
          if (context.mounted) AppToast.showCopied(context);
        },
      );
    } else {
      AppToast.showError(context, result.error ?? 'Échec du téléchargement');
    }
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
    required this.onDownload,
  });

  final DeezerSearchResult album;
  final double artSize;
  final bool isDownloading;
  final double? progress;
  final VoidCallback onDownload;

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
              onTap: isDownloading ? null : onDownload,
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
                            onTap: onDownload,
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

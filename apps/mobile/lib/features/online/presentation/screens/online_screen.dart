import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musio/features/download/data/models/deezer_search_result.dart';
import 'package:musio/features/download/data/telegramusic_api_client.dart';
import 'package:musio/features/download/presentation/providers/download_provider.dart';
import 'package:musio/shared/utils/app_toast.dart';
import 'package:musio/shared/widgets/mini_player.dart';

class OnlineScreen extends ConsumerStatefulWidget {
  const OnlineScreen({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  ConsumerState<OnlineScreen> createState() => _OnlineScreenState();
}

class _OnlineScreenState extends ConsumerState<OnlineScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

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

    return Scaffold(
      appBar: AppBar(
        leading: widget.showBackButton
            ? BackButton(
                onPressed: () => context.pop(),
              )
            : null,
        automaticallyImplyLeading: widget.showBackButton,
        title: const Text('Découvrir'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Morceau ou album (Deezer)…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(onlineSearchStateProvider.notifier).clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  ref.read(onlineSearchStateProvider.notifier).search(value.trim());
                }
              },
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
      ),
      body: _buildBody(context, apiClient, searchState, downloadingTrackId, downloadingAlbumId, downloadProgress),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.settings_ethernet_rounded,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Serveur non configuré',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Allez dans Paramètres > Serveur de téléchargement et indiquez l’URL de l’API Telegramusic (par défaut : https://lkm.emmanuekebeh.dev).',
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

    if (searchState.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Recherche en cours…',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (searchState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                searchState.error!,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (searchState.results.isEmpty && searchState.albumResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_rounded,
                size: 72,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 20),
              Text(
                'Rechercher un morceau ou un album',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Saisissez un titre ou un artiste puis validez.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final tracks = searchState.results.where((r) => r.isTrack).toList();
    final albums = searchState.albumResults.where((r) => r.isAlbum).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        if (albums.isNotEmpty) ...[
          _sectionHeaderSpotify(context, 'Albums'),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final album = albums[index];
                final isDownloading = downloadingAlbumId == album.id;
                return Padding(
                  padding: EdgeInsets.only(right: index < albums.length - 1 ? 16 : 0),
                  child: _buildAlbumCardSpotify(
                    context,
                    apiClient,
                    album,
                    isDownloading,
                    isDownloading ? downloadProgress : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 28),
        ],
        if (tracks.isNotEmpty) ...[
          _sectionHeaderSpotify(context, 'Morceaux'),
          const SizedBox(height: 8),
          ...tracks.map((track) {
            final isDownloading = downloadingTrackId == track.id;
            return _buildTrackRowSpotify(
              context,
              apiClient,
              track,
              isDownloading,
              isDownloading ? downloadProgress : null,
            );
          }),
        ],
      ],
    );
  }

  Widget _sectionHeaderSpotify(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 0, top: 16, bottom: 0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
          letterSpacing: 1.2,
          fontSize: 13,
        ),
      ),
    );
  }

  /// Carte album comme dans l’onglet Albums offline : image + titre + artiste + bouton télécharger.
  Widget _buildAlbumCardSpotify(
    BuildContext context,
    TelegramusicApiClient client,
    DeezerSearchResult album,
    bool isDownloading,
    double? progress,
  ) {
    const cardWidth = 160.0;
    const imageSize = 160.0;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: isDownloading ? null : () => _downloadAlbum(context, album),
      child: SizedBox(
        width: cardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: imageSize,
                    height: imageSize,
                    child: album.imgUrl != null && album.imgUrl!.isNotEmpty
                        ? Image.network(
                            album.imgUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _gridPlaceholder(context),
                          )
                        : _gridPlaceholder(context),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: isDownloading
                      ? SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            value: (progress ?? 0.0).clamp(0.0, 1.0),
                            strokeWidth: 2,
                            backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.5),
                          ),
                        )
                      : Material(
                          color: theme.colorScheme.primary,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _downloadAlbum(context, album),
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(Icons.download_rounded, color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              album.displayTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              album.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ligne piste style Spotify : pochette arrondie, titre + artiste, fond au tap, bouton download discret.
  Widget _buildTrackRowSpotify(
    BuildContext context,
    TelegramusicApiClient client,
    DeezerSearchResult track,
    bool isDownloading,
    double? progress,
  ) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDownloading ? null : () => _downloadTrack(context, track),
        splashColor: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        highlightColor: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: _coverLeading(context, client, track, size: 56),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isDownloading)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    value: (progress ?? 0.0).clamp(0.0, 1.0),
                    strokeWidth: 2,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.download_rounded, size: 22),
                  onPressed: () => _downloadTrack(context, track),
                  style: IconButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coverLeading(
    BuildContext context,
    TelegramusicApiClient client,
    DeezerSearchResult item, {
    double size = 48,
  }) {
    final url = item.imgUrl;
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size > 56 ? 10 : 8),
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholderCover(context, size),
        ),
      );
    }
    return _placeholderCover(context, size);
  }

  Widget _placeholderCover(BuildContext context, [double size = 48]) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(size > 56 ? 10 : 8),
      ),
      child: Icon(Icons.album_rounded, size: size * 0.5),
    );
  }

  Widget _gridPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.album_rounded,
          size: 48,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
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

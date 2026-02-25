import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_lyric/lyrics_reader.dart' as lyric_ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musio/features/music/data/models/song_model.dart';
import 'package:musio/features/music/presentation/providers/lyrics_provider.dart';
import 'package:musio/features/music/presentation/providers/music_provider.dart' hide lyricsProvider;
import 'package:musio/features/player/data/models/player_state.dart';
import 'package:musio/features/player/presentation/providers/audio_player_provider.dart';
import 'package:musio/features/player/presentation/providers/sleep_timer_provider.dart';
import 'package:musio/features/player/presentation/widgets/audio_visualizer.dart';
import 'package:musio/features/player/presentation/widgets/equalizer_sheet.dart';
import 'package:musio/features/settings/presentation/providers/settings_provider.dart';
import 'package:musio/shared/widgets/album_art_image.dart';
import 'package:share_plus/share_plus.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(audioPlayerProvider);
    final currentSong = playerState.currentSong;

    if (currentSong == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Aucune musique en cours'),
        ),
      );
    }

    final musicState = ref.watch(musicProvider);
    final isFavorite = musicState.maybeWhen(
      data: (state) => state.songs
          .firstWhere(
            (s) => s.id == currentSong.id,
            orElse: () => currentSong,
          )
          .isFavorite,
      orElse: () => currentSong.isFavorite,
    );

    return Scaffold(
      body: Stack(
        children: [
          // Fond flouté
          if (currentSong.albumArtPath != null)
            Positioned.fill(
              child: Image.file(
                File(currentSong.albumArtPath!),
                fit: BoxFit.cover,
              ),
            )
          else
            Container(color: Theme.of(context).colorScheme.surface),
          
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7),
              ),
            ),
          ),

          // Contenu
          SafeArea(
            child: Column(
              children: [
                // AppBar personnalisée
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Column(
                        children: [
                          Text(
                            'EN LECTURE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentSong.album,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => _showOptionsMenu(context, ref, currentSong),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Album art (plus grand et avec ombre)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: AlbumArtImageLarge(
                          songId: currentSong.id,
                          albumArtPath: currentSong.albumArtPath,
                          heroTag: 'album-art-${currentSong.id}',
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                AudioVisualizer(
                  isPlaying: playerState.isPlaying,
                  barCount: 28,
                  barWidth: 3,
                  minHeight: 6,
                  maxHeight: 28,
                ),
                const SizedBox(height: 16),

                // Song info & Favorite
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentSong.title,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentSong.artist,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                        ),
                        iconSize: 32,
                        color: isFavorite
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        onPressed: () {
                          ref
                              .read(musicProvider.notifier)
                              .toggleFavoriteStatus(currentSong);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Progress bar (seek uniquement à la fin du glissement pour éviter la lenteur)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _SeekBar(
                    position: playerState.position,
                    duration: playerState.duration,
                    formatDuration: _formatDuration,
                    onSeek: (d) => ref.read(audioPlayerProvider.notifier).seek(d),
                  ),
                ),

                const SizedBox(height: 16),

                // Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(
                          playerState.isShuffled
                              ? Icons.shuffle_on_outlined
                              : Icons.shuffle,
                          color: playerState.isShuffled
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        iconSize: 28,
                        onPressed: () {
                          ref.read(audioPlayerProvider.notifier).toggleShuffle();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded),
                        iconSize: 48,
                        onPressed: () {
                          ref.read(audioPlayerProvider.notifier).previous();
                        },
                      ),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                          ),
                          iconSize: 40,
                          onPressed: () {
                            if (playerState.isPlaying) {
                              ref.read(audioPlayerProvider.notifier).pause();
                            } else {
                              ref.read(audioPlayerProvider.notifier).resume();
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded),
                        iconSize: 48,
                        onPressed: () {
                          ref.read(audioPlayerProvider.notifier).next();
                        },
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final repeatMode = ref.watch(audioPlayerProvider.select((s) => s.repeatMode));
                          return IconButton(
                            icon: Icon(
                              _getRepeatIcon(repeatMode),
                              color: repeatMode != RepeatMode.off
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            iconSize: 28,
                            onPressed: () {
                              ref.read(audioPlayerProvider.notifier).toggleRepeat();
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                          final current = playerState.playbackSpeed;
                          final next = current <= 1.0 ? 1.5 : (current < 2.0 ? 2.0 : 1.0);
                          ref.read(audioPlayerProvider.notifier).setSpeed(next);
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.speed, color: Theme.of(context).colorScheme.onSurface),
                              const SizedBox(width: 6),
                              Text(
                                _speedLabel(playerState.playbackSpeed),
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.lyrics_outlined),
                        onPressed: () {
                          _showLyricsSheet(context, ref, currentSong.id);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.queue_music),
                        onPressed: () {
                          _showQueueSheet(context, ref);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.equalizer),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const EqualizerSheet(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _speedLabel(double speed) {
    if (speed <= 1.0) return '1x';
    if (speed < 2.0) return '1.5x';
    return '2x';
  }

  IconData _getRepeatIcon(RepeatMode repeatMode) {
    switch (repeatMode) {
      case RepeatMode.off:
        return Icons.repeat_rounded;
      case RepeatMode.one:
        return Icons.repeat_one_on_rounded;
      case RepeatMode.all:
        return Icons.repeat_on_rounded;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showOptionsMenu(BuildContext context, WidgetRef ref, SongModel currentSong) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHandle(),
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: const Text('Ajouter à la playlist'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddToPlaylistSheet(context, ref, currentSong);
                },
              ),
              if (currentSong.albumId != null)
                ListTile(
                  leading: const Icon(Icons.album),
                  title: const Text('Aller à l\'album'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/album/${currentSong.albumId}');
                  },
                ),
              if (currentSong.artistId != null)
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Aller à l\'artiste'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/artist/${currentSong.artistId}');
                  },
                ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Partager'),
                onTap: () {
                  Navigator.pop(context);
                  Share.share(
                    'J\'écoute ${currentSong.title} de ${currentSong.artist} sur LKM Player !',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text('Minuteur de sommeil'),
                subtitle: ref.watch(sleepTimerProvider) != null
                    ? Text('Arrêt dans ${(ref.watch(sleepTimerProvider)! / 60).ceil()} min')
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _showSleepTimerSheet(context, ref);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showSleepTimerSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final remaining = ref.watch(sleepTimerProvider);
          final defaultMinutes = ref.watch(sleepTimerDefaultMinutesProvider).valueOrNull ?? 0;

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SheetHandle(),
                    const SizedBox(height: 8),
                    Text(
                      'Minuteur de sommeil',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (remaining != null && remaining > 0) ...[
                      Text(
                        'Arrêt dans ${(remaining / 60).ceil()} min',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          ref.read(sleepTimerProvider.notifier).cancel();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Minuteur annulé'), behavior: SnackBarBehavior.floating),
                          );
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Annuler le minuteur'),
                      ),
                    ] else ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [15, 30, 45, 60].map((m) {
                          return ActionChip(
                            label: Text('$m min'),
                            onPressed: () {
                              ref.read(sleepTimerProvider.notifier).start(m);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Arrêt dans $m min'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                      if (defaultMinutes > 0) ...[
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () {
                            ref.read(sleepTimerProvider.notifier).start(defaultMinutes);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Arrêt dans $defaultMinutes min (défaut)'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.timer),
                          label: Text('$defaultMinutes min (défaut)'),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddToPlaylistSheet(
      BuildContext context, WidgetRef ref, SongModel song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final playlists = ref.watch(musicProvider).asData?.value.playlists ?? [];
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SheetHandle(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Ajouter à une playlist',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                if (playlists.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('Aucune playlist trouvée.'),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.music_note, color: Theme.of(context).colorScheme.primary),
                          ),
                          title: Text(playlist.name),
                          subtitle: Text('${playlist.songIds.length} titres'),
                          onTap: () {
                            ref
                                .read(musicProvider.notifier)
                                .addSongToPlaylist(song.id, playlist.id);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Ajouté à "${playlist.name}"'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showQueueSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                const _SheetHandle(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'File d\'attente',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final playerState = ref.watch(audioPlayerProvider);
                      return playerState.queue.isEmpty
                          ? const Center(
                              child: Text('La file d\'attente est vide'),
                            )
                          : ReorderableListView.builder(
                              scrollController: scrollController,
                              padding: const EdgeInsets.only(bottom: 32),
                              itemCount: playerState.queue.length,
                              itemBuilder: (context, index) {
                                final song = playerState.queue[index];
                                final isCurrentSong =
                                    playerState.currentIndex == index;

                                return Material(
                                  key: ValueKey(song.id),
                                  color: Colors.transparent,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                    leading: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: song.albumArtPath != null
                                            ? DecorationImage(
                                                image: FileImage(File(song.albumArtPath!)),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      ),
                                      child: song.albumArtPath == null
                                          ? const Icon(Icons.music_note, color: Colors.grey)
                                          : null,
                                    ),
                                    title: Text(
                                      song.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: isCurrentSong
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isCurrentSong
                                            ? Theme.of(context).colorScheme.primary
                                            : null,
                                      ),
                                    ),
                                    subtitle: Text(
                                      song.artist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isCurrentSong)
                                          Icon(Icons.equalizer, color: Theme.of(context).colorScheme.primary, size: 20),
                                        const SizedBox(width: 16),
                                        ReorderableDragStartListener(
                                          index: index,
                                          child: const Icon(Icons.drag_handle, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      ref
                                          .read(audioPlayerProvider.notifier)
                                          .skipToIndex(index);
                                    },
                                  ),
                                );
                              },
                              onReorder: (oldIndex, newIndex) {
                                ref
                                    .read(audioPlayerProvider.notifier)
                                    .reorderQueue(oldIndex, newIndex);
                              },
                            );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLyricsSheet(BuildContext context, WidgetRef ref, String songId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                const _SheetHandle(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Paroles',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Lyrics content
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final lyricsAsync = ref.watch(lyricsProvider(songId));
                      final playerState = ref.watch(audioPlayerProvider);

                      return lyricsAsync.when(
                        data: (lyrics) {
                          if (lyrics == null || lyrics.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lyrics_outlined,
                                    size: 64,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucune parole disponible',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.5),
                                        ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Créer le modèle de paroles
                          final lyricModel =
                              lyric_ui.LyricsModelBuilder.create()
                                  .bindLyricToMain(lyrics)
                                  .getModel();

                          return lyric_ui.LyricsReader(
                            model: lyricModel,
                            position: playerState.position.inMilliseconds,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            emptyBuilder: () => const Center(
                              child: Text('Aucune parole disponible'),
                            ),
                            selectLineBuilder: (progress, confirm) {
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.play_arrow,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Lecture sélectionnée',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                          Text(
                                            _formatDuration(
                                              Duration(milliseconds: progress),
                                            ),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        ref
                                            .read(audioPlayerProvider.notifier)
                                            .seek(
                                              Duration(milliseconds: progress),
                                            );
                                        confirm();
                                      },
                                      child: const Text('Lire'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            lyricUi: lyric_ui.UINetease(
                              highlight: true,
                              defaultSize: 18, // Texte un peu plus grand
                              defaultExtSize: 14,
                              otherMainSize: 16,
                              bias: 0.5,
                              lineGap: 24, // Plus d'espace entre les lignes
                              inlineGap: 10,
                              lyricAlign: lyric_ui.LyricAlign.CENTER,
                              highlightDirection:
                                  lyric_ui.HighlightDirection.LTR,
                            ),
                            onTap: () {
                              // Optionnel : afficher les contrôles de sélection
                            },
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (err, stack) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Erreur lors du chargement',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32),
                                child: Text(
                                  err.toString(),
                                  style: Theme.of(context).textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Barre de progression : seek uniquement à la fin du glissement (onChangeEnd)
/// pour éviter les appels répétés pendant le drag et la lenteur.
class _SeekBar extends StatefulWidget {
  const _SeekBar({
    required this.position,
    required this.duration,
    required this.formatDuration,
    required this.onSeek,
  });

  final Duration position;
  final Duration duration;
  final String Function(Duration) formatDuration;
  final ValueChanged<Duration> onSeek;

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  bool _isDragging = false;
  double _dragValue = 0;

  @override
  Widget build(BuildContext context) {
    final maxMs = widget.duration.inMilliseconds;
    final max = maxMs > 0 ? maxMs.toDouble() : 1.0;
    final positionMs = widget.position.inMilliseconds.toDouble().clamp(0.0, max);
    final value = _isDragging ? _dragValue : positionMs;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            trackHeight: 4,
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            thumbColor: Theme.of(context).colorScheme.primary,
          ),
          child: Slider(
            value: value,
            max: max,
            onChanged: (v) {
              setState(() {
                _isDragging = true;
                _dragValue = v;
              });
            },
            onChangeEnd: (v) {
              final position = Duration(milliseconds: v.toInt());
              widget.onSeek(position);
              // Laisser le parent se mettre à jour avant de repasser à widget.position
              Future.microtask(() => setState(() => _isDragging = false));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isDragging
                    ? widget.formatDuration(Duration(milliseconds: _dragValue.toInt()))
                    : widget.formatDuration(widget.position),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                widget.formatDuration(widget.duration),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

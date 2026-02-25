import 'dart:io';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// Widget réutilisable pour afficher les images d'albums
/// Utilise le chemin du fichier en priorité, puis QueryArtworkWidget en fallback
class AlbumArtImage extends StatelessWidget {
  final String? albumArtPath;
  final String songId;
  final double size;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final Widget? placeholderIcon;

  const AlbumArtImage({
    super.key,
    this.albumArtPath,
    required this.songId,
    this.size = 48,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.placeholderIcon,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(8);

    // Si on a un chemin et que le fichier existe, l'utiliser
    if (albumArtPath != null && File(albumArtPath!).existsSync()) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.file(
          File(albumArtPath!),
          width: size,
          height: size,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return _buildQueryArtwork(context, radius);
          },
        ),
      );
    }

    // Sinon, utiliser QueryArtworkWidget d'on_audio_query
    return _buildQueryArtwork(context, radius);
  }

  Widget _buildQueryArtwork(BuildContext context, BorderRadius radius) {
    final artworkSize = size.isFinite ? size.toInt() * 2 : 200;
    return ClipRRect(
      borderRadius: radius,
      child: QueryArtworkWidget(
        id: int.tryParse(songId) ?? 0,
        type: ArtworkType.AUDIO,
        size: artworkSize, // Meilleure qualité
        quality: 100,
        artworkFit: fit,
        artworkBorder: BorderRadius.zero,
        nullArtworkWidget: _buildPlaceholder(context),
        errorBuilder: (context, error, stack) {
          return _buildPlaceholder(context);
        },
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.3),
            Theme.of(context).colorScheme.secondary.withOpacity(0.3),
          ],
        ),
      ),
      child: placeholderIcon ??
          Icon(
            Icons.music_note,
            color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
            size: size.isFinite ? size * 0.5 : 48,
          ),
    );
  }
}

/// Widget pour les grandes images (Now Playing, Album Details)
class AlbumArtImageLarge extends StatelessWidget {
  final String? albumArtPath;
  final String songId;
  final double size;
  final String? heroTag;

  const AlbumArtImageLarge({
    super.key,
    this.albumArtPath,
    required this.songId,
    this.size = 300,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    Widget artworkWidget = AlbumArtImage(
      albumArtPath: albumArtPath,
      songId: songId,
      size: size,
      borderRadius: BorderRadius.circular(16),
      fit: BoxFit.cover,
    );

    // Ajouter Hero animation si tag fourni
    if (heroTag != null) {
      artworkWidget = Hero(
        tag: heroTag!,
        child: artworkWidget,
      );
    }

    // Ajouter ombre et bordure
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: artworkWidget,
    );
  }
}

/// Widget pour les vignettes circulaires (artistes, etc.)
class AlbumArtCircle extends StatelessWidget {
  final String? albumArtPath;
  final String songId;
  final double size;

  const AlbumArtCircle({
    super.key,
    this.albumArtPath,
    required this.songId,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: AlbumArtImage(
        albumArtPath: albumArtPath,
        songId: songId,
        size: size,
        borderRadius: BorderRadius.zero,
        fit: BoxFit.cover,
      ),
    );
  }
}

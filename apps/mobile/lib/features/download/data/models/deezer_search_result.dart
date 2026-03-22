/// Résultat de recherche Deezer (track ou album) depuis l'API Telegramusic.
class DeezerSearchResult {
  const DeezerSearchResult({
    required this.id,
    required this.idType,
    required this.title,
    required this.artist,
    this.album,
    /// ID album Deezer (quand connu) — pour regrouper les pistes téléchargées à la pièce.
    this.deezerAlbumId,
    this.imgUrl,
    this.previewUrl,
  });

  final String id;
  final String idType; // 'track' | 'album'
  final String title;
  final String artist;
  final String? album;
  final String? deezerAlbumId;
  final String? imgUrl;
  final String? previewUrl;

  factory DeezerSearchResult.fromJson(Map<String, dynamic> json) {
    final idType = json['id_type'] as String? ?? 'track';
    // Pour les albums, l'API Deezer met le nom dans "album", pas "title".
    final titleValue = idType == 'album'
        ? (json['album'] as String? ?? json['title'] as String? ?? '')
        : (json['title'] as String? ?? json['album'] as String? ?? '');
    final rawAlbumId = json['album_id'];
    final parsedAlbumId = rawAlbumId == null
        ? null
        : (rawAlbumId is int ? rawAlbumId.toString() : rawAlbumId as String?);
    final normalizedAlbumId =
        (parsedAlbumId != null && parsedAlbumId.isNotEmpty) ? parsedAlbumId : null;
    return DeezerSearchResult(
      id: json['id']?.toString() ?? '',
      idType: idType,
      title: titleValue,
      artist: json['artist'] as String? ?? 'Artiste inconnu',
      album: json['album'] as String?,
      deezerAlbumId: normalizedAlbumId,
      imgUrl: json['img_url'] as String?,
      previewUrl: json['preview_url'] as String?,
    );
  }

  bool get isTrack => idType == 'track';
  bool get isAlbum => idType == 'album';

  /// Titre affiché : pour un album c'est le nom de l'album, pour un track c'est le titre du morceau.
  String get displayTitle => title.trim().isEmpty ? (album ?? 'Sans titre') : title;
}

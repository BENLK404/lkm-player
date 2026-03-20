/// Identifiants des playlists système (non stockées en base).
class SystemPlaylist {
  SystemPlaylist._();

  static const String favorites = 'system_favorites';
  static const String recent = 'system_recent';
  static const String mostPlayed = 'system_most_played';

  static const String favoritesTitle = 'Favoris';
  static const String recentTitle = 'Récemment jouées';
  static const String mostPlayedTitle = 'Les plus jouées';

  static bool isSystemId(String id) =>
      id == favorites || id == recent || id == mostPlayed;

  static String titleFor(String id) {
    return switch (id) {
      favorites => favoritesTitle,
      recent => recentTitle,
      mostPlayed => mostPlayedTitle,
      _ => 'Playlist',
    };
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ordre de tri pour la section "Tous les titres" de l'écran Pour Moi.
enum ForYouSort {
  title('Titre'),
  artist('Artiste'),
  dateAdded('Date d\'ajout'),
  recentlyPlayed('Récemment joués'),
  mostPlayed('Plus joués');

  const ForYouSort(this.label);
  final String label;
}

final forYouSortProvider = StateProvider<ForYouSort>((ref) => ForYouSort.title);

/// Filtre par genre (null = tous les genres).
final forYouGenreFilterProvider = StateProvider<String?>((ref) => null);

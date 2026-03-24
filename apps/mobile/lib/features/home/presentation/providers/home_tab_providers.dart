import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nombre de colonnes dans la grille d’albums (2–5).
final albumGridColumnsProvider = StateProvider<double>((ref) => 2.0);

/// Mode d’affichage des chansons (true = liste, false = grille).
final songDisplayModeProvider = StateProvider<bool>((ref) => true);

/// Mode sélection multiple : null = inactif, `songs` | `albums`.
final selectionModeProvider = StateProvider<String?>((ref) => null);

final selectedSongIdsProvider = StateProvider<Set<String>>((ref) => {});
final selectedAlbumIdsProvider = StateProvider<Set<String>>((ref) => {});

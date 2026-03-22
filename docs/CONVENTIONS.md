# Conventions de Code - LKM Player

Ce document définit les standards et conventions à suivre pour le projet LKM Player.

---

## Organisation des Fichiers

### Naming Conventions

```
 CORRECT                           INCORRECT
song_model.dart                     SongModel.dart
audio_player_service.dart           audioPlayerService.dart
music_provider.dart                 MusicProvider.dart
home_screen.dart                    HomeScreen.dart
```

**Règle** : `snake_case` pour les noms de fichiers

### Structure des Dossiers

```
feature/
├── data/
│   ├── models/          # Modèles de données (Freezed)
│   ├── repositories/    # Implémentations repositories
│   ├── datasources/     # Sources de données (API, Local)
│   └── services/        # Services métier
├── domain/
│   ├── entities/        # Entités métier (pure Dart)
│   └── usecases/        # Cas d'utilisation
└── presentation/
    ├── providers/       # Providers Riverpod
    ├── screens/         # Écrans complets
    └── widgets/         # Widgets réutilisables
```

---

## Naming Conventions

### Classes

```dart
//  CORRECT - PascalCase
class AudioPlayerService { }
class SongModel { }
class HomeScreen extends StatelessWidget { }

//  INCORRECT
class audioPlayerService { }
class song_model { }
```

### Variables & Functions

```dart
//  CORRECT - camelCase
final currentSong = song;
void playSong() { }
bool isPlaying = false;

//  INCORRECT
final CurrentSong = song;
void PlaySong() { }
bool is_playing = false;
```

### Constants

```dart
//  CORRECT - lowerCamelCase
const defaultVolume = 1.0;
const maxQueueSize = 100;

//  INCORRECT
const DEFAULT_VOLUME = 1.0;  // Éviter SCREAMING_SNAKE_CASE
const MaxQueueSize = 100;
```

### Providers (Riverpod)

```dart
//  CORRECT - Suffixe "Provider"
@riverpod
AudioPlayerService audioPlayerService(AudioPlayerServiceRef ref) { }

@riverpod
Future<List<SongModel>> allSongs(AllSongsRef ref) async { }

//  INCORRECT
@riverpod
AudioPlayerService audioPlayer(AudioPlayerRef ref) { }
```

---

## Code Style

### Imports

```dart
//  CORRECT - Ordre: Dart SDK, Flutter, Packages, Relative
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/song_model.dart';
import 'audio_player_service.dart';

//  INCORRECT - Désorganisé
import '../models/song_model.dart';
import 'package:flutter/material.dart';
import 'dart:async';
```

### Const Constructors

```dart
//  CORRECT - Utiliser const quand possible
const SizedBox(height: 16);
const Text('Hello');
const EdgeInsets.all(8);

//  INCORRECT - Oublier const
SizedBox(height: 16);
Text('Hello');
```

### Final vs Const

```dart
//  CORRECT
const defaultSpeed = 1.0;           // Compile-time constant
final currentTime = DateTime.now(); // Runtime constant

//  INCORRECT
var defaultSpeed = 1.0;             // Peut changer
const currentTime = DateTime.now(); // Erreur: pas compile-time
```

---

## Riverpod Best Practices

### Provider Definition

```dart
//  CORRECT - Utiliser riverpod_generator
@riverpod
Future<List<SongModel>> allSongs(AllSongsRef ref) async {
  final repository = ref.watch(musicRepositoryProvider);
  return repository.getAllSongs();
}

//  CORRECT - keepAlive pour singletons
@Riverpod(keepAlive: true)
AudioPlayerService audioPlayerService(AudioPlayerServiceRef ref) {
  final service = AudioPlayerService();
  ref.onDispose(() => service.dispose());
  return service;
}
```

### Provider Usage

```dart
//  CORRECT - Dans ConsumerWidget
class SongsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(allSongsProvider);

    return songsAsync.when(
      data: (songs) => ListView(...),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => ErrorWidget(err),
    );
  }
}

//  INCORRECT - Utiliser StatelessWidget sans ref
class SongsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Pas d'accès à ref !
  }
}
```

---

## Freezed Best Practices

### Model Definition

```dart
//  CORRECT - Complet avec defaults et nullable
@freezed
class SongModel with _$SongModel {
  const factory SongModel({
    required String id,
    required String title,
    required String artist,
    String? albumArtPath,        // Nullable explicite
    @Default(0) int playCount,   // Default value
    @Default(false) bool isFavorite,
  }) = _SongModel;

  factory SongModel.fromJson(Map<String, dynamic> json) =>
      _$SongModelFromJson(json);
}

//  INCORRECT - Manque defaults et nullable
@freezed
class SongModel with _$SongModel {
  const factory SongModel({
    String id,                   // Devrait être required
    String albumArtPath,         // Devrait être nullable
    int playCount,               // Devrait avoir @Default
  }) = _SongModel;
}
```

### Usage

```dart
//  CORRECT - Utiliser copyWith
final updatedSong = song.copyWith(
  playCount: song.playCount + 1,
  lastPlayed: DateTime.now(),
);

//  INCORRECT - Créer un nouvel objet
final updatedSong = SongModel(
  id: song.id,
  title: song.title,
  // ... copier tous les champs manuellement
  playCount: song.playCount + 1,
);
```

---

## Testing Conventions

### Test File Naming

```
apps/mobile/lib/features/player/data/services/audio_player_service.dart
→
apps/mobile/test/features/player/audio_player_service_test.dart
```

**Règle** : Même structure + suffixe `_test.dart`

### Test Structure

```dart
void main() {
  group('AudioPlayerService', () {        // Group par classe
    late AudioPlayerService service;

    setUp(() {                            // Setup avant chaque test
      service = AudioPlayerService();
    });

    tearDown(() async {                   // Cleanup après chaque test
      await service.dispose();
    });

    group('Play Controls', () {           // Sous-groupe par feature
      test('should play song when playSong called', () async {
        // Arrange
        final song = createTestSong();

        // Act
        await service.playSong(song);

        // Assert
        expect(service.currentState.isPlaying, isTrue);
      });
    });
  });
}
```

---

## Documentation

### Documenter les Classes Publiques

```dart
/// Service principal gérant la lecture audio.
///
/// Utilise [AudioPlayer] de just_audio pour la lecture
/// et émet des mises à jour d'état via [stateStream].
///
/// Exemple:
/// ```dart
/// final service = AudioPlayerService();
/// await service.playSong(song);
/// ```
class AudioPlayerService {
  // ...
}
```

### Documenter les Méthodes Complexes

```dart
/// Mélange la queue en gardant la chanson actuelle en premier.
///
/// La chanson [currentSong] reste en position 0, le reste
/// de la [queue] est mélangé aléatoirement.
///
/// Returns: Liste mélangée avec [currentSong] en tête.
List<SongModel> _shuffleQueue(List<SongModel> queue, SongModel currentSong) {
  // ...
}
```

### TODO Comments

```dart
// TODO(username): Implémenter la sauvegarde des playlists
// FIXME: Le shuffle ne fonctionne pas avec queue vide
// HACK: Workaround temporaire pour bug Android 13
```

---

## Anti-Patterns à Éviter

### Magic Numbers

```dart
//  INCORRECT
await Future.delayed(Duration(milliseconds: 500));
if (songs.length > 100) { }

//  CORRECT
const loadingDelay = Duration(milliseconds: 500);
const maxDisplayedSongs = 100;

await Future.delayed(loadingDelay);
if (songs.length > maxDisplayedSongs) { }
```

### Nested Conditionals

```dart
//  INCORRECT
if (song != null) {
  if (song.isPlaying) {
    if (song.duration > 0) {
      // ...
    }
  }
}

//  CORRECT - Early returns
if (song == null) return;
if (!song.isPlaying) return;
if (song.duration <= 0) return;
// ...
```

### God Classes

```dart
//  INCORRECT - Tout dans une classe
class MusicManager {
  void playSong() { }
  void scanLibrary() { }
  void savePlaylist() { }
  void fetchLyrics() { }
  void applyEqualizer() { }
  // ... 50 autres méthodes
}

//  CORRECT - Separation of Concerns
class AudioPlayerService { }
class MusicRepository { }
class PlaylistService { }
class LyricsService { }
class EqualizerService { }
```

---

## Code Review Checklist

Avant de commit, vérifiez :

- [ ] Tous les imports sont organisés
- [ ] Pas de code commenté inutile
- [ ] Utilisation de `const` quand possible
- [ ] Noms de variables explicites
- [ ] Pas de magic numbers
- [ ] Documentation pour API publiques
- [ ] Tests passent (`flutter test`)
- [ ] Pas de warnings (`flutter analyze`)
- [ ] Code formaté (`dart format`)

---

## Git Commit Messages

```
 CORRECT
feat: add shuffle functionality to player
fix: resolve crash when queue is empty
docs: update architecture documentation
refactor: extract playlist logic to service
test: add unit tests for AudioPlayerService

 INCORRECT
Update stuff
Fixed bug
WIP
asdfasdf
```

**Format** : `type: description`

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

---

**Respecter ces conventions garantit un code maintenable et cohérent.**

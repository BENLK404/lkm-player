# Architecture de LKM Player

Ce document explique l'architecture et les choix de conception du projet LKM Player.

---

## Architecture Globale

LKM Player suit une architecture **Clean Architecture** combinée avec une organisation **Feature-First**.

```
┌─────────────────────────────────────────────┐
│           PRESENTATION LAYER                │
│  (UI, Widgets, Screens, Providers)         │
│                                             │
│  • ConsumerWidgets                          │
│  • Riverpod Providers                       │
│  • State Management                         │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│            DOMAIN LAYER                     │
│  (Business Logic, Use Cases, Entities)     │
│                                             │
│  • Use Cases                                │
│  • Business Rules                           │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│             DATA LAYER                      │
│  (Models, Repositories, Datasources)       │
│                                             │
│  • Repositories                             │
│  • Data Models (Freezed)                    │
│  • Local/Remote Datasources                 │
└─────────────────────────────────────────────┘
```

---

## Principes de Conception

### 1. Separation of Concerns (SoC)
Chaque couche a une responsabilité unique :
- **Presentation** : Affichage et interaction utilisateur
- **Domain** : Logique métier pure
- **Data** : Accès aux données et persistance

### 2. Dependency Inversion
Les dépendances pointent vers l'intérieur (vers le domain).

```
Presentation → Domain ← Data
```

### 3. Single Responsibility Principle
Chaque classe/fichier a une responsabilité unique.

---

## Organisation par Features

> Tous les chemins ci-dessous sont relatifs à `apps/mobile/lib/`.

```
features/
├── music/          # Tout ce qui concerne la bibliothèque musicale
├── player/         # Tout ce qui concerne la lecture audio
└── lyrics/         # Tout ce qui concerne les paroles
```

Avantages :
-  Code organisé par fonctionnalité métier
-  Facile à naviguer et maintenir
-  Isolation des features
-  Scalabilité

---

## Flux de Données

### Exemple : Charger toutes les chansons

```
1. UI (Widget)
   └─> ref.watch(allSongsProvider)
       │
2. Provider (Riverpod)
   └─> musicRepository.getAllSongs()
       │
3. Repository
   └─> OnAudioQuery.querySongs()
       │
4. Datasource (on_audio_query)
   └─> Accès au système de fichiers Android/iOS
       │
5. Retour des données
   └─> SongModel[] → Provider → UI
```

### Exemple : Jouer une chanson

```
1. UI (Widget)
   └─> onTap: () => playerService.playSong(song)
       │
2. Service
   └─> AudioPlayerService.playSong()
       │
       ├─> _audioPlayer.setFilePath(path)
       ├─> _updateState(newState)
       └─> _audioPlayer.play()
       │
3. State Update
   └─> Stream<PlayerState>
       │
4. UI Update
   └─> ref.watch(playerStateProvider)
```

---

## State Management (Riverpod)

### Types de Providers Utilisés

#### 1. **Singleton Providers** (keepAlive: true)
```dart
@Riverpod(keepAlive: true)
AudioPlayerService audioPlayerService(AudioPlayerServiceRef ref) {
  return AudioPlayerService();
}
```

Utilisé pour :
- Services globaux (AudioPlayerService, MusicRepository)
- Ne doivent jamais être disposés

#### 2. **Auto-Dispose Providers**
```dart
@riverpod
Future<List<SongModel>> allSongs(AllSongsRef ref) async {
  // Se dispose automatiquement quand plus utilisé
}
```

Utilisé pour :
- Données qui peuvent être rechargées
- Optimisation mémoire

#### 3. **Stream Providers**
```dart
@riverpod
Stream<PlayerState> playerState(PlayerStateRef ref) {
  return service.stateStream;
}
```

Utilisé pour :
- Données temps réel (position audio, état lecture)

---

## Modèles de Données (Freezed)

### Pourquoi Freezed ?

```dart
@freezed
class SongModel with _$SongModel {
  const factory SongModel({
    required String id,
    required String title,
    // ...
  }) = _SongModel;
}
```

Avantages :
-  **Immutabilité** : État prévisible
-  **copyWith** : Copie avec modifications
-  **Equality** : Comparaison automatique
-  **toString** : Debugging facile
-  **JSON** : Sérialisation automatique

### Exemple d'utilisation

```dart
// Créer
final song = SongModel(
  id: '1',
  title: 'Bohemian Rhapsody',
  artist: 'Queen',
);

// Copier avec modification
final updatedSong = song.copyWith(
  playCount: song.playCount + 1,
);

// Comparaison
if (song == updatedSong) { } // false

// JSON
final json = song.toJson();
final fromJson = SongModel.fromJson(json);
```

---

## Persistance (Hive)

### Structure Hive

```dart
@HiveType(typeId: 0)
class SongModel {
  @HiveField(0) String id;
  @HiveField(1) String title;
  // ...
}
```

### Boxes Hive Prévues

```dart
// Initialisé dans main.dart
final songsBox = await Hive.openBox<SongModel>('songs');
final playlistsBox = await Hive.openBox<PlaylistModel>('playlists');
final settingsBox = await Hive.openBox('settings');
```

---

## Architecture du Player

### AudioPlayerService

Le service central qui gère :

```dart
class AudioPlayerService {
  final AudioPlayer _audioPlayer;           // just_audio
  final StreamController _stateController;  // État

  PlayerState _currentState;                // État actuel
  List<SongModel> _originalQueue;           // Queue non mélangée
}
```

### État du Player (PlayerState)

```dart
@freezed
class PlayerState {
  SongModel? currentSong;        // Chanson en cours
  List<SongModel> queue;         // File d'attente
  int currentIndex;              // Index actuel
  Duration position;             // Position actuelle
  Duration duration;             // Durée totale
  bool isPlaying;                // En lecture ?
  RepeatMode repeatMode;         // Mode répétition
  bool isShuffled;               // Aléatoire activé ?
}
```

### Gestion du Shuffle

```dart
// Activer shuffle
toggleShuffle() {
  if (shuffleOn) {
    // Garder la chanson actuelle en premier
    final shuffled = [currentSong, ...restOfQueue.shuffled()];
  } else {
    // Restaurer l'ordre original
    queue = originalQueue;
  }
}
```

---

## Gestion des Permissions

### Permission Flow

```
App Start
   │
   ▼
Request Permission (permission_handler)
   │
   ├─> Granted → Scan Music Library
   │
   └─> Denied → Show Permission Dialog
```

### Code

```dart
final status = await Permission.audio.request();

if (status.isGranted) {
  // Scanner la bibliothèque
  final songs = await musicRepository.getAllSongs();
} else {
  // Afficher message d'erreur
}
```

---

## Patterns Utilisés

### 1. Repository Pattern
```dart
class MusicRepository {
  Future<List<SongModel>> getAllSongs();
  Future<List<AlbumModel>> getAllAlbums();
}
```

### 2. Service Pattern
```dart
class AudioPlayerService {
  Future<void> playSong(SongModel song);
  Future<void> togglePlayPause();
}
```

### 3. Stream Pattern
```dart
Stream<PlayerState> get stateStream => _controller.stream;
```

### 4. Factory Pattern (Freezed)
```dart
const factory SongModel(...) = _SongModel;
```

---

## Performance Optimizations

### 1. Lazy Loading
```dart
// Providers auto-dispose quand pas utilisés
@riverpod
Future<List<SongModel>> allSongs(...) { }
```

### 2. Stream Builders
```dart
// Mise à jour uniquement quand nécessaire
ref.watch(playerStateProvider).when(...)
```

### 3. Const Constructors
```dart
const PlayerState(); // Réutilisé si identique
```

### 4. Caching avec Riverpod
```dart
// Résultat en cache automatiquement
final songs = ref.watch(allSongsProvider);
```

---

## Extensions Futures

### Phase 2 : Audio Background
```dart
// Intégration audio_service
class AudioPlayerHandler extends BaseAudioHandler {
  @override
  Future<void> play() => _audioPlayer.play();
}
```

### Phase 3 : Equalizer
```dart
class EqualizerService {
  void setBand(int band, double gain);
  void applyPreset(EqualizerPreset preset);
}
```

### Phase 4 : Lyrics Sync
```dart
class LyricsService {
  Stream<LyricLine> syncedLyrics(Duration position);
}
```

---

## Ressources Supplémentaires

- [Clean Architecture (Uncle Bob)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Riverpod Architecture](https://codewithandrea.com/articles/flutter-app-architecture-riverpod-introduction/)
- [Feature-First Organization](https://codewithandrea.com/articles/flutter-project-structure/)

---

**Cette architecture vise un code maintenable, testable et évolutif.**

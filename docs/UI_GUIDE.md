# 🎨 Guide de l'Interface Utilisateur - LKM Player

## 📱 Structure de Navigation

L'application utilise **GoRouter** pour une navigation déclarative et performante.

### Routes Principales

```
/                    → HomeScreen (Écran principal)
/now-playing         → NowPlayingScreen (Lecteur plein écran)
/album/:id           → AlbumDetailsScreen (Détails d'un album)
/artist/:id          → ArtistDetailsScreen (Détails d'un artiste)
/playlist/:id        → PlaylistScreen (Détails d'une playlist)
/search              → SearchScreen (Recherche globale)
```

### Navigation Exemple

```dart
// Naviguer vers un écran
context.push('/album/123');

// Retour
context.pop();

// Remplacer l'écran actuel
context.go('/now-playing');
```

---

## 🎨 Thème

L'application utilise un thème personnalisé avec support du mode clair et sombre.

### Couleurs Principales

- **Primary**: `#6C63FF` (Violet vibrant)
- **Secondary**: `#FF6584` (Rose)
- **Accent**: `#4ECDC4` (Turquoise)

### Mode Sombre (Par défaut)
- Background: `#121212`
- Surface: `#1E1E1E`
- Card: `#2A2A2A`

### Mode Clair
- Background: `#F5F5F5`
- Surface: `#FFFFFF`
- Card: `#FFFFFF`

### Utilisation

```dart
// Accéder aux couleurs du thème
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.surface

// Accéder aux styles de texte
Theme.of(context).textTheme.headlineMedium
Theme.of(context).textTheme.bodyMedium
```

---

## 🧩 Widgets Réutilisables

### 1. SongTile

Widget pour afficher une chanson dans une liste.

```dart
SongTile(
  song: songModel,
  onTap: () => playSong(),
  showTrailingMenu: true, // Afficher le menu contextuel
)
```

**Fonctionnalités:**
- Pochette d'album
- Titre, artiste, album
- Durée
- Indicateur de lecture
- Menu contextuel (Lire ensuite, Ajouter à la file, etc.)

### 2. MiniPlayer

Lecteur mini sticky en bas de l'écran.

```dart
const MiniPlayer()
```

**Fonctionnalités:**
- Barre de progression
- Pochette miniature
- Titre et artiste
- Contrôles (Previous, Play/Pause, Next)
- Navigation vers NowPlayingScreen au tap

### 3. AlbumCard

Card pour afficher un album dans une grille.

```dart
AlbumCard(
  album: albumModel,
  onTap: () => navigateToAlbum(),
)
```

**Affiche:**
- Pochette d'album
- Titre
- Artiste
- Année

### 4. ArtistCard

Card pour afficher un artiste.

```dart
ArtistCard(
  artist: artistModel,
  onTap: () => navigateToArtist(),
)
```

**Affiche:**
- Avatar circulaire avec initiale
- Nom de l'artiste
- Nombre d'albums

---

## 📺 Écrans Principaux

### HomeScreen

Écran d'accueil avec 4 onglets:

1. **Chansons**: Liste de toutes les chansons
2. **Albums**: Grille des albums
3. **Artistes**: Liste des artistes
4. **Playlists**: Liste des playlists

**Fonctionnalités:**
- Pull-to-refresh pour rescanner
- Bouton recherche dans l'AppBar
- Menu pour rescanner ou accéder aux paramètres
- MiniPlayer sticky en bas

### NowPlayingScreen

Lecteur plein écran avec:

- Grande pochette d'album
- Titre, artiste, album
- Barre de progression interactive
- Contrôles de lecture (Previous, Play/Pause, Next)
- Shuffle et Repeat
- Bouton favoris
- Bouton paroles
- Bouton file d'attente

**Gestures:**
- Swipe down pour fermer
- Drag sur la barre de progression pour seek

### AlbumDetailsScreen

Détails d'un album:

- Header avec pochette
- Infos (Artiste, année, nombre de chansons, durée)
- Boutons "Lire tout" et "Mélanger"
- Liste des chansons de l'album

### ArtistDetailsScreen

Détails d'un artiste:

- Header avec photo/avatar
- Statistiques (Albums, Chansons, Durée totale)
- Boutons "Lire tout" et "Mélanger"
- Section "Top chansons"
- Grille des albums

### PlaylistScreen

Détails d'une playlist:

- Header avec icône
- Infos (Nombre de chansons, durée)
- Boutons "Lire tout" et "Mélanger"
- Liste des chansons
- Menu pour éditer/supprimer

### SearchScreen

Recherche globale:

- Barre de recherche autofocus
- Résultats groupés par catégorie:
  - Artistes (top 3 + "Voir tous")
  - Albums (scroll horizontal)
  - Chansons (liste complète)
- Recherche en temps réel

---

## 🎯 Bonnes Pratiques

### 1. Utilisation des Providers

```dart
// Lire l'état
final musicState = ref.watch(musicProvider);

// Modifier l'état
ref.read(musicProvider.notifier).scanLibrary();

// Écouter les changements
ref.listen(audioPlayerProvider, (previous, next) {
  // Réagir aux changements
});
```

### 2. Gestion des Erreurs

```dart
musicState.when(
  data: (state) => /* Afficher les données */,
  loading: () => const CircularProgressIndicator(),
  error: (error, stack) => /* Afficher l'erreur */,
);
```

### 3. Navigation Sécurisée

```dart
// Vérifier si le widget est monté
if (mounted) {
  context.push('/route');
}

// Avec GoRouter, toujours utiliser context
// Ne pas garder de référence au BuildContext
```

### 4. Performance

```dart
// Lazy loading des listes
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => /* Item */,
);

// Const widgets quand possible
const MiniPlayer()
```

---

## 🔄 États du Lecteur

### PlayerState

```dart
class PlayerState {
  final SongModel? currentSong;
  final List<SongModel> queue;
  final int currentIndex;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final bool isShuffleEnabled;
  final RepeatMode repeatMode;
}
```

### RepeatMode

```dart
enum RepeatMode {
  off,    // Pas de répétition
  all,    // Répéter toute la file
  one,    // Répéter la chanson actuelle
}
```

---

## 🎨 Personnalisation

### Modifier le Thème

Éditez `/lib/core/theme/app_theme.dart`:

```dart
static const Color primaryColor = Color(0xFF6C63FF); // Votre couleur
```

### Ajouter une Route

1. Créez l'écran dans `/lib/features/{feature}/presentation/screens/`
2. Ajoutez la route dans `/lib/core/routing/app_router.dart`

```dart
GoRoute(
  path: '/your-route',
  name: 'your-route',
  builder: (context, state) => YourScreen(),
),
```

### Créer un Widget Réutilisable

1. Créez le fichier dans `/lib/shared/widgets/`
2. Exportez-le dans `/lib/shared/widgets/widgets.dart`
3. Utilisez-le partout avec `import 'package:musio/shared/widgets/widgets.dart';`

---

## 📦 Packages UI Utilisés

- **go_router**: Navigation déclarative
- **flutter_riverpod**: State management
- **flutter_animate**: Animations
- **palette_generator**: Couleurs adaptatives depuis les images

---

## 🚀 Prochaines Étapes UI

- [ ] Animations de transition entre écrans
- [ ] Couleurs adaptatives basées sur la pochette (palette_generator)
- [ ] Animations du lecteur (rotation pochette)
- [ ] Bottom sheets pour les actions rapides
- [ ] Drag & drop pour réorganiser les playlists
- [ ] Hero animations
- [ ] Skeleton loaders
- [ ] Empty states améliorés

---

**Dernière mise à jour**: 2024-02-08

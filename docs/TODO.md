# TODO - LKM Player Development Roadmap

## Phase 1 : Structure & Core (TERMINÉ)

- [x] Structure du projet (Feature-First)
- [x] Configuration Freezed + Riverpod
- [x] Modèles de données (Song, Album, Artist, Playlist)
- [x] AudioPlayerService (moteur de lecture)
- [x] MusicRepository (scan bibliothèque)
- [x] Providers Riverpod
- [x] Documentation (README, Architecture, Getting Started)
- [x] Tests unitaires exemple
- [x] Scripts de développement

---

## Phase 2 : Interface Utilisateur (TERMINÉE)

### 2.1 Navigation & Routing

- [x] Configurer GoRouter
- [x] Définir les routes principales
  - `/` : Splash puis Home
  - `/home` : Home (Pour Moi, Chansons, Albums, Artistes, Playlists)
  - `/now-playing` : Lecteur plein écran
  - `/album/:id` : Détails album
  - `/artist/:id` : Détails artiste
  - `/playlist/:id` : Détails playlist
  - `/search` : Recherche
  - `/settings`, `/settings/about`, `/song-list`

### 2.2 Écrans Principaux

#### Home Screen
- [x] AppBar avec titre "LKM Player" et bouton recherche
- [x] TabBar (Pour Moi, Chansons, Albums, Artistes, Playlists)
- [x] Liste des chansons avec pochette miniature (vue liste/grille)
- [x] Pull-to-refresh et menu "Rescanner la bibliothèque"
- [x] Mini-player en bas (sticky)

#### Now Playing Screen
- [x] Pochette d'album (grande taille, fond flouté)
- [x] Titre, artiste, album
- [x] Barre de progression interactive
- [x] Contrôles : Previous, Play/Pause, Next
- [x] Boutons : Shuffle, Repeat
- [x] Bouton queue, paroles, égaliseur
- [x] Menu options (partage, etc.)

#### Album / Artist / Playlist Details
- [x] Album Details : header, liste chansons, Play All
- [x] Artist Details : header, albums, titres
- [x] Playlist Details : création, édition, suppression, ajout/retrait de chansons

### 2.3 Widgets Réutilisables

- [x] `SongTile`, `AlbumCard`, `ArtistCard`, `AlbumArtImage`
- [x] `MiniPlayer`, `VinylCard`, `PlaylistCard`, `SongCard`
- [x] Paroles (LyricsView), égaliseur (EqualizerSheet)
- [ ] `AddToPlaylistDialog` (à compléter si besoin)

---

## Phase 3 : Fonctionnalités Avancées

### 3.1 Recherche

- [x] Barre de recherche globale (SearchScreen)
- [x] Recherche en temps réel (par titre, artiste, album)
- [ ] Résultats groupés (Songs, Albums, Artists) – à enrichir
- [ ] Historique de recherche

### 3.2 Playlists

- [x] Créer playlist
- [x] Éditer playlist (nom)
- [x] Supprimer playlist
- [x] Ajouter chanson à playlist
- [x] Retirer chanson de playlist
- [ ] Playlist "Favoris" (système)
- [ ] Playlist "Récemment jouées" (système)
- [ ] Playlist "Les plus jouées" (système)

### 3.3 Paroles

- [x] Paroles depuis métadonnées (audiotagger)
- [x] Affichage (LyricsView / flutter_lyric)
- [ ] Détecter fichiers .lrc externes
- [ ] Parser format LRC, auto-scroll, highlight ligne actuelle

### 3.4 Background Audio

- [x] Intégrer audio_service (MusioAudioHandler)
- [x] Contrôles notification et lockscreen
- [x] MediaSession Android / Now Playing iOS

---

## Phase 4 : Perfectionnement

### 4.1 Persistance & Cache

- [ ] Ouvrir boxes Hive dans main.dart
- [ ] Sauvegarder playlists dans Hive
- [ ] Sauvegarder favoris
- [ ] Sauvegarder historique d'écoute
- [ ] Sauvegarder préférences utilisateur
- [ ] Cache des pochettes

### 4.2 Statistiques

- [ ] Tracker nombre d'écoutes par chanson
- [ ] Tracker temps d'écoute total
- [ ] Générer "Top 10 du mois"
- [ ] Graphiques d'écoute
- [ ] Artistes les plus écoutés

### 4.3 Paramètres

- [ ] Thème (Clair/Sombre/Auto)
- [ ] Égaliseur
- [ ] Sleep timer
- [ ] Qualité audio (bitrate)
- [ ] Gapless playback
- [ ] Crossfade
- [ ] Exporter/Importer playlists

### 4.4 Performance

- [ ] Lazy loading des listes
- [ ] Pagination
- [ ] Cache des images
- [ ] Optimisation du scan initial
- [ ] Background scan

---

## Phase 5 : Fonctionnalités Bonus

### 5.1 Recommandations

- [ ] "Vous pourriez aimer" (basé sur historique)
- [ ] Artistes similaires
- [ ] Albums similaires

### 5.2 Synchronisation

- [ ] Export playlists M3U
- [ ] Import playlists M3U
- [ ] Sync avec stockage cloud (optionnel)

### 5.3 Widgets Home Screen

- [ ] Widget Android mini-player
- [ ] Widget iOS

### 5.4 Intégrations

- [ ] Scrobbling Last.fm (optionnel)
- [ ] Récupération paroles online (Genius, etc.)
- [ ] Récupération métadonnées (MusicBrainz)

---

## Bugs & Corrections

### Bugs Connus
- [ ] Aucun pour l'instant

### À Tester
- [ ] Comportement avec bibliothèque vide
- [ ] Comportement avec 10 000+ chansons
- [ ] Gestion permissions refusées
- [ ] Rotation écran
- [ ] Minimiser l'app en lecture
- [ ] Casque déconnecté pendant lecture

---

## Documentation

- [ ] Ajouter screenshots dans README
- [ ] Créer guide utilisateur
- [ ] Documenter API providers
- [ ] Créer changelog

---

## Tests

### Tests Unitaires
- [x] AudioPlayerService (basique)
- [ ] MusicRepository
- [ ] Providers Riverpod
- [ ] Utils & Helpers

### Tests d'Intégration
- [ ] Flow complet : Scan → Play → Pause
- [ ] Création playlist
- [ ] Recherche

### Tests Widget
- [ ] SongTile
- [ ] MiniPlayer
- [ ] NowPlayingScreen

---

## Déploiement

- [ ] Icône d'application
- [ ] Splash screen
- [ ] Configuration signing Android
- [ ] Configuration iOS
- [ ] Screenshots store
- [ ] Description store
- [ ] Build release Android (APK/AAB)
- [ ] Build release iOS

---

## Idées Futures

- [ ] Mode voiture (Car Mode)
- [ ] Gestes (swipe pour changer chanson)
- [ ] Shake pour shuffle
- [ ] Chromecast support
- [ ] Bluetooth auto-play
- [ ] Tag editor (éditer métadonnées)
- [ ] Visualiseur audio
- [ ] Radio mode (station aléatoire)

---

## Priorités

### HAUTE PRIORITÉ
1. Tests unitaires (repository, player, providers)
2. Messages d’erreur utilisateur explicites (permissions, scan)
3. Persistance paramètres (thème, égaliseur) si pas déjà fait

### MOYENNE PRIORITÉ
1. Playlists système (Favoris, Récemment jouées, Les plus jouées)
2. Paroles .lrc externes, égaliseur presets
3. Performance (pagination / lazy load si grosse bibliothèque)

### BASSE PRIORITÉ
1. Statistiques avancées, recommandations
2. Widgets home screen (Android / iOS)
3. Intégrations (Last.fm, Genius, etc.)

---

**Dernière mise à jour** : 2025-02-23

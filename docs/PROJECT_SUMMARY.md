# LKM Player - Résumé du Projet

## Vue d'Ensemble

**LKM Player** est un lecteur audio mobile Flutter moderne avec :
-  Architecture Clean + Feature-First
-  State Management : Riverpod 2.0
-  Modèles immutables : Freezed
-  Persistance : Hive
-  Audio : just_audio + audio_service

---

## Fichiers Créés (20 fichiers)

### Documentation (dans `docs/`)
```
docs/GETTING_STARTED.md     # Guide d'installation pas à pas
docs/ARCHITECTURE.md        # Explication de l'architecture
docs/CONVENTIONS.md         # Standards de code
docs/TODO.md                # Roadmap et tâches
docs/DOCKER.md              # Déploiement Docker de l'API
```

### Configuration
```
Makefile                          # Orchestrateur de commandes (racine)
docker-compose.yml                # Déploiement unifié (racine)
apps/mobile/pubspec.yaml          # Dépendances Flutter
apps/mobile/analysis_options.yaml # Configuration lint Dart
services/api/requirements.txt     # Dépendances Python
services/api/Dockerfile.api       # Image Docker FastAPI
services/api/Dockerfile.bot       # Image Docker bot Telegram
```

### Scripts
```
scripts/setup.sh       # Setup complet (Flutter + Python)
apps/mobile/dev.sh     # Script helper Flutter
```

### Code Source Flutter (`apps/mobile/lib/`)

#### Modèles de Données
```
apps/mobile/lib/features/music/data/models/
├── song_model.dart       # Modèle chanson avec métadonnées
├── album_model.dart      # Modèle album
├── artist_model.dart     # Modèle artiste
└── playlist_model.dart   # Modèle playlist

apps/mobile/lib/features/player/data/models/
└── player_state.dart     # État du lecteur audio
```

#### Repositories & Services
```
apps/mobile/lib/features/music/data/repositories/
└── music_repository.dart # Scan et accès bibliothèque

apps/mobile/lib/features/player/data/services/
└── audio_player_service.dart # Moteur de lecture audio
```

#### Providers
```
apps/mobile/lib/features/music/presentation/providers/
└── music_provider.dart   # Providers pour musique

apps/mobile/lib/features/player/presentation/providers/
└── audio_player_provider.dart # Providers pour player
```

### Code Source API (`services/api/`)
```
services/api/api/server.py        # API REST FastAPI
services/api/handlers/deezer.py   # Logique Deezer
services/api/handlers/yt_dlp.py   # Logique YouTube/SoundCloud
services/api/dl_utils/            # Utilitaires de téléchargement
services/api/main.py              # Bot Telegram
```

---

## Structure Complète du Projet (Monorepo)

```
lkm-player/
├── README.md
├── LICENSE
├── Makefile                 # Orchestrateur de commandes
├── docker-compose.yml       # Déploiement unifié (bot + API)
│
├──  docs/                 # Documentation
│   ├── ARCHITECTURE.md
│   ├── GETTING_STARTED.md
│   ├── CONVENTIONS.md
│   ├── TODO.md
│   └── ...
│
├──  scripts/
│   └── setup.sh             # Setup complet
│
├──  apps/
│   └── mobile/              # App Flutter (Android/iOS)
│       ├── pubspec.yaml
│       ├── lib/
│       │   ├── core/
│       │   │   ├── providers/       # Providers globaux
│       │   │   ├── routing/         # Navigation (go_router)
│       │   │   ├── theme/           # Thème Material 3
│       │   │   └── utils/           # Logger
│       │   ├── features/
│       │   │   ├── music/           # Bibliothèque, modèles, repository
│       │   │   ├── player/          # Lecture audio, état, égaliseur
│       │   │   ├── playlist/        # Playlists personnalisées
│       │   │   ├── album/           # Détail album
│       │   │   ├── artist/          # Détail artiste + Wikipedia
│       │   │   ├── search/          # Recherche
│       │   │   ├── settings/        # Paramètres, thème, stats
│       │   │   ├── for_you/         # Suggestions
│       │   │   ├── download/        # Téléchargement via API
│       │   │   └── online/          # Découverte en ligne
│       │   └── shared/              # Widgets partagés
│       ├── android/
│       └── ios/
│
├──  services/
│   └── api/                 # Backend Python
│       ├── Dockerfile.api
│       ├── Dockerfile.bot
│       ├── requirements.txt
│       ├── api/             # FastAPI REST server
│       │   └── server.py
│       ├── handlers/        # Logique Deezer/YouTube
│       ├── dl_utils/        # Utilitaires de téléchargement
│       ├── main.py          # Bot Telegram
│       └── bot.py
│
└── .github/
    ├── workflows/
    │   ├── flutter.yml      # CI Flutter (path: apps/mobile/**)
    │   └── api.yml          # CI API (path: services/api/**)
    ├── ISSUE_TEMPLATE/
    └── PULL_REQUEST_TEMPLATE.md
```

---

## Fonctionnalités Implémentées

### Core Système

 **Architecture**
- Clean Architecture avec Feature-First
- Separation of Concerns
- Dependency Inversion

 **State Management**
- Riverpod 2.0 avec code generation
- Providers singleton (keepAlive)
- Stream providers pour temps réel

 **Modèles de Données** (Freezed)
- `SongModel` : Chanson avec métadonnées complètes
- `AlbumModel` : Album avec liste de chansons
- `ArtistModel` : Artiste avec statistiques
- `PlaylistModel` : Playlist éditable
- `PlayerState` : État complet du lecteur

### Fonctionnalités Audio

 **AudioPlayerService**
- Lecture/Pause/Stop
- Navigation : Previous/Next
- Seek (aller à une position)
- Shuffle (aléatoire)
- Repeat (Off/One/All)
- Gestion de la queue
- Vitesse de lecture variable
- Contrôle du volume
- Auto-play next song

 **MusicRepository**
- Scan complet de la bibliothèque
- Récupération chansons/albums/artistes
- Extraction des pochettes (artwork)
- Recherche par titre/artiste/album
- Filtrage par album/artiste

---

## Prochaines Étapes Immédiates

### 1. Setup Initial (5 min)
```bash
cd lkm-player
make setup
# Ou manuellement : cd apps/mobile && flutter pub get && dart run build_runner build --delete-conflicting-outputs
```

### 2. Configuration Android (10 min)
- Ajouter permissions dans AndroidManifest.xml
- Configurer audio_service

### 3. Premier Écran (1h)
- Implémenter `HomeScreen`
- Afficher liste des chansons
- Bouton pour scanner la bibliothèque

### 4. Lecteur Basique (2h)
- Écran `NowPlayingScreen`
- Contrôles play/pause/next/previous
- Barre de progression

---

## Statistiques

- **Lignes de code Dart** : ~1500 lignes
- **Fichiers créés** : 20
- **Packages utilisés** : 15
- **Tests** : 8 tests unitaires
- **Documentation** : 5 fichiers MD (~5000 mots)

---

## Commandes Rapides (Makefile)

```bash
# Installation complète (Flutter + Python)
make setup

# Lancer l'app Flutter
make app-run

# Lancer l'API FastAPI (dev)
make api-run

# Lancer le bot Telegram
make api-bot

# Docker (bot + API)
make docker-up

# Tests Flutter
make app-test

# Toutes les commandes
make help
```

---

## Documentation Détaillée

| Fichier | Contenu |
|---------|---------|
| [`README.md`](../README.md) | Vue d'ensemble monorepo, installation |
| [`docs/GETTING_STARTED.md`](./GETTING_STARTED.md) | Guide pas-à-pas pour démarrer |
| [`docs/ARCHITECTURE.md`](./ARCHITECTURE.md) | Explication architecture, flux de données |
| [`docs/CONVENTIONS.md`](./CONVENTIONS.md) | Standards de code, best practices |
| [`docs/TODO.md`](./TODO.md) | Roadmap complète, tâches restantes |
| [`docs/DOCKER.md`](./DOCKER.md) | Déploiement Docker de l'API |

---

## Technologies & Patterns

### Technologies
- **Framework** : Flutter 3.2+
- **Language** : Dart 3.2+
- **State** : Riverpod 2.5
- **Models** : Freezed 2.4
- **Storage** : Hive 2.2
- **Audio** : just_audio 0.9

### Design Patterns
- Repository Pattern
- Service Pattern
- Provider Pattern
- Factory Pattern (Freezed)
- Stream Pattern
- Singleton Pattern

### Architecture Principles
- Clean Architecture
- SOLID Principles
- Feature-First Organization
- Separation of Concerns
- Dependency Inversion

---

## Points Forts du Projet

1. **Architecture Solide** : Clean Architecture + Feature-First
2. **Type Safety** : Freezed pour immutabilité
3. **Reactive** : Riverpod streams pour UI temps réel
4. **Testable** : Séparation claire des responsabilités
5. **Maintenable** : Code organisé et documenté
6. **Scalable** : Prêt pour des features complexes

---

## Concepts Clés à Comprendre

### 1. Riverpod
- Auto-dispose des providers non utilisés
- KeepAlive pour singletons
- Ref pour lire d'autres providers
- Watch/Read/Listen

### 2. Freezed
- Immutabilité par défaut
- copyWith automatique
- Equality comparison
- JSON serialization

### 3. Clean Architecture
- Presentation → Domain ← Data
- Pas de dépendances vers l'extérieur
- Business logic dans Domain

### 4. Feature-First
- Organisation par feature métier
- Isolation des fonctionnalités
- Facile à naviguer

---

## Objectifs Finaux

### Version 1.0 (MVP)
- Scan bibliothèque musicale *(livré)*
- Lecture audio de base *(livré)*
- Interface utilisateur complète *(en cours / à compléter)*
- Playlists *(en cours / à compléter)*
- Recherche *(en cours / à compléter)*

### Version 1.5
- Background audio
- Paroles synchronisées
- Statistiques d'écoute

### Version 2.0
- Thèmes personnalisables
- Égaliseur
- Recommandations intelligentes

---

## Support & Ressources

- **Documentation Flutter** : https://docs.flutter.dev/
- **Riverpod Docs** : https://riverpod.dev/
- **Freezed Package** : https://pub.dev/packages/freezed
- **Just Audio** : https://pub.dev/packages/just_audio

---

**Projet** : LKM Player (monorepo : `apps/mobile` + `services/api`)
**Statut** : phases 1 et 2 complètes ; phase 3 en cours

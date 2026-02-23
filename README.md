# 🎵 LKM Player

**Un lecteur audio local open source, moderne et respectueux de ta vie privée.**

[![Flutter](https://img.shields.io/badge/Flutter-3.2+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.2+-0175C2?logo=dart)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

LKM Player est une application mobile Flutter qui lit ta bibliothèque musicale locale : scan, playlists, paroles (fichiers .lrc, tags, ou API en ligne), égaliseur, thème clair/sombre, statistiques et suggestions. **Aucun compte, aucune pub, tes fichiers restent sur ton appareil.**

> **Dépôt** : [github.com/BENLK404/lkm-player](https://github.com/BENLK404/lkm-player)

---

## ✨ Fonctionnalités

- **Bibliothèque** : Scan local, chansons / albums / artistes / playlists, recherche
- **Lecteur** : File d’attente, shuffle, repeat, vitesse 1x / 1.5x / 2x, lecture en arrière-plan (notification)
- **Paroles** : Fichiers .lrc, métadonnées, ou récupération en ligne (LRCLib) avec cache
- **Pour vous** : Écoutez aussi, artistes similaires, tri/filtres par genre et année
- **Playlists système** : Favoris, Récemment jouées, Les plus jouées
- **Extras** : Égaliseur, minuteur de sommeil, thème clair/sombre/système, statistiques, visualiseur

---

## 🚀 Démarrage rapide

### Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) >= 3.2.0

### Installation

```bash
git clone https://github.com/BENLK404/lkm-player.git
cd lkm-player
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Lancer l’app

```bash
flutter run
```

Sur Android, configure les permissions et le service audio comme indiqué dans [GETTING_STARTED.md](GETTING_STARTED.md).

---

## 📁 Structure du projet

```
lib/
├── core/           # Routing, thème, utilitaires, providers globaux
├── features/       # Par fonctionnalité (music, player, settings, for_you, …)
│   ├── music/      # Bibliothèque, modèles, repository, providers
│   ├── player/     # Lecture audio, état, UI now playing
│   ├── settings/   # Paramètres, stats
│   ├── for_you/    # Onglet Pour Moi, suggestions
│   └── …
└── shared/        # Widgets partagés (SongTile, MiniPlayer, …)
```

Architecture **Clean + Feature-First**, state avec **Riverpod**, modèles **Freezed** + **Hive**. Détails : [ARCHITECTURE.md](ARCHITECTURE.md).

---

## 🤝 Rejoindre la communauté

On aime les retours, les idées et les contributions.

- **Discuter** : ouvrez une [Discussion](https://github.com/BENLK404/lkm-player/discussions) pour une idée, une question ou un partage.
- **Bug ou idée** : [ouvrez une issue](https://github.com/BENLK404/lkm-player/issues).
- **Contribuer** : lisez [CONTRIBUTING.md](CONTRIBUTING.md) (conventions, comment proposer une PR).

En participant, vous acceptez notre [Code de conduite](CODE_OF_CONDUCT.md).

---

## 📜 Licence

Ce projet est sous [licence MIT](LICENSE). Tu peux l’utiliser, le modifier et le redistribuer librement.

---

## 📚 Documentation

| Fichier | Contenu |
|--------|---------|
| [GETTING_STARTED.md](GETTING_STARTED.md) | Installation détaillée, permissions Android |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Architecture et flux de données |
| [CONVENTIONS.md](CONVENTIONS.md) | Standards de code du projet |
| [TODO.md](TODO.md) | Roadmap et tâches prévues |

---

*Fait avec Flutter • Aucun tracking • Ta musique, ton appareil.*

# 🎵 LKM Player

**Un lecteur audio local open source, moderne et respectueux de ta vie privée.**

[![Flutter](https://img.shields.io/badge/Flutter-3.2+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.2+-0175C2?logo=dart)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)

LKM Player est une application mobile Flutter qui lit **ta** bibliothèque musicale locale : scan, playlists, paroles (fichiers .lrc, tags ou API en ligne), égaliseur, thème clair/sombre, statistiques et suggestions. **Aucun compte, aucune pub, aucun tracking — tes fichiers restent sur ton appareil.**

> **Dépôt** : [github.com/BENLK404/lkm-player](https://github.com/BENLK404/lkm-player)

---

## 🌟 Pourquoi LKM Player ?

| Tu en as marre de… | LKM Player te propose… |
|--------------------|-------------------------|
| Comptes obligatoires et abonnements | **Zéro compte** — tout est local |
| Publicités et trackers | **Aucune pub**, aucune collecte de données |
| Apps qui oublient tes playlists | **Cache persistant** : bibliothèque et paroles sauvegardés |
| Paroles introuvables | **3 sources** : .lrc, tags, ou recherche en ligne (LRCLib, Lyrics.ovh) avec mise en cache |
| Interface figée | **Thème clair / sombre / système**, UI fluide et lisible |

Idéal si tu veux **reprendre le contrôle** de ta musique : tout reste sur ton téléphone, l’app ne dépend pas du cloud.

---

## ✨ Fonctionnalités

### 📚 Bibliothèque
- **Scan local** de ta musique (albums, artistes, chansons)
- **Recherche** par titre, artiste ou album
- **Playlists personnalisées** : crée, renomme, ajoute ou retire des titres
- **Cache Hive** : la bibliothèque est conservée entre les lancements, pas besoin de rescanner à chaque ouverture
- Filtrage par durée minimale des morceaux (paramétrable)

### 🎧 Lecteur
- **File d’attente** : ajoute à la suite, joue un album ou une playlist en entier
- **Shuffle** et **repeat** (tout / un seul / désactivé)
- **Vitesse** : 1x, 1.5x, 2x
- **Lecture en arrière-plan** avec notification et contrôles (pause, suivant, précédent)
- **Mini lecteur** en bas de l’écran pour accès rapide

### 📝 Paroles
- **Fichiers .lrc** à côté du fichier audio
- **Métadonnées** (tags) des MP3 / autres formats
- **Recherche en ligne** (optionnelle) : LRCLib et Lyrics.ovh, paroles **mises en cache** pour les retrouver hors ligne ensuite
- Affichage **synchronisé** (LRC) quand disponible
- Réglage « Fonctionnalités en ligne » pour activer ou désactiver la recherche web

### 🎯 Pour vous
- **Écoutez aussi** : suggestions basées sur tes écoutes
- **Artistes similaires** et découverte
- **Tri et filtres** par genre et année

### 📋 Playlists système
- **Favoris** : tes titres préférés
- **Récemment jouées** : historique d’écoute
- **Les plus jouées** : titres les plus écoutés

### ⚙️ Extras
- **Égaliseur** pour ajuster les basses et aigus
- **Minuteur de sommeil** : arrêt automatique après un délai
- **Thème** : clair, sombre ou suivi du système
- **Statistiques** : vue d’ensemble de ta bibliothèque et de ton écoute
- **Visualiseur** audio pendant la lecture
- **Partage** de titres (lien ou fichier selon le contexte)

---

## 🛠 Stack technique

- **Flutter** 3.2+ / **Dart** 3.2+
- **State** : [Riverpod](https://riverpod.dev) (providers + code généré)
- **Modèles** : [Freezed](https://pub.dev/packages/freezed) + [Hive](https://docs.hivedb.dev) (stockage local)
- **Audio** : [just_audio](https://pub.dev/packages/just_audio), [audio_service](https://pub.dev/packages/audio_service), [on_audio_query](https://pub.dev/packages/on_audio_query), [audiotagger](https://pub.dev/packages/audiotagger)
- **Navigation** : [go_router](https://pub.dev/packages/go_router)
- **UI** : Material Design 3, [flutter_animate](https://pub.dev/packages/flutter_animate), [flutter_lyric](https://pub.dev/packages/flutter_lyric) pour les paroles

Architecture **Clean + Feature-First** : chaque fonctionnalité (music, player, settings, for_you, etc.) est isolée pour un code maintenable et évolutif.

---

## 📸 Aperçu

> *Tu peux ajouter ici des captures d’écran (bibliothèque, lecteur, paroles, paramètres) pour donner un aperçu visuel de l’app.*

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

### Build APK (release)

```bash
flutter build apk
```

L’APK sera généré dans `build/app/outputs/flutter-apk/app-release.apk`.

Sur Android, configure les permissions et le service audio comme indiqué dans **[GETTING_STARTED.md](./.github/.github/.github/GETTING_STARTED.md)**.

---

## 📁 Structure du projet

```text
lib/
├── core/           # Routing, thème, utilitaires, providers globaux
├── features/       # Par fonctionnalité
│   ├── music/      # Bibliothèque, modèles, repository, cache, paroles
│   ├── player/     # Lecture audio, état, écran now playing, égaliseur
│   ├── settings/   # Paramètres, thème, stats, à propos
│   ├── for_you/    # Onglet Pour Moi, suggestions
│   ├── search/     # Recherche
│   ├── playlist/   # Playlists et détails
│   ├── album/      # Détail album
│   ├── artist/     # Détail artiste
│   └── online/     # Découverte en ligne (optionnel)
└── shared/         # Widgets partagés (SongTile, MiniPlayer, …)
```

Détails : **[ARCHITECTURE.md](./.github/.github/.github/ARCHITECTURE.md)**.

---

## 🤝 Rejoindre la communauté

Les retours, idées et contributions sont les bienvenus.

- **Discuter** : ouvrez une [Discussion](https://github.com/BENLK404/lkm-player/discussions) pour une idée, une question ou un partage.
- **Bug ou idée** : [ouvrez une issue](https://github.com/BENLK404/lkm-player/issues).
- **Contribuer** : lisez **[CONTRIBUTING.md](./.github/.github/.github/CONTRIBUTING.md)** (conventions, comment proposer une PR).

En participant, vous acceptez notre **[Code de conduite](./.github/.github/.github/CODE_OF_CONDUCT.md)**.

---

## 📜 Licence

Ce projet est sous **[licence MIT](./LICENSE)**. Tu peux l’utiliser, le modifier et le redistribuer librement.

---

## 📚 Documentation

| Fichier | Contenu |
|--------|---------|
| **[GETTING_STARTED.md](./.github/.github/.github/GETTING_STARTED.md)** | Installation détaillée, permissions Android |
| **[ARCHITECTURE.md](./.github/.github/.github/ARCHITECTURE.md)** | Architecture et flux de données |
| **[CONTRIBUTING.md](./.github/.github/.github/CONTRIBUTING.md)** | Standards, comment contribuer, proposer une PR |
| **[CODE_OF_CONDUCT.md](./.github/.github/.github/CODE_OF_CONDUCT.md)** | Règles de conduite |
| **[CONVENTIONS.md](./.github/.github/.github/CONVENTIONS.md)** | Conventions & standards de code |
| **[TODO.md](./.github/.github/.github/TODO.md)** | Roadmap et tâches prévues |
| **[LICENSE](./LICENSE)** | Licence du projet |

---

*Fait avec Flutter • Aucun tracking • Ta musique, ton appareil.*

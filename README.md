# LKM Player

**Monorepo — App mobile Flutter + API backend Python + Landing Page Astro**

[![Flutter](https://img.shields.io/badge/Flutter-3.2+-02569B?logo=flutter)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Python-3.13+-3776AB?logo=python)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115+-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)

LKM Player est un lecteur audio open source composé de trois parties :

- **`apps/mobile/`** — Application Flutter (Android/iOS) : lecture locale, playlists, paroles, égaliseur, thème clair/sombre
- **`apps/web/`** — Landing page (Astro) : site statique, SEO optimisé, animations scroll
- **`services/api/`** — Backend Python : API REST (FastAPI) pour le téléchargement depuis Deezer/YouTube/SoundCloud + bot Telegram

> **Dépôt** : [github.com/BENLK404/lkm-player](https://github.com/BENLK404/lkm-player)

---

## Structure du monorepo

```text
lkm-player/
├── apps/
│   ├── mobile/              # App Flutter (Android/iOS)
│   │   ├── lib/             # Code source Dart
│   │   ├── android/
│   │   ├── ios/
│   │   └── pubspec.yaml
│   └── web/                 # Landing page (Astro + Tailwind)
│       ├── src/             # Pages, composants, styles
│       ├── public/          # Assets statiques
│       └── package.json
│
├── services/
│   └── api/                 # Backend Python
│       ├── api/             # FastAPI REST server
│       ├── handlers/        # Logique Deezer/YouTube
│       ├── dl_utils/        # Utilitaires de téléchargement
│       ├── Dockerfile.api   # Image FastAPI / uvicorn
│       ├── Dockerfile.bot   # Image bot Telegram
│       └── requirements.txt
│
├── docs/                    # Documentation
├── .github/                 # Templates & workflows CI/CD
├── docker-compose.yml       # Déploiement unifié
└── Makefile                 # Commandes Make
```

---

## Démarrage rapide

### Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) >= 3.2.0
- [Python](https://python.org) >= 3.13
- [Node.js](https://nodejs.org) >= 22 + [pnpm](https://pnpm.io) (pour la landing page)
- [Docker](https://docs.docker.com/get-docker/) (optionnel, pour le backend)

### Installation

```bash
git clone https://github.com/BENLK404/lkm-player.git
cd lkm-player
make setup
```

### Lancer l'app mobile

```bash
make app-run
```

### Lancer l'API (dev)

```bash
make api-run
```

### Lancer la landing page

```bash
make web-dev
```

### Docker (bot + API)

```bash
make docker-up
```

### Toutes les commandes

```bash
make help
```

---

## Documentation

| Fichier | Contenu |
|---------|---------|
| [GETTING_STARTED.md](./docs/GETTING_STARTED.md) | Installation détaillée, permissions Android |
| [ARCHITECTURE.md](./docs/ARCHITECTURE.md) | Architecture et flux de données |
| [CONTRIBUTING.md](./docs/CONTRIBUTING.md) | Comment contribuer |
| [CONVENTIONS.md](./docs/CONVENTIONS.md) | Standards de code |
| [DOCKER.md](./docs/DOCKER.md) | Déploiement Docker de l'API |
| [UI_GUIDE.md](./docs/UI_GUIDE.md) | Guide UI/UX |
| [TODO.md](./docs/TODO.md) | Roadmap |

---

## Contribuer

Les retours, idées et contributions sont les bienvenus.

- **Discuter** : ouvrez une [Discussion](https://github.com/BENLK404/lkm-player/discussions)
- **Bug ou idée** : [ouvrez une issue](https://github.com/BENLK404/lkm-player/issues)
- **Contribuer** : lisez [CONTRIBUTING.md](./docs/CONTRIBUTING.md)

En participant, vous acceptez notre [Code de conduite](./docs/CODE_OF_CONDUCT.md).

---

## Licence

Ce projet est sous [licence MIT](./LICENSE).

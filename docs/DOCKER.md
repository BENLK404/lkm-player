# Docker (Bot + API)

Ce projet peut tourner en Docker de 2 façons :

- **Bot Telegram** : `main.py` (polling Telegram)
- **API REST** : `api.server:app` (FastAPI / Uvicorn) pour une app (ex: Flutter / LKM Player)

## Prérequis

- Docker (Docker Desktop sur Windows)
- Docker Compose
- Un fichier `token.env` **à la racine** du projet (même dossier que `docker-compose.yml`)

Exemple minimal :

```env
DEEZER_TOKEN=VOTRE_ARL_DEEZER
TELEGRAM_TOKEN=VOTRE_TOKEN_BOT
BOT_LANG=fr
```

Optionnel (YouTube) : place un `cookies.txt` dans `./local_resources/` (voir la doc `yt-dlp`).

## Lancer avec Docker Compose (recommandé)

Depuis la racine du projet :

### Bot uniquement

```bash
docker-compose up -d --build bot
docker-compose logs -f bot
```

### API uniquement

```bash
docker-compose up -d --build api
docker-compose logs -f api
```

- API : `http://localhost:8000/`
- Docs : `http://localhost:8000/docs`

### Bot + API

```bash
docker-compose up -d --build
```

### Stop / suppression

```bash
docker-compose down
```

## Lancer sans Compose (docker run)

### Construire l’image

```bash
docker build -t telegramusic:latest .
```

### Lancer le bot

```bash
docker run --rm --env-file token.env ^
  -v "%cd%/local_resources:/tmp/local_resources:ro" ^
  -e COOKIES_PATH=/tmp/local_resources/cookies.txt ^
  telegramusic:latest
```

### Lancer l’API

```bash
docker run --rm -p 8000:8000 --env-file token.env ^
  telegramusic:latest python -m uvicorn api.server:app --host 0.0.0.0 --port 8000
```

## Image “portable” (export/import)

Sur une machine :

```bash
docker save -o telegramusic.tar telegramusic:latest
```

Sur une autre machine :

```bash
docker load -i telegramusic.tar
```

## Dépannage

### Windows : `dockerDesktopLinuxEngine` introuvable

- Démarrer **Docker Desktop**
- Vérifier :

```powershell
docker ps
```

Quand `docker ps` fonctionne, relancer `docker-compose up ...`.


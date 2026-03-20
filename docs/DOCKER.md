# Docker (Bot + API)

Ce projet peut tourner en Docker de 2 facons :

- **Bot Telegram** : `main.py` (polling Telegram)
- **API REST** : `api.server:app` (FastAPI / Uvicorn) pour une app (ex: Flutter / LKM Player)

## Prerequis

- Docker (Docker Desktop sur Windows)
- Docker Compose
- Un fichier `token.env` dans `services/api/` (le `docker-compose.yml` racine le reference)

Exemple minimal :

```env
DEEZER_TOKEN=VOTRE_ARL_DEEZER
TELEGRAM_TOKEN=VOTRE_TOKEN_BOT
BOT_LANG=fr
```

Optionnel (YouTube) : place un `cookies.txt` dans `services/api/local_resources/` (voir la doc `yt-dlp`).

## Lancer avec Docker Compose (recommande)

Depuis la **racine du monorepo** (`lkm-player/`) :

### Bot uniquement

```bash
docker compose up -d --build bot
docker compose logs -f bot
```

### API uniquement

```bash
docker compose up -d --build api
docker compose logs -f api
```

- API : `http://localhost:8000/`
- Docs : `http://localhost:8000/docs`

### Bot + API

```bash
docker compose up -d --build
```

Ou via le Makefile :

```bash
make docker-up
```

### Stop / suppression

```bash
docker compose down
```

## Lancer sans Compose (docker run)

### Construire l'image

```bash
docker build -t lkm-api:latest ./services/api
```

### Lancer le bot

```bash
docker run --rm --env-file services/api/token.env \
  -v "$(pwd)/services/api/local_resources:/tmp/local_resources:ro" \
  -e COOKIES_PATH=/tmp/local_resources/cookies.txt \
  lkm-api:latest
```

### Lancer l'API

```bash
docker run --rm -p 8000:8000 --env-file services/api/token.env \
  lkm-api:latest python -m uvicorn api.server:app --host 0.0.0.0 --port 8000
```

## Image "portable" (export/import)

Sur une machine :

```bash
docker save -o lkm-api.tar lkm-api:latest
```

Sur une autre machine :

```bash
docker load -i lkm-api.tar
```

## Depannage

### Windows : `dockerDesktopLinuxEngine` introuvable

- Demarrer **Docker Desktop**
- Verifier :

```powershell
docker ps
```

Quand `docker ps` fonctionne, relancer `docker compose up ...`.

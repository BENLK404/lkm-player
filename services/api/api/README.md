# API REST Telegramusic

API HTTP pour utiliser la logique de téléchargement (Deezer) **depuis une application** (ex: Flutter, LKM Player) sans passer par le bot Telegram.

## Prérequis

- `DEEZER_TOKEN` : cookie ARL Deezer (voir [Finding Your Deezer ARL Cookie](https://github.com/nathom/streamrip/wiki/Finding-Your-Deezer-ARL-Cookie))
- Optionnel : `TELEGRAM_TOKEN` uniquement si vous lancez aussi le bot

## Démarrer l’API

Depuis la racine du projet Telegramusic :

```bash
# Windows (PowerShell)
$env:DEEZER_TOKEN = "votre_arl_cookie"
uvicorn api.server:app --host 0.0.0.0 --port 8000

# Linux / macOS
export DEEZER_TOKEN=your_arl_cookie
uvicorn api.server:app --host 0.0.0.0 --port 8000
```

- **Docs interactives** : http://localhost:8000/docs  
- **Résumé des routes** : http://localhost:8000/

## Endpoints

| Méthode | Route | Description |
|--------|--------|-------------|
| GET | `/api/search?q=...&type=track\|album` | Recherche Deezer (titres ou albums) |
| GET | `/api/track/{id}/meta` | Métadonnées d’un morceau (sans téléchargement) |
| GET | `/api/album/{id}/meta` | Métadonnées d’un album |
| GET | `/api/playlist/{id}/meta` | Métadonnées d’une playlist |
| GET | `/api/download/track/{id}` | Télécharge le morceau (fichier audio) |
| GET | `/api/download/album/{id}` | Télécharge l’album (ZIP) |
| GET | `/api/download/playlist/{id}` | Télécharge la playlist (ZIP) |

`{id}` peut être l’ID Deezer seul (ex: `123456`) ou une URL Deezer (ex: `https://www.deezer.com/track/123456`).

## Exemples pour ton app Flutter

### Recherche

```http
GET http://localhost:8000/api/search?q=adele+hello&type=track
```

Réponse JSON : `{ "query": "adele hello", "type": "track", "results": [ { "id": "...", "title": "...", "artist": "...", ... } ] }`

### Téléchargement d’un morceau

```http
GET http://localhost:8000/api/download/track/823267272
```

Réponse : fichier binaire (MP3 ou FLAC) avec en-tête `Content-Disposition` pour le nom du fichier.

Dans Flutter, utiliser par ex. `http.get()` ou `dio` sur cette URL et écrire les bytes dans un fichier local, puis ouvrir avec ton lecteur (ex: `just_audio`).

### Métadonnées (pour afficher avant téléchargement)

```http
GET http://localhost:8000/api/track/823267272/meta
```

Réponse JSON : titre, artiste, album, année, `cover_url` (route pour récupérer la pochette), etc.

## CORS

L’API autorise toutes les origines (`allow_origins=["*"]`) pour que ton app Flutter (ou une autre origine) puisse l’appeler. En production, restreindre si besoin.

## Note

- Un seul téléchargement à la fois côté API (verrou) pour éviter de surcharger Deezer.
- Les fichiers temporaires sont nettoyés après envoi (track après ~10 s, ZIP après envoi).

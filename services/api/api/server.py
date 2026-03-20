"""
API REST exposant la logique de téléchargement Telegramusic (Deezer, YouTube, SoundCloud).
Utilisable depuis une app Flutter ou tout client HTTP sans passer par le bot Telegram.

Usage:
  Depuis la racine du projet (où se trouve token.env) :
    python -m uvicorn api.server:app --host 0.0.0.0 --port 8000
  Les variables de token.env (DEEZER_TOKEN, TELEGRAM_TOKEN, etc.) sont chargées automatiquement.
"""

import asyncio
import functools
import os
import re
from pathlib import Path
from urllib.parse import quote

# Charger token.env avant tout import qui utilise os.environ (ex: handlers.deezer)
def _load_token_env():
    root = Path(__file__).resolve().parent.parent
    env_path = root / "token.env"
    if env_path.exists():
        with open(env_path, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    key, _, value = line.partition("=")
                    os.environ.setdefault(key.strip(), value.strip())

_load_token_env()

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, Response

# Import de la logique métier (handlers.deezer initialise la session Deezer au chargement)
from handlers.deezer import (
    download_album,
    download_playlist,
    download_track,
    get_album_metadata_from_api,
    get_playlist_metadata_from_api,
    get_track_metadata_from_api,
)
from dl_utils.deezer_download import TYPE_ALBUM, TYPE_TRACK, deezer_search
from utils import TMP_DIR

# Verrou pour éviter trop de téléchargements concurrents côté API
_download_lock = asyncio.Lock()

app = FastAPI(
    title="Telegramusic API",
    description="API de téléchargement musique (Deezer). Pour usage depuis une app sans Telegram.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Regex pour valider les IDs / liens Deezer
TRACK_REGEX = re.compile(r"https?://(?:www\.)?deezer\.com/([a-z]*/)?track/(\d+)/?$")
ALBUM_REGEX = re.compile(r"https?://(?:www\.)?deezer\.com/([a-z]*/)?album/(\d+)/?$")
PLAYLIST_REGEX = re.compile(r"https?://(?:www\.)?deezer\.com/([a-z]*/)?playlist/(\d+)/?$")


def _extract_id(link: str | None, regex: re.Pattern) -> str | None:
    if not link or not link.strip():
        return None
    link = link.strip()
    if link.isdigit():
        return link
    m = regex.search(link)
    return m.group(2) if m else None


# ---------- Recherche ----------


@app.get("/api/search")
async def search(
    q: str = Query(..., min_length=1),
    type: str = Query("track", regex="^(track|album)$"),
):
    """
    Recherche Deezer.
    - q: requête texte (espaces en début/fin ignorés)
    - type: "track" ou "album"
    """
    query = (q or "").strip()
    if not query:
        raise HTTPException(status_code=400, detail="Requête vide")
    search_type = TYPE_ALBUM if type == "album" else TYPE_TRACK
    try:
        loop = asyncio.get_running_loop()
        results = await loop.run_in_executor(
            None, functools.partial(deezer_search, query, search_type)
        )
    except Exception as e:
        print(f"API /api/search error: {e}", flush=True)
        raise HTTPException(status_code=502, detail=f"Recherche échouée: {e}")
    return {"query": query, "type": type, "results": results[:30]}


# ---------- Métadonnées (sans téléchargement) ----------


@app.get("/api/track/{track_id}/meta")
async def track_meta(track_id: str):
    """Métadonnées d'un morceau Deezer (sans téléchargement)."""
    tid = _extract_id(track_id, TRACK_REGEX) or track_id
    try:
        meta = get_track_metadata_from_api(tid)
        # Ne pas renvoyer cover_data en base64 dans le JSON par défaut (trop lourd)
        out = {k: v for k, v in meta.items() if k != "cover_data"}
        if meta.get("cover_data"):
            out["cover_url"] = f"/api/track/{tid}/cover"
        return out
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))


@app.get("/api/album/{album_id}/meta")
async def album_meta(album_id: str):
    """Métadonnées d'un album Deezer (sans téléchargement)."""
    aid = _extract_id(album_id, ALBUM_REGEX) or album_id
    try:
        meta = get_album_metadata_from_api(aid)
        out = {k: v for k, v in meta.items() if k != "cover_data"}
        if meta.get("cover_data"):
            out["cover_url"] = f"/api/album/{aid}/cover"
        return out
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))


@app.get("/api/playlist/{playlist_id}/meta")
async def playlist_meta(playlist_id: str):
    """Métadonnées d'une playlist Deezer (sans téléchargement)."""
    pid = _extract_id(playlist_id, PLAYLIST_REGEX) or playlist_id
    try:
        meta = get_playlist_metadata_from_api(pid)
        out = {k: v for k, v in meta.items() if k != "cover_data"}
        if meta.get("cover_data"):
            out["cover_url"] = f"/api/playlist/{pid}/cover"
        return out
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))


# ---------- Pochettes (images) ----------


@app.get("/api/track/{track_id}/cover")
async def track_cover(track_id: str):
    """Pochette d'un morceau (JPEG)."""
    tid = _extract_id(track_id, TRACK_REGEX) or track_id
    try:
        meta = get_track_metadata_from_api(tid)
        cover = meta.get("cover_data")
        if not cover:
            raise HTTPException(status_code=404, detail="Pas de pochette")
        return Response(content=cover, media_type="image/jpeg")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))


@app.get("/api/album/{album_id}/cover")
async def album_cover(album_id: str):
    """Pochette d'un album (JPEG)."""
    aid = _extract_id(album_id, ALBUM_REGEX) or album_id
    try:
        meta = get_album_metadata_from_api(aid)
        cover = meta.get("cover_data")
        if not cover:
            raise HTTPException(status_code=404, detail="Pas de pochette")
        return Response(content=cover, media_type="image/jpeg")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))


@app.get("/api/playlist/{playlist_id}/cover")
async def playlist_cover(playlist_id: str):
    """Pochette d'une playlist (JPEG)."""
    pid = _extract_id(playlist_id, PLAYLIST_REGEX) or playlist_id
    try:
        meta = get_playlist_metadata_from_api(pid)
        cover = meta.get("cover_data")
        if not cover:
            raise HTTPException(status_code=404, detail="Pas de pochette")
        return Response(content=cover, media_type="image/jpeg")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))


# ---------- Téléchargement ----------


@app.get("/api/download/track/{track_id}")
async def download_track_file(track_id: str):
    """
    Télécharge un morceau Deezer et renvoie le fichier audio (MP3/FLAC).
    """
    tid = _extract_id(track_id, TRACK_REGEX) or track_id
    async with _download_lock:
        try:
            dl_info = await download_track(tid)
        except Exception as e:
            raise HTTPException(status_code=502, detail=str(e))
        if not dl_info or "song_path" not in dl_info:
            raise HTTPException(status_code=502, detail="Échec du téléchargement")
        song_path = Path(dl_info["song_path"])
        if not song_path.exists():
            raise HTTPException(status_code=502, detail="Fichier non trouvé")
        filename = f"{dl_info.get('artist_name', 'Artist')} - {dl_info.get('song_name', tid)}{dl_info.get('file_extension', '.mp3')}"
        filename = re.sub(r'[<>:"/\\|?*]', "_", filename)
        base_dir = dl_info.get("download_dir")

        async def cleanup_later():
            await asyncio.sleep(10)
            try:
                import shutil
                if base_dir and Path(base_dir).exists():
                    shutil.rmtree(base_dir, ignore_errors=True)
            except Exception:
                pass

        asyncio.create_task(cleanup_later())
        return FileResponse(
            path=str(song_path),
            filename=filename,
            media_type="audio/mpeg" if song_path.suffix == ".mp3" else "audio/flac",
        )


@app.get("/api/download/album/{album_id}")
async def download_album_zip(album_id: str):
    """
    Télécharge un album Deezer et renvoie une archive ZIP des pistes.
    """
    aid = _extract_id(album_id, ALBUM_REGEX) or album_id
    async with _download_lock:
        try:
            dl_tracks = await download_album(aid)
        except Exception as e:
            raise HTTPException(status_code=502, detail=str(e))
        if not dl_tracks:
            raise HTTPException(status_code=502, detail="Aucune piste téléchargée")
        try:
            metadata = get_album_metadata_from_api(aid)
        except Exception:
            metadata = {"title": f"Album_{aid}", "artist": "Unknown"}
        from zipfile import ZIP_DEFLATED, ZipFile
        from dl_utils.deezer_utils import clean_filename

        source_dir = Path(dl_tracks[0]["download_dir"])
        safe_name = clean_filename(f"{metadata.get('artist', 'Artist')} - {metadata.get('title', aid)}")
        zip_path = Path(TMP_DIR) / "api" / f"{safe_name}.zip"
        zip_path.parent.mkdir(parents=True, exist_ok=True)
        with ZipFile(zip_path, "w", ZIP_DEFLATED) as zf:
            for t in sorted(dl_tracks, key=lambda x: int(x.get("TRACK_NUMBER", 999))):
                p = Path(t["song_path"])
                if p.exists():
                    name = p.name
                    zf.write(p, name)
        if not zip_path.exists():
            raise HTTPException(status_code=502, detail="Échec création ZIP")

        async def cleanup_album_later():
            await asyncio.sleep(60)
            try:
                import shutil
                if zip_path.exists():
                    zip_path.unlink()
                if source_dir.exists():
                    shutil.rmtree(source_dir, ignore_errors=True)
            except Exception:
                pass

        asyncio.create_task(cleanup_album_later())
        return FileResponse(
            path=str(zip_path),
            filename=f"{safe_name}.zip",
            media_type="application/zip",
        )


@app.get("/api/download/playlist/{playlist_id}")
async def download_playlist_zip(playlist_id: str):
    """
    Télécharge une playlist Deezer et renvoie une archive ZIP des pistes.
    """
    pid = _extract_id(playlist_id, PLAYLIST_REGEX) or playlist_id
    async with _download_lock:
        try:
            dl_tracks = await download_playlist(pid)
        except Exception as e:
            raise HTTPException(status_code=502, detail=str(e))
        if not dl_tracks:
            raise HTTPException(status_code=502, detail="Aucune piste téléchargée")
        try:
            metadata = get_playlist_metadata_from_api(pid)
        except Exception:
            metadata = {"title": f"Playlist_{pid}", "artist": "Unknown"}
        from zipfile import ZIP_DEFLATED, ZipFile
        from dl_utils.deezer_utils import clean_filename

        source_dir = Path(dl_tracks[0]["download_dir"])
        safe_name = clean_filename(f"{metadata.get('artist', 'Artist')} - {metadata.get('title', pid)}")
        zip_path = Path(TMP_DIR) / "api" / f"{safe_name}.zip"
        zip_path.parent.mkdir(parents=True, exist_ok=True)
        with ZipFile(zip_path, "w", ZIP_DEFLATED) as zf:
            for t in dl_tracks:
                p = Path(t["song_path"])
                if p.exists():
                    zf.write(p, p.name)
        if not zip_path.exists():
            raise HTTPException(status_code=502, detail="Échec création ZIP")

        async def cleanup_playlist_later():
            await asyncio.sleep(60)
            try:
                import shutil
                if zip_path.exists():
                    zip_path.unlink()
                if source_dir.exists():
                    shutil.rmtree(source_dir, ignore_errors=True)
            except Exception:
                pass

        asyncio.create_task(cleanup_playlist_later())
        return FileResponse(
            path=str(zip_path),
            filename=f"{safe_name}.zip",
            media_type="application/zip",
        )


@app.get("/")
async def root():
    return {
        "service": "Telegramusic API",
        "docs": "/docs",
        "endpoints": {
            "search": "GET /api/search?q=...&type=track|album",
            "track_meta": "GET /api/track/{id}/meta",
            "download_track": "GET /api/download/track/{id}",
            "album_meta": "GET /api/album/{id}/meta",
            "download_album": "GET /api/download/album/{id}",
            "playlist_meta": "GET /api/playlist/{id}/meta",
            "download_playlist": "GET /api/download/playlist/{id}",
        },
    }


if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", "8000"))
    uvicorn.run(app, host="0.0.0.0", port=port)

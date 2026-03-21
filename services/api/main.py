import asyncio
import locale
import logging
import os
import sys
from pathlib import Path

from aiogram import types, __version__ as aiogram_version
from aiogram.filters import Command
from aiogram.types import InlineKeyboardButton, InlineKeyboardMarkup

from bot import bot, dp
from handlers.deezer import deezer_router
from handlers.yt_dlp import youtube_router, soundcloud_router
from utils import TMP_DIR

if sys.version_info < (3, 13):
    print(
        "Python 3.13 is required, but you are using Python {}.{}".format(
            sys.version_info.major, sys.version_info.minor
        )
    )
    sys.exit(1)

# Print the version of all modules
print("Python version: ", sys.version)
print("aiogram version: ", aiogram_version)

locale.setlocale(locale.LC_TIME, "")

try:
    os.mkdir(TMP_DIR)
except FileExistsError:
    pass

try:
    os.mkdir(Path(TMP_DIR, "yt"))
except FileExistsError:
    pass

logging.basicConfig(level=logging.INFO)


@dp.message(Command(commands=["start", "help"]))
async def help_start(event: types.Message):
    bot_info = await bot.get_me()
    bot_name = bot_info.first_name
    bot_username = bot_info.username

    welcome = (
        f"👋 <b>Bienvenue sur {bot_name} !</b>\n\n"
        "Je permet de télécharger de la musique depuis <b>Deezer</b>, "
        "<b>YouTube</b> et <b>SoundCloud</b>.\n\n"
        "━━━━━━━━━━━━━━━━━━━━\n"
        "📌 <b>Commandes</b>\n\n"
        "• <code>/start</code> — Ce message de bienvenue\n"
        "• <code>/help</code> — Aide et commandes\n\n"
        "━━━━━━━━━━━━━━━━━━━━\n"
        "🔍 <b>Mode inline</b> (dans n'importe quel chat)\n\n"
        f"Tape <code>@{bot_username}</code> puis :\n"
        "• <code>track</code> &lt;recherche&gt; — Chercher un morceau\n"
        "• <code>album</code> &lt;recherche&gt; — Chercher un album\n"
        "• <code>artist</code> &lt;recherche&gt; — Chercher un artiste\n\n"
        "━━━━━━━━━━━━━━━━━━━━\n"
        "🔗 <b>Ou envoie directement un lien</b>\n\n"
        "• Lien Deezer (titre, album, <b>playlist</b>)\n"
        "• Lien YouTube\n"
        "• Lien SoundCloud"
    )
    # Boutons : au clic, remplit la zone de saisie dans ce chat (pas de sélection de conversation)
    keyboard = InlineKeyboardMarkup(inline_keyboard=[
        [
            InlineKeyboardButton(
                text="🔍 Rechercher un morceau",
                switch_inline_query_current_chat="track ",
            ),
            InlineKeyboardButton(
                text="📀 Rechercher un album",
                switch_inline_query_current_chat="album ",
            ),
        ],
        [
            InlineKeyboardButton(
                text="▶️ Ouvrir la recherche",
                switch_inline_query_current_chat="",
            ),
        ],
    ])
    await event.answer(welcome, parse_mode="HTML", reply_markup=keyboard)


async def main() -> None:
    dp.include_routers(youtube_router, soundcloud_router, deezer_router)
    await dp.start_polling(bot)


if __name__ == "__main__":
    asyncio.run(main())

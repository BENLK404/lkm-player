import os

from aiogram import Bot, Dispatcher

# Token optionnel : permet de lancer uniquement l'API (sans bot Telegram)
telegram_token = os.environ.get("TELEGRAM_TOKEN") or "0:API_ONLY_DUMMY_TOKEN"
bot = Bot(token=telegram_token)
dp = Dispatcher()

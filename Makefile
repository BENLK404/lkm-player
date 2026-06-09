.PHONY: help setup app-run app-build app-test app-analyze app-codegen \
       api-run api-bot api-lint \
       web-install web-check web-dev web-build web-preview \
       docker-up docker-down docker-build docker-logs

help: ## Affiche cette aide
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

# ───────────── Setup ─────────────

setup: ## Installation complète (Flutter + Python + Web)
	cd apps/mobile && flutter pub get
	cd services/api && pip install -r requirements.txt
	cd apps/web && pnpm install

# ───────────── Flutter (Mobile App) ─────────────

app-run: ## Lance l'app Flutter en mode debug
	cd apps/mobile && flutter run

app-build: ## Build APK release
	cd apps/mobile && flutter build apk --release

app-test: ## Lance les tests Flutter
	cd apps/mobile && flutter test

app-analyze: ## Analyse statique Flutter
	cd apps/mobile && flutter analyze

app-codegen: ## Génère le code (Freezed, Riverpod, JSON)
	cd apps/mobile && dart run build_runner build --delete-conflicting-outputs

# ───────────── Landing Page (Astro) ─────────────

web-install: ## Installe les dépendances web (pnpm)
	cd apps/web && pnpm install

web-check: ## Vérifie Astro + TypeScript (astro check)
	cd apps/web && pnpm check

web-dev: ## Lance le serveur de dev Astro
	cd apps/web && pnpm dev

web-build: ## Build statique de la landing page
	cd apps/web && pnpm build

web-preview: ## Preview du build statique
	cd apps/web && pnpm preview

# ───────────── API Python ─────────────

api-run: ## Lance l'API FastAPI en mode dev
	cd services/api && python -m uvicorn api.server:app --host 0.0.0.0 --port 8000 --reload

api-bot: ## Lance le bot Telegram
	cd services/api && python -u main.py

api-lint: ## Lint Python (ruff)
	cd services/api && ruff check .

# ───────────── Docker ─────────────

docker-up: ## Démarre tous les services Docker
	docker compose up -d

docker-down: ## Arrête tous les services Docker
	docker compose down

docker-build: ## Build les images Docker
	docker compose build

docker-logs: ## Affiche les logs des services
	docker compose logs -f

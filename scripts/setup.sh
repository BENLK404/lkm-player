#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== LKM Player — Setup ==="
echo ""

# Flutter
echo "▸ Flutter (apps/mobile)"
cd "$REPO_ROOT/apps/mobile"
flutter pub get
echo "  ✓ flutter pub get"

# Code generation (Freezed, Riverpod, JSON)
dart run build_runner build --delete-conflicting-outputs
echo "  ✓ build_runner"

# Python API
echo ""
echo "▸ Python API (services/api)"
cd "$REPO_ROOT/services/api"
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
    echo "  ✓ venv créé"
fi
source .venv/bin/activate
pip install -q -r requirements.txt
echo "  ✓ pip install"

# Landing Page (Astro)
echo ""
echo "▸ Landing Page (apps/web)"
cd "$REPO_ROOT/apps/web"
pnpm install
echo "  ✓ pnpm install"

echo ""
echo "=== Setup terminé ==="
echo "  → make app-run     pour lancer l'app Flutter"
echo "  → make api-run     pour lancer l'API"
echo "  → make web-dev     pour lancer la landing page"
echo "  → make docker-up   pour lancer via Docker"

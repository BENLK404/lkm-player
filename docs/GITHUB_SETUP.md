# Préparer le dépôt GitHub (open source)

Checklist pour publier LKM Player sur GitHub et accueillir une communauté.

## 1. Créer le dépôt

- Sur GitHub : **New repository**
- Nom suggéré : `lkm-player` (ou `LKM-Player`)
- Visibilité : **Public**
- Ne pas initialiser avec README (le projet en a déjà un)

## 2. Liens du dépôt

Les liens pointent déjà vers **BENLK404/lkm-player**. Pour un autre compte ou une organisation, remplace `BENLK404` dans les mêmes fichiers.

## 3. Pousser le code

```bash
git remote add origin https://github.com/BENLK404/lkm-player.git
git branch -M main
git push -u origin main
```

## 4. Paramètres du dépôt (Settings)

- **About** : description courte, topics (ex. `flutter`, `dart`, `music-player`, `open-source`), site web si tu en as un
- **General** : activer **Discussions** (pour la communauté)
- **Features** : Issues activées, templates déjà présents via `.github/`

## 5. Publier une release (APK sur GitHub)

### Option A : Interface GitHub

1. **Builder l’APK** : `flutter build apk --release`  
   → Fichier : `build/app/outputs/flutter-apk/app-release.apk`

2. Sur le dépôt : **Releases** → **Create a new release**.

3. **Tag** : créer un tag (ex. `v1.0.0`) ou en choisir un existant.

4. **Title** : ex. `v1.0.0 – Première release`.

5. **Description** : copier les notes du `CHANGELOG.md` pour cette version.

6. **Fichiers** : glisser-déposer `app-release.apk` dans “Attach binaries”.

7. **Publish release**.

### Option B : GitHub CLI

Si [GitHub CLI (gh)](https://cli.github.com/) est installé et connecté (`gh auth login`) :

```bash
cd musio
flutter build apk --release
gh release create v1.0.0 build/app/outputs/flutter-apk/app-release.apk --title "v1.0.0" --notes-file CHANGELOG.md
```

Pour une release draft (à publier plus tard) : ajouter `--draft`.

## 6. Optionnel

- **Branch protection** : sur `main`, exiger une review avant merge (Settings → Branches)
- **Labels** : garder les labels par défaut ou ajouter `good first issue`, `help wanted`

Une fois ces étapes faites, le projet est prêt à être partagé et à recevoir des contributions.

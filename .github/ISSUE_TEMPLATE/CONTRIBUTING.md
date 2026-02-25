# Contribuer à LKM Player

Merci de ton intérêt pour contribuer. Ce document explique comment proposer des changements et respecter le projet.

## Comment contribuer

- **Signaler un bug** : [Ouvrir une issue](https://github.com/BENLK404/lkm-player/issues/new) avec le template "Bug report".
- **Proposer une fonctionnalité** : [Ouvrir une issue](https://github.com/BENLK404/lkm-player/issues/new) avec le template "Feature request".
- **Proposer du code** : Fork → branche → commits → [Pull Request](https://github.com/BENLK404/lkm-player/compare) en suivant le template PR.

## Avant de coder

1. Parcourir [ARCHITECTURE.md](ARCHITECTURE.md) et [CONVENTIONS.md](CONVENTIONS.md).
2. Vérifier les [issues ouvertes](https://github.com/BENLK404/lkm-player/issues) et les [discussions](https://github.com/BENLK404/lkm-player/discussions) pour éviter les doublons.
3. Pour une grosse feature, ouvrir d’abord une issue ou une discussion pour en discuter.

## Conventions de code

- **Fichiers** : `snake_case` (ex. `audio_player_service.dart`).
- **Classes** : `PascalCase`.
- **Imports** : ordre Dart SDK → Flutter → packages → relatifs ; pas d’imports relatifs vers `lib/` (utiliser `package:musio/...`).
- **Format** : `dart format .` avant de commit.
- **Lint** : `flutter analyze` doit passer (voir `analysis_options.yaml`).
- **Riverpod** : préférer `@riverpod` / `@Riverpod()` avec code generation.
- **Tests** : nouveaux comportements métier ou services de préférence couverts par des tests.

Détails : [CONVENTIONS.md](CONVENTIONS.md).

## Processus de Pull Request

1. Créer une branche depuis `main` : `git checkout -b feat/ma-feature` ou `fix/description-bug`.
2. Faire des commits clairs (ex. `feat: ajout du preset Rock à l’égaliseur`).
3. Lancer `flutter analyze` et `dart run build_runner build` si tu touches aux modèles/providers.
4. Ouvrir une PR vers `main` en remplissant le template (description, type, checklist).
5. Répondre aux retours de review si besoin.

Les mainteneurs feront une relecture et te diront s’il faut des ajustements.

## Questions

Tu peux ouvrir une [Discussion](https://github.com/BENLK404/lkm-player/discussions) pour toute question sur le projet ou les contributions.

Merci de respecter le [Code de conduite](CODE_OF_CONDUCT.md).

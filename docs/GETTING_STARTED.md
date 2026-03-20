# 🚀 Guide de Démarrage Rapide - LKM Player

Ce guide vous accompagne étape par étape pour configurer et lancer LKM Player.

---

## ⚡ Installation Rapide (5 minutes)

### Étape 1 : Cloner et naviguer
```bash
cd musio
```

### Étape 2 : Installer les dépendances
```bash
flutter pub get
```

### Étape 3 : Générer le code
```bash
dart run build_runner build --delete-conflicting-outputs
```

Cette commande génère :
- ✅ Fichiers `.freezed.dart` (pour les modèles immutables)
- ✅ Fichiers `.g.dart` (pour JSON et Hive)
- ✅ Fichiers providers Riverpod

### Étape 4 : Configuration Android

Ouvrez `android/app/src/main/AndroidManifest.xml` et ajoutez :

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- PERMISSIONS - Ajoutez ces lignes AVANT <application> -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    
    <application
        android:label="LKM Player"
        android:icon="@mipmap/ic_launcher">
        
        <!-- SERVICE AUDIO - Ajoutez cette section DANS <application> -->
        <service
            android:name="com.ryanheise.audioservice.AudioService"
            android:exported="true"
            android:foregroundServiceType="mediaPlayback">
            <intent-filter>
                <action android:name="android.media.browse.MediaBrowserService"/>
            </intent-filter>
        </service>
        
        <!-- Le reste de votre configuration -->
        <activity ...>
        </activity>
    </application>
</manifest>
```

### Étape 5 : Lancer l'app
```bash
flutter run
```

---

## 🔍 Vérification de l'Installation

Après `build_runner`, vous devriez voir ces fichiers générés :

```
lib/features/music/data/models/
├── song_model.dart
├── song_model.freezed.dart      ✅ GÉNÉRÉ
├── song_model.g.dart            ✅ GÉNÉRÉ
├── album_model.dart
├── album_model.freezed.dart     ✅ GÉNÉRÉ
└── ...
```

---

## 🧪 Tester les Fonctionnalités

### Test 1 : Scanner la bibliothèque

```dart
// Dans n'importe quel widget Consumer
final songsAsync = ref.watch(allSongsProvider);

songsAsync.when(
  data: (songs) => Text('${songs.length} chansons trouvées'),
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => Text('Erreur: $err'),
);
```

### Test 2 : Jouer une chanson

```dart
final playerService = ref.read(audioPlayerServiceProvider);
final songs = ref.read(allSongsProvider).value ?? [];

if (songs.isNotEmpty) {
  await playerService.playSong(songs.first, queue: songs);
}
```

### Test 3 : Écouter l'état du player

```dart
final playerState = ref.watch(playerStateProvider);

playerState.when(
  data: (state) => Text(
    state.isPlaying ? 'En lecture' : 'En pause',
  ),
  loading: () => SizedBox.shrink(),
  error: (_, __) => SizedBox.shrink(),
);
```

---

## 🐛 Résolution de Problèmes Courants

### Erreur : "No file or variants found for asset"
**Solution** : Exécutez `flutter clean && flutter pub get`

### Erreur : "MissingPluginException"
**Solution** : 
1. Arrêtez l'app
2. Exécutez `flutter clean`
3. Relancez `flutter run`

### Erreur : "Permission denied"
**Solution** : Vérifiez que les permissions sont bien dans `AndroidManifest.xml`

### Les fichiers .g.dart ne se génèrent pas
**Solution** :
```bash
# Nettoyer les anciens fichiers
flutter clean

# Regénérer
dart run build_runner build --delete-conflicting-outputs
```

### L'app crash au démarrage
**Solution** : Vérifiez que Hive est bien initialisé dans `main.dart`

---

## 📱 Tester sur Appareil Réel

Pour les permissions audio, il est recommandé de tester sur un **appareil physique** :

1. Activez le mode développeur sur votre téléphone
2. Activez le débogage USB
3. Connectez votre téléphone
4. Exécutez `flutter devices` pour vérifier
5. Lancez `flutter run`

---

## 🎯 Prochaines Actions

Une fois l'installation terminée, vous pouvez :

1. **Créer l'interface utilisateur**
   - Écran de liste des chansons
   - Écran Now Playing
   - Bottom player widget

2. **Implémenter les fonctionnalités**
   - Recherche
   - Playlists
   - Favoris

3. **Personnaliser le design**
   - Thème clair/sombre
   - Animations
   - Couleurs adaptatives

---

## 💡 Conseils

- **Utilisez le watch mode** pour la génération automatique :
  ```bash
  dart run build_runner watch
  ```

- **Activez les logs** pour déboguer :
  ```dart
  // Dans main.dart
  debugPrint('État du player: ${playerState}');
  ```

- **Utilisez Riverpod DevTools** pour inspecter l'état :
  - Installez l'extension dans votre IDE
  - Accédez aux providers en temps réel

---

## 📞 Besoin d'Aide ?

- Consultez le [README.md](README.md) principal
- Vérifiez les [issues GitHub](https://github.com/votre-repo/issues)
- Documentation [Riverpod](https://riverpod.dev/)
- Documentation [Freezed](https://pub.dev/packages/freezed)

---

**Bon développement ! 🎵**

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musio/core/routing/app_router.dart';
import 'package:musio/features/music/presentation/providers/music_provider.dart';
import 'package:musio/features/settings/presentation/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minDuration = ref.watch(minSongDurationProvider);
    final isOnlineEnabled = ref.watch(onlineFeatureEnabledProvider);

    final themeMode = ref.watch(themeModeSettingProvider);
    final sleepTimerDefault = ref.watch(sleepTimerDefaultMinutesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Apparence'),
          themeMode.when(
            data: (modeIndex) => ListTile(
              title: const Text('Thème'),
              subtitle: Text(_themeModeLabel(modeIndex)),
              leading: const Icon(Icons.palette_outlined),
              onTap: () => _showThemeModeDialog(context, ref),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          sleepTimerDefault.when(
            data: (minutes) => ListTile(
              title: const Text('Minuteur de sommeil (défaut)'),
              subtitle: Text(minutes == 0 ? 'Désactivé' : '$minutes min'),
              leading: const Icon(Icons.timer_outlined),
              onTap: () => _showSleepTimerDefaultDialog(context, ref),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Général'),
          isOnlineEnabled.when(
            data: (enabled) => SwitchListTile(
              title: const Text('Fonctionnalités en ligne'),
              subtitle: const Text('Afficher le bouton pour découvrir de la musique en ligne'),
              value: enabled,
              onChanged: (value) {
                ref.read(onlineFeatureEnabledProvider.notifier).setEnabled(value);
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (e, s) => const SizedBox.shrink(),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Bibliothèque'),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Rescanner la bibliothèque'),
            subtitle: const Text('Chercher les nouveaux fichiers musicaux'),
            onTap: () {
              ref.read(musicProvider.notifier).rescanLibrary();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Scan de la bibliothèque démarré...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          minDuration.when(
            data: (duration) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text(
                    'Durée minimale des chansons',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Ignorer les fichiers audio de moins de ${duration}s',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Slider(
                  value: duration.toDouble(),
                  min: 0,
                  max: 60,
                  divisions: 12,
                  label: '${duration.round()}s',
                  onChanged: (value) {
                    ref.read(minSongDurationProvider.notifier).setDuration(value.round());
                  },
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (e, s) => const SizedBox.shrink(),
          ),
          const Divider(),
          ref.watch(excludeMessagingAppsProvider).when(
            data: (excluded) => SwitchListTile(
              title: const Text('Exclure les apps de messagerie'),
              subtitle: const Text(
                'Masque les audios WhatsApp, Telegram, Signal… '
                'lors du scan de la bibliothèque',
              ),
              secondary: const Icon(Icons.chat_bubble_outline),
              value: excluded,
              onChanged: (value) async {
                await ref
                    .read(excludeMessagingAppsProvider.notifier)
                    .setEnabled(value);
                ref.read(musicProvider.notifier).rescanLibrary();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value
                          ? 'Apps de messagerie exclues. Scan en cours…'
                          : 'Apps de messagerie incluses. Scan en cours…',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Stockage'),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined),
            title: const Text('Vider le cache des pochettes'),
            subtitle: const Text('Supprime les images des albums téléchargées'),
            onTap: () async {
              await ref.read(musicProvider.notifier).clearArtworkCache();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache des pochettes vidé.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'Statistiques'),
          ListTile(
            leading: const Icon(Icons.bar_chart_rounded),
            title: const Text('Statistiques d\'écoute'),
            subtitle: const Text('Titres, durée, top écoutes'),
            onTap: () => context.push(AppRouter.stats),
          ),
          const Divider(),
          _buildSectionHeader(context, 'À propos'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('À propos de LKM Player'),
            onTap: () => context.push(AppRouter.about),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(int index) {
    switch (index) {
      case 0:
        return 'Clair';
      case 1:
        return 'Sombre';
      default:
        return 'Système';
    }
  }

  void _showThemeModeDialog(BuildContext context, WidgetRef ref) {
    final current = ref.read(themeModeSettingProvider).valueOrNull ?? 1;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thème'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<int>(
              title: const Text('Clair'),
              value: 0,
              groupValue: current,
              onChanged: (v) {
                if (v != null) ref.read(themeModeSettingProvider.notifier).setMode(v);
                Navigator.pop(context);
              },
            ),
            RadioListTile<int>(
              title: const Text('Sombre'),
              value: 1,
              groupValue: current,
              onChanged: (v) {
                if (v != null) ref.read(themeModeSettingProvider.notifier).setMode(v);
                Navigator.pop(context);
              },
            ),
            RadioListTile<int>(
              title: const Text('Système'),
              value: 2,
              groupValue: current,
              onChanged: (v) {
                if (v != null) ref.read(themeModeSettingProvider.notifier).setMode(v);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSleepTimerDefaultDialog(BuildContext context, WidgetRef ref) {
    final current = ref.read(sleepTimerDefaultMinutesProvider).valueOrNull ?? 0;
    const options = [0, 15, 30, 45, 60];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Minuteur de sommeil (défaut)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options
                .map((m) => RadioListTile<int>(
                      title: Text(m == 0 ? 'Désactivé' : '$m min'),
                      value: m,
                      groupValue: current,
                      onChanged: (v) {
                        if (v != null) ref.read(sleepTimerDefaultMinutesProvider.notifier).setDefaultMinutes(v);
                        Navigator.pop(context);
                      },
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

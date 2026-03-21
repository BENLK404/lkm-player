import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musio/core/routing/app_router.dart';
import 'package:musio/core/theme/app_theme.dart';
import 'package:musio/features/download/presentation/providers/download_provider.dart';
import 'package:musio/features/music/presentation/providers/music_provider.dart';
import 'package:musio/features/settings/presentation/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minDuration = ref.watch(minSongDurationProvider);
    final isOnlineEnabled = ref.watch(onlineFeatureEnabledProvider);
    final themeMode = ref.watch(themeModeSettingProvider);
    final accentColor = ref.watch(accentColorSettingProvider);
    final sleepTimerDefault = ref.watch(sleepTimerDefaultMinutesProvider);

    return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Paramètres'),
        ),
        body: SafeArea(
      child: ListView(
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
          accentColor.when(
            data: (colorIndex) {
              final idx = colorIndex.clamp(0, AppTheme.accentColors.length - 1);
              return ListTile(
                title: const Text('Couleur principale'),
                subtitle: Text(AppTheme.accentColorNames[idx]),
                leading: const Icon(Icons.color_lens_outlined),
                trailing: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.accentColors[idx],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      width: 2,
                    ),
                  ),
                ),
                onTap: () => _showAccentColorDialog(context, ref, colorIndex),
              );
            },
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
              subtitle: const Text(
                  'Afficher le bouton pour découvrir de la musique en ligne'),
              value: enabled,
              onChanged: (value) {
                ref
                    .read(onlineFeatureEnabledProvider.notifier)
                    .setEnabled(value);
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (e, s) => const SizedBox.shrink(),
          ),
          ref.watch(downloadApiBaseUrlProvider).when(
            data: (baseUrl) => ListTile(
              leading: const Icon(Icons.cloud_download_outlined),
              title: const Text('Serveur de téléchargement'),
              subtitle: Text(
                baseUrl.isEmpty
                    ? 'Non configuré (défaut: https://lkm.emmanuekebeh.dev)'
                    : baseUrl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _showDownloadApiUrlDialog(context, ref, baseUrl),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          ref.watch(downloadDirectoryPathProvider).when(
            data: (dirPath) => ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Dossier des téléchargements'),
              subtitle: Text(
                dirPath,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: dirPath));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chemin copié. Collez-le dans votre gestionnaire de fichiers pour ouvrir le dossier.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
            loading: () => const ListTile(
              leading: Icon(Icons.folder_outlined),
              title: Text('Dossier des téléchargements'),
              subtitle: Text('Chargement…'),
            ),
            error: (_, __) => const SizedBox.shrink(),
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
                    ref
                        .read(minSongDurationProvider.notifier)
                        .setDuration(value.round());
                  },
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (e, s) => const SizedBox.shrink(),
          ),
          const Divider(),
          // Toggle global
          ref.watch(excludeMessagingAppsProvider).when(
                data: (excluded) => SwitchListTile(
                  title: const Text('Filtrer les apps de messagerie'),
                  subtitle: const Text(
                    'Active le filtrage des fichiers audio provenant des apps de chat',
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
                        content: Text(value
                            ? 'Filtrage activé. Scan en cours…'
                            : 'Filtrage désactivé. Scan en cours…'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

          // Toggles par app — visibles uniquement si le filtre global est actif
          ref.watch(excludeMessagingAppsProvider).maybeWhen(
                data: (excluded) => excluded
                    ? Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                            child: Text(
                              'Configurer par application',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          _buildAppToggle(
                            context,
                            ref,
                            icon: Icons.message,
                            label: 'WhatsApp',
                            subtitle: 'Exclure les audios WhatsApp',
                            value: ref.watch(excludeWhatsAppProvider),
                            onChanged: (v) => ref
                                .read(excludeWhatsAppProvider.notifier)
                                .setEnabled(v),
                          ),
                          _buildAppToggle(
                            context,
                            ref,
                            icon: Icons.send,
                            label: 'Telegram',
                            subtitle:
                                'Exclure les audios Telegram (bots inclus)',
                            value: ref.watch(excludeTelegramProvider),
                            onChanged: (v) => ref
                                .read(excludeTelegramProvider.notifier)
                                .setEnabled(v),
                          ),
                          _buildAppToggle(
                            context,
                            ref,
                            icon: Icons.lock_outline,
                            label: 'Signal',
                            subtitle: 'Exclure les audios Signal',
                            value: ref.watch(excludeSignalProvider),
                            onChanged: (v) => ref
                                .read(excludeSignalProvider.notifier)
                                .setEnabled(v),
                          ),
                          _buildAppToggle(
                            context,
                            ref,
                            icon: Icons.phone_in_talk_outlined,
                            label: 'Viber',
                            subtitle: 'Exclure les audios Viber',
                            value: ref.watch(excludeViberProvider),
                            onChanged: (v) => ref
                                .read(excludeViberProvider.notifier)
                                .setEnabled(v),
                          ),
                          _buildAppToggle(
                            context,
                            ref,
                            icon: Icons.headset_mic_outlined,
                            label: 'Discord',
                            subtitle: 'Exclure les audios Discord',
                            value: ref.watch(excludeDiscordProvider),
                            onChanged: (v) => ref
                                .read(excludeDiscordProvider.notifier)
                                .setEnabled(v),
                          ),
                          _buildAppToggle(
                            context,
                            ref,
                            icon: Icons.more_horiz,
                            label: 'Autres',
                            subtitle: 'Skype, Line, WeChat, Snapchat, Slack…',
                            value: ref.watch(excludeOtherMessagingProvider),
                            onChanged: (v) => ref
                                .read(excludeOtherMessagingProvider.notifier)
                                .setEnabled(v),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
                orElse: () => const SizedBox.shrink(),
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
    ));
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
                if (v != null)
                  ref.read(themeModeSettingProvider.notifier).setMode(v);
                Navigator.pop(context);
              },
            ),
            RadioListTile<int>(
              title: const Text('Sombre'),
              value: 1,
              groupValue: current,
              onChanged: (v) {
                if (v != null)
                  ref.read(themeModeSettingProvider.notifier).setMode(v);
                Navigator.pop(context);
              },
            ),
            RadioListTile<int>(
              title: const Text('Système'),
              value: 2,
              groupValue: current,
              onChanged: (v) {
                if (v != null)
                  ref.read(themeModeSettingProvider.notifier).setMode(v);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAccentColorDialog(BuildContext context, WidgetRef ref, int current) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Couleur principale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            AppTheme.accentColors.length,
            (index) {
              final color = AppTheme.accentColors[index];
              final name = AppTheme.accentColorNames[index];
              final isSelected = index == current.clamp(0, AppTheme.accentColors.length - 1);
              return InkWell(
                onTap: () {
                  ref.read(accentColorSettingProvider.notifier).setColorIndex(index);
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)]
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : null,
                        ),
                      ),
                      if (isSelected) ...[
                        const Spacer(),
                        Icon(Icons.check_rounded,
                            color: Theme.of(context).colorScheme.primary),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showDownloadApiUrlDialog(BuildContext context, WidgetRef ref, String currentUrl) {
    final controller = TextEditingController(text: currentUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Serveur de téléchargement'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://lkm.emmanuekebeh.dev',
            labelText: 'URL de l\'API Telegramusic',
          ),
          keyboardType: TextInputType.url,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(downloadApiBaseUrlProvider.notifier).setBaseUrl(controller.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
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
                        if (v != null)
                          ref
                              .read(sleepTimerDefaultMinutesProvider.notifier)
                              .setDefaultMinutes(v);
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

  Widget _buildAppToggle(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String label,
    required String subtitle,
    required AsyncValue<bool> value,
    required Future<void> Function(bool) onChanged,
  }) {
    return value.maybeWhen(
      data: (excluded) => SwitchListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 32),
        secondary: Icon(icon, size: 20),
        title: Text(label),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        value: excluded,
        onChanged: (val) async {
          await onChanged(val);
          ref.read(musicProvider.notifier).rescanLibrary();
        },
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

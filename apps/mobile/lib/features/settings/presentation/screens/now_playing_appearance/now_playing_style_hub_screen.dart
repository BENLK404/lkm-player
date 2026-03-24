import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musio/core/routing/app_router.dart';
import 'package:musio/features/player/presentation/providers/now_playing_design_provider.dart';

import 'now_playing_style_mapping_card.dart';

/// Point d’entrée : liste des styles, chacun a sa propre page de réglages.
class NowPlayingStyleHubScreen extends ConsumerWidget {
  const NowPlayingStyleHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active =
        ref.watch(nowPlayingDesignProvider).valueOrNull ?? NowPlayingDesign.classic;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Écran lecture en cours'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Choisis un style puis ouvre sa page pour l’activer et affiner les options. '
              'Chaque style a sa propre cartographie de réglages.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
          ),
          for (final d in NowPlayingDesign.values)
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: Icon(
                switch (d) {
                  NowPlayingDesign.classic => Icons.waves_rounded,
                  NowPlayingDesign.immersive => Icons.wallpaper_rounded,
                  NowPlayingDesign.minimal => Icons.density_small_rounded,
                  NowPlayingDesign.vinyl => Icons.album_rounded,
                },
                color: d == active ? scheme.primary : scheme.onSurfaceVariant,
              ),
              title: Row(
                children: [
                  Expanded(child: Text(d.title)),
                  if (d == active)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Chip(
                        label: const Text('Actif'),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Text(d.subtitle),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
              onTap: () {
                context.push(_routeFor(d));
              },
            ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: NowPlayingStyleMappingCard(
              styleId: 'global_prefs',
              entries: const [
                StyleMappingEntry(
                  jsonKey: 'now_playing_design_v1',
                  description: 'Index du style actif (SharedPreferences int)',
                ),
                StyleMappingEntry(
                  jsonKey: 'now_playing_tuning_v1',
                  description: 'JSON fusionné de tous les curseurs par style',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _routeFor(NowPlayingDesign d) {
    return switch (d) {
      NowPlayingDesign.classic => AppRouter.nowPlayingStyleClassic,
      NowPlayingDesign.immersive => AppRouter.nowPlayingStyleImmersive,
      NowPlayingDesign.minimal => AppRouter.nowPlayingStyleMinimal,
      NowPlayingDesign.vinyl => AppRouter.nowPlayingStyleVinyl,
    };
  }
}

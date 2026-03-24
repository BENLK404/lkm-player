import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musio/features/player/presentation/providers/now_playing_design_provider.dart';
import 'package:musio/features/player/presentation/providers/now_playing_tuning_provider.dart';

import 'now_playing_style_mapping_card.dart';

class MinimalNowPlayingStyleScreen extends ConsumerWidget {
  const MinimalNowPlayingStyleScreen({super.key});

  static const String styleId = 'minimal';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tuning =
        ref.watch(nowPlayingTuningProvider).valueOrNull ?? const NowPlayingTuning();
    final active = ref.watch(nowPlayingDesignProvider).valueOrNull ==
        NowPlayingDesign.minimal;
    final notifier = ref.read(nowPlayingTuningProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Style minimal'),
      ),
      body: ListView(
        children: [
          if (active)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Material(
                color: scheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: scheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Ce style est celui affiché sur l’écran lecture.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: FilledButton.icon(
              onPressed: () async {
                await ref
                    .read(nowPlayingDesignProvider.notifier)
                    .setDesign(NowPlayingDesign.minimal);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Style minimal activé'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.touch_app_rounded),
              label: const Text('Utiliser le style minimal'),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Personnalisation',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Taille de la pochette (fraction de la largeur d’écran).',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
          Slider(
            value: tuning.minimalCoverFraction.clamp(0.45, 0.88),
            min: 0.45,
            max: 0.88,
            divisions: 43,
            label: '${(tuning.minimalCoverFraction * 100).round()} %',
            onChanged: (v) {
              notifier.setTuning(tuning.copyWith(minimalCoverFraction: v));
            },
          ),
          NowPlayingStyleMappingCard(
            styleId: styleId,
            entries: const [
              StyleMappingEntry(
                jsonKey: 'minimalCoverFraction',
                description: 'largeur_pochette / largeur_écran',
                unit: '0.45–0.88',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

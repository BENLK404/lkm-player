import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musio/features/player/presentation/providers/now_playing_design_provider.dart';
import 'package:musio/features/player/presentation/providers/now_playing_tuning_provider.dart';

import 'now_playing_style_mapping_card.dart';

class VinylNowPlayingStyleScreen extends ConsumerWidget {
  const VinylNowPlayingStyleScreen({super.key});

  static const String styleId = 'vinyl';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tuning =
        ref.watch(nowPlayingTuningProvider).valueOrNull ?? const NowPlayingTuning();
    final active = ref.watch(nowPlayingDesignProvider).valueOrNull ==
        NowPlayingDesign.vinyl;
    final notifier = ref.read(nowPlayingTuningProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Style vinyle'),
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
                    .setDesign(NowPlayingDesign.vinyl);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Style vinyle activé'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.touch_app_rounded),
              label: const Text('Utiliser le style vinyle'),
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
          ListTile(
            title: const Text('Marge disque (anneau)'),
            subtitle: Slider(
              value: tuning.vinylDiscPadding.clamp(4.0, 22.0),
              min: 4,
              max: 22,
              divisions: 18,
              label: tuning.vinylDiscPadding.toStringAsFixed(0),
              onChanged: (v) {
                notifier.setTuning(tuning.copyWith(vinylDiscPadding: v));
              },
            ),
          ),
          ListTile(
            title: const Text('Taille max. de la pochette'),
            subtitle: Slider(
              value: tuning.vinylCoverMaxSide.clamp(220.0, 400.0),
              min: 220,
              max: 400,
              divisions: 36,
              label: tuning.vinylCoverMaxSide.round().toString(),
              onChanged: (v) {
                notifier.setTuning(tuning.copyWith(vinylCoverMaxSide: v));
              },
            ),
          ),
          NowPlayingStyleMappingCard(
            styleId: styleId,
            entries: const [
              StyleMappingEntry(
                jsonKey: 'vinylDiscPadding',
                description: 'Padding entre bord du disque et image',
                unit: 'dp',
              ),
              StyleMappingEntry(
                jsonKey: 'vinylCoverMaxSide',
                description: 'Côté max. calculé avant clamp écran',
                unit: 'dp',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

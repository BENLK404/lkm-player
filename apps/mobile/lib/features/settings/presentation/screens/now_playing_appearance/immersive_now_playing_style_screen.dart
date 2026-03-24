import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musio/features/player/presentation/providers/now_playing_design_provider.dart';
import 'package:musio/features/player/presentation/providers/now_playing_tuning_provider.dart';

import 'now_playing_style_mapping_card.dart';

class ImmersiveNowPlayingStyleScreen extends ConsumerWidget {
  const ImmersiveNowPlayingStyleScreen({super.key});

  static const String styleId = 'immersive';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tuning =
        ref.watch(nowPlayingTuningProvider).valueOrNull ?? const NowPlayingTuning();
    final active = ref.watch(nowPlayingDesignProvider).valueOrNull ==
        NowPlayingDesign.immersive;
    final notifier = ref.read(nowPlayingTuningProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Style immersion'),
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
                    .setDesign(NowPlayingDesign.immersive);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Style immersion activé'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.touch_app_rounded),
              label: const Text('Utiliser le style immersion'),
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
            title: const Text('Intensité du flou'),
            subtitle: Slider(
              value: tuning.immersiveBlurSigma.clamp(20.0, 80.0),
              min: 20,
              max: 80,
              divisions: 30,
              label: tuning.immersiveBlurSigma.round().toString(),
              onChanged: (v) {
                notifier.setTuning(tuning.copyWith(immersiveBlurSigma: v));
              },
            ),
          ),
          ListTile(
            title: const Text('Assombrissement du fond'),
            subtitle: Slider(
              value: tuning.immersiveOverlayDarken.clamp(0.15, 0.7),
              min: 0.15,
              max: 0.7,
              divisions: 55,
              label: tuning.immersiveOverlayDarken.toStringAsFixed(2),
              onChanged: (v) {
                notifier.setTuning(
                  tuning.copyWith(immersiveOverlayDarken: v),
                );
              },
            ),
          ),
          NowPlayingStyleMappingCard(
            styleId: styleId,
            entries: const [
              StyleMappingEntry(
                jsonKey: 'immersiveBlurSigma',
                description: 'Sigma du flou gaussien sur la pochette',
              ),
              StyleMappingEntry(
                jsonKey: 'immersiveOverlayDarken',
                description: 'Opacité du voile sombre',
                unit: '0–1',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

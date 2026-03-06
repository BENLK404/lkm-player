import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:musio/features/player/presentation/providers/audio_player_provider.dart';

/// Retourne le rôle d'une bande selon sa fréquence centrale (Hz).
String _bandLabelForFrequency(double centerFrequencyHz) {
  final hz = centerFrequencyHz;
  if (hz < 90) return 'Graves';
  if (hz < 200) return 'Bas-médiums';
  if (hz < 700) return 'Médiums';
  if (hz < 5000) return 'Haut-médiums';
  return 'Aigus';
}

class EqualizerSheet extends ConsumerStatefulWidget {
  const EqualizerSheet({super.key});

  @override
  ConsumerState<EqualizerSheet> createState() => _EqualizerSheetState();
}

class _EqualizerSheetState extends ConsumerState<EqualizerSheet> {
  late final ja.AndroidEqualizer _equalizer;

  @override
  void initState() {
    super.initState();
    _equalizer = ref.read(audioPlayerServiceProvider).equalizer;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = MediaQuery.sizeOf(context).height * 0.80;
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight.isFinite
                    ? constraints.maxHeight.clamp(0, maxHeight)
                    : maxHeight,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          tooltip: 'Fermer',
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.graphic_eq_rounded,
                            color: scheme.onPrimaryContainer,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Égaliseur',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      children: [
                        StreamBuilder<bool>(
                          stream: _equalizer.enabledStream,
                          builder: (context, snapshot) {
                            final enabled = snapshot.data ?? false;
                            return Card(
                              child: SwitchListTile(
                                title: Text(
                                  'Activé',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                subtitle: Text(
                                  enabled
                                      ? 'Les réglages sont appliqués'
                                      : 'Désactivé',
                                ),
                                value: enabled,
                                onChanged: (value) => _equalizer.setEnabled(value),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Bandes',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 260,
                          child: FutureBuilder<ja.AndroidEqualizerParameters>(
                            future: _equalizer.parameters,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Center(
                                  child: CircularProgressIndicator(
                                    color: primary,
                                    strokeWidth: 2,
                                  ),
                                );
                              }
                              final parameters = snapshot.data!;
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: parameters.bands
                                    .map((band) => _buildBandSlider(
                                          context,
                                          band,
                                          parameters.minDecibels,
                                          parameters.maxDecibels,
                                        ))
                                    .toList(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBandSlider(
    BuildContext context,
    ja.AndroidEqualizerBand band,
    double minGain,
    double maxGain,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final label = _bandLabelForFrequency(band.centerFrequency);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Expanded(
              child: StreamBuilder<double>(
                stream: band.gainStream,
                builder: (context, snapshot) {
                  final gain = snapshot.data ?? 0.0;
                  return RotatedBox(
                    quarterTurns: -1,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: primary,
                        inactiveTrackColor:
                            scheme.onSurface.withValues(alpha: 0.12),
                        thumbColor: primary,
                        overlayColor: primary.withValues(alpha: 0.2),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        min: minGain,
                        max: maxGain,
                        value: gain,
                        onChanged: (value) => band.setGain(value),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            StreamBuilder<double>(
              stream: band.gainStream,
              builder: (context, snapshot) {
                final gain = snapshot.data ?? 0.0;
                return Text(
                  gain >= 0 ? '+${gain.toStringAsFixed(0)}' : gain.toStringAsFixed(0),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

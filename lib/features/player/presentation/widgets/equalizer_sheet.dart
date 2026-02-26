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

  static const _bgDark = Color(0xFF121212);
  static const _bgGradientTop = Color(0xFF1a1a2e);

  @override
  void initState() {
    super.initState();
    _equalizer = ref.read(audioPlayerServiceProvider).equalizer;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: const BoxDecoration(
        color: _bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _bgGradientTop.withOpacity(0.95),
                    _bgGradientTop.withOpacity(0.0),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      color: Colors.white,
                      iconSize: 32,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.graphic_eq_rounded, color: primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Égaliseur',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: StreamBuilder<bool>(
                stream: _equalizer.enabledStream,
                builder: (context, snapshot) {
                  final enabled = snapshot.data ?? false;
                  return Material(
                    color: Colors.white.withOpacity(enabled ? 0.08 : 0.04),
                    borderRadius: BorderRadius.circular(14),
                    child: SwitchListTile(
                      title: Text(
                        'Activé',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        enabled ? 'Les réglages sont appliqués' : 'Désactivé',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                      value: enabled,
                      activeColor: primary,
                      onChanged: (value) => _equalizer.setEnabled(value),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Bandes',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 20),
          ],
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
    final primary = Theme.of(context).colorScheme.primary;
    final label = _bandLabelForFrequency(band.centerFrequency);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              label,
              style: TextStyle(
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
                        inactiveTrackColor: Colors.white12,
                        thumbColor: primary,
                        overlayColor: primary.withOpacity(0.2),
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
                  style: TextStyle(
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

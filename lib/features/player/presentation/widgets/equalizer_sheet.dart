import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:musio/features/player/presentation/providers/audio_player_provider.dart';

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
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Égaliseur', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          StreamBuilder<bool>(
            stream: _equalizer.enabledStream,
            builder: (context, snapshot) {
              final enabled = snapshot.data ?? false;
              return SwitchListTile(
                title: const Text('Activé'),
                value: enabled,
                onChanged: (value) {
                  _equalizer.setEnabled(value);
                },
              );
            },
          ),
          const Divider(),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: FutureBuilder<ja.AndroidEqualizerParameters>(
              future: _equalizer.parameters,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final parameters = snapshot.data!;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
    );
  }

  Widget _buildBandSlider(BuildContext context, ja.AndroidEqualizerBand band,
      double minGain, double maxGain) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${band.centerFrequency.round() < 1000 ? band.centerFrequency.round() : (band.centerFrequency / 1000).toStringAsFixed(1) + 'k'}',
            style: const TextStyle(fontSize: 12),
          ),
          Expanded(
            child: StreamBuilder<double>(
              stream: band.gainStream,
              builder: (context, snapshot) {
                final gain = snapshot.data ?? 0.0;
                return RotatedBox(
                  quarterTurns: -1,
                  child: Slider(
                    min: minGain,
                    max: maxGain,
                    value: gain,
                    onChanged: (value) {
                      band.setGain(value);
                    },
                  ),
                );
              },
            ),
          ),
          StreamBuilder<double>(
            stream: band.gainStream,
            builder: (context, snapshot) {
              final gain = snapshot.data ?? 0.0;
              return Text(
                '${gain.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 12),
              );
            },
          ),
        ],
      ),
    );
  }
}

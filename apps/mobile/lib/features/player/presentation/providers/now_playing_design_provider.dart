import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Variantes d’écran lecture en cours (persistées).
enum NowPlayingDesign {
  classic,
  immersive,
  minimal,
  vinyl,
}

extension NowPlayingDesignLabels on NowPlayingDesign {
  String get title => switch (this) {
        NowPlayingDesign.classic => 'Classique',
        NowPlayingDesign.immersive => 'Immersion',
        NowPlayingDesign.minimal => 'Minimal',
        NowPlayingDesign.vinyl => 'Vinyle',
      };

  String get subtitle => switch (this) {
        NowPlayingDesign.classic => 'Barre onde, pochette arrondie',
        NowPlayingDesign.immersive => 'Fond flou, texte clair',
        NowPlayingDesign.minimal => 'Pochette discrète, barre simple',
        NowPlayingDesign.vinyl => 'Disque circulaire',
      };
}

class NowPlayingDesignNotifier extends AsyncNotifier<NowPlayingDesign> {
  static const _key = 'now_playing_design_v1';

  @override
  Future<NowPlayingDesign> build() async {
    final p = await SharedPreferences.getInstance();
    final i = p.getInt(_key) ?? 0;
    final idx = i.clamp(0, NowPlayingDesign.values.length - 1);
    return NowPlayingDesign.values[idx];
  }

  Future<void> setDesign(NowPlayingDesign d) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_key, d.index);
    state = AsyncData(d);
  }
}

final nowPlayingDesignProvider =
    AsyncNotifierProvider<NowPlayingDesignNotifier, NowPlayingDesign>(
  NowPlayingDesignNotifier.new,
);

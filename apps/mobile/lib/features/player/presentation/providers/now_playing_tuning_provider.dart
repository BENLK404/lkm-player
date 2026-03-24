import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Réglages fins par style (persistés JSON — extensible / « mappable »).
class NowPlayingTuning {
  const NowPlayingTuning({
    this.classicWaveAmplitude = 5.0,
    this.immersiveBlurSigma = 48.0,
    this.immersiveOverlayDarken = 0.38,
    this.minimalCoverFraction = 0.62,
    this.vinylDiscPadding = 10.0,
    this.vinylCoverMaxSide = 340.0,
  });

  /// Amplitude visuelle de l’onde (classique). Clé JSON : `classicWaveAmplitude`
  final double classicWaveAmplitude;

  /// Flou du fond (immersion). Clé : `immersiveBlurSigma`
  final double immersiveBlurSigma;

  /// Assombrissement 0–1 sur le fond (immersion). Clé : `immersiveOverlayDarken`
  final double immersiveOverlayDarken;

  /// Largeur pochette = fraction * largeur écran (minimal). Clé : `minimalCoverFraction`
  final double minimalCoverFraction;

  /// Anneau disque : padding intérieur (vinyle). Clé : `vinylDiscPadding`
  final double vinylDiscPadding;

  /// Côté max de la pochette dans le disque (vinyle). Clé : `vinylCoverMaxSide`
  final double vinylCoverMaxSide;

  NowPlayingTuning copyWith({
    double? classicWaveAmplitude,
    double? immersiveBlurSigma,
    double? immersiveOverlayDarken,
    double? minimalCoverFraction,
    double? vinylDiscPadding,
    double? vinylCoverMaxSide,
  }) {
    return NowPlayingTuning(
      classicWaveAmplitude:
          classicWaveAmplitude ?? this.classicWaveAmplitude,
      immersiveBlurSigma: immersiveBlurSigma ?? this.immersiveBlurSigma,
      immersiveOverlayDarken:
          immersiveOverlayDarken ?? this.immersiveOverlayDarken,
      minimalCoverFraction: minimalCoverFraction ?? this.minimalCoverFraction,
      vinylDiscPadding: vinylDiscPadding ?? this.vinylDiscPadding,
      vinylCoverMaxSide: vinylCoverMaxSide ?? this.vinylCoverMaxSide,
    );
  }

  Map<String, dynamic> toJson() => {
        'classicWaveAmplitude': classicWaveAmplitude,
        'immersiveBlurSigma': immersiveBlurSigma,
        'immersiveOverlayDarken': immersiveOverlayDarken,
        'minimalCoverFraction': minimalCoverFraction,
        'vinylDiscPadding': vinylDiscPadding,
        'vinylCoverMaxSide': vinylCoverMaxSide,
      };

  factory NowPlayingTuning.fromJson(Map<String, dynamic> j) {
    double d(String k, double def) {
      final v = j[k];
      if (v is num) return v.toDouble();
      return def;
    }

    return NowPlayingTuning(
      classicWaveAmplitude: d('classicWaveAmplitude', 5.0),
      immersiveBlurSigma: d('immersiveBlurSigma', 48.0),
      immersiveOverlayDarken: d('immersiveOverlayDarken', 0.38).clamp(0.05, 0.95),
      minimalCoverFraction: d('minimalCoverFraction', 0.62).clamp(0.4, 0.92),
      vinylDiscPadding: d('vinylDiscPadding', 10.0).clamp(4.0, 24.0),
      vinylCoverMaxSide: d('vinylCoverMaxSide', 340.0).clamp(200.0, 420.0),
    );
  }
}

class NowPlayingTuningNotifier extends AsyncNotifier<NowPlayingTuning> {
  static const _key = 'now_playing_tuning_v1';

  @override
  Future<NowPlayingTuning> build() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null || raw.isEmpty) return const NowPlayingTuning();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return NowPlayingTuning.fromJson(map);
    } catch (_) {
      return const NowPlayingTuning();
    }
  }

  Future<void> setTuning(NowPlayingTuning next) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(next.toJson()));
    state = AsyncData(next);
  }
}

final nowPlayingTuningProvider =
    AsyncNotifierProvider<NowPlayingTuningNotifier, NowPlayingTuning>(
  NowPlayingTuningNotifier.new,
);

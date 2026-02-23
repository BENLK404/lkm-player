import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musio/features/player/data/services/audio_handler.dart';

/// Provider pour accéder au [MusioAudioHandler].
/// Doit être overridé dans [main] avec l'instance créée par [AudioService.init].
final audioHandlerProvider = Provider<MusioAudioHandler>((ref) {
  throw UnimplementedError(
    'audioHandlerProvider must be overridden in main() with the AudioService handler.',
  );
});

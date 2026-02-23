import 'package:audiotagger/audiotagger.dart';
import 'package:audiotagger/models/tag.dart';
import 'package:musio/core/utils/app_logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'metadata_provider.g.dart';

@riverpod
Future<Tag?> songMetadata(SongMetadataRef ref, String filePath) async {
  final tagger = Audiotagger();
  try {
    final tags = await tagger.readTags(path: filePath);
    return tags;
  } catch (e) {
    AppLogger.w('Erreur de lecture des métadonnées pour $filePath', error: e);
    return null;
  }
}

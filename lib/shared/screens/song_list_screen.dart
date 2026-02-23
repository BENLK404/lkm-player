import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musio/features/music/data/models/song_model.dart';
import 'package:musio/shared/widgets/song_tile.dart';

class SongListScreen extends ConsumerWidget {
  final String title;
  final List<SongModel> songs;

  const SongListScreen({
    super.key,
    required this.title,
    required this.songs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return SongTile(
            song: song,
            playlist: songs,
            songIndex: index,
          );
        },
      ),
    );
  }
}

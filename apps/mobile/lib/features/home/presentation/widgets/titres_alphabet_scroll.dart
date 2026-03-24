import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:musio/features/music/data/models/song_model.dart';

/// Lettres affichées dans la barre d’index (# puis A–Z).
const List<String> kAlphabetIndexLetters = [
  '#',
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J',
  'K',
  'L',
  'M',
  'N',
  'O',
  'P',
  'Q',
  'R',
  'S',
  'T',
  'U',
  'V',
  'W',
  'X',
  'Y',
  'Z',
];

/// Hauteur moyenne (ListTile + séparateur) pour lier le scroll à l’index.
const double _kEstimatedRowExtent = 73.0;

/// Première lettre d’index pour le tri (# = chiffres / symboles / non-latin).
String indexLetterForSongTitle(String rawTitle) {
  final t = rawTitle.trim();
  if (t.isEmpty) return '#';
  final it = t.characters;
  if (it.isEmpty) return '#';
  final ch = it.first.toUpperCase();
  if (ch.isEmpty) return '#';
  final cu = ch.codeUnitAt(0);
  if (cu >= 0x41 && cu <= 0x5A) return ch;
  if (cu >= 0x30 && cu <= 0x39) return '#';
  return '#';
}

/// Trie une copie par titre (insensible à la casse).
List<T> sortByTitle<T>(List<T> items, String Function(T) titleOf) {
  final copy = List<T>.from(items);
  copy.sort(
    (a, b) => titleOf(a).toLowerCase().compareTo(titleOf(b).toLowerCase()),
  );
  return copy;
}

Map<String, int> _firstIndexByLetter(List<SongModel> sortedSongs) {
  final map = <String, int>{};
  for (var i = 0; i < sortedSongs.length; i++) {
    final L = indexLetterForSongTitle(sortedSongs[i].title);
    map.putIfAbsent(L, () => i);
  }
  return map;
}

/// Liste avec marge droite pour la barre d’alphabet + rail synchronisé au scroll.
class TitresAlphabetScrollView extends StatefulWidget {
  const TitresAlphabetScrollView({
    super.key,
    required this.sortedSongs,
    required this.tileBuilder,
    required this.separatorBuilder,
    this.physics,
  });

  final List<SongModel> sortedSongs;
  final Widget Function(BuildContext context, int index, SongModel song)
      tileBuilder;
  final Widget Function(BuildContext context, int index) separatorBuilder;
  final ScrollPhysics? physics;

  @override
  State<TitresAlphabetScrollView> createState() =>
      _TitresAlphabetScrollViewState();
}

class _TitresAlphabetScrollViewState extends State<TitresAlphabetScrollView> {
  final ScrollController _controller = ScrollController();
  final Map<String, GlobalKey> _letterKeys = {
    for (final L in kAlphabetIndexLetters) L: GlobalKey(),
  };

  /// Lettre alignée sur le titre en bas de la zone visible (suit le scroll).
  late String _scrollHighlightLetter;

  @override
  void initState() {
    super.initState();
    _scrollHighlightLetter = _initialLetter();
    _controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncLetterFromScroll());
  }

  String _initialLetter() {
    final songs = widget.sortedSongs;
    if (songs.isEmpty) return '#';
    return indexLetterForSongTitle(songs.first.title);
  }

  @override
  void didUpdateWidget(TitresAlphabetScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sortedSongs != widget.sortedSongs) {
      _scrollHighlightLetter = _initialLetter();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncLetterFromScroll();
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() => _syncLetterFromScroll();

  void _syncLetterFromScroll() {
    if (!mounted) return;
    final songs = widget.sortedSongs;
    if (songs.isEmpty) return;
    if (!_controller.hasClients) return;

    final position = _controller.position;
    // Bas de la fenêtre visible, en coordonnées du contenu défilant.
    final bottomContentY = position.pixels + position.viewportDimension;
    var index = (bottomContentY / _kEstimatedRowExtent).floor();
    if (index < 0) index = 0;
    if (index >= songs.length) index = songs.length - 1;

    final letter = indexLetterForSongTitle(songs[index].title);
    if (letter != _scrollHighlightLetter) {
      setState(() => _scrollHighlightLetter = letter);
    }
  }

  void _scrollToLetter(String letter) {
    final ctx = _letterKeys[letter]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.02,
    ).then((_) {
      if (mounted) _syncLetterFromScroll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final songs = widget.sortedSongs;
    final firstByLetter = _firstIndexByLetter(songs);
    final lettersWithContent = firstByLetter.keys.toSet();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (n) {
            // Fin / momentum : resync après layout (hauteurs réelles).
            if (n is ScrollEndNotification) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _syncLetterFromScroll();
              });
            }
            return false;
          },
          child: ListView.separated(
            controller: _controller,
            physics: widget.physics,
            padding: const EdgeInsets.only(right: 22, bottom: 8),
            itemCount: songs.length,
            separatorBuilder: widget.separatorBuilder,
            itemBuilder: (context, index) {
              final song = songs[index];
              final L = indexLetterForSongTitle(song.title);
              final anchorKey =
                  firstByLetter[L] == index ? _letterKeys[L] : null;
              Widget child = widget.tileBuilder(context, index, song);
              if (anchorKey != null) {
                child = KeyedSubtree(key: anchorKey, child: child);
              }
              return child;
            },
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          bottom: 0,
          child: _AlphabetRail(
            totalTracks: songs.length,
            lettersWithContent: lettersWithContent,
            scrollHighlightLetter: _scrollHighlightLetter,
            onLetter: _scrollToLetter,
            scheme: scheme,
          ),
        ),
      ],
    );
  }
}

class _AlphabetRail extends StatelessWidget {
  const _AlphabetRail({
    required this.totalTracks,
    required this.lettersWithContent,
    required this.scrollHighlightLetter,
    required this.onLetter,
    required this.scheme,
  });

  final int totalTracks;
  final Set<String> lettersWithContent;
  /// Lettre courante (titre en bas de l’écran visible).
  final String scrollHighlightLetter;
  final void Function(String letter) onLetter;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final muted = scheme.onSurfaceVariant.withValues(alpha: 0.45);
    final active = scheme.primary.withValues(alpha: 0.95);

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 20,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              child: Text(
                '$totalTracks',
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final h = constraints.maxHeight;
                  final n = kAlphabetIndexLetters.length;
                  final slotH = h / n;
                  var idx = kAlphabetIndexLetters.indexOf(scrollHighlightLetter);
                  if (idx < 0) idx = 0;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        top: idx * slotH,
                        left: 0,
                        right: 0,
                        height: slotH,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          for (final L in kAlphabetIndexLetters)
                            Expanded(
                              child: _LetterCell(
                                letter: L,
                                hasTarget: lettersWithContent.contains(L),
                                isScrollHighlight: L == scrollHighlightLetter,
                                activeColor: active,
                                mutedColor: muted,
                                onTap: () => onLetter(L),
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LetterCell extends StatelessWidget {
  const _LetterCell({
    required this.letter,
    required this.hasTarget,
    required this.isScrollHighlight,
    required this.activeColor,
    required this.mutedColor,
    required this.onTap,
  });

  final String letter;
  final bool hasTarget;
  final bool isScrollHighlight;
  final Color activeColor;
  final Color mutedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (isScrollHighlight) {
      color = activeColor;
    } else if (hasTarget) {
      color = mutedColor.withValues(alpha: 0.85);
    } else {
      color = mutedColor.withValues(alpha: 0.35);
    }

    return SizedBox.expand(
      child: InkWell(
        onTap: hasTarget ? onTap : null,
        borderRadius: BorderRadius.circular(4),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              fontSize: 8.5,
              height: 1,
              fontWeight:
                  isScrollHighlight ? FontWeight.w900 : FontWeight.w500,
              color: color,
            ),
            child: Text(letter),
          ),
        ),
      ),
    );
  }
}

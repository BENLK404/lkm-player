// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$musicRepositoryHash() => r'1f25c35c6566013e3f2988fbcf6f3c5b25c21ba3';

/// Provider singleton pour le repository music
///
/// Copied from [musicRepository].
@ProviderFor(musicRepository)
final musicRepositoryProvider = Provider<MusicRepository>.internal(
  musicRepository,
  name: r'musicRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$musicRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MusicRepositoryRef = ProviderRef<MusicRepository>;
String _$allSongsHash() => r'b3341a652dc594d4e64fdc5892159bb6b668640f';

/// Provider pour toutes les chansons (Synchrone)
///
/// Copied from [allSongs].
@ProviderFor(allSongs)
final allSongsProvider = AutoDisposeProvider<List<SongModel>>.internal(
  allSongs,
  name: r'allSongsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allSongsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AllSongsRef = AutoDisposeProviderRef<List<SongModel>>;
String _$allAlbumsHash() => r'7cf04a2755ccc10e88877e52576ad8019de056c7';

/// Provider pour tous les albums (Synchrone)
///
/// Copied from [allAlbums].
@ProviderFor(allAlbums)
final allAlbumsProvider = AutoDisposeProvider<List<AlbumModel>>.internal(
  allAlbums,
  name: r'allAlbumsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allAlbumsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AllAlbumsRef = AutoDisposeProviderRef<List<AlbumModel>>;
String _$allArtistsHash() => r'90394a5bc12fcbd66972cedbf154f99044f3ca20';

/// Provider pour tous les artistes (Synchrone)
///
/// Copied from [allArtists].
@ProviderFor(allArtists)
final allArtistsProvider = AutoDisposeProvider<List<ArtistModel>>.internal(
  allArtists,
  name: r'allArtistsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allArtistsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AllArtistsRef = AutoDisposeProviderRef<List<ArtistModel>>;
String _$albumSongsHash() => r'cc087c951a13a9c4227c18cf63705578aa502256';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Provider pour les chansons d'un album spécifique (Synchrone)
///
/// Copied from [albumSongs].
@ProviderFor(albumSongs)
const albumSongsProvider = AlbumSongsFamily();

/// Provider pour les chansons d'un album spécifique (Synchrone)
///
/// Copied from [albumSongs].
class AlbumSongsFamily extends Family<List<SongModel>> {
  /// Provider pour les chansons d'un album spécifique (Synchrone)
  ///
  /// Copied from [albumSongs].
  const AlbumSongsFamily();

  /// Provider pour les chansons d'un album spécifique (Synchrone)
  ///
  /// Copied from [albumSongs].
  AlbumSongsProvider call(
    String albumId,
  ) {
    return AlbumSongsProvider(
      albumId,
    );
  }

  @override
  AlbumSongsProvider getProviderOverride(
    covariant AlbumSongsProvider provider,
  ) {
    return call(
      provider.albumId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'albumSongsProvider';
}

/// Provider pour les chansons d'un album spécifique (Synchrone)
///
/// Copied from [albumSongs].
class AlbumSongsProvider extends AutoDisposeProvider<List<SongModel>> {
  /// Provider pour les chansons d'un album spécifique (Synchrone)
  ///
  /// Copied from [albumSongs].
  AlbumSongsProvider(
    String albumId,
  ) : this._internal(
          (ref) => albumSongs(
            ref as AlbumSongsRef,
            albumId,
          ),
          from: albumSongsProvider,
          name: r'albumSongsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$albumSongsHash,
          dependencies: AlbumSongsFamily._dependencies,
          allTransitiveDependencies:
              AlbumSongsFamily._allTransitiveDependencies,
          albumId: albumId,
        );

  AlbumSongsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.albumId,
  }) : super.internal();

  final String albumId;

  @override
  Override overrideWith(
    List<SongModel> Function(AlbumSongsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AlbumSongsProvider._internal(
        (ref) => create(ref as AlbumSongsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        albumId: albumId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<List<SongModel>> createElement() {
    return _AlbumSongsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AlbumSongsProvider && other.albumId == albumId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, albumId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AlbumSongsRef on AutoDisposeProviderRef<List<SongModel>> {
  /// The parameter `albumId` of this provider.
  String get albumId;
}

class _AlbumSongsProviderElement
    extends AutoDisposeProviderElement<List<SongModel>> with AlbumSongsRef {
  _AlbumSongsProviderElement(super.provider);

  @override
  String get albumId => (origin as AlbumSongsProvider).albumId;
}

String _$artistSongsHash() => r'34ab4d45e1760ebb1e21a1f80d7a2ee1c7b69dcb';

/// Provider pour les chansons d'un artiste spécifique (Synchrone)
///
/// Copied from [artistSongs].
@ProviderFor(artistSongs)
const artistSongsProvider = ArtistSongsFamily();

/// Provider pour les chansons d'un artiste spécifique (Synchrone)
///
/// Copied from [artistSongs].
class ArtistSongsFamily extends Family<List<SongModel>> {
  /// Provider pour les chansons d'un artiste spécifique (Synchrone)
  ///
  /// Copied from [artistSongs].
  const ArtistSongsFamily();

  /// Provider pour les chansons d'un artiste spécifique (Synchrone)
  ///
  /// Copied from [artistSongs].
  ArtistSongsProvider call(
    String artistId,
  ) {
    return ArtistSongsProvider(
      artistId,
    );
  }

  @override
  ArtistSongsProvider getProviderOverride(
    covariant ArtistSongsProvider provider,
  ) {
    return call(
      provider.artistId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'artistSongsProvider';
}

/// Provider pour les chansons d'un artiste spécifique (Synchrone)
///
/// Copied from [artistSongs].
class ArtistSongsProvider extends AutoDisposeProvider<List<SongModel>> {
  /// Provider pour les chansons d'un artiste spécifique (Synchrone)
  ///
  /// Copied from [artistSongs].
  ArtistSongsProvider(
    String artistId,
  ) : this._internal(
          (ref) => artistSongs(
            ref as ArtistSongsRef,
            artistId,
          ),
          from: artistSongsProvider,
          name: r'artistSongsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$artistSongsHash,
          dependencies: ArtistSongsFamily._dependencies,
          allTransitiveDependencies:
              ArtistSongsFamily._allTransitiveDependencies,
          artistId: artistId,
        );

  ArtistSongsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.artistId,
  }) : super.internal();

  final String artistId;

  @override
  Override overrideWith(
    List<SongModel> Function(ArtistSongsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ArtistSongsProvider._internal(
        (ref) => create(ref as ArtistSongsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        artistId: artistId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<List<SongModel>> createElement() {
    return _ArtistSongsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ArtistSongsProvider && other.artistId == artistId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, artistId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ArtistSongsRef on AutoDisposeProviderRef<List<SongModel>> {
  /// The parameter `artistId` of this provider.
  String get artistId;
}

class _ArtistSongsProviderElement
    extends AutoDisposeProviderElement<List<SongModel>> with ArtistSongsRef {
  _ArtistSongsProviderElement(super.provider);

  @override
  String get artistId => (origin as ArtistSongsProvider).artistId;
}

String _$searchSongsHash() => r'a343d60ccdb15342635c72ce541df3c75b4d08e8';

/// Provider pour rechercher des chansons (Synchrone)
///
/// Copied from [searchSongs].
@ProviderFor(searchSongs)
const searchSongsProvider = SearchSongsFamily();

/// Provider pour rechercher des chansons (Synchrone)
///
/// Copied from [searchSongs].
class SearchSongsFamily extends Family<List<SongModel>> {
  /// Provider pour rechercher des chansons (Synchrone)
  ///
  /// Copied from [searchSongs].
  const SearchSongsFamily();

  /// Provider pour rechercher des chansons (Synchrone)
  ///
  /// Copied from [searchSongs].
  SearchSongsProvider call(
    String query,
  ) {
    return SearchSongsProvider(
      query,
    );
  }

  @override
  SearchSongsProvider getProviderOverride(
    covariant SearchSongsProvider provider,
  ) {
    return call(
      provider.query,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'searchSongsProvider';
}

/// Provider pour rechercher des chansons (Synchrone)
///
/// Copied from [searchSongs].
class SearchSongsProvider extends AutoDisposeProvider<List<SongModel>> {
  /// Provider pour rechercher des chansons (Synchrone)
  ///
  /// Copied from [searchSongs].
  SearchSongsProvider(
    String query,
  ) : this._internal(
          (ref) => searchSongs(
            ref as SearchSongsRef,
            query,
          ),
          from: searchSongsProvider,
          name: r'searchSongsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$searchSongsHash,
          dependencies: SearchSongsFamily._dependencies,
          allTransitiveDependencies:
              SearchSongsFamily._allTransitiveDependencies,
          query: query,
        );

  SearchSongsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final String query;

  @override
  Override overrideWith(
    List<SongModel> Function(SearchSongsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SearchSongsProvider._internal(
        (ref) => create(ref as SearchSongsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<List<SongModel>> createElement() {
    return _SearchSongsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchSongsProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin SearchSongsRef on AutoDisposeProviderRef<List<SongModel>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _SearchSongsProviderElement
    extends AutoDisposeProviderElement<List<SongModel>> with SearchSongsRef {
  _SearchSongsProviderElement(super.provider);

  @override
  String get query => (origin as SearchSongsProvider).query;
}

String _$lyricsHash() => r'b9d317513da0f2a0f52ce4cb722c49a9e82b30d1';

/// See also [lyrics].
@ProviderFor(lyrics)
const lyricsProvider = LyricsFamily();

/// See also [lyrics].
class LyricsFamily extends Family<AsyncValue<String?>> {
  /// See also [lyrics].
  const LyricsFamily();

  /// See also [lyrics].
  LyricsProvider call(
    String songId,
  ) {
    return LyricsProvider(
      songId,
    );
  }

  @override
  LyricsProvider getProviderOverride(
    covariant LyricsProvider provider,
  ) {
    return call(
      provider.songId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'lyricsProvider';
}

/// See also [lyrics].
class LyricsProvider extends AutoDisposeFutureProvider<String?> {
  /// See also [lyrics].
  LyricsProvider(
    String songId,
  ) : this._internal(
          (ref) => lyrics(
            ref as LyricsRef,
            songId,
          ),
          from: lyricsProvider,
          name: r'lyricsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$lyricsHash,
          dependencies: LyricsFamily._dependencies,
          allTransitiveDependencies: LyricsFamily._allTransitiveDependencies,
          songId: songId,
        );

  LyricsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.songId,
  }) : super.internal();

  final String songId;

  @override
  Override overrideWith(
    FutureOr<String?> Function(LyricsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LyricsProvider._internal(
        (ref) => create(ref as LyricsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        songId: songId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<String?> createElement() {
    return _LyricsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LyricsProvider && other.songId == songId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, songId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin LyricsRef on AutoDisposeFutureProviderRef<String?> {
  /// The parameter `songId` of this provider.
  String get songId;
}

class _LyricsProviderElement extends AutoDisposeFutureProviderElement<String?>
    with LyricsRef {
  _LyricsProviderElement(super.provider);

  @override
  String get songId => (origin as LyricsProvider).songId;
}

String _$musicHash() => r'bc8b24649ace0f903d5cc46bc0c68a99793bd914';

/// See also [Music].
@ProviderFor(Music)
final musicProvider = AsyncNotifierProvider<Music, MusicLibraryState>.internal(
  Music.new,
  name: r'musicProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$musicHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Music = AsyncNotifier<MusicLibraryState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member

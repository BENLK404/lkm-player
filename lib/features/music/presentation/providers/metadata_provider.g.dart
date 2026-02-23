// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metadata_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$songMetadataHash() => r'441b47480d00ac009ae8009c957351c017dd8725';

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

/// See also [songMetadata].
@ProviderFor(songMetadata)
const songMetadataProvider = SongMetadataFamily();

/// See also [songMetadata].
class SongMetadataFamily extends Family<AsyncValue<Tag?>> {
  /// See also [songMetadata].
  const SongMetadataFamily();

  /// See also [songMetadata].
  SongMetadataProvider call(
    String filePath,
  ) {
    return SongMetadataProvider(
      filePath,
    );
  }

  @override
  SongMetadataProvider getProviderOverride(
    covariant SongMetadataProvider provider,
  ) {
    return call(
      provider.filePath,
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
  String? get name => r'songMetadataProvider';
}

/// See also [songMetadata].
class SongMetadataProvider extends AutoDisposeFutureProvider<Tag?> {
  /// See also [songMetadata].
  SongMetadataProvider(
    String filePath,
  ) : this._internal(
          (ref) => songMetadata(
            ref as SongMetadataRef,
            filePath,
          ),
          from: songMetadataProvider,
          name: r'songMetadataProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$songMetadataHash,
          dependencies: SongMetadataFamily._dependencies,
          allTransitiveDependencies:
              SongMetadataFamily._allTransitiveDependencies,
          filePath: filePath,
        );

  SongMetadataProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.filePath,
  }) : super.internal();

  final String filePath;

  @override
  Override overrideWith(
    FutureOr<Tag?> Function(SongMetadataRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SongMetadataProvider._internal(
        (ref) => create(ref as SongMetadataRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        filePath: filePath,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Tag?> createElement() {
    return _SongMetadataProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SongMetadataProvider && other.filePath == filePath;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, filePath.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin SongMetadataRef on AutoDisposeFutureProviderRef<Tag?> {
  /// The parameter `filePath` of this provider.
  String get filePath;
}

class _SongMetadataProviderElement
    extends AutoDisposeFutureProviderElement<Tag?> with SongMetadataRef {
  _SongMetadataProviderElement(super.provider);

  @override
  String get filePath => (origin as SongMetadataProvider).filePath;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member

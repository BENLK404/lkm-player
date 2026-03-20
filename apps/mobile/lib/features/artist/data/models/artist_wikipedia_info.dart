/// Informations Wikipedia pour un artiste (extrait + lien).
class ArtistWikipediaInfo {
  const ArtistWikipediaInfo({
    required this.extract,
    required this.pageUrl,
  });

  final String extract;
  final String pageUrl;

  Map<String, dynamic> toJson() => {
        'extract': extract,
        'pageUrl': pageUrl,
      };

  factory ArtistWikipediaInfo.fromJson(Map<String, dynamic> json) {
    return ArtistWikipediaInfo(
      extract: json['extract'] as String? ?? '',
      pageUrl: json['pageUrl'] as String? ?? '',
    );
  }

  static String cacheKeyFromArtistName(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}

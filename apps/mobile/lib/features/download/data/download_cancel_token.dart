/// Raison de l’arrêt du flux HTTP (pause vs annulation définitive).
enum DownloadCancelReason {
  pause,
  cancel,
}

/// Annulation / pause d’un téléchargement en cours (vérifié entre chaque chunk).
class DownloadCancelToken {
  DownloadCancelReason? _reason;

  void request(DownloadCancelReason reason) {
    _reason = reason;
  }

  bool get isCancelled => _reason != null;

  DownloadCancelReason? get reason => _reason;

  void reset() {
    _reason = null;
  }
}

class DownloadCancelledException implements Exception {
  DownloadCancelledException(this.reason);

  final DownloadCancelReason reason;

  @override
  String toString() => 'DownloadCancelledException($reason)';
}

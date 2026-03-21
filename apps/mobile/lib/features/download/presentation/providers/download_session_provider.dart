import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/download_cancel_token.dart';
import '../../data/models/deezer_search_result.dart';
import 'download_provider.dart';

/// Statut affiché pour une tâche active (file).
enum DownloadTaskUiStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

class DownloadSessionTask {
  const DownloadSessionTask({
    required this.id,
    required this.item,
    required this.status,
    this.progress = 0,
    this.errorMessage,
  });

  final String id;
  final DeezerSearchResult item;
  final DownloadTaskUiStatus status;
  final double progress;
  final String? errorMessage;

  String get title => item.isAlbum ? item.displayTitle : item.title;
  String get subtitle => item.artist;

  DownloadSessionTask copyWith({
    DownloadTaskUiStatus? status,
    double? progress,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DownloadSessionTask(
      id: id,
      item: item,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Entrée d’historique (terminé, échec, annulé).
class DownloadHistoryEntry {
  const DownloadHistoryEntry({
    required this.id,
    required this.deezerItemId,
    required this.isAlbum,
    required this.title,
    required this.subtitle,
    required this.outcome,
    required this.at,
    this.filePath,
    this.errorMessage,
    this.trackCount,
  });

  final String id;
  final String deezerItemId;
  final bool isAlbum;
  final String title;
  final String subtitle;
  final DownloadTaskUiStatus outcome;
  final DateTime at;
  final String? filePath;
  final String? errorMessage;
  final int? trackCount;

  DeezerSearchResult toDeezerItem() {
    if (isAlbum) {
      return DeezerSearchResult(
        id: deezerItemId,
        idType: 'album',
        title: title,
        artist: subtitle,
        album: title,
      );
    }
    return DeezerSearchResult(
      id: deezerItemId,
      idType: 'track',
      title: title,
      artist: subtitle,
    );
  }
}

class SessionBanner {
  const SessionBanner({
    this.successMessage,
    this.errorMessage,
    this.playSongId,
    this.playAlbumDeezerId,
  });

  final String? successMessage;
  final String? errorMessage;

  /// ID [SongModel.id] du morceau (téléchargement d’une piste seule).
  final String? playSongId;

  /// ID album Deezer : lecture de toutes les pistes dont `albumId` correspond.
  final String? playAlbumDeezerId;
}

class DownloadSessionState {
  const DownloadSessionState({
    this.activeTasks = const [],
    this.history = const [],
    this.banner,
  });

  final List<DownloadSessionTask> activeTasks;
  final List<DownloadHistoryEntry> history;
  final SessionBanner? banner;

  /// File d’attente / en cours / en pause.
  bool get hasActiveWork => activeTasks.isNotEmpty;

  DownloadSessionState copyWith({
    List<DownloadSessionTask>? activeTasks,
    List<DownloadHistoryEntry>? history,
    SessionBanner? banner,
    bool clearBanner = false,
  }) {
    return DownloadSessionState(
      activeTasks: activeTasks ?? this.activeTasks,
      history: history ?? this.history,
      banner: clearBanner ? null : (banner ?? this.banner),
    );
  }
}

const int _kMaxHistory = 200;

final downloadSessionProvider =
    StateNotifierProvider<DownloadSessionNotifier, DownloadSessionState>((ref) {
  return DownloadSessionNotifier(ref);
});

class DownloadSessionNotifier extends StateNotifier<DownloadSessionState> {
  DownloadSessionNotifier(this._ref) : super(const DownloadSessionState());

  final Ref _ref;
  final _uuid = const Uuid();

  bool _pumpRunning = false;
  DownloadCancelToken? _activeToken;

  void clearBanner() {
    state = state.copyWith(clearBanner: true);
  }

  void _replaceTask(String id, DownloadSessionTask updated) {
    state = state.copyWith(
      activeTasks: [
        for (final t in state.activeTasks)
          if (t.id == id) updated else t,
      ],
    );
  }

  DownloadSessionTask? _taskById(String id) {
    for (final t in state.activeTasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  void _removeActiveTask(String taskId) {
    state = state.copyWith(
      activeTasks: state.activeTasks.where((e) => e.id != taskId).toList(),
    );
  }

  void _pushHistory(DownloadHistoryEntry entry) {
    final next = [entry, ...state.history];
    if (next.length > _kMaxHistory) {
      next.removeRange(_kMaxHistory, next.length);
    }
    state = state.copyWith(history: next);
  }

  Future<void> enqueue(DeezerSearchResult item) async {
    final id = _uuid.v4();
    final task = DownloadSessionTask(
      id: id,
      item: item,
      status: DownloadTaskUiStatus.queued,
      progress: 0,
    );
    state = state.copyWith(activeTasks: [...state.activeTasks, task]);
    unawaited(_pump());
  }

  /// Relancer depuis l’historique.
  Future<void> retryFromHistory(DownloadHistoryEntry entry) async {
    await enqueue(entry.toDeezerItem());
  }

  void removeHistoryEntry(String historyId) {
    state = state.copyWith(
      history: state.history.where((e) => e.id != historyId).toList(),
    );
  }

  void clearHistory() {
    state = state.copyWith(history: []);
  }

  void pauseTask(String taskId) {
    final t = _taskById(taskId);
    if (t == null || t.status != DownloadTaskUiStatus.downloading) return;
    _activeToken?.request(DownloadCancelReason.pause);
  }

  void cancelTask(String taskId) {
    final t = _taskById(taskId);
    if (t == null) return;
    if (t.status == DownloadTaskUiStatus.downloading) {
      _activeToken?.request(DownloadCancelReason.cancel);
      return;
    }
    if (t.status == DownloadTaskUiStatus.queued) {
      _removeActiveTask(taskId);
    }
  }

  void resumeTask(String taskId) {
    final t = _taskById(taskId);
    if (t == null || t.status != DownloadTaskUiStatus.paused) return;
    final rest = state.activeTasks.where((e) => e.id != taskId).toList();
    final resumed = t.copyWith(
      status: DownloadTaskUiStatus.queued,
      progress: 0,
      clearError: true,
    );
    state = state.copyWith(activeTasks: [resumed, ...rest]);
    unawaited(_pump());
  }

  void removeTask(String taskId) {
    final t = _taskById(taskId);
    if (t == null) return;
    if (t.status == DownloadTaskUiStatus.downloading) {
      cancelTask(taskId);
      return;
    }
    _removeActiveTask(taskId);
  }

  Future<void> _pump() async {
    if (_pumpRunning) return;
    _pumpRunning = true;
    try {
      while (true) {
        final idx = state.activeTasks
            .indexWhere((t) => t.status == DownloadTaskUiStatus.queued);
        if (idx < 0) break;

        final task = state.activeTasks[idx];
        _activeToken = DownloadCancelToken();
        _replaceTask(
          task.id,
          task.copyWith(
            status: DownloadTaskUiStatus.downloading,
            progress: 0,
            clearError: true,
          ),
        );

        final tid = task.id;
        try {
          final DownloadResult result;
          if (task.item.isAlbum) {
            result = await downloadAlbumAndAddToLibrary(
              _ref,
              task.item,
              cancelToken: _activeToken,
              onDownloadProgress: (p) {
                final cur = _taskById(tid);
                if (cur != null &&
                    cur.status == DownloadTaskUiStatus.downloading) {
                  _replaceTask(tid, cur.copyWith(progress: p));
                }
              },
            );
          } else {
            result = await downloadTrackAndAddToLibrary(
              _ref,
              task.item,
              cancelToken: _activeToken,
              onDownloadProgress: (p) {
                final cur = _taskById(tid);
                if (cur != null &&
                    cur.status == DownloadTaskUiStatus.downloading) {
                  _replaceTask(tid, cur.copyWith(progress: p));
                }
              },
            );
          }

          if (result.isSuccess) {
            final msg = task.item.isAlbum
                ? ((result.trackCount ?? 0) > 1
                    ? '« ${task.item.displayTitle} » · ${result.trackCount} pistes'
                    : '« ${task.item.displayTitle} » ajouté')
                : '« ${task.item.title} » ajouté';
            _removeActiveTask(task.id);
            _pushHistory(
              DownloadHistoryEntry(
                id: _uuid.v4(),
                deezerItemId: task.item.id,
                isAlbum: task.item.isAlbum,
                title: task.title,
                subtitle: task.subtitle,
                outcome: DownloadTaskUiStatus.completed,
                at: DateTime.now(),
                filePath: result.filePath,
                trackCount: result.trackCount,
              ),
            );
            state = state.copyWith(
              banner: SessionBanner(
                successMessage: msg,
                playSongId: task.item.isAlbum ? null : result.song?.id,
                playAlbumDeezerId: task.item.isAlbum ? task.item.id : null,
              ),
            );
          } else {
            _removeActiveTask(task.id);
            _pushHistory(
              DownloadHistoryEntry(
                id: _uuid.v4(),
                deezerItemId: task.item.id,
                isAlbum: task.item.isAlbum,
                title: task.title,
                subtitle: task.subtitle,
                outcome: DownloadTaskUiStatus.failed,
                at: DateTime.now(),
                errorMessage: result.error ?? 'Échec',
              ),
            );
            state = state.copyWith(
              banner: SessionBanner(
                errorMessage: result.error ?? 'Échec du téléchargement',
              ),
            );
          }
        } on DownloadCancelledException catch (e) {
          final tNow = _taskById(task.id);
          if (tNow != null) {
            if (e.reason == DownloadCancelReason.pause) {
              _replaceTask(
                task.id,
                tNow.copyWith(status: DownloadTaskUiStatus.paused),
              );
            } else {
              _removeActiveTask(task.id);
              _pushHistory(
                DownloadHistoryEntry(
                  id: _uuid.v4(),
                  deezerItemId: task.item.id,
                  isAlbum: task.item.isAlbum,
                  title: task.title,
                  subtitle: task.subtitle,
                  outcome: DownloadTaskUiStatus.cancelled,
                  at: DateTime.now(),
                ),
              );
            }
          }
        }

        _activeToken = null;
      }
    } finally {
      _pumpRunning = false;
      _activeToken = null;
    }

    if (state.activeTasks.any((t) => t.status == DownloadTaskUiStatus.queued)) {
      unawaited(_pump());
    }
  }
}

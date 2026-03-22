import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musio/shared/utils/app_toast.dart';

import '../providers/download_session_provider.dart';
import '../utils/download_playback.dart';

/// Écoute les fins de téléchargement pour afficher un SnackBar (succès / erreur).
void listenDownloadSessionBanner(BuildContext context, WidgetRef ref) {
  ref.listen<DownloadSessionState>(downloadSessionProvider, (prev, next) {
    final banner = next.banner;
    if (banner == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      if (banner.successMessage != null) {
        final String? actionLabel;
        final VoidCallback? onAction;
        if (banner.playSongId != null) {
          actionLabel = 'Jouer';
          onAction = () => playSingleSongFromLibrary(ref, banner.playSongId!);
        } else if (banner.playAlbumDeezerId != null) {
          actionLabel = 'Jouer';
          onAction = () => playAlbumFromLibraryByDeezerId(
                ref,
                banner.playAlbumDeezerId!,
              );
        } else {
          actionLabel = null;
          onAction = null;
        }
        AppToast.showSuccess(
          context,
          message: banner.successMessage!,
          actionLabel: actionLabel,
          onAction: onAction,
        );
      } else if (banner.errorMessage != null) {
        AppToast.showError(context, banner.errorMessage!);
      }
      ref.read(downloadSessionProvider.notifier).clearBanner();
    });
  });
}

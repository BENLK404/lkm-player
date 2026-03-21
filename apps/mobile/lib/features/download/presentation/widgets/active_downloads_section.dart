import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musio/shared/utils/app_toast.dart';

import '../providers/download_session_provider.dart';

/// Écoute les fins de téléchargement pour afficher un SnackBar (succès / erreur).
void listenDownloadSessionBanner(BuildContext context, WidgetRef ref) {
  ref.listen<DownloadSessionState>(downloadSessionProvider, (prev, next) {
    final banner = next.banner;
    if (banner == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      if (banner.successMessage != null) {
        AppToast.showSuccess(
          context,
          message: banner.successMessage!,
          actionLabel: banner.copyPath != null ? 'Copier' : null,
          onAction: banner.copyPath != null
              ? () {
                  Clipboard.setData(ClipboardData(text: banner.copyPath!));
                  if (context.mounted) AppToast.showCopied(context);
                }
              : null,
        );
      } else if (banner.errorMessage != null) {
        AppToast.showError(context, banner.errorMessage!);
      }
      ref.read(downloadSessionProvider.notifier).clearBanner();
    });
  });
}

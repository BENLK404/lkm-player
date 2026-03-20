import 'package:logger/logger.dart';

/// Logger partagé pour l'application LKM Player.
/// Utiliser [AppLogger.log] pour les messages de debug/erreur au lieu de [print].
final AppLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 4,
    lineLength: 80,
    colors: true,
    printEmojis: false,
  ),
);

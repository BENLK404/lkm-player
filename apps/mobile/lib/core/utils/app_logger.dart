import 'package:logger/logger.dart';

/// Logger partagé pour l'application LKM Player.
/// Utiliser [appLogger] pour les messages de debug/erreur (ex. `.d`, `.w`, `.e`) au lieu de [print].
final appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 4,
    lineLength: 80,
    colors: true,
    printEmojis: false,
  ),
);

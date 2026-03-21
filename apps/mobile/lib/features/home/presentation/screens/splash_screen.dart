import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musio/core/routing/app_router.dart';
import 'package:musio/features/music/presentation/providers/music_provider.dart';

// Assurez-vous que cet import existe ou ajustez-le selon votre structure
// import '../../../../core/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Attendre un délai minimum pour que le logo soit visible
    final minDelay = Future.delayed(const Duration(seconds: 2));

    // Attendre que la musique soit chargée depuis le cache
    final musicLoad = ref.read(musicProvider.future);

    try {
      await Future.wait([minDelay, musicLoad]);
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation: $e');
    }

    if (mounted) {
      context.go(AppRouter.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // On retire la couleur de fond statique pour laisser place au Container dégradé
      // backgroundColor: AppTheme.aColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            // Ces couleurs sont échantillonnées directement depuis le fond de l'image fournie
            // pour recréer cet effet "métal froid / sombre"
            colors: [
              Color(0xFF374755), // Gris-bleu ardoise (Lumière venant du haut gauche)
              Color(0xFF263238), // Transition sombre
              Color(0xFF15191E), // Noir quasi total (Ombre en bas à droite)
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(

                width: 120,

                height: 120,

                decoration: BoxDecoration(

                  color: Theme.of(context).colorScheme.primary,

                  shape: BoxShape.circle,

                  boxShadow: [

                    BoxShadow(

                      color: Theme.of(context).colorScheme.surface.withOpacity(0.6),

                      blurRadius: 20,

                      offset: const Offset(0, 10),

                    ),

                  ],

                ),

                child: ClipOval(

                  child: Image.asset(

                    'assets/icon/app.png',

                    fit: BoxFit.cover,

                    errorBuilder: (context, error, stackTrace) {

// Fallback si l'image n'est pas trouvée

                      return const Icon(

                        Icons.music_note_rounded,

                        size: 60,

                        color: Colors.white,

                      );

                    },

                  ),

                ),

              ),
              const SizedBox(height: 24),

              // Nom de l'application
              Text(
                'LKM Player',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    // Texte en blanc pour contraster avec le fond sombre
                    color: Colors.white,
                    letterSpacing: 1.5,
                    shadows: [
                      const Shadow(
                        blurRadius: 10.0,
                        color: Colors.black45,
                        offset: Offset(2.0, 2.0),
                      ),
                    ]
                ),
              ),
              const SizedBox(height: 48),

              // Indicateur de chargement
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  // On utilise une couleur "Cyan/Teal" pour rappeler les circuits du logo
                  color: const Color(0xFF64FFDA),
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
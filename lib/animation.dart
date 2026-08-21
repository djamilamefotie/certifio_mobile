import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:certifio_mobile/home.dart';
class Myanimation extends StatefulWidget {
  const Myanimation({super.key});
  
  @override
  State<Myanimation> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<Myanimation>
    with SingleTickerProviderStateMixin {
  // Contrôleur pour l'animation d'entrée (fade/scale) uniquement.
  // On n'utilise plus ce contrôleur pour piloter Lottie afin d'éviter les saccades.
  late final AnimationController _entryController;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  // Timer pour naviguer automatiquement après X secondes (comportement d'avant).
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    // Durée courte pour l'animation d'apparition (fluide et légère).
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fade = CurvedAnimation(parent: _entryController, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack),
    );

    // Lance l'animation d'entrée une seule fois.
    _entryController.forward();

    // Comportement comme avant : naviguer après 10 secondes.
    _navTimer = Timer(const Duration(seconds: 10), () {
      _navigateToHome();
    });
  }

  // Navigation sécurisée vers l'écran d'accueil.
  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const  OnboardingScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fond en dégradé pour un rendu plus moderne.
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 24),
                const Text(
                  'Bienvenue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Entrée animée (fade + scale). La Lottie elle-même tourne en boucle
                // de manière autonome (repeat: true) pour éviter toute saccade.
                FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: SizedBox(
                      width: 220,
                      height: 220,
                      child: Lottie.asset(
                        'asserts/lottie/verification.json',
                        // Ne pas fournir de controller ici : laisser Lottie gérer sa lecture
                        // afin d'assurer une lecture fluide et répétée.
                        repeat: true,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Bouton pour passer l'animation immédiatement.
                TextButton(
                  onPressed: () {
                    _navTimer?.cancel();
                    _navigateToHome();
                  },
                  child: const Text(
                    'Passer',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

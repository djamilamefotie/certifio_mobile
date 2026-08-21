import 'package:flutter/material.dart';
import 'package:certifio_mobile/Inscription.dart' as ins;
import 'package:certifio_mobile/Connection.dart' as conn;

class CertifioColors {
  static const fondVertFonce = Color(0xFF0A2E24);
  static const fondVertMoyen = Color(0xFF0E3B2E);
  static const vertMedaillon = Color(0xFF2F7D4F);
  static const or = Color(0xFFD9A93E);
  static const orClair = Color(0xFFF0C868);
  static const rouge = Color(0xFFC1272D);
  static const texteClair = Color(0xFFFFF8E7);
}

// ============================================================
// PAGE DE PRÉSENTATION (ONBOARDING) — CERTIFIO
// ------------------------------------------------------------
// C'est la toute première page vue par un visiteur qui ouvre
// l'application. Elle ne contient AUCUN appel à une API Laravel :
// tout est fixe, écrit directement dans le code Flutter.
//
// Rôle de cette page :
//   1. Montrer en 4 slides ce que fait Certifio
//   2. Proposer 2 boutons à la fin de chaque slide :
//        - "Créer un compte"   -> écran Inscription
//        - "J'ai déjà un compte" -> écran Connexion
// ============================================================


// ------------------------------------------------------------
// 1. COULEURS DE CERTIFIO
// ------------------------------------------------------------
// On regroupe ici toutes les couleurs prises directement sur le
// logo (la médaille verte et dorée). Comme ça, si un jour tu veux
// changer une couleur, tu la changes UNE SEULE FOIS ici, et elle
// change partout dans le fichier automatiquement.
// Couleurs centralisées dans lib/certifio_colors.dart


// ------------------------------------------------------------
// 2. CONTENU DE CHAQUE SLIDE
// ------------------------------------------------------------
// Cette petite classe sert juste à "ranger" les infos d'une slide
// (titre, texte, icône, couleurs de fond) dans un seul objet.
// Ça évite de tout mélanger dans le code plus bas.
class SlideOnboarding {
  final String titre;
  final String texte;
  final IconData icone;
  final List<Color> couleursFond; // dégradé de 2 couleurs

  const SlideOnboarding({
    required this.titre,
    required this.texte,
    required this.icone,
    required this.couleursFond,
  });
}


// ------------------------------------------------------------
// 3. L'ÉCRAN LUI-MÊME
// ------------------------------------------------------------
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Contrôleur qui gère le glissement (swipe) entre les slides.
  final PageController _controleurPages = PageController();

  // Numéro de la slide actuellement affichée (0, 1, 2 ou 3).
  int _pageActuelle = 0;

  // ----------------------------------------------------------
  // Liste des 4 slides. Les textes sont volontairement courts
  // et simples (pas de longues phrases marketing).
  // Tu peux modifier le titre/texte de chaque slide ici.
  // ----------------------------------------------------------
  final List<SlideOnboarding> _slides = const [
    SlideOnboarding(
      titre: "Vérifiez un diplôme",
      texte: "Certifio détecte les faux diplômes en quelques secondes.",
      icone: Icons.workspace_premium_rounded,
      couleursFond: [CertifioColors.fondVertFonce, CertifioColors.fondVertMoyen],
    ),
    SlideOnboarding(
      titre: "Scan + Intelligence Artificielle",
      texte: "L'OCR lit le diplôme, l'IA l'analyse, puis Certifio le compare à sa base de référence.",
      icone: Icons.document_scanner_rounded,
      couleursFond: [CertifioColors.fondVertMoyen, CertifioColors.vertMedaillon],
    ),
    SlideOnboarding(
      titre: "Pour tout le monde",
      texte: "Étudiants, recruteurs, écoles : tout le monde peut vérifier.",
      icone: Icons.groups_2_rounded,
      couleursFond: [CertifioColors.fondVertFonce, Color(0xFF1B4D3A)],
    ),
    SlideOnboarding(
      titre: "Résultat clair et sûr",
      texte: "Un résultat simple : diplôme authentique ou suspect.",
      icone: Icons.verified_rounded,
      couleursFond: [CertifioColors.fondVertMoyen, CertifioColors.fondVertFonce],
    ),
  ];

  // ----------------------------------------------------------
  // Ces deux fonctions seront appelées quand on clique sur les
  // boutons en bas de l'écran. Pour l'instant elles sont vides :
  // tu n'as qu'à décommenter la ligne Navigator.push quand tes
  // écrans LoginScreen et RegisterScreen existeront.
  // ----------------------------------------------------------
  void _allerVersConnexion() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const conn.LoginScreen()));
  }

  void _allerVersInscription() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ins.RegisterScreen()));
  }

  @override
  Widget build(BuildContext context) {
    // On récupère les infos de la slide actuellement affichée.
    final slide = _slides[_pageActuelle];
    final estDerniereSlide = _pageActuelle == _slides.length - 1;

    return Scaffold(
      body: AnimatedContainer(
        // Le fond change doucement de couleur quand on change de slide.
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: slide.couleursFond,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ======================================================
              // EN-TÊTE : petit logo "C" + nom "Certifio" + bouton "Passer"
              // ======================================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // --- Logo + nom à gauche ---
                    Row(
                      children: [
                        // Petit rond doré avec la lettre "C", comme le logo
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [CertifioColors.or, CertifioColors.orClair],
                              ),
                            ),
                            child: const Text(
                              "C",
                              style: TextStyle(
                                color: CertifioColors.fondVertFonce,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                        ),
                        const SizedBox(width: 10),
                          const Text(
                            "Certifio",
                            style: TextStyle(
                              color: CertifioColors.texteClair,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),

                    // --- Bouton "Passer" à droite ---
                    // On ne l'affiche pas sur la toute dernière slide
                    // (ça ne sert à rien de "passer" si on est déjà à la fin).
                    if (!estDerniereSlide)
                      TextButton(
                        onPressed: () {
                          // Va directement à la dernière slide
                          _controleurPages.animateToPage(
                            _slides.length - 1,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Text(
                          "Passer",
                          style: TextStyle(color: CertifioColors.texteClair.withOpacity(0.75)),
                        ),
                      ),
                  ],
                ),
              ),

              // ======================================================
              // ZONE DES SLIDES (celle qui glisse quand on swipe)
              // ======================================================
              Expanded(
                child: PageView.builder(
                  controller: _controleurPages,
                  itemCount: _slides.length,
                  // Appelée à chaque fois qu'on change de slide :
                  // on met à jour _pageActuelle pour rafraîchir l'écran
                  // (couleur de fond, points en bas, etc.)
                  onPageChanged: (index) {
                    setState(() => _pageActuelle = index);
                  },
                  itemBuilder: (context, index) {
                    final s = _slides[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // --- Icône dans un rond doré (façon médaille) ---
                          Container(
                            width: 150,
                            height: 150,
                            padding: const EdgeInsets.all(6), // épaisseur de l'anneau doré
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [CertifioColors.or, CertifioColors.orClair, CertifioColors.or],
                              ),
                            ),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: CertifioColors.vertMedaillon,
                              ),
                              child: Icon(s.icone, size: 60, color: CertifioColors.texteClair),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // --- Titre de la slide ---
                          Text(
                            s.titre,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: CertifioColors.texteClair,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // --- Texte court d'explication ---
                          Text(
                            s.texte,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: CertifioColors.texteClair.withOpacity(0.75),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ======================================================
              // POINTS EN BAS (indicateurs de progression)
              // ======================================================
              // Un petit trait/point par slide. Le point de la slide
              // actuelle est plus long et doré, les autres sont petits
              // et transparents.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (index) {
                  final estActive = _pageActuelle == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: estActive ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: estActive
                          ? CertifioColors.or
                          : CertifioColors.texteClair.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 28),

              // ======================================================
              // BOUTONS EN BAS : Créer un compte / J'ai déjà un compte
              // ======================================================
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: Column(
                  children: [
                    // --- Bouton principal : Créer un compte (doré) ---
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _allerVersInscription,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CertifioColors.or,
                          foregroundColor: CertifioColors.fondVertFonce,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Créer un compte",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // --- Bouton secondaire : J'ai déjà un compte (juste un contour) ---
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _allerVersConnexion,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: CertifioColors.texteClair,
                          side: BorderSide(color: CertifioColors.texteClair.withOpacity(0.4)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "J'ai déjà un compte",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // On "détruit" le contrôleur quand l'écran n'existe plus,
  // pour ne pas laisser de mémoire inutilisée (bonne pratique Flutter).
  @override
  void dispose() {
    _controleurPages.dispose();
    super.dispose();
  }
}
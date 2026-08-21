import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // TODO : ajuste ce chemin selon l'emplacement réel de auth_service.dart dans ton projet

// ============================================================
// DASHBOARD UTILISATEUR — CERTIFIO
// ------------------------------------------------------------
// C'est l'écran principal vu par l'utilisateur UNE FOIS connecté.
// Contrairement à l'onboarding (lib/home.dart, malgré son nom),
// cet écran est le vrai "chez soi" de l'app.
//
// Structure : une barre de navigation en bas avec 4 onglets :
//   - Accueil      : bouton principal + stats + aperçu historique
//   - Vérification : scan/import d'un diplôme
//   - Historique   : liste des vérifications passées
//   - Profil       : infos du compte + déconnexion
//
// MISE À JOUR : les infos utilisateur (nom, email, catégorie)
// sont maintenant récupérées depuis l'API Laravel (GET /api/user)
// au chargement de cet écran, via AuthService.recupererUtilisateur().
// Elles sont chargées UNE SEULE FOIS ici (dans le parent) puis
// transmises aux onglets Accueil et Profil, pour éviter de faire
// 2 appels réseau identiques.
// ============================================================


// ------------------------------------------------------------
// Couleurs de Certifio (identiques aux autres écrans).
// ------------------------------------------------------------
class CertifioColors {
  static const fondVertFonce = Color(0xFF0A2E24);
  static const fondVertMoyen = Color(0xFF0E3B2E);
  static const vertMedaillon = Color(0xFF2F7D4F);
  static const or = Color(0xFFD9A93E);
  static const orClair = Color(0xFFF0C868);
  static const rouge = Color(0xFFC1272D);
  static const texteClair = Color(0xFFFFF8E7);
}


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ----------------------------------------------------------
  // Index de l'onglet actuellement sélectionné dans la barre
  // de navigation du bas : 0 = Accueil, 1 = Vérification,
  // 2 = Historique, 3 = Profil.
  // ----------------------------------------------------------
  int _ongletActuel = 0;

  // ----------------------------------------------------------
  // État du chargement des infos utilisateur (GET /api/user).
  // ----------------------------------------------------------
  Map<String, dynamic>? _utilisateur; // null tant que pas chargé
  bool _chargementUtilisateur = true;
  String? _erreurUtilisateur;

  @override
  void initState() {
    super.initState();
    _chargerUtilisateur();
  }

  // ----------------------------------------------------------
  // Appelle AuthService.recupererUtilisateur() et met à jour
  // l'état en fonction du résultat.
  // ----------------------------------------------------------
  Future<void> _chargerUtilisateur() async {
    setState(() {
      _chargementUtilisateur = true;
      _erreurUtilisateur = null;
    });

    final resultat = await AuthService.recupererUtilisateur();

    if (!mounted) return; // l'écran peut avoir été fermé entre-temps

    if (resultat.succes) {
      setState(() {
        _utilisateur = resultat.utilisateur;
        _chargementUtilisateur = false;
      });
    } else {
      setState(() {
        _erreurUtilisateur = resultat.message;
        _chargementUtilisateur = false;
      });

      // Session expirée ou absente -> on renvoie vers la connexion.
      // TODO : adapte cette navigation à la vraie structure de routes
      // de ton app (route nommée '/login' ou MaterialPageRoute vers
      // ton LoginScreen).
      if (resultat.message.contains("reconnecter") ||
          resultat.message.contains("expirée")) {
        // Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  // ----------------------------------------------------------
  // Change l'onglet actif. Passée aux pages qui ont besoin de
  // rediriger vers un autre onglet (ex: le bouton "Vérifier un
  // diplôme" de l'Accueil doit ouvrir l'onglet Vérification, ou
  // "Voir tout" doit ouvrir l'onglet Historique).
  // ----------------------------------------------------------
  void _allerVersOnglet(int index) {
    setState(() => _ongletActuel = index);
  }

  @override
  Widget build(BuildContext context) {
    // On construit la liste des 4 pages ici (et pas en dehors de
    // build) pour pouvoir leur passer les données utilisateur
    // à jour et la fonction _allerVersOnglet.
    final List<Widget> pages = [
      _OngletAccueil(
        utilisateur: _utilisateur,
        chargement: _chargementUtilisateur,
        surAllerVersVerification: () => _allerVersOnglet(1),
        surAllerVersHistorique: () => _allerVersOnglet(2),
      ),
      const _OngletVerification(),
      const _OngletHistorique(),
      _OngletProfil(
        utilisateur: _utilisateur,
        chargement: _chargementUtilisateur,
        surDeconnexion: _deconnecter,
      ),
    ];

    return Scaffold(
      backgroundColor: CertifioColors.fondVertFonce,
      body: SafeArea(
        child: Column(
          children: [
            if (_erreurUtilisateur != null)
              Container(
                width: double.infinity,
                color: Colors.redAccent,
                padding: const EdgeInsets.all(8),
                child: Text(
                  _erreurUtilisateur!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            Expanded(child: pages[_ongletActuel]),
          ],
        ),
      ),

      // ======================================================
      // BARRE DE NAVIGATION EN BAS
      // ======================================================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _ongletActuel,
        onTap: (index) => setState(() => _ongletActuel = index),
        backgroundColor: CertifioColors.fondVertMoyen,
        selectedItemColor: CertifioColors.orClair,
        unselectedItemColor: CertifioColors.texteClair.withOpacity(0.5),
        type: BottomNavigationBarType.fixed, // garde les items visibles et de taille égale
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: "Accueil",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.document_scanner_rounded),
            label: "Vérification",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: "Historique",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: "Profil",
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // Déconnexion : supprime le token local puis renvoie vers
  // l'écran de connexion.
  // ----------------------------------------------------------
  Future<void> _deconnecter() async {
    await AuthService.deconnecter();
    if (!mounted) return;

    // TODO : adapte à la vraie structure de routes de ton app.
    // Exemple avec route nommée :
    // Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    // Exemple avec MaterialPageRoute :
    // Navigator.pushAndRemoveUntil(
    //   context,
    //   MaterialPageRoute(builder: (_) => const LoginScreen()),
    //   (route) => false,
    // );
  }
}


// ============================================================
// ONGLET 1 : ACCUEIL
// ============================================================
class _OngletAccueil extends StatelessWidget {
  final Map<String, dynamic>? utilisateur;
  final bool chargement;
  final VoidCallback surAllerVersVerification;
  final VoidCallback surAllerVersHistorique;

  const _OngletAccueil({
    required this.utilisateur,
    required this.chargement,
    required this.surAllerVersVerification,
    required this.surAllerVersHistorique,
  });

  @override
  Widget build(BuildContext context) {
    // Nom réel si dispo, sinon valeur de repli pendant le chargement
    // ou en cas d'erreur (utilisateur reste null).
    final String nomUtilisateur =
        (utilisateur?["name"] as String?) ?? (chargement ? "..." : "Utilisateur");
    final String initiale =
        nomUtilisateur.isNotEmpty ? nomUtilisateur[0].toUpperCase() : "?";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --------------------------------------------------
          // En-tête : message de bienvenue + avatar rond
          // --------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bonjour,",
                    style: TextStyle(
                      color: CertifioColors.texteClair.withOpacity(0.7),
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    nomUtilisateur,
                    style: const TextStyle(
                      color: CertifioColors.texteClair,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Petit avatar rond avec l'initiale du nom
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [CertifioColors.or, CertifioColors.orClair],
                  ),
                ),
                child: Text(
                  initiale,
                  style: const TextStyle(
                    color: CertifioColors.fondVertFonce,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // --------------------------------------------------
          // Bouton principal : Vérifier un diplôme
          // --------------------------------------------------
          SizedBox(
            width: double.infinity,
            height: 130,
            child: ElevatedButton(
              onPressed: surAllerVersVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: CertifioColors.vertMedaillon,
                foregroundColor: CertifioColors.texteClair,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: CertifioColors.or, width: 1.5),
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.document_scanner_rounded, size: 36),
                  SizedBox(height: 8),
                  Text(
                    "Vérifier un diplôme",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Scanner ou importer une image",
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // --------------------------------------------------
          // Statistiques rapides (2 petites cartes côte à côte)
          // --------------------------------------------------
          // TODO : brancher sur GET /api/diplomes/historique une fois
          // cette route disponible (nombre total + nombre authentiques).
          Row(
            children: [
              Expanded(
                child: _carteStat(
                  icone: Icons.fact_check_rounded,
                  valeur: "0",
                  libelle: "Vérifications",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _carteStat(
                  icone: Icons.verified_rounded,
                  valeur: "0",
                  libelle: "Authentiques",
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // --------------------------------------------------
          // Aperçu de l'historique récent
          // --------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Vérifications récentes",
                style: TextStyle(
                  color: CertifioColors.texteClair,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: surAllerVersHistorique,
                child: const Text(
                  "Voir tout",
                  style: TextStyle(color: CertifioColors.orClair, fontSize: 13),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Message affiché tant qu'il n'y a aucune vérification.
          // TODO : remplacer par une vraie liste dès que l'historique
          // sera branché à l'API.
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: CertifioColors.fondVertMoyen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.inbox_rounded,
                  color: CertifioColors.texteClair.withOpacity(0.4),
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  "Aucune vérification pour l'instant",
                  style: TextStyle(color: CertifioColors.texteClair.withOpacity(0.6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // Petite "fabrique" de carte statistique, pour ne pas
  // dupliquer le style entre les 2 cartes ci-dessus.
  // ----------------------------------------------------------
  Widget _carteStat({
    required IconData icone,
    required String valeur,
    required String libelle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CertifioColors.fondVertMoyen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: CertifioColors.orClair, size: 22),
          const SizedBox(height: 8),
          Text(
            valeur,
            style: const TextStyle(
              color: CertifioColors.texteClair,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            libelle,
            style: TextStyle(color: CertifioColors.texteClair.withOpacity(0.6), fontSize: 12),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// ONGLET 2 : VÉRIFICATION
// ============================================================
// Inchangé — le pipeline (Tesseract OCR -> Gemini IA ->
// comparaison -> score) sera branché plus tard.
class _OngletVerification extends StatelessWidget {
  const _OngletVerification();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Vérification",
            style: TextStyle(
              color: CertifioColors.texteClair,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Scannez ou importez une image du diplôme à vérifier.",
            style: TextStyle(color: CertifioColors.texteClair.withOpacity(0.6)),
          ),

          const SizedBox(height: 32),

          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.document_scanner_rounded,
                    color: CertifioColors.texteClair.withOpacity(0.3),
                    size: 72,
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO : ouvrir la caméra (package image_picker,
                        // source: ImageSource.camera), puis lancer
                        // l'envoi de l'image à l'API Laravel.
                      },
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text(
                        "Scanner avec l'appareil photo",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CertifioColors.or,
                        foregroundColor: CertifioColors.fondVertFonce,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO : ouvrir la galerie (package image_picker,
                        // source: ImageSource.gallery), une seule image
                        // à la fois (pas de sélection multiple).
                      },
                      icon: const Icon(Icons.image_rounded),
                      label: const Text(
                        "Importer une image",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CertifioColors.texteClair,
                        side: BorderSide(color: CertifioColors.texteClair.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// ONGLET 3 : HISTORIQUE
// ============================================================
// Inchangé — sera branché sur GET /api/diplomes/historique.
class _OngletHistorique extends StatelessWidget {
  const _OngletHistorique();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Historique",
            style: TextStyle(
              color: CertifioColors.texteClair,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    color: CertifioColors.texteClair.withOpacity(0.3),
                    size: 56,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Aucune vérification effectuée",
                    style: TextStyle(color: CertifioColors.texteClair.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// ONGLET 4 : PROFIL
// ============================================================
class _OngletProfil extends StatelessWidget {
  final Map<String, dynamic>? utilisateur;
  final bool chargement;
  final VoidCallback surDeconnexion;

  const _OngletProfil({
    required this.utilisateur,
    required this.chargement,
    required this.surDeconnexion,
  });

  @override
  Widget build(BuildContext context) {
    // Valeurs réelles si dispo, sinon valeurs de repli pendant
    // le chargement ou en cas d'erreur.
    final String nom =
        (utilisateur?["name"] as String?) ?? (chargement ? "..." : "Utilisateur");
    final String email = (utilisateur?["email"] as String?) ?? "";
    // Champ confirmé côté Laravel (AuthController) : "categorie".
    final String categorie = (utilisateur?["categorie"] as String?) ?? "Utilisateur";
    final String initiale = nom.isNotEmpty ? nom[0].toUpperCase() : "?";

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Profil",
            style: TextStyle(
              color: CertifioColors.texteClair,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 28),

          // --------------------------------------------------
          // Grand avatar + nom + email, centrés
          // --------------------------------------------------
          Center(
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [CertifioColors.or, CertifioColors.orClair],
                    ),
                  ),
                  child: Text(
                    initiale,
                    style: const TextStyle(
                      color: CertifioColors.fondVertFonce,
                      fontWeight: FontWeight.w900,
                      fontSize: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  nom,
                  style: const TextStyle(
                    color: CertifioColors.texteClair,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  email,
                  style: TextStyle(color: CertifioColors.texteClair.withOpacity(0.6)),
                ),
                const SizedBox(height: 6),
                // Petite étiquette qui affiche la catégorie du compte
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: CertifioColors.or.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: CertifioColors.or.withOpacity(0.4)),
                  ),
                  child: Text(
                    categorie,
                    style: const TextStyle(color: CertifioColors.orClair, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // --------------------------------------------------
          // Bouton de déconnexion
          // --------------------------------------------------
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: surDeconnexion,
              icon: const Icon(Icons.logout_rounded, color: CertifioColors.rouge),
              label: const Text(
                "Se déconnecter",
                style: TextStyle(color: CertifioColors.rouge, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: CertifioColors.rouge.withOpacity(0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
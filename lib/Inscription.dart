import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'package:certifio_mobile/services/Accueil.dart' as accueil;
import 'package:certifio_mobile/Connection.dart' as conn;

// ============================================================
// ÉCRAN D'INSCRIPTION — CERTIFIO
// ------------------------------------------------------------
// L'utilisateur y arrive depuis le bouton "Créer un compte"
// de la page de présentation (onboarding).
//
// Rôle de cet écran :
//   1. Récupérer les infos saisies (nom, email, mot de passe...)
//   2. Vérifier que les champs sont bien remplis (validation)
//   3. Envoyer ces infos à l'API Laravel via AuthService.inscrire()
//   4. Si succès -> aller à l'écran d'Accueil
//   5. Si erreur -> afficher le message d'erreur à l'utilisateur
// ============================================================


// ------------------------------------------------------------
// Couleurs de Certifio (les mêmes que sur la page onboarding,
// prises sur le logo officiel).
// ------------------------------------------------------------
class CertifioColors {
  static const fondVertFonce = Color(0xFF0A2E24);
  static const fondVertMoyen = Color(0xFF0E3B2E);
  static const vertMedaillon = Color(0xFF2F7D4F);
  static const or = Color(0xFFD9A93E);
  static const orClair = Color(0xFFF0C868);
  static const rouge = Color(0xFFC1272D); // utilisé ici pour les messages d'erreur
  static const texteClair = Color(0xFFFFF8E7);
}


// ============================================================
// ÉCRAN D'INSCRIPTION — CERTIFIO
// ------------------------------------------------------------
// L'utilisateur y arrive depuis le bouton "Créer un compte"
// de la page de présentation (onboarding).
//
// Rôle de cet écran :
//   1. Récupérer les infos saisies (nom, email, mot de passe...)
//   2. Vérifier que les champs sont bien remplis (validation)
//   3. Envoyer ces infos à l'API Laravel via AuthService.inscrire()
//   4. Si succès -> aller à l'écran d'Accueil
//   5. Si erreur -> afficher le message d'erreur à l'utilisateur
// ============================================================


// Couleurs centralisées dans lib/certifio_colors.dart


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ----------------------------------------------------------
  // _formKey permet de valider tous les champs du formulaire
  // d'un coup (ex: vérifier que l'email est valide, que les
  // mots de passe correspondent, etc.) quand on appuie sur
  // le bouton "S'inscrire".
  // ----------------------------------------------------------
  final _formKey = GlobalKey<FormState>();

  // Un "controller" par champ de texte : il sert à LIRE ce que
  // l'utilisateur a tapé dans le champ correspondant.
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _motDePasseController = TextEditingController();
  final _confirmationController = TextEditingController();

  // Pour afficher ou cacher le mot de passe (icône œil).
  bool _motDePasseVisible = false;
  bool _confirmationVisible = false;

  // Pendant l'appel à l'API, on affiche un petit rond de
  // chargement sur le bouton et on empêche de cliquer 2 fois.
  bool _chargementEnCours = false;

  // Message d'erreur à afficher si l'API renvoie un problème
  // (ex : "Cet email est déjà utilisé").
  String? _messageErreur;

  // ----------------------------------------------------------
  // Fonction appelée quand on clique sur "S'inscrire".
  // ----------------------------------------------------------
  Future<void> _sInscrire() async {
    // Étape 1 : on vérifie que tous les champs sont valides
    // (les règles de validation sont écrites plus bas, dans
    // chaque TextFormField avec "validator").
    final formulaireValide = _formKey.currentState?.validate() ?? false;
    if (!formulaireValide) return;

    // Étape 2 : on vérifie que les deux mots de passe sont identiques.
    if (_motDePasseController.text != _confirmationController.text) {
      setState(() => _messageErreur = "Les mots de passe ne correspondent pas.");
      return;
    }

    setState(() {
      _chargementEnCours = true;
      _messageErreur = null;
    });

    // --------------------------------------------------
    // Appel réel à l'API Laravel, via AuthService.
    // Toute la logique réseau (http.post, décodage JSON,
    // gestion des codes d'erreur) est déjà écrite dans
    // lib/services/auth_service.dart — ici on n'a qu'à
    // lire le résultat.
    // --------------------------------------------------
    final resultat = await AuthService.inscrire(
      nom: _nomController.text.trim(),
      email: _emailController.text.trim(),
      motDePasse: _motDePasseController.text,
      confirmationMotDePasse: _confirmationController.text,
    );

    if (!mounted) return; // sécurité : l'écran a pu être fermé entretemps

    if (resultat.succes) {
      // TODO : sauvegarder resultat.token (flutter_secure_storage)
      // puis remplacer la ligne ci-dessous par la vraie redirection :
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const accueil.DashboardScreen()));
    } else {
      setState(() {
        _chargementEnCours = false;
        _messageErreur = resultat.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CertifioColors.fondVertFonce,
      body: SafeArea(
        child: SingleChildScrollView(
          // SingleChildScrollView : permet de faire défiler l'écran
          // si le clavier prend de la place (sinon les champs du bas
          // seraient cachés par le clavier).
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ======================================================
                // Bouton retour
                // ======================================================
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: CertifioColors.texteClair),
                ),

                const SizedBox(height: 8),

                // ======================================================
                // Petit logo "C" + titre de l'écran
                // ======================================================
                Container(
                  width: 56,
                  height: 56,
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
                      fontSize: 26,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Créer un compte",
                  style: TextStyle(
                    color: CertifioColors.texteClair,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Renseignez vos informations pour commencer.",
                  style: TextStyle(color: CertifioColors.texteClair.withOpacity(0.6)),
                ),

                const SizedBox(height: 28),

                // ======================================================
                // Champ : Nom complet
                // ======================================================
                _champTexte(
                  controller: _nomController,
                  label: "Nom complet",
                  icone: Icons.person_outline,
                  validator: (valeur) {
                    if (valeur == null || valeur.trim().isEmpty) {
                      return "Le nom est obligatoire";
                    }
                    return null; // null = pas d'erreur
                  },
                ),

                const SizedBox(height: 16),

                // ======================================================
                // Champ : Email
                // ======================================================
                _champTexte(
                  controller: _emailController,
                  label: "Adresse email",
                  icone: Icons.email_outlined,
                  typeClavier: TextInputType.emailAddress,
                  validator: (valeur) {
                    if (valeur == null || valeur.trim().isEmpty) {
                      return "L'email est obligatoire";
                    }
                    // Vérification simple du format email (contient un @ et un .)
                    final regexEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!regexEmail.hasMatch(valeur)) {
                      return "Adresse email invalide";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ======================================================
                // Champ : Mot de passe
                // ======================================================
                _champTexte(
                  controller: _motDePasseController,
                  label: "Mot de passe",
                  icone: Icons.lock_outline,
                  cacherTexte: !_motDePasseVisible,
                  iconeSuffixe: IconButton(
                    icon: Icon(
                      _motDePasseVisible ? Icons.visibility_off : Icons.visibility,
                      color: CertifioColors.texteClair.withOpacity(0.6),
                    ),
                    onPressed: () => setState(() => _motDePasseVisible = !_motDePasseVisible),
                  ),
                  validator: (valeur) {
                    if (valeur == null || valeur.length < 6) {
                      return "6 caractères minimum";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ======================================================
                // Champ : Confirmation du mot de passe
                // ======================================================
                _champTexte(
                  controller: _confirmationController,
                  label: "Confirmer le mot de passe",
                  icone: Icons.lock_outline,
                  cacherTexte: !_confirmationVisible,
                  iconeSuffixe: IconButton(
                    icon: Icon(
                      _confirmationVisible ? Icons.visibility_off : Icons.visibility,
                      color: CertifioColors.texteClair.withOpacity(0.6),
                    ),
                    onPressed: () => setState(() => _confirmationVisible = !_confirmationVisible),
                  ),
                  validator: (valeur) {
                    if (valeur == null || valeur.isEmpty) {
                      return "Veuillez confirmer le mot de passe";
                    }
                    return null;
                  },
                ),

                // ======================================================
                // Message d'erreur (affiché seulement s'il y en a un)
                // ======================================================
                if (_messageErreur != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CertifioColors.rouge.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: CertifioColors.rouge.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: CertifioColors.rouge, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _messageErreur!,
                            style: const TextStyle(color: CertifioColors.texteClair, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // ======================================================
                // Bouton "S'inscrire"
                // ======================================================
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    // Si le chargement est en cours, le bouton est désactivé
                    // (onPressed = null) pour éviter un double-clic.
                    onPressed: _chargementEnCours ? null : _sInscrire,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CertifioColors.or,
                      foregroundColor: CertifioColors.fondVertFonce,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _chargementEnCours
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: CertifioColors.fondVertFonce,
                            ),
                          )
                        : const Text(
                            "S'inscrire",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // ======================================================
                // Lien vers la connexion (pour ceux qui ont déjà un compte)
                // ======================================================
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const conn.LoginScreen()));
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Déjà un compte ? ",
                        style: TextStyle(color: CertifioColors.texteClair.withOpacity(0.6)),
                        children: const [
                          TextSpan(
                            text: "Se connecter",
                            style: TextStyle(
                              color: CertifioColors.orClair,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // Petite fonction "fabrique" de champ de texte.
  // Plutôt que de réécrire tout le style à chaque champ (nom,
  // email, mot de passe...), on l'écrit une seule fois ici et
  // on l'appelle avec des paramètres différents à chaque fois.
  // ----------------------------------------------------------
  Widget _champTexte({
    required TextEditingController controller,
    required String label,
    required IconData icone,
    required String? Function(String?) validator,
    TextInputType typeClavier = TextInputType.text,
    bool cacherTexte = false,
    Widget? iconeSuffixe,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: cacherTexte,
      keyboardType: typeClavier,
      validator: validator,
      style: const TextStyle(color: CertifioColors.texteClair),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: CertifioColors.texteClair.withOpacity(0.6)),
        prefixIcon: Icon(icone, color: CertifioColors.texteClair.withOpacity(0.6)),
        suffixIcon: iconeSuffixe,
        filled: true,
        fillColor: CertifioColors.fondVertMoyen,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CertifioColors.or, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: CertifioColors.rouge.withOpacity(0.6)),
        ),
      ),
    );
  }

  // On libère la mémoire utilisée par les controllers quand
  // l'écran est fermé (bonne pratique Flutter).
  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _motDePasseController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }
}
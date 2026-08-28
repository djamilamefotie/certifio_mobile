import 'package:flutter/material.dart';
import 'services/auth_service.dart';

// Mêmes couleurs que le reste de l'app (copiées de connexion.dart)
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
// ÉCRAN MOT DE PASSE OUBLIÉ — CERTIFIO
// ------------------------------------------------------------
// Un seul écran, 3 étapes gérées en interne :
//   1) saisie de l'email -> envoi du code par mail
//   2) saisie du code à 6 chiffres -> vérification
//   3) saisie du nouveau mot de passe -> réinitialisation
// ============================================================

class MotDePasseOublieScreen extends StatefulWidget {
  const MotDePasseOublieScreen({super.key});

  @override
  State<MotDePasseOublieScreen> createState() => _MotDePasseOublieScreenState();
}

class _MotDePasseOublieScreenState extends State<MotDePasseOublieScreen> {
  int _etape = 1; // 1 = email, 2 = code, 3 = nouveau mot de passe

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _nouveauMotDePasseController = TextEditingController();
  final _confirmationController = TextEditingController();

  bool _motDePasseVisible = false;
  bool _chargementEnCours = false;
  String? _messageErreur;

  // ----------------------------------------------------------
  // ÉTAPE 1 : demander l'envoi du code
  // ----------------------------------------------------------
  Future<void> _envoyerCode() async {
    final formulaireValide = _formKey.currentState?.validate() ?? false;
    if (!formulaireValide) return;

    setState(() {
      _chargementEnCours = true;
      _messageErreur = null;
    });

    final resultat = await AuthService.demanderCodeReinitialisation(
      email: _emailController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _chargementEnCours = false);

    if (resultat.succes) {
      setState(() => _etape = 2);
    } else {
      setState(() => _messageErreur = resultat.message);
    }
  }

  // ----------------------------------------------------------
  // ÉTAPE 2 : vérifier le code
  // ----------------------------------------------------------
  Future<void> _verifierCode() async {
    final formulaireValide = _formKey.currentState?.validate() ?? false;
    if (!formulaireValide) return;

    setState(() {
      _chargementEnCours = true;
      _messageErreur = null;
    });

    final resultat = await AuthService.verifierCodeReinitialisation(
      email: _emailController.text.trim(),
      code: _codeController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _chargementEnCours = false);

    if (resultat.succes) {
      setState(() => _etape = 3);
    } else {
      setState(() => _messageErreur = resultat.message);
    }
  }

  // ----------------------------------------------------------
  // ÉTAPE 3 : réinitialiser le mot de passe
  // ----------------------------------------------------------
  Future<void> _reinitialiser() async {
    final formulaireValide = _formKey.currentState?.validate() ?? false;
    if (!formulaireValide) return;

    setState(() {
      _chargementEnCours = true;
      _messageErreur = null;
    });

    final resultat = await AuthService.reinitialiserMotDePasse(
      email: _emailController.text.trim(),
      code: _codeController.text.trim(),
      nouveauMotDePasse: _nouveauMotDePasseController.text,
      confirmationMotDePasse: _confirmationController.text,
    );

    if (!mounted) return;

    setState(() => _chargementEnCours = false);

    if (resultat.succes) {
      // On revient à l'écran de connexion avec un message de succès.
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mot de passe réinitialisé avec succès. Connectez-vous.")),
      );
    } else {
      setState(() => _messageErreur = resultat.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CertifioColors.fondVertFonce,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () {
                    if (_etape == 1) {
                      Navigator.pop(context);
                    } else {
                      setState(() {
                        _etape -= 1;
                        _messageErreur = null;
                      });
                    }
                  },
                  icon: const Icon(Icons.arrow_back, color: CertifioColors.texteClair),
                ),

                const SizedBox(height: 24),

                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [CertifioColors.or, CertifioColors.orClair],
                      ),
                    ),
                    child: Icon(
                      _etape == 3 ? Icons.lock_reset : Icons.mail_lock_outlined,
                      color: CertifioColors.fondVertFonce,
                      size: 32,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  _titreEtape(),
                  style: const TextStyle(
                    color: CertifioColors.texteClair,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _sousTitreEtape(),
                  style: TextStyle(color: CertifioColors.texteClair.withOpacity(0.6)),
                ),

                const SizedBox(height: 28),

                ..._champsEtape(),

                if (_messageErreur != null) ...[
                  const SizedBox(height: 8),
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

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _chargementEnCours ? null : _actionEtape(),
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
                        : Text(
                            _texteBoutonEtape(),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                if (_etape == 2) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: _chargementEnCours ? null : _envoyerCode,
                      child: const Text(
                        "Renvoyer le code",
                        style: TextStyle(color: CertifioColors.orClair, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // Textes et champs qui changent selon l'étape en cours
  // ----------------------------------------------------------

  String _titreEtape() {
    switch (_etape) {
      case 1:
        return "Mot de passe oublié ?";
      case 2:
        return "Vérification";
      default:
        return "Nouveau mot de passe";
    }
  }

  String _sousTitreEtape() {
    switch (_etape) {
      case 1:
        return "Entrez votre email, on vous envoie un code.";
      case 2:
        return "Entrez le code à 6 chiffres reçu par email.";
      default:
        return "Choisissez un nouveau mot de passe.";
    }
  }

  String _texteBoutonEtape() {
    switch (_etape) {
      case 1:
        return "Envoyer le code";
      case 2:
        return "Vérifier";
      default:
        return "Réinitialiser";
    }
  }

  VoidCallback _actionEtape() {
    switch (_etape) {
      case 1:
        return _envoyerCode;
      case 2:
        return _verifierCode;
      default:
        return _reinitialiser;
    }
  }

  List<Widget> _champsEtape() {
    switch (_etape) {
      case 1:
        return [
          _champTexte(
            controller: _emailController,
            label: "Adresse email",
            icone: Icons.email_outlined,
            typeClavier: TextInputType.emailAddress,
            validator: (valeur) {
              if (valeur == null || valeur.trim().isEmpty) return "L'email est obligatoire";
              final regexEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
              if (!regexEmail.hasMatch(valeur)) return "Adresse email invalide";
              return null;
            },
          ),
        ];
      case 2:
        return [
          _champTexte(
            controller: _codeController,
            label: "Code à 6 chiffres",
            icone: Icons.pin_outlined,
            typeClavier: TextInputType.number,
            validator: (valeur) {
              if (valeur == null || valeur.trim().isEmpty) return "Le code est obligatoire";
              if (valeur.trim().length != 6) return "Le code doit contenir 6 chiffres";
              return null;
            },
          ),
        ];
      default:
        return [
          _champTexte(
            controller: _nouveauMotDePasseController,
            label: "Nouveau mot de passe",
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
              if (valeur == null || valeur.isEmpty) return "Le mot de passe est obligatoire";
              if (valeur.length < 8) return "8 caractères minimum";
              return null;
            },
          ),
          const SizedBox(height: 16),
          _champTexte(
            controller: _confirmationController,
            label: "Confirmer le mot de passe",
            icone: Icons.lock_outline,
            cacherTexte: !_motDePasseVisible,
            validator: (valeur) {
              if (valeur != _nouveauMotDePasseController.text) return "Les mots de passe ne correspondent pas";
              return null;
            },
          ),
        ];
    }
  }

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

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _nouveauMotDePasseController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }
}
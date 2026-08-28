import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'package:certifio_mobile/Mot_de_passe_oublie.dart';
import 'package:certifio_mobile/services/Accueil.dart' as accueil;
import 'package:certifio_mobile/Inscription.dart' as ins;

// Définitions locales renommées pour préserver les couleurs
class CertifioColors {
  static const fondVertFonce = Color(0xFF0A2E24);
  static const fondVertMoyen = Color(0xFF0E3B2E);
  static const vertMedaillon = Color(0xFF2F7D4F);
  static const or = Color(0xFFD9A93E);
  static const orClair = Color(0xFFF0C868);
  static const rouge = Color(0xFFC1272D);
  static const texteClair = Color(0xFFFFF8E7);
}

// ÉCRAN DE CONNEXION — CERTIFIO

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _motDePasseController = TextEditingController();
  bool _motDePasseVisible = false;
  bool _chargementEnCours = false;
  String? _messageErreur;
  Future<void> _seConnecter() async {
    final formulaireValide = _formKey.currentState?.validate() ?? false;
    if (!formulaireValide) return;

    setState(() {
      _chargementEnCours = true;
      _messageErreur = null;
    });

    final resultat = await AuthService.connecter(
      email: _emailController.text.trim(),
      motDePasse: _motDePasseController.text,
    );

    if (!mounted) return;

    if (resultat.succes) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const accueil.DashboardScreen()));
      // TODO: sauvegarder token et rediriger vers l'accueil
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
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
                    child: const Text(
                      "C",
                      style: TextStyle(
                        color: CertifioColors.fondVertFonce,
                        fontWeight: FontWeight.w900,
                        fontSize: 32,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  "Content de vous revoir",
                    style: TextStyle(
                    color: CertifioColors.texteClair,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Connectez-vous pour continuer.",
                  style: TextStyle(color: CertifioColors.texteClair.withOpacity(0.6)),
                ),

                const SizedBox(height: 28),

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

                const SizedBox(height: 16),

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
                    if (valeur == null || valeur.isEmpty) return "Le mot de passe est obligatoire";
                    return null;
                  },
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const MotDePasseOublieScreen()));
                    },
                    child: const Text(
                      "Mot de passe oublié ?",
                      style: TextStyle(color: CertifioColors.orClair, fontSize: 13),
                    ),
                  ),
                ),

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
                    onPressed: _chargementEnCours ? null : _seConnecter,
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
                            "Se connecter",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ins.RegisterScreen()));
                      },
                    child: RichText(
                      text: TextSpan(
                        text: "Pas encore de compte ? ",
                        style: TextStyle(color: CertifioColors.texteClair.withOpacity(0.6)),
                        children: const [
                          TextSpan(
                            text: "S'inscrire",
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
    _motDePasseController.dispose();
    super.dispose();
  }
}

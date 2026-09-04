import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../Verification.dart';
import '../historique.dart';
import '../models/verification.dart';
import 'historique_service.dart';
import 'package:certifio_mobile/Connection.dart' as conn;

// ============================================================
// DASHBOARD UTILISATEUR — CERTIFIO
// ============================================================

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
  int _ongletActuel = 0;

  Map<String, dynamic>? _utilisateur;
  bool _chargementUtilisateur = true;
  String? _erreurUtilisateur;

  @override
  void initState() {
    super.initState();
    _chargerUtilisateur();
  }

  Future<void> _chargerUtilisateur() async {
    setState(() {
      _chargementUtilisateur = true;
      _erreurUtilisateur = null;
    });

    final resultat = await AuthService.recupererUtilisateur();

    if (!mounted) return;

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

      if (resultat.message.contains("reconnecter") ||
          resultat.message.contains("expirée")) {
        // Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  void _allerVersOnglet(int index) {
    setState(() => _ongletActuel = index);
  }

  void _surProfilMisAJour(Map<String, dynamic> nouvelUtilisateur) {
    setState(() => _utilisateur = nouvelUtilisateur);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _OngletAccueil(
        utilisateur: _utilisateur,
        chargement: _chargementUtilisateur,
        surAllerVersVerification: () => _allerVersOnglet(1),
        surAllerVersHistorique: () => _allerVersOnglet(2),
      ),
      const VerificationScreen(),
      const HistoriqueScreen(),
      _OngletProfil(
        utilisateur: _utilisateur,
        chargement: _chargementUtilisateur,
        surDeconnexion: _deconnecter,
        surProfilMisAJour: _surProfilMisAJour,
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
            Expanded(
              child: IndexedStack(
                index: _ongletActuel,
                children: pages,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _ongletActuel,
        onTap: (index) => setState(() => _ongletActuel = index),
        backgroundColor: CertifioColors.fondVertMoyen,
        selectedItemColor: CertifioColors.orClair,
        unselectedItemColor: CertifioColors.texteClair.withOpacity(0.5),
        type: BottomNavigationBarType.fixed,
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

  Future<void> _deconnecter() async {
    // Demande de confirmation avant de couper la session.
    final confirmer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CertifioColors.fondVertMoyen,
        title: const Text(
          "Se déconnecter",
          style: TextStyle(color: CertifioColors.texteClair),
        ),
        content: Text(
          "Voulez-vous vraiment vous déconnecter ?",
          style: TextStyle(color: CertifioColors.texteClair.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Annuler",
              style: TextStyle(color: CertifioColors.texteClair.withOpacity(0.7)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Se déconnecter",
              style: TextStyle(color: CertifioColors.rouge, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmer != true) return;

    // Supprime le token côté serveur (logout Sanctum) et localement
    // (flutter_secure_storage), voir AuthService.deconnecter().
    await AuthService.deconnecter();

    if (!mounted) return;

    // On vide l'état local pour que l'interface ne montre plus
    // les anciennes données utilisateur (nom, email, avatar...).
    setState(() {
      _utilisateur = null;
      _erreurUtilisateur = null;
      _ongletActuel = 0;
    });

    // Redirige vers l'écran de connexion et retire toutes les
    // pages précédentes de la pile (l'utilisateur ne doit pas
    // pouvoir revenir en arrière vers le Dashboard après s'être
    // déconnecté).
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const conn.LoginScreen()),
      (route) => false,
    );
  }
}

// ============================================================
// ONGLET 1 : ACCUEIL
// ============================================================
class _OngletAccueil extends StatefulWidget {
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
  State<_OngletAccueil> createState() => _OngletAccueilState();
}

class _OngletAccueilState extends State<_OngletAccueil> {
  bool _chargementHistorique = true;
  List<Verification> _verifications = [];

  @override
  void initState() {
    super.initState();
    _chargerHistorique();
  }

  Future<void> _chargerHistorique() async {
    final resultat = await HistoriqueService.recupererHistorique();
    if (!mounted) return;

    setState(() {
      _chargementHistorique = false;
      if (resultat.succes) {
        _verifications = List<Verification>.from(resultat.verifications)
          ..sort((a, b) => b.dateVerification.compareTo(a.dateVerification));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String nomUtilisateur =
        (widget.utilisateur?["name"] as String?) ??
        (widget.chargement ? "..." : "Utilisateur");
    final String initiale =
        nomUtilisateur.isNotEmpty ? nomUtilisateur[0].toUpperCase() : "?";

    final int totalVerifications = _verifications.length;
    final int totalAuthentiques = _verifications
        .where((v) => v.statut == StatutVerification.authentique)
        .length;
    final List<Verification> recentes = _verifications.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          SizedBox(
            width: double.infinity,
            height: 130,
            child: ElevatedButton(
              onPressed: widget.surAllerVersVerification,
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

          Row(
            children: [
              Expanded(
                child: _carteStat(
                  icone: Icons.fact_check_rounded,
                  valeur: _chargementHistorique ? "..." : "$totalVerifications",
                  libelle: "Vérifications",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _carteStat(
                  icone: Icons.verified_rounded,
                  valeur: _chargementHistorique ? "..." : "$totalAuthentiques",
                  libelle: "Authentiques",
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

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
                onPressed: widget.surAllerVersHistorique,
                child: const Text(
                  "Voir tout",
                  style: TextStyle(color: CertifioColors.orClair, fontSize: 13),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (_chargementHistorique)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(color: CertifioColors.orClair),
              ),
            )
          else if (recentes.isEmpty)
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
            )
          else
            Column(
              children: recentes.map((v) => _carteVerificationRecente(v)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _carteVerificationRecente(Verification v) {
    Color couleur;
    IconData icone;
    String texte;

    switch (v.statut) {
      case StatutVerification.authentique:
        couleur = CertifioColors.vertMedaillon;
        icone = Icons.verified_rounded;
        texte = "AUTHENTIQUE";
        break;
      case StatutVerification.suspect:
        couleur = CertifioColors.rouge;
        icone = Icons.warning_amber_rounded;
        texte = "SUSPECT";
        break;
      case StatutVerification.ambigu:
        couleur = CertifioColors.or;
        icone = Icons.help_outline_rounded;
        texte = "AMBIGU";
        break;
      case StatutVerification.inconnu:
        couleur = CertifioColors.or;
        icone = Icons.help_outline_rounded;
        texte = "INCONNU";
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icone, color: couleur),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.diplome.nomTitulaire,
                  style: const TextStyle(
                    color: CertifioColors.texteClair,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  v.diplome.typeDiplome,
                  style: TextStyle(
                    color: CertifioColors.texteClair.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                texte,
                style: TextStyle(color: couleur, fontWeight: FontWeight.bold, fontSize: 11),
              ),
              Text(
                "${v.scoreFinal.toStringAsFixed(0)}%",
                style: TextStyle(color: couleur, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
// ONGLET 4 : PROFIL
// ============================================================
class _OngletProfil extends StatefulWidget {
  final Map<String, dynamic>? utilisateur;
  final bool chargement;
  final VoidCallback surDeconnexion;
  final ValueChanged<Map<String, dynamic>> surProfilMisAJour;

  const _OngletProfil({
    required this.utilisateur,
    required this.chargement,
    required this.surDeconnexion,
    required this.surProfilMisAJour,
  });

  @override
  State<_OngletProfil> createState() => _OngletProfilState();
}

class _OngletProfilState extends State<_OngletProfil> {
  bool _modificationEnCours = false;
  String? _messageErreur;

  Future<void> _ouvrirDialogueModification() async {
    final controleurNom = TextEditingController(
      text: (widget.utilisateur?["name"] as String?) ?? "",
    );
    final controleurEmail = TextEditingController(
      text: (widget.utilisateur?["email"] as String?) ?? "",
    );

    // On récupère les deux champs à la fois via une Map, pour
    // pouvoir envoyer nom ET email en un seul appel à l'API.
    final donneesModifiees = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CertifioColors.fondVertMoyen,
        title: const Text(
          "Modifier mes informations",
          style: TextStyle(color: CertifioColors.texteClair),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controleurNom,
              style: const TextStyle(color: CertifioColors.texteClair),
              decoration: InputDecoration(
                labelText: "Nom complet",
                labelStyle: TextStyle(color: CertifioColors.texteClair.withOpacity(0.6)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: CertifioColors.texteClair.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: CertifioColors.or),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controleurEmail,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: CertifioColors.texteClair),
              decoration: InputDecoration(
                labelText: "Adresse email",
                labelStyle: TextStyle(color: CertifioColors.texteClair.withOpacity(0.6)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: CertifioColors.texteClair.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: CertifioColors.or),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Annuler",
              style: TextStyle(color: CertifioColors.texteClair.withOpacity(0.7)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              "nom": controleurNom.text.trim(),
              "email": controleurEmail.text.trim(),
            }),
            child: const Text(
              "Enregistrer",
              style: TextStyle(color: CertifioColors.orClair, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (donneesModifiees == null) return;

    final nouveauNom = donneesModifiees["nom"] ?? "";
    final nouvelEmail = donneesModifiees["email"] ?? "";

    if (nouveauNom.isEmpty || nouvelEmail.isEmpty) {
      setState(() => _messageErreur = "Le nom et l'email ne peuvent pas être vides.");
      return;
    }

    setState(() {
      _modificationEnCours = true;
      _messageErreur = null;
    });

    final resultat = await AuthService.modifierProfil(
      nom: nouveauNom,
      email: nouvelEmail,
    );

    if (!mounted) return;

    setState(() => _modificationEnCours = false);

    if (resultat.succes && resultat.utilisateur != null) {
      widget.surProfilMisAJour(resultat.utilisateur!);
    } else {
      setState(() => _messageErreur = resultat.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String nom =
        (widget.utilisateur?["name"] as String?) ?? (widget.chargement ? "..." : "Utilisateur");
    final String email = (widget.utilisateur?["email"] as String?) ?? "";
    final String categorie = (widget.utilisateur?["categorie"] as String?) ?? "Utilisateur";
    final String abonnement = (widget.utilisateur?["abonnement"] as String?) ?? "gratuit";
    final String initiale = nom.isNotEmpty ? nom[0].toUpperCase() : "?";
    final bool estPremium = abonnement == "premium";

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

          const SizedBox(height: 28),

          // Carte Abonnement
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CertifioColors.fondVertMoyen,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: estPremium
                    ? CertifioColors.or.withOpacity(0.5)
                    : CertifioColors.texteClair.withOpacity(0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  estPremium ? Icons.workspace_premium_rounded : Icons.star_border_rounded,
                  color: estPremium ? CertifioColors.orClair : CertifioColors.texteClair.withOpacity(0.6),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Mon abonnement",
                        style: TextStyle(
                          color: CertifioColors.texteClair,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        estPremium ? "Premium" : "Gratuit",
                        style: TextStyle(
                          color: estPremium ? CertifioColors.orClair : CertifioColors.texteClair,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Bouton Modifier mes informations
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _modificationEnCours ? null : _ouvrirDialogueModification,
              icon: _modificationEnCours
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: CertifioColors.orClair),
                    )
                  : const Icon(Icons.edit_rounded, color: CertifioColors.orClair),
              label: const Text(
                "Modifier mes informations",
                style: TextStyle(color: CertifioColors.orClair, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: CertifioColors.orClair.withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          if (_messageErreur != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _messageErreur!,
                style: const TextStyle(color: CertifioColors.rouge),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 12),

          // Bouton de déconnexion
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: widget.surDeconnexion,
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
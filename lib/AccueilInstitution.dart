import 'package:flutter/material.dart';
import 'package:certifio_mobile/Connection.dart' show CertifioColors, LoginScreen;
import 'package:certifio_mobile/services/auth_service.dart';

// ============================================================
// ÉCRAN D'ACCUEIL — COMPTE INSTITUTION (avec navigation persistante)
// ============================================================

class AccueilInstitutionScreen extends StatefulWidget {
  final String nomInstitution;

  const AccueilInstitutionScreen({super.key, required this.nomInstitution});

  @override
  State<AccueilInstitutionScreen> createState() => _AccueilInstitutionScreenState();
}

class _AccueilInstitutionScreenState extends State<AccueilInstitutionScreen> {
  int _indexActif = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _AccueilContenu(nomInstitution: widget.nomInstitution, onNaviguer: (i) => setState(() => _indexActif = i)),
      const SoumettreDiplomeContenu(),
      const SoumissionsInstitutionContenu(),
      ProfilInstitutionContenu(nomInstitution: widget.nomInstitution),
    ];

    return Scaffold(
      backgroundColor: CertifioColors.fondVertFonce,
      body: SafeArea(
        child: IndexedStack(
          index: _indexActif,
          children: pages,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indexActif,
        onTap: (index) => setState(() => _indexActif = index),
        backgroundColor: CertifioColors.fondVertFonce,
        selectedItemColor: CertifioColors.orClair,
        unselectedItemColor: CertifioColors.texteClair.withOpacity(0.5),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Accueil"),
          BottomNavigationBarItem(icon: Icon(Icons.upload_file_outlined), label: "Soumettre"),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), label: "Soumissions"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profil"),
        ],
      ),
    );
  }
}

// ============================================================
// CONTENU DE L'ONGLET "ACCUEIL"
// ============================================================

class _AccueilContenu extends StatelessWidget {
  final String nomInstitution;
  final void Function(int) onNaviguer;

  const _AccueilContenu({required this.nomInstitution, required this.onNaviguer});

  @override
  Widget build(BuildContext context) {
    final initiale = nomInstitution.isNotEmpty ? nomInstitution[0].toUpperCase() : "I";

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : Bonjour + avatar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bonjour,",
                    style: TextStyle(
                      fontSize: 14,
                      color: CertifioColors.texteClair.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nomInstitution,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: CertifioColors.texteClair,
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
                  color: CertifioColors.or,
                ),
                child: Text(
                  initiale,
                  style: const TextStyle(
                    color: CertifioColors.fondVertFonce,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Grande carte action principale
          InkWell(
            onTap: () => onNaviguer(1),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: CertifioColors.vertMedaillon,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CertifioColors.or, width: 1.2),
              ),
              child: Column(
                children: [
                  const Icon(Icons.upload_file_rounded, color: CertifioColors.texteClair, size: 28),
                  const SizedBox(height: 10),
                  const Text(
                    "Soumettre un diplôme",
                    style: TextStyle(
                      color: CertifioColors.texteClair,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Importer un dossier d'images",
                    style: TextStyle(
                      color: CertifioColors.texteClair.withOpacity(0.75),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Deux petites cartes statistiques
          Row(
            children: const [
              Expanded(
                child: _CarteStat(
                  icone: Icons.assignment_turned_in_outlined,
                  valeur: "0",
                  libelle: "Soumissions",
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: _CarteStat(
                  icone: Icons.verified_outlined,
                  valeur: "0",
                  libelle: "Validées",
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Soumissions récentes",
                style: TextStyle(
                  color: CertifioColors.texteClair,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              TextButton(
                onPressed: () => onNaviguer(2),
                child: const Text(
                  "Voir tout",
                  style: TextStyle(color: CertifioColors.orClair, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30),
            decoration: BoxDecoration(
              color: CertifioColors.fondVertMoyen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, color: CertifioColors.texteClair.withOpacity(0.5), size: 26),
                const SizedBox(height: 8),
                Text(
                  "Aucune soumission pour l'instant",
                  style: TextStyle(color: CertifioColors.texteClair.withOpacity(0.6), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CarteStat extends StatelessWidget {
  final IconData icone;
  final String valeur;
  final String libelle;

  const _CarteStat({required this.icone, required this.valeur, required this.libelle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CertifioColors.fondVertMoyen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: CertifioColors.orClair, size: 20),
          const SizedBox(height: 10),
          Text(
            valeur,
            style: const TextStyle(
              color: CertifioColors.texteClair,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
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
// CONTENU DE L'ONGLET "SOUMETTRE UN DIPLÔME"
// ============================================================

class SoumettreDiplomeContenu extends StatelessWidget {
  const SoumettreDiplomeContenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Icon(Icons.upload_file_rounded, color: CertifioColors.orClair.withOpacity(0.8), size: 64),
          const SizedBox(height: 20),
          const Text(
            "Import de diplômes",
            style: TextStyle(color: CertifioColors.texteClair, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "Cette fonctionnalité permettra à l'institution d'importer un dossier de diplômes délivrés pour les ajouter à la base de référence.",
            textAlign: TextAlign.center,
            style: TextStyle(color: CertifioColors.texteClair.withOpacity(0.6), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CONTENU DE L'ONGLET "MES SOUMISSIONS"
// ============================================================

class SoumissionsInstitutionContenu extends StatelessWidget {
  const SoumissionsInstitutionContenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, color: CertifioColors.texteClair.withOpacity(0.4), size: 56),
          const SizedBox(height: 16),
          Text(
            "Aucune soumission pour l'instant",
            style: TextStyle(color: CertifioColors.texteClair.withOpacity(0.6), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CONTENU DE L'ONGLET "MON PROFIL"
// ============================================================

class ProfilInstitutionContenu extends StatelessWidget {
  final String nomInstitution;

  const ProfilInstitutionContenu({super.key, required this.nomInstitution});

  @override
  Widget build(BuildContext context) {
    final initiale = nomInstitution.isNotEmpty ? nomInstitution[0].toUpperCase() : "I";

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: CertifioColors.or),
            child: Text(
              initiale,
              style: const TextStyle(color: CertifioColors.fondVertFonce, fontWeight: FontWeight.w900, fontSize: 28),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            nomInstitution,
            style: const TextStyle(color: CertifioColors.texteClair, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "Compte Institution",
            style: TextStyle(color: CertifioColors.texteClair.withOpacity(0.6), fontSize: 13),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                await AuthService.deconnecter();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: CertifioColors.rouge,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Se déconnecter", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
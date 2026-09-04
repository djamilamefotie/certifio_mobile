import 'package:flutter/material.dart';

import 'models/verification.dart';
import 'services/Accueil.dart'; // pour CertifioColors
import 'services/historique_service.dart';

class HistoriqueScreen extends StatefulWidget {
  const HistoriqueScreen({super.key});

  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> {
  late Future<ResultatHistorique> _futureHistorique;

  @override
  void initState() {
    super.initState();
    _futureHistorique = HistoriqueService.recupererHistorique();
  }

  Future<void> _rafraichir() async {
    setState(() {
      _futureHistorique = HistoriqueService.recupererHistorique();
    });
    await _futureHistorique;
  }

  Color _couleurStatut(StatutVerification statut) {
    switch (statut) {
      case StatutVerification.authentique:
        return CertifioColors.vertMedaillon;
      case StatutVerification.suspect:
        return CertifioColors.rouge;
      case StatutVerification.ambigu:
      case StatutVerification.inconnu:
        return CertifioColors.or;
    }
  }

  IconData _iconeStatut(StatutVerification statut) {
    switch (statut) {
      case StatutVerification.authentique:
        return Icons.verified_rounded;
      case StatutVerification.suspect:
        return Icons.warning_amber_rounded;
      case StatutVerification.ambigu:
      case StatutVerification.inconnu:
        return Icons.help_outline_rounded;
    }
  }

  String _texteStatut(StatutVerification statut) {
    switch (statut) {
      case StatutVerification.authentique:
        return "AUTHENTIQUE";
      case StatutVerification.suspect:
        return "SUSPECT";
      case StatutVerification.ambigu:
        return "AMBIGU";
      case StatutVerification.inconnu:
        return "INCONNU";
    }
  }

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
          const SizedBox(height: 4),
          Text(
            "Retrouvez toutes vos vérifications précédentes.",
            style: TextStyle(color: CertifioColors.texteClair.withValues(alpha: 0.6)),
          ),

          const SizedBox(height: 24),

          Expanded(
            child: FutureBuilder<ResultatHistorique>(
              future: _futureHistorique,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: CertifioColors.orClair),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Erreur inattendue : ${snapshot.error}",
                      style: const TextStyle(color: CertifioColors.rouge),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final resultat = snapshot.data!;

                if (!resultat.succes) {
                  return Center(
                    child: Text(
                      resultat.message ?? "Erreur inconnue.",
                      style: const TextStyle(color: CertifioColors.rouge),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (resultat.verifications.isEmpty) {
                  return Center(
                    child: Text(
                      "Aucune vérification pour le moment.",
                      style: TextStyle(color: CertifioColors.texteClair.withValues(alpha: 0.6)),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _rafraichir,
                  child: ListView.builder(
                    itemCount: resultat.verifications.length,
                    itemBuilder: (context, index) {
                      final Verification v = resultat.verifications[index];
                      final Diplome d = v.diplome;
                      final couleur = _couleurStatut(v.statut);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: couleur.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: couleur.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            Icon(_iconeStatut(v.statut), color: couleur),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.nomTitulaire,
                                    style: const TextStyle(
                                      color: CertifioColors.texteClair,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    d.typeDiplome,
                                    style: TextStyle(
                                      color: CertifioColors.texteClair.withValues(alpha: 0.6),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _texteStatut(v.statut),
                                  style: TextStyle(color: couleur, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                Text(
                                  "${v.scoreFinal.toStringAsFixed(0)}%",
                                  style: TextStyle(color: couleur, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
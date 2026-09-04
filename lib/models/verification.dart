// lib/models/verification.dart

class Diplome {
  final int id;
  final String numeroDiplome;
  final String typeDiplome;
  final String? institution;
  final String nomTitulaire;
  final String? mention;
  final String? etablissement;
  final DateTime? dateObtention;
  final String fichier;

  Diplome({
    required this.id,
    required this.numeroDiplome,
    required this.typeDiplome,
    this.institution,
    required this.nomTitulaire,
    this.mention,
    this.etablissement,
    this.dateObtention,
    required this.fichier,
  });

  factory Diplome.fromJson(Map<String, dynamic> json) {
    return Diplome(
      id: json['id'],
      numeroDiplome: json['numeroDiplome'] ?? '',
      typeDiplome: json['typeDiplome'] ?? '',
      institution: json['institution'],
      nomTitulaire: json['nomTitulaire'] ?? '',
      mention: json['mention'],
      etablissement: json['etablissement'],
      dateObtention: json['dateObtention'] != null
          ? DateTime.tryParse(json['dateObtention'])
          : null,
      fichier: json['fichier'] ?? '',
    );
  }

  /// URL complète de l'image du diplôme (à adapter selon ton storage Laravel)
  String urlFichier(String baseUrl) => '$baseUrl/storage/$fichier';
}

enum StatutVerification { authentique, suspect, ambigu, inconnu }

extension StatutVerificationParsing on String {
  StatutVerification toStatutVerification() {
    switch (this) {
      case 'authentique':
        return StatutVerification.authentique;
      case 'suspect':
        return StatutVerification.suspect;
      case 'ambigu':
        return StatutVerification.ambigu;
      default:
        return StatutVerification.inconnu;
    }
  }
}

class Verification {
  final int id;
  final DateTime dateVerification;
  final StatutVerification statut;
  final String resultat;
  final double scoreFinal;
  final int diplomeId;
  final int? baseReferenceId;
  final Diplome diplome;
  final Map<String, dynamic>? donneesAnalyseIa;

  Verification({
    required this.id,
    required this.dateVerification,
    required this.statut,
    required this.resultat,
    required this.scoreFinal,
    required this.diplomeId,
    this.baseReferenceId,
    required this.diplome,
    this.donneesAnalyseIa,
  });

  factory Verification.fromJson(Map<String, dynamic> json) {
    return Verification(
      id: json['id'],
      // La clé JSON contient un accent : "dateVérification"
      dateVerification: DateTime.tryParse(
            json['dateVérification'] ?? json['dateVerification'] ?? '',
          ) ??
          DateTime.now(),
      statut: (json['statut'] ?? '').toString().toStatutVerification(),
      resultat: json['resultat'] ?? '',
      scoreFinal: double.tryParse(json['scoreFinal']?.toString() ?? '0') ?? 0,
      diplomeId: json['diplome_id'],
      baseReferenceId: json['base_reference_id'],
      diplome: Diplome.fromJson(json['diplome']),
      donneesAnalyseIa: json['donneesAnalyseIa'] != null
          ? Map<String, dynamic>.from(json['donneesAnalyseIa'])
          : null,
    );
  }
}

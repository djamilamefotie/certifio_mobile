import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ============================================================
// SERVICE DE VÉRIFICATION — CERTIFIO
// ------------------------------------------------------------
// Envoie l'image du diplôme à POST /api/diplomes/verifier
// (upload multipart + token Bearer), et renvoie le résultat
// de la vérification (authentique / suspect / ambigu).
// ============================================================

const String _urlBase = "http://192.168.85.56:8000/api"; // TODO: garder identique à auth_service.dart
final _storage = FlutterSecureStorage();
const String _cleToken = "auth_token";

class ResultatVerification {
  final bool succes;
  final String message;
  final String? statut; // 'authentique' | 'suspect' | 'ambigu'
  final String? resultatTexte; // explication détaillée
  final double? scoreFinal;
  final Map<String, dynamic>? diplome;
  final Map<String, dynamic>? verification;

  ResultatVerification({
    required this.succes,
    required this.message,
    this.statut,
    this.resultatTexte,
    this.scoreFinal,
    this.diplome,
    this.verification,
  });
}

class VerificationService {
  // ----------------------------------------------------------
  // Envoie l'image au serveur pour analyse complète
  // (OCR -> Gemini -> Comparaison), protégé par le token.
  // ----------------------------------------------------------
  static Future<ResultatVerification> verifierDiplome(String cheminImage) async {
    try {
      final token = await _storage.read(key: _cleToken);

      if (token == null) {
        return ResultatVerification(
          succes: false,
          message: "Session expirée. Veuillez vous reconnecter.",
        );
      }

      final requete = http.MultipartRequest(
        'POST',
        Uri.parse("$_urlBase/diplomes/verifier"),
      );

      requete.headers['Authorization'] = 'Bearer $token';
      requete.headers['Accept'] = 'application/json';

      requete.files.add(
        await http.MultipartFile.fromPath('image', cheminImage),
      );

      final reponseStream = await requete.send();
      final reponse = await http.Response.fromStream(reponseStream);
      final donnees = jsonDecode(reponse.body);

      // Succès : diplôme analysé (201)
      if (reponse.statusCode == 201) {
        final verification = donnees['verification'];
        return ResultatVerification(
          succes: true,
          message: donnees['message'] ?? "Analyse terminée",
          statut: verification?['statut'],
          resultatTexte: verification?['resultat'],
          scoreFinal: (verification?['scoreFinal'] as num?)?.toDouble(),
          diplome: donnees['diplome'],
          verification: verification,
        );
      }

      // Token invalide/expiré
      if (reponse.statusCode == 401) {
        await _storage.delete(key: _cleToken);
        return ResultatVerification(
          succes: false,
          message: "Session expirée. Veuillez vous reconnecter.",
        );
      }

      // Diplôme reçu mais analyse échouée côté serveur (500, cf. DiplomeController)
      return ResultatVerification(
        succes: false,
        message: donnees['message'] ?? "L'analyse du diplôme a échoué.",
      );
    } catch (e) {
      return ResultatVerification(
        succes: false,
        message: "Impossible de contacter le serveur. Vérifiez votre connexion.",
      );
    }
  }
}
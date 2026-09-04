// lib/services/historique_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/verification.dart';

/// Résultat renvoyé par HistoriqueService, sur le même principe que
/// ResultatVerification : un flag "succes" + message, pas d'exception
/// à catch côté UI.
class ResultatHistorique {
  final bool succes;
  final String? message;
  final List<Verification> verifications;

  ResultatHistorique({
    required this.succes,
    this.message,
    this.verifications = const [],
  });

  factory ResultatHistorique.succesAvec(List<Verification> verifications) {
    return ResultatHistorique(succes: true, verifications: verifications);
  }

  factory ResultatHistorique.echec(String message) {
    return ResultatHistorique(succes: false, message: message);
  }
}

class HistoriqueService {
  // Même base URL que VerificationScreen / VerificationService.
  static const String _baseUrl = 'http://192.168.85.56:8000/api';

  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Récupère l'historique complet des vérifications de l'utilisateur connecté.
  static Future<ResultatHistorique> recupererHistorique() async {
    try {
      final String? token = await _storage.read(key: 'auth_token');

      if (token == null) {
        return ResultatHistorique.echec('Utilisateur non authentifié.');
      }

      final Uri uri = Uri.parse('$_baseUrl/diplomes/historique');

      final http.Response reponse = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (reponse.statusCode == 401) {
        return ResultatHistorique.echec(
          'Session expirée, veuillez vous reconnecter.',
        );
      }

      if (reponse.statusCode != 200) {
        return ResultatHistorique.echec(
          "Erreur lors de la récupération de l'historique (${reponse.statusCode}).",
        );
      }

      final Map<String, dynamic> corps =
          jsonDecode(utf8.decode(reponse.bodyBytes));
      final List<dynamic> liste = corps['verifications'] ?? [];

      final verifications = liste
          .map((item) => Verification.fromJson(item as Map<String, dynamic>))
          .toList();

      return ResultatHistorique.succesAvec(verifications);
    } catch (e) {
      return ResultatHistorique.echec('Impossible de contacter le serveur.');
    }
  }

  /// Récupère uniquement les vérifications d'un statut donné,
  /// pratique pour filtrer côté UI sans re-solliciter le serveur.
  static Future<ResultatHistorique> recupererHistoriqueParStatut(
    StatutVerification statut,
  ) async {
    final resultat = await recupererHistorique();
    if (!resultat.succes) return resultat;

    final filtrees =
        resultat.verifications.where((v) => v.statut == statut).toList();
    return ResultatHistorique.succesAvec(filtrees);
  }
}
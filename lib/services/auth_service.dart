import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ============================================================
// SERVICE D'AUTHENTIFICATION — CERTIFIO
// ------------------------------------------------------------
// Ce fichier centralise TOUS les appels réseau vers l'API
// Laravel liés à l'authentification (inscription, connexion,
// récupération de l'utilisateur connecté) ainsi que le
// stockage sécurisé du token entre les écrans.
// ============================================================


// ------------------------------------------------------------
// ADRESSE DE TON SERVEUR LARAVEL
// ------------------------------------------------------------
const String _urlBase = "http://192.168.98.56:8000/api";


// ------------------------------------------------------------
// Stockage sécurisé (chiffré) du token, partagé par tout le
// service. flutter_secure_storage utilise le Keystore sur
// Android et le Keychain sur iOS.
// ------------------------------------------------------------
final _storage = FlutterSecureStorage();
const String _cleToken = "auth_token"; // nom de la clé dans le stockage


// ------------------------------------------------------------
// Petite classe pour "ranger" le résultat d'un appel API.
// ------------------------------------------------------------
class ResultatAuth {
  final bool succes;
  final String message;
  final String? token; // null si échec
  final Map<String, dynamic>? utilisateur; // null si échec

  ResultatAuth({
    required this.succes,
    required this.message,
    this.token,
    this.utilisateur,
  });
}


class AuthService {
  // ----------------------------------------------------------
  // INSCRIPTION — appelle POST /api/register
  // ----------------------------------------------------------
  static Future<ResultatAuth> inscrire({
    required String nom,
    required String email,
    required String motDePasse,
    required String confirmationMotDePasse,
  }) async {
    try {
      final reponse = await http.post(
        Uri.parse("$_urlBase/register"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "name": nom,
          "email": email,
          "password": motDePasse,
          "password_confirmation": confirmationMotDePasse,
        }),
      );

      final donnees = jsonDecode(reponse.body);

      if (reponse.statusCode == 201) {
        final token = donnees["token"];

        // Si Laravel connecte déjà l'utilisateur à l'inscription
        // (token renvoyé), on le stocke tout de suite.
        if (token != null) {
          await _storage.write(key: _cleToken, value: token);
        }

        return ResultatAuth(
          succes: true,
          message: donnees["message"] ?? "Inscription réussie",
          token: token,
          utilisateur: donnees["user"],
        );
      }

      if (reponse.statusCode == 422 && donnees["errors"] != null) {
        final premiereErreur = (donnees["errors"] as Map).values.first[0];
        return ResultatAuth(succes: false, message: premiereErreur);
      }

      return ResultatAuth(
        succes: false,
        message: donnees["message"] ?? "Une erreur est survenue.",
      );
    } catch (e) {
      return ResultatAuth(
        succes: false,
        message: "Impossible de contacter le serveur. Vérifiez votre connexion.",
      );
    }
  }

  // ----------------------------------------------------------
  // CONNEXION — appelle POST /api/login
  // ----------------------------------------------------------
  static Future<ResultatAuth> connecter({
    required String email,
    required String motDePasse,
  }) async {
    try {
      final reponse = await http.post(
        Uri.parse("$_urlBase/login"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "email": email,
          "password": motDePasse,
        }),
      );

      final donnees = jsonDecode(reponse.body);

      if (reponse.statusCode == 200) {
        final token = donnees["token"];

        // On stocke le token de façon chiffrée pour pouvoir
        // l'utiliser plus tard dans les requêtes protégées
        // (ex: recupererUtilisateur, déconnexion...).
        if (token != null) {
          await _storage.write(key: _cleToken, value: token);
        }

        return ResultatAuth(
          succes: true,
          message: donnees["message"] ?? "Connexion réussie",
          token: token,
          utilisateur: donnees["user"],
        );
      }

      return ResultatAuth(
        succes: false,
        message: donnees["message"] ?? "Erreur de connexion.",
      );
    } catch (e) {
      return ResultatAuth(
        succes: false,
        message: "Impossible de contacter le serveur. Vérifiez votre connexion.",
      );
    }
  }

  // ----------------------------------------------------------
  // RÉCUPÉRER L'UTILISATEUR CONNECTÉ — appelle GET /api/user
  // ----------------------------------------------------------
  // Utilisée au chargement de l'écran d'accueil pour afficher
  // les vraies infos (nom, email, catégorie...) au lieu de
  // données statiques. Nécessite un token déjà stocké.
  // ----------------------------------------------------------
  static Future<ResultatAuth> recupererUtilisateur() async {
    try {
      final token = await _storage.read(key: _cleToken);

      // Pas de token stocké -> l'utilisateur n'est pas connecté.
      if (token == null) {
        return ResultatAuth(
          succes: false,
          message: "Aucune session active. Veuillez vous reconnecter.",
        );
      }

      final reponse = await http.get(
        Uri.parse("$_urlBase/user"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      // Code 200 = token valide, données utilisateur renvoyées.
      if (reponse.statusCode == 200) {
        final donnees = jsonDecode(reponse.body);
        return ResultatAuth(
          succes: true,
          message: "Utilisateur récupéré",
          token: token,
          utilisateur: donnees,
        );
      }

      // Code 401 = token invalide ou expiré.
      // On supprime le token local devenu inutile pour forcer
      // une reconnexion propre plutôt que de le garder en cache.
      if (reponse.statusCode == 401) {
        await _storage.delete(key: _cleToken);
        return ResultatAuth(
          succes: false,
          message: "Session expirée. Veuillez vous reconnecter.",
        );
      }

      return ResultatAuth(
        succes: false,
        message: "Impossible de récupérer les informations utilisateur.",
      );
    } catch (e) {
      return ResultatAuth(
        succes: false,
        message: "Impossible de contacter le serveur. Vérifiez votre connexion.",
      );
    }
  }

  // ----------------------------------------------------------
  // DÉCONNEXION — appelle POST /api/logout puis supprime le
  // token stocké localement.
  // ----------------------------------------------------------
  // On invalide d'abord le token côté Laravel (il supprime
  // uniquement le token de CET appareil, voir AuthController::logout),
  // puis on le supprime du stockage local dans tous les cas —
  // même si l'appel réseau échoue (token déjà expiré, pas de
  // connexion...), l'utilisateur doit pouvoir se déconnecter
  // localement sans rester bloqué.
  // ----------------------------------------------------------
  static Future<void> deconnecter() async {
    try {
      final token = await _storage.read(key: _cleToken);

      if (token != null) {
        await http.post(
          Uri.parse("$_urlBase/logout"),
          headers: {
            "Accept": "application/json",
            "Authorization": "Bearer $token",
          },
        );
      }
    } catch (e) {
      // On ignore l'erreur réseau ici : la déconnexion locale
      // doit se faire quoi qu'il arrive (voir commentaire ci-dessus).
    } finally {
      await _storage.delete(key: _cleToken);
    }
  }

  // ----------------------------------------------------------
  // Utilitaire : savoir si un token existe déjà en local
  // (utile au démarrage de l'app pour sauter directement
  // à l'écran d'accueil si l'utilisateur est déjà connecté).
  // ----------------------------------------------------------
  static Future<bool> estConnecte() async {
    final token = await _storage.read(key: _cleToken);
    return token != null;
  }
    // ----------------------------------------------------------
  // MOT DE PASSE OUBLIÉ — ÉTAPE 1 : demander l'envoi du code
  // appelle POST /api/forgot-password
  // ----------------------------------------------------------
  static Future<ResultatAuth> demanderCodeReinitialisation({
    required String email,
  }) async {
    try {
      final reponse = await http.post(
        Uri.parse("$_urlBase/forgot-password"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"email": email}),
      );

      final donnees = jsonDecode(reponse.body);

      return ResultatAuth(
        succes: reponse.statusCode == 200,
        message: donnees["message"] ?? "Une erreur est survenue.",
      );
    } catch (e) {
      return ResultatAuth(
        succes: false,
        message: "Impossible de contacter le serveur. Vérifiez votre connexion.",
      );
    }
  }

  // ----------------------------------------------------------
  // MOT DE PASSE OUBLIÉ — ÉTAPE 2 : vérifier le code à 6 chiffres
  // appelle POST /api/verify-reset-code
  // ----------------------------------------------------------
  static Future<ResultatAuth> verifierCodeReinitialisation({
    required String email,
    required String code,
  }) async {
    try {
      final reponse = await http.post(
        Uri.parse("$_urlBase/verify-reset-code"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"email": email, "code": code}),
      );

      final donnees = jsonDecode(reponse.body);

      return ResultatAuth(
        succes: reponse.statusCode == 200,
        message: donnees["message"] ?? "Code invalide.",
      );
    } catch (e) {
      return ResultatAuth(
        succes: false,
        message: "Impossible de contacter le serveur. Vérifiez votre connexion.",
      );
    }
  }

  // ----------------------------------------------------------
  // MOT DE PASSE OUBLIÉ — ÉTAPE 3 : définir le nouveau mot de passe
  // appelle POST /api/reset-password
  // ----------------------------------------------------------
  static Future<ResultatAuth> reinitialiserMotDePasse({
    required String email,
    required String code,
    required String nouveauMotDePasse,
    required String confirmationMotDePasse,
  }) async {
    try {
      final reponse = await http.post(
        Uri.parse("$_urlBase/reset-password"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "email": email,
          "code": code,
          "password": nouveauMotDePasse,
          "password_confirmation": confirmationMotDePasse,
        }),
      );

      final donnees = jsonDecode(reponse.body);

      if (reponse.statusCode == 422 && donnees["errors"] != null) {
        final premiereErreur = (donnees["errors"] as Map).values.first[0];
        return ResultatAuth(succes: false, message: premiereErreur);
      }

      return ResultatAuth(
        succes: reponse.statusCode == 200,
        message: donnees["message"] ?? "Une erreur est survenue.",
      );
    } catch (e) {
      return ResultatAuth(
        succes: false,
        message: "Impossible de contacter le serveur. Vérifiez votre connexion.",
      );
    }
  }
}
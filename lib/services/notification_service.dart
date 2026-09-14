import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ------------------------------------------------------------
// Doit correspondre exactement à _urlBase dans auth_service.dart
// ------------------------------------------------------------
const String _urlBase = "http://192.168.212.56:8000/api";

// Doit correspondre exactement à _storage / _cleToken dans auth_service.dart
final _storage = FlutterSecureStorage();
const String _cleToken = "auth_token";

// Handler pour les notifications reçues quand l'app est totalement fermée
// (doit être une fonction top-level ou statique)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Notification reçue en arrière-plan: ${message.messageId}');
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Demander la permission (obligatoire sur iOS et Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('Permission notifications refusée par l\'utilisateur');
      return;
    }

    // 2. Configurer l'affichage local (nécessaire pour le premier plan)
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(initSettings);

    // Créer un channel Android (obligatoire sur Android 8+)
    const channel = AndroidNotificationChannel(
      'verification_alerts', // id
      'Résultats de vérification', // nom visible
      description: 'Notifications de résultat de vérification de diplôme',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Récupérer le token FCM et l'envoyer au backend Laravel
    //    (seulement si l'utilisateur est déjà connecté, sinon inutile)
    String? tokenFcm = await _fcm.getToken();
    if (tokenFcm != null) {
      await sendTokenToBackend(tokenFcm);
    }
    // Le token peut changer (réinstall, changement d'appareil...)
    _fcm.onTokenRefresh.listen(sendTokenToBackend);

    // 4. ÉTAT 1 : app au premier plan (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // 5. ÉTAT 2 : app en arrière-plan, l'utilisateur tape sur la notif
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });

    // 6. ÉTAT 3 : app était complètement fermée, ouverte via la notif
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  // À appeler juste après un login réussi.
  // Contrairement à init(), ne redemande pas la permission et ne
  // rajoute pas de listeners (evite les notifications dupliquées) :
  // se contente de récupérer le token FCM actuel et de le renvoyer
  // au backend, maintenant que l'authToken est disponible.
  Future<void> renvoyerToken() async {
    String? tokenFcm = await _fcm.getToken();
    if (tokenFcm != null) {
      await sendTokenToBackend(tokenFcm);
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Certifio',
      message.notification?.body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'verification_alerts',
          'Résultats de vérification',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Exemple : rediriger vers l'écran de détail de la vérification
    final verificationId = message.data['verification_id'];
    print('Notification tapée, vérification: $verificationId');
    // Navigator.pushNamed(context, '/historique', arguments: verificationId);
  }

  Future<void> sendTokenToBackend(String tokenFcm) async {
    try {
      // On récupère le token d'authentification stocké au login
      // (exactement comme dans auth_service.dart)
      final authToken = await _storage.read(key: _cleToken);

      if (authToken == null) {
        // Utilisateur pas encore connecté : on ne peut pas encore
        // associer ce token FCM à un compte. Ce n'est pas grave,
        // on réessaiera après le login (voir note plus bas).
        print('Pas de session active, token FCM non envoyé pour le moment.');
        return;
      }

      final reponse = await http.post(
        Uri.parse("$_urlBase/fcm-token"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $authToken",
        },
        body: jsonEncode({'fcm_token': tokenFcm}),
      );

      if (reponse.statusCode == 200) {
        print('Token FCM envoyé au serveur avec succès.');
      } else {
        print('Échec envoi token FCM : ${reponse.statusCode} ${reponse.body}');
      }
    } catch (e) {
      print('Erreur réseau lors de l\'envoi du token FCM : $e');
    }
  }
}
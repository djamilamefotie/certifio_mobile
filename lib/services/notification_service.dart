import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ------------------------------------------------------------
// Doit correspondre exactement à _urlBase dans auth_service.dart
// ------------------------------------------------------------
const String _urlBase = "http://192.168.11.56:8000/api";

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
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('Permission notifications refusée par l\'utilisateur');
      return;
    }

    const androidSettings = AndroidInitializationSettings('notification_icon');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(initSettings);

    const channel = AndroidNotificationChannel(
      'verification_alerts',
      'Résultats de vérification',
      description: 'Notifications de résultat de vérification de diplôme',
      importance: Importance.high,
    );

    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);

    String? tokenFcm = await _fcm.getToken();
    if (tokenFcm != null) {
      await sendTokenToBackend(tokenFcm);
    }
    _fcm.onTokenRefresh.listen(sendTokenToBackend);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });

    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

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
    final verificationId = message.data['verification_id'];
    print('Notification tapée, vérification: $verificationId');
  }

  Future<void> sendTokenToBackend(String tokenFcm) async {
    try {
      final authToken = await _storage.read(key: _cleToken);

      if (authToken == null) {
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
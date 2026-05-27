import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:revive_eco_tech_app/pickup_details_page.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // 🔒 Guards against duplicate initialization and permission requests
  bool _isInitializing = false;
  bool _listenersInitialized = false;

  Future<void> initNotifications(BuildContext context) async {
    if (_isInitializing) return; // Prevent concurrent calls
    _isInitializing = true;

    try {
      NotificationSettings settings =
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus ==
          AuthorizationStatus.authorized) {
        print('User granted permission');

        await _saveDeviceToken();
        await _initLocalNotifications(context);

        // ✅ Attach listeners only once
        if (!_listenersInitialized) {
          _listenersInitialized = true;

          // Foreground messages
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
            _showForegroundNotification(message);
          });

          // Background tap
          FirebaseMessaging.onMessageOpenedApp
              .listen((RemoteMessage message) {
            _handleMessageNavigation(context, message);
          });

          // Terminated launch
          RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
          if (initialMessage != null) {
            _handleMessageNavigation(context, initialMessage);
          }
        }
      }
    } finally {
      _isInitializing = false;
    }
  }

  void _handleMessageNavigation(
      BuildContext context, RemoteMessage message) {
    if (message.data.containsKey('pickupId')) {
      String pickupId = message.data['pickupId'];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PickupDetailsPage(pickupId: pickupId),
        ),
      );
    }
  }

  Future<void> _saveDeviceToken() async {
    String? token = await _firebaseMessaging.getToken();
    User? user = FirebaseAuth.instance.currentUser;

    if (token != null && user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'fcmToken': token,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _initLocalNotifications(BuildContext context) async {
    // ✅ Use the monochrome silhouette name (no prefix required)
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('ic_stat_volunteer_activism');

    const InitializationSettings initSettings =
    InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse response) {
        if (response.payload != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PickupDetailsPage(
                pickupId: response.payload!,
              ),
            ),
          );
        }
      },
    );
  }

  Future<void> _showForegroundNotification(
      RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      String? payload = message.data['pickupId'];

      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
            color: Color(0xFF013856),
            icon: 'ic_stat_volunteer_activism',
          ),
        ),
        payload: payload,
      );
    }
  }
}

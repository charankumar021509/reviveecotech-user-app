import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:revive_eco_tech_app/pickup_details_page.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Prevent duplicate initialization
  bool _isInitializing = false;
  bool _listenersInitialized = false;

  // ============================================================
  // INITIALIZE NOTIFICATIONS
  // ============================================================

  Future<void> initNotifications(
    BuildContext context,
  ) async {
    if (_isInitializing) return;

    _isInitializing = true;

    try {
      final NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus !=
          AuthorizationStatus.authorized) {
        debugPrint(
          'Notification permission not granted',
        );
        return;
      }

      debugPrint(
        'User granted notification permission',
      );

      await _saveDeviceToken();

      await _initLocalNotifications(context);

      // Attach listeners only once
      if (_listenersInitialized) {
        return;
      }

      _listenersInitialized = true;

      // ========================================================
      // FOREGROUND MESSAGE
      // ========================================================

      FirebaseMessaging.onMessage.listen(
        (RemoteMessage message) {
          debugPrint(
            'Foreground FCM received',
          );

          debugPrint(
            'FCM data: ${message.data}',
          );

          // Estimate notification
          if (message.data['type'] ==
              'estimate') {
            _showEstimatePopup(
              context,
              message,
            );
          } else {
            // Normal notification
            _showForegroundNotification(
              message,
            );
          }
        },
      );

      // ========================================================
      // BACKGROUND NOTIFICATION TAP
      // ========================================================

      FirebaseMessaging.onMessageOpenedApp.listen(
        (RemoteMessage message) {
          _handleMessageNavigation(
            context,
            message,
          );
        },
      );

      // ========================================================
      // APP OPENED FROM TERMINATED STATE
      // ========================================================

      final RemoteMessage? initialMessage =
          await _firebaseMessaging
              .getInitialMessage();

      if (initialMessage != null) {
        _handleMessageNavigation(
          context,
          initialMessage,
        );
      }
    } catch (e) {
      debugPrint(
        'Notification initialization error: $e',
      );
    } finally {
      _isInitializing = false;
    }
  }

  // ============================================================
  // SAVE FCM TOKEN
  // ============================================================

  Future<void> _saveDeviceToken() async {
    try {
      final String? token =
          await _firebaseMessaging.getToken();

      final User? user =
          FirebaseAuth.instance.currentUser;

      if (token == null || user == null) {
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'fcmToken': token,
          'lastActive':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      debugPrint(
        'FCM token saved successfully',
      );
    } catch (e) {
      debugPrint(
        'FCM token error: $e',
      );
    }
  }

  // ============================================================
  // LOCAL NOTIFICATION INITIALIZATION
  // ============================================================

  Future<void> _initLocalNotifications(
    BuildContext context,
  ) async {
    const AndroidInitializationSettings
        androidSettings =
        AndroidInitializationSettings(
      'ic_stat_volunteer_activism',
    );

    const InitializationSettings
        initSettings =
        InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse response) {
        final String? payload =
            response.payload;

        if (payload == null ||
            payload.isEmpty) {
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PickupDetailsPage(
              pickupId: payload,
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // NORMAL FOREGROUND NOTIFICATION
  // ============================================================

  Future<void> _showForegroundNotification(
    RemoteMessage message,
  ) async {
    final RemoteNotification? notification =
        message.notification;

    final AndroidNotification? android =
        message.notification?.android;

    if (notification == null ||
        android == null) {
      return;
    }

    final String? payload =
        message.data['pickupId']?.toString();

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android:
            AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance:
              Importance.max,
          priority:
              Priority.high,
          color:
              Color(0xFF013856),
          icon:
              'ic_stat_volunteer_activism',
        ),
      ),
      payload: payload,
    );
  }

  // ============================================================
  // ESTIMATE TOP POPUP
  // ============================================================

  void _showEstimatePopup(
    BuildContext context,
    RemoteMessage message,
  ) {
    final String pickupId =
        message.data['pickupId']
                ?.toString() ??
            '';

    final double price =
        double.tryParse(
              message.data['finalPrice']
                      ?.toString() ??
                  '',
            ) ??
            0;

    if (pickupId.isEmpty) {
      debugPrint(
        'Estimate notification has no pickupId',
      );
      return;
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel:
          'Estimate Notification',
      barrierColor:
          Colors.transparent,
      transitionDuration:
          const Duration(
        milliseconds: 300,
      ),
      pageBuilder: (
        dialogContext,
        animation,
        secondaryAnimation,
      ) {
        return SafeArea(
          child: Align(
            alignment:
                Alignment.topCenter,
            child: Material(
              color:
                  Colors.transparent,
              child: Container(
                margin:
                    const EdgeInsets.fromLTRB(
                  12,
                  12,
                  12,
                  0,
                ),
                padding:
                    const EdgeInsets.all(
                  18,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(
                        0.20,
                      ),
                      blurRadius:
                          20,
                      offset:
                          const Offset(
                        0,
                        8,
                      ),
                    ),
                  ],
                ),
                child:
                    Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // HEADER
                    // ==================================================

                    Row(
                      children: [
                        Container(
                          padding:
                              const EdgeInsets
                                  .all(
                            8,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFF013D5A,
                            ),
                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),
                          ),
                          child:
                              const Icon(
                            Icons
                                .notifications_active,
                            color:
                                Colors.white,
                            size:
                                22,
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        const Expanded(
                          child:
                              Text(
                            'Waste Estimate Ready',
                            style:
                                TextStyle(
                              fontSize:
                                  18,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  Color(
                                0xFF013D5A,
                              ),
                            ),
                          ),
                        ),

                        IconButton(
                          onPressed:
                              () {
                            Navigator.pop(
                              dialogContext,
                            );
                          },
                          icon:
                              const Icon(
                            Icons.close,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // ==================================================
                    // DESCRIPTION
                    // ==================================================

                    const Text(
                      'Your final estimate is',
                      style:
                          TextStyle(
                        fontSize:
                            14,
                        color:
                            Colors.grey,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    // ==================================================
                    // PRICE
                    // ==================================================

                    Text(
                      '₹${price.toStringAsFixed(2)}',
                      style:
                          const TextStyle(
                        fontSize:
                            30,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(
                          0xFF013D5A,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    const Text(
                      'Please accept or decline this estimate.',
                      style:
                          TextStyle(
                        fontSize:
                            13,
                        color:
                            Colors.grey,
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    // ==================================================
                    // BUTTONS
                    // ==================================================

                    Row(
                      children: [
                        // DECLINE
                        Expanded(
                          child:
                              OutlinedButton(
                            onPressed:
                                () async {
                              Navigator.pop(
                                dialogContext,
                              );

                              await _declineEstimate(
                                context,
                                pickupId,
                              );
                            },
                            style:
                                OutlinedButton.styleFrom(
                              foregroundColor:
                                  Colors.red,
                              side:
                                  const BorderSide(
                                color:
                                    Colors.red,
                              ),
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                vertical:
                                    13,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  12,
                                ),
                              ),
                            ),
                            child:
                                const Text(
                              'Decline',
                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        // ACCEPT
                        Expanded(
                          child:
                              ElevatedButton(
                            onPressed:
                                () async {
                              Navigator.pop(
                                dialogContext,
                              );

                              await _acceptEstimate(
                                context,
                                pickupId,
                              );
                            },
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.green,
                              foregroundColor:
                                  Colors.white,
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                vertical:
                                    13,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  12,
                                ),
                              ),
                            ),
                            child:
                                const Text(
                              'Accept',
                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ACCEPT ESTIMATE
  // ============================================================

  Future<void> _acceptEstimate(
    BuildContext context,
    String pickupId,
  ) async {
    try {
      final DocumentReference pickupRef =
          FirebaseFirestore.instance
              .collection('pickups')
              .doc(pickupId);

      final DocumentSnapshot pickupDoc =
          await pickupRef.get();

      if (!pickupDoc.exists) {
        throw Exception(
          'Pickup order not found.',
        );
      }

      final Map<String, dynamic>? data =
          pickupDoc.data()
              as Map<String, dynamic>?;

      if (data == null) {
        throw Exception(
          'Pickup data not found.',
        );
      }

      final String? status =
          data['status']?.toString();

      if (status == 'Declined' ||
          status == 'Cancelled' ||
          status == 'Completed') {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                'This order is already closed.',
              ),
            ),
          );
        }

        return;
      }

      await pickupRef.update({
        'status': 'Confirmed',
        'estimateAccepted': true,
        'estimateAcceptedAt':
            FieldValue.serverTimestamp(),
        'estimateAcceptedBy': 'user',
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Estimate accepted successfully.',
            ),
            backgroundColor:
                Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'Accept estimate error: $e',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Unable to accept estimate: $e',
            ),
          ),
        );
      }
    }
  }

  // ============================================================
  // DECLINE ESTIMATE
  // ============================================================

  Future<void> _declineEstimate(
    BuildContext context,
    String pickupId,
  ) async {
    try {
      final DocumentReference pickupRef =
          FirebaseFirestore.instance
              .collection('pickups')
              .doc(pickupId);

      final DocumentSnapshot pickupDoc =
          await pickupRef.get();

      if (!pickupDoc.exists) {
        throw Exception(
          'Pickup order not found.',
        );
      }

      final Map<String, dynamic>? data =
          pickupDoc.data()
              as Map<String, dynamic>?;

      if (data == null) {
        throw Exception(
          'Pickup data not found.',
        );
      }

      final String? status =
          data['status']?.toString();

      if (status == 'Completed' ||
          status == 'Cancelled') {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                'This order is already closed.',
              ),
            ),
          );
        }

        return;
      }

      await pickupRef.update({
        'status': 'Declined',
        'estimateAccepted': false,
        'declinedAt':
            FieldValue.serverTimestamp(),
        'declinedBy': 'user',
        'declineReason':
            'User declined estimate',
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Estimate declined. Order cancelled.',
            ),
            backgroundColor:
                Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'Decline estimate error: $e',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Unable to decline estimate: $e',
            ),
          ),
        );
      }
    }
  }

  // ============================================================
  // HANDLE BACKGROUND / TERMINATED NOTIFICATION
  // ============================================================

  void _handleMessageNavigation(
    BuildContext context,
    RemoteMessage message,
  ) {
    final String? pickupId =
        message.data['pickupId']
            ?.toString();

    if (pickupId == null ||
        pickupId.isEmpty) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PickupDetailsPage(
          pickupId: pickupId,
        ),
      ),
    );
  }
}
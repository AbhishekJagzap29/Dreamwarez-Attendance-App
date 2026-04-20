// import 'package:onesignal_flutter/onesignal_flutter.dart';
// import 'package:flutter/material.dart';

// class OneSignalService {
//   final BuildContext? context;

//   OneSignalService({this.context});

//   Future<void> initOneSignal(String? userId) async {
//     try {
//       OneSignal.shared.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);
//       OneSignal.shared.setAppId('6e07cf60-4789-426c-afa8-d0354f53f974');

//       OneSignal.shared.setLocationShared(false);

//       bool accepted = await OneSignal.shared
//           .promptUserForPushNotificationPermission(fallbackToSettings: true);
//       debugPrint('🔔 Push permission accepted: $accepted');

//       if (!accepted && context != null) {
//         showDialog(
//           context: context!,
//           builder: (context) => AlertDialog(
//             title: const Text('Enable Push Notifications'),
//             content: const Text(
//                 'Push notifications are required for task updates. Please enable them in settings.'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   OneSignal.shared.promptUserForPushNotificationPermission(
//                       fallbackToSettings: true);
//                 },
//                 child: const Text('Open Settings'),
//               ),
//             ],
//           ),
//         );
//       }

//       if (userId != null) {
//         await OneSignal.shared.setExternalUserId(userId);
//         debugPrint('Set external user ID: $userId');
//       }

//       // Foreground notification handler
//       OneSignal.shared.setNotificationWillShowInForegroundHandler(
//           (OSNotificationReceivedEvent event) {
//         event.complete(event.notification);
//         debugPrint(
//             '📩 Notification in foreground: ${event.notification.jsonRepresentation()}');
//       });

//       OneSignal.shared
//           .setNotificationOpenedHandler((OSNotificationOpenedResult result) {
//         debugPrint(
//             '📬 Notification opened: ${result.notification.jsonRepresentation()}');
//         final data = result.notification.additionalData;
//         if (data != null && data.containsKey('task_id') && context != null) {
//           debugPrint('📌 Task ID from notification: ${data['task_id']}');
//         }
//       });
//     } catch (e) {
//       debugPrint('🚫 Error initializing OneSignal: $e');
//     }
//   }
// }

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class OneSignalService {
  final BuildContext? context;

  OneSignalService({this.context});

  Future<void> initOneSignal(String? userId) async {
    try {
      OneSignal.shared.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);
      OneSignal.shared.setAppId('6e07cf60-4789-426c-afa8-d0354f53f974');

      OneSignal.shared.setLocationShared(false);

      bool accepted = await OneSignal.shared
          .promptUserForPushNotificationPermission(fallbackToSettings: true);
      debugPrint('🔔 Push permission accepted: $accepted');

      if (!accepted && context != null) {
        showDialog(
          context: context!,
          builder: (context) => AlertDialog(
            title: const Text('Enable Push Notifications'),
            content: const Text(
                'Push notifications are required for task updates. Please enable them in settings.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  OneSignal.shared.promptUserForPushNotificationPermission(
                      fallbackToSettings: true);
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }

      if (userId != null) {
        await OneSignal.shared.setExternalUserId(userId);
        debugPrint('Set external user ID: $userId');
      }

      // Foreground notification handler with Flushbar
      OneSignal.shared.setNotificationWillShowInForegroundHandler(
          (OSNotificationReceivedEvent event) {
        if (context != null) {
          _showFlushbarNotification(event.notification);
        }
        event.complete(event.notification);
        debugPrint(
            '📩 Notification in foreground: ${event.notification.jsonRepresentation()}');
      });

      OneSignal.shared
          .setNotificationOpenedHandler((OSNotificationOpenedResult result) {
        debugPrint(
            '📬 Notification opened: ${result.notification.jsonRepresentation()}');
        final data = result.notification.additionalData;
        if (data != null && data.containsKey('task_id') && context != null) {
          debugPrint('📌 Task ID from notification: ${data['task_id']}');
          Navigator.pushNamed(context!, '/task_details',
              arguments: data['task_id']);
        }
      });
    } catch (e) {
      debugPrint('🚫 Error initializing OneSignal: $e');
    }
  }

  // Show Flushbar notification for foreground notifications
  void _showFlushbarNotification(OSNotification notification) {
    if (context == null) {
      debugPrint('Cannot show Flushbar: BuildContext is null');
      return;
    }

    final title = notification.title ?? 'New Notification';
    final message = notification.body ?? 'You have a new message';
    final additionalData = notification.additionalData;

    Flushbar(
      title: title,
      message: message,
      duration: const Duration(seconds: 5),
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      backgroundColor: const Color(0xFF075E54), // WhatsApp-like green color
      flushbarPosition: FlushbarPosition.TOP,
      flushbarStyle: FlushbarStyle.FLOATING,
      icon: const Icon(
        Icons.notifications_active,
        color: Colors.white,
      ),
      leftBarIndicatorColor: Colors.white,
      boxShadows: const [
        BoxShadow(
          color: Colors.black26,
          offset: Offset(0, 2),
          blurRadius: 3,
        ),
      ],
      onTap: (flushbar) {
        if (additionalData != null && additionalData.containsKey('task_id')) {
          debugPrint(
              'Tapped notification with task_id: ${additionalData['task_id']}');
          Navigator.pushNamed(context!, '/task_details',
              arguments: additionalData['task_id']);
        }
      },
    ).show(context!);
  }
}

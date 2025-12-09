
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../data/models/product_model.dart';

class NotificationService {
  final fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      fln.FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    const fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    const fln.InitializationSettings initializationSettings = fln.InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const fln.NotificationDetails(
        android: fln.AndroidNotificationDetails(
          'expiry_channel',
          'Expiry Notifications',
          channelDescription: 'Notifications for expiring products',
          importance: fln.Importance.max,
          priority: fln.Priority.high,
        ),
      ),
      androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
      // uiLocalNotificationDateInterpretation:
      //     fln.UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> scheduleExpiryNotifications(ProductModel product) async {
    final expiry = product.expiryDate;
    final idBase = product.id.hashCode;

    await scheduleNotification(
      id: idBase + 7,
      title: 'Expiring in 7 days',
      body: '${product.name} is expiring on ${expiry.toLocal().toString().split(' ')[0]}',
      scheduledDate: expiry.subtract(const Duration(days: 7)),
    );

    await scheduleNotification(
      id: idBase + 3,
      title: 'Expiring in 3 days',
      body: '${product.name} is expiring soon!',
      scheduledDate: expiry.subtract(const Duration(days: 3)),
    );

    await scheduleNotification(
      id: idBase + 1,
      title: 'Expiring Tomorrow',
      body: 'Consume ${product.name} before it expires!',
      scheduledDate: expiry.subtract(const Duration(days: 1)),
    );

    await scheduleNotification(
      id: idBase,
      title: 'Expired Today',
      body: '${product.name} expires today!',
      scheduledDate: expiry,
    );
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

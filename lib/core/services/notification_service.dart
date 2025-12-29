
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../data/models/product_model.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialize Timezone (with error handling so it doesn't block app)
    try {
      tz.initializeTimeZones();
      // Use dynamic because return type might be String or TimezoneInfo depending on version/platform
      final dynamic localTimezoneResult = await FlutterTimezone.getLocalTimezone();
      
      String locationName;
      if (localTimezoneResult is String) {
        locationName = localTimezoneResult;
      } else {
        // Fallback for TimezoneInfo object: Try to extract ID from toString()
        // Format seen: "TimezoneInfo(Asia/Calcutta, ...)"
        String raw = localTimezoneResult.toString();
        print("DEBUG: Raw Timezone Object: $raw");
        if (raw.startsWith('TimezoneInfo(')) {
          locationName = raw.split('(')[1].split(',')[0].trim();
        } else {
          locationName = raw;
        }
      }
      
      print("DEBUG: Extracted Timezone ID: '$locationName'");

      // Try setting location
      try {
        tz.setLocalLocation(tz.getLocation(locationName));
        print("DEBUG: Local timezone set to $locationName");
      } catch (e) {
        print("DEBUG: TZ set error '$e'. Fallback logic...");
        if (locationName.contains('Asia/Calcutta') || locationName.contains('India')) {
           try {
             tz.setLocalLocation(tz.getLocation('Asia/Kolkata')); 
             print("DEBUG: Set to Asia/Kolkata alias");
           } catch (_) {
             tz.setLocalLocation(tz.UTC);
           }
        } else {
           tz.setLocalLocation(tz.UTC);
        }
      }
    } catch (e) {
      print("DEBUG: Critical Timezone Init Failure: $e");
      // Fallback
      try {
        tz.setLocalLocation(tz.UTC);
      } catch (_) {}
    }

    // Initialize Notifications Plugin (MUST RUN)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );
    print("DEBUG: Notification Plugin Initialized.");
  }

  Future<void> requestPermissions() async {
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
    
    final iosImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        
    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final now = DateTime.now();
    final diff = scheduledDate.difference(now);

    // If scheduled for the past or very near future (< 1 minute), show immediately/directly
    if (diff.inSeconds < 60) {
       print("DEBUG: Scheduled time is effectively NOW (${diff.inSeconds}s diff). Using direct show().");
       try {
         await flutterLocalNotificationsPlugin.show(
            id,
            title,
            body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'expiry_channel',
                'Expiry Notifications',
                channelDescription: 'Notifications for expiring products',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
         );
         print("DEBUG: Direct show() command sent for ID $id");
         return; 
       } catch (e) {
         print("DEBUG: Error in direct show(): $e");
       }
    }

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'expiry_channel',
            'Expiry Notifications',
            channelDescription: 'Notifications for expiring products',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      // Fallback to inexact if exact permission is denied
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'expiry_channel',
            'Expiry Notifications',
            channelDescription: 'Notifications for expiring products',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        // uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> scheduleExpiryNotifications(ProductModel product) async {
    print("DEBUG: scheduleExpiryNotifications called for ${product.name}");
    final expiry = product.expiryDate;
    final idBase = product.id.hashCode;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDateOnly = DateTime(expiry.year, expiry.month, expiry.day);
    
    final diff = expiryDateOnly.difference(today).inDays;
    print("DEBUG: Expiry: $expiryDateOnly, Today: $today, Diff: $diff");

    // Helper to set time to 8:00 AM
    DateTime set8AM(DateTime date) {
      return DateTime(date.year, date.month, date.day, 8, 0, 0);
    }

    // 7 Days Before
    DateTime date7Days = set8AM(expiry.subtract(const Duration(days: 7)));
    if (date7Days.isAfter(now)) {
      print("DEBUG: Scheduling 7-day alert...");
      await scheduleNotification(
        id: idBase + 7,
        title: 'Expiring in 7 days',
        body: '${product.name} is expiring on ${expiry.toLocal().toString().split(' ')[0]}',
        scheduledDate: date7Days,
      );
    } else {
      print("DEBUG: Skipping 7-day alert (Time passed: $date7Days)");
    }

    // 3 Days Before
    DateTime date3Days = set8AM(expiry.subtract(const Duration(days: 3)));
    if (date3Days.isAfter(now)) {
      print("DEBUG: Scheduling 3-day alert...");
      await scheduleNotification(
        id: idBase + 3,
        title: 'Expiring in 3 days',
        body: '${product.name} is expiring soon!',
        scheduledDate: date3Days,
      );
    } else {
      print("DEBUG: Skipping 3-day alert (Time passed: $date3Days)");
    }

    // Expiring Tomorrow (1 Day Before)
    DateTime scheduledTomorrow = set8AM(expiry.subtract(const Duration(days: 1)));
    
    // Catch-up logic for Tomorrow alert
    if (diff == 1) {
       print("DEBUG: Product expires Tomorrow. Scheduling immediate alert (5s delay).");
       scheduledTomorrow = DateTime.now().add(const Duration(seconds: 5));
    }
    
    // Only schedule if future (or made future by catch-up)
    if (scheduledTomorrow.isAfter(now)) {
       print("DEBUG: Scheduling Tomorrow alert for $scheduledTomorrow");
       await scheduleNotification(
        id: idBase + 1,
        title: 'Expiring Tomorrow',
        body: 'Consume ${product.name} before it expires!',
        scheduledDate: scheduledTomorrow,
      );
    }

    // Expired Today
    DateTime scheduledToday = set8AM(expiry);
    
    // Catch-up logic for Today alert
    if (diff == 0) {
       print("DEBUG: Product expires Today. Scheduling immediate alert (5s delay).");
       scheduledToday = DateTime.now().add(const Duration(seconds: 5));
    }

    // Only schedule if future (or made future by catch-up)
    if (scheduledToday.isAfter(now)) {
       print("DEBUG: Scheduling Today alert for $scheduledToday");
       await scheduleNotification(
        id: idBase,
        title: 'Expired Today',
        body: '${product.name} expires today!',
        scheduledDate: scheduledToday,
      );
    }
    
    print("DEBUG: All schedules requested for ${product.name}");
  }

  Future<void> scheduleTestNotification() async {
    await scheduleNotification(
      id: 99999,
      title: 'Test Notification',
      body: 'This is a test notification to verify offline mode.',
      scheduledDate: DateTime.now().add(const Duration(seconds: 10)),
    );
  }

  Future<void> showImmediateNotification() async {
    print("DEBUG: Showing immediate notification...");
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // Explicitly create channel to be sure
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            'expiry_channel',
            'Expiry Notifications',
            description: 'Notifications for expiring products',
            importance: Importance.max,
          ),
        );
        print("DEBUG: Channel created/verified.");
        
        // Check permission status
        final bool? granted = await androidImplementation.requestNotificationsPermission();
        print("DEBUG: Permission status: $granted");
      }

      await flutterLocalNotificationsPlugin.show(
        88888,
        'Immediate Test',
        'This notification is sent immediately. If you see this, permissions are working.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'expiry_channel',
            'Expiry Notifications',
            channelDescription: 'Notifications for expiring products',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
      print("DEBUG: Immediate notification command sent.");
    } catch (e) {
      print("DEBUG: Error showing immediate notification: $e");
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

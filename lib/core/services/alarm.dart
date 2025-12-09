import 'dart:io';
import 'package:flutter/services.dart';

const MethodChannel _alarmChannel = MethodChannel('exact_alarm');

Future<void> requestExactAlarmPermission() async {
  if (!Platform.isAndroid) return;

  try {
    final bool isAllowed =
        await _alarmChannel.invokeMethod('isExactAlarmAllowed');

    if (!isAllowed) {
      // Ask only if not allowed
      await _alarmChannel.invokeMethod('requestExactAlarmPermission');
    }
  } catch (e) {
    print("Exact alarm permission error: $e");
  }
}

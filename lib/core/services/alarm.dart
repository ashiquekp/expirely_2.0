import 'dart:io';
import 'package:flutter/services.dart';

Future<void> requestExactAlarmPermission() async {
  if (Platform.isAndroid) {
    const channel = MethodChannel('exact_alarm');

    try {
      await channel.invokeMethod('requestExactAlarmPermission');
    } catch (e) {
      print("Exact alarm permission error: $e");
    }
  }
}
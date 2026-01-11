
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/product_provider.dart';
import '../../core/services/notification_service.dart';
import '../widgets/stats_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Request permissions after the first frame to ensure smooth UI capability
    WidgetsBinding.instance.addPostFrameCallback((_) async {
       await ref.read(notificationServiceProvider).requestPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productListProvider);

    final totalItems = products.length;
    final expiredItems = products.where((p) => p.daysRemaining < 0).length;
    // Expiring within 7 days
    final expiringSoon = products.where((p) => p.daysRemaining >= 0 && p.daysRemaining <= 7).length;
    final freshItems = products.where((p) => p.daysRemaining > 7).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: 'Test Immediate Notification',
            onPressed: () async {
              await ref.read(notificationServiceProvider).showImmediateNotification();
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sent immediate notification'))
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Test Notification (10s)',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scheduling test notification in 10s... Close the app now!'))
              );
              await ref.read(notificationServiceProvider).scheduleTestNotification();
            },
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Debug Info',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  final ns = ref.read(notificationServiceProvider);
                  return AlertDialog(
                    title: const Text('Notification Debug'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Timezone: ${ns.getCurrentTimezone()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          const Text('Pending Requests:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const Divider(),
                          FutureBuilder( 
                            future: ns.getPendingNotifications(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              }
                              if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              }
                              final data = snapshot.data ?? [];
                              if (data.isEmpty) return const Text('No pending notifications');
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: data.map((n) {
                                  // n is PendingNotificationRequest
                                  String scheduledTime = "Unknown/Direct";
                                  if (n.payload != null) {
                                      final parsed = DateTime.tryParse(n.payload!);
                                      if (parsed != null) {
                                          scheduledTime = parsed.toString().split('.')[0];
                                      }
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text('[ID: ${n.id}] ${n.title}\nScheduled: $scheduledTime'),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                   StatsCard(
                    title: 'Total Items',
                    value: totalItems.toString(),
                    icon: PhosphorIconsRegular.package,
                    color: Colors.blue,
                  ),
                  StatsCard(
                    title: 'Expiring Soon',
                    value: expiringSoon.toString(),
                    icon: PhosphorIconsRegular.timer,
                    color: Colors.orange,
                  ),
                   StatsCard(
                    title: 'Expired',
                    value: expiredItems.toString(),
                    icon: PhosphorIconsRegular.warningCircle,
                    color: Colors.red,
                  ),
                   StatsCard(
                    title: 'Fresh',
                    value: freshItems.toString(),
                    icon: PhosphorIconsRegular.checkCircle,
                    color: Colors.green,
                  ),
                ],
              ),
            ),
            // Could add a list of "Expiring this week" below
          ],
        ),
      ),
    );
  }
}

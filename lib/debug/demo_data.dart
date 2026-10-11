import 'dart:math';

import '../models/app_model.dart';
import '../models/condition_model.dart';
import '../models/device_model.dart';
import '../models/notification_model.dart';
import '../models/topic_model.dart';
import '../services/app_storage_service.dart';
import '../services/notification_storage_service.dart';
import '../services/secure_storage_service.dart';

/// Debug-only sample data for screenshots and manual review. Only referenced
/// from `ScreenshotRouter`, which is never registered in release builds.
class DemoData {
  DemoData._();

  /// Fake, service-account-shaped credentials. Never a real key.
  static Map<String, dynamic> fakeServiceAccount(String projectId) => {
        'type': 'service_account',
        'project_id': projectId,
        'private_key_id': '3f9a1c5e7b2d4f60a8c1e9d3b5a7f204',
        'private_key': '-----BEGIN PRIVATE KEY-----\nDEMO\n-----END PRIVATE KEY-----\n',
        'client_email': 'firebase-adminsdk-fbsvc@$projectId.iam.gserviceaccount.com',
        'client_id': '104729385610293847561',
        'auth_uri': 'https://accounts.google.com/o/oauth2/auth',
        'token_uri': 'https://oauth2.googleapis.com/token',
        'universe_domain': 'googleapis.com',
      };

  static const _shop = 'demo_acme_shop';
  static const _staging = 'demo_acme_shop_staging';
  static const _dev = 'demo_acme_shop_dev';
  static const _pulse = 'demo_pulse_fitness';

  static const _projects = {
    _shop: 'acme-shop',
    _staging: 'acme-shop-staging',
    _dev: 'acme-shop-dev',
    _pulse: 'pulse-fitness',
  };

  static String _fcmToken(int seed) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_';
    final r = Random(seed);
    String part(int n) => List.generate(n, (_) => chars[r.nextInt(chars.length)]).join();
    return '${part(11)}:APA91b${part(134)}';
  }

  static List<TopicModel> _topics(String appId, DateTime now, List<String> names) => [
        for (final n in names)
          TopicModel(id: '${appId}_t_$n', name: n, createdAt: now.subtract(const Duration(days: 30))),
      ];

  static List<DeviceModel> _devices(String appId, DateTime now, List<String> names, int seed) => [
        for (var i = 0; i < names.length; i++)
          DeviceModel(
            id: '${appId}_d_$i',
            name: names[i],
            notificationToken: _fcmToken(seed + i),
            createdAt: now.subtract(Duration(days: 28 - i)),
          ),
      ];

  static ConditionModel _condition(String appId, DateTime now, String name, String op, List<String> topics) =>
      ConditionModel(
        id: '${appId}_c_${name.hashCode.abs()}',
        name: name,
        operator: op,
        topicIds: [for (final t in topics) '${appId}_t_$t'],
        createdAt: now.subtract(const Duration(days: 20)),
      );

  /// The apps used by the demo, built relative to [now].
  static List<AppModel> buildApps(DateTime now) {
    final allTopics = ['news', 'promotions', 'beta_testers', 'order_updates'];
    return [
      AppModel(
        id: _shop,
        name: 'Acme Shop',
        packageName: 'com.acme.shop',
        createdAt: now.subtract(const Duration(days: 40)),
        topics: _topics(_shop, now, allTopics),
        devices: _devices(_shop, now, ['Pixel 9 Pro', 'iPhone 17', 'QA Galaxy S25'], 100),
        conditions: [
          _condition(_shop, now, 'Promo beta testers', 'AND', ['promotions', 'beta_testers']),
          _condition(_shop, now, 'News or promotions', 'OR', ['news', 'promotions']),
        ],
      ),
      AppModel(
        id: _staging,
        name: 'Acme Shop Staging',
        packageName: 'com.acme.shop.staging',
        createdAt: now.subtract(const Duration(days: 38)),
        topics: _topics(_staging, now, allTopics),
        devices: _devices(_staging, now, ['Pixel 9 Pro', 'QA Galaxy S25'], 200),
        conditions: [_condition(_staging, now, 'Promo beta testers', 'AND', ['promotions', 'beta_testers'])],
      ),
      AppModel(
        id: _dev,
        name: 'Acme Shop Dev',
        packageName: 'com.acme.shop.dev',
        createdAt: now.subtract(const Duration(days: 35)),
        topics: _topics(_dev, now, ['news', 'beta_testers', 'order_updates']),
        devices: _devices(_dev, now, ['Pixel 9 Pro', 'iPhone 17'], 300),
        conditions: [_condition(_dev, now, 'News and beta', 'AND', ['news', 'beta_testers'])],
      ),
      AppModel(
        id: _pulse,
        name: 'Pulse Fitness',
        packageName: 'com.pulse.fitness',
        createdAt: now.subtract(const Duration(days: 21)),
        topics: _topics(_pulse, now, ['news', 'promotions', 'beta_testers']),
        devices: _devices(_pulse, now, ['iPhone 17', 'Pixel 9 Pro'], 400),
        conditions: [_condition(_pulse, now, 'Promo beta testers', 'AND', ['promotions', 'beta_testers'])],
      ),
    ];
  }

  /// Replaces saved apps, credentials and history with the demo set.
  static Future<void> seed() async {
    final now = DateTime.now();
    final appStorage = AppStorageService();
    final secure = SecureStorageService();
    final history = NotificationStorageService();

    for (final existing in await appStorage.getApps()) {
      await appStorage.deleteApp(existing.id);
    }
    await history.clearHistory();

    final apps = buildApps(now);
    for (final app in apps) {
      await appStorage.saveApp(app);
      await secure.saveAppCredentials(app.id, fakeServiceAccount(_projects[app.id]!));
    }
    final byId = {for (final a in apps) a.id: a};

    String ok(String project, int n) =>
        'projects/$project/messages/0:17123456789${10000 + n}%${n.toRadixString(16)}b3c9a1';

    NotificationModel n({
      required String id,
      required String appId,
      required Duration ago,
      required String nickname,
      required String title,
      required String body,
      Map<String, dynamic>? data,
      String? topic,
      String? condition,
      String? deviceName,
      bool success = true,
      String? error,
    }) {
      final app = byId[appId]!;
      final device = deviceName == null ? null : app.devices.firstWhere((d) => d.name == deviceName);
      return NotificationModel(
        id: id,
        app: app,
        title: title,
        body: body,
        data: data,
        topic: topic,
        condition: condition,
        token: device?.notificationToken,
        createdAt: now.subtract(ago),
        sent: success,
        nickname: nickname,
        resultCode: success ? '200' : '404',
        resultMessage: success ? ok(_projects[appId]!, int.parse(id)) : error,
      );
    }

    // Oldest first: saveNotification inserts at the top of the list.
    final items = [
      n(
        id: '1',
        appId: _pulse,
        ago: const Duration(days: 4, hours: 3),
        nickname: 'Weekly challenge',
        title: 'Weekly challenge starts now 🏃',
        body: 'Beat 40,000 steps this week and earn the Gold badge.',
        data: {'screen': 'challenges', 'challenge_id': 'wk-41'},
        topic: 'news',
      ),
      n(
        id: '2',
        appId: _staging,
        ago: const Duration(days: 3, hours: 6),
        nickname: 'Checkout test',
        title: 'Complete your purchase',
        body: 'You left 2 items in your cart. They are waiting for you.',
        data: {'screen': 'cart'},
        deviceName: 'QA Galaxy S25',
      ),
      n(
        id: '3',
        appId: _shop,
        ago: const Duration(days: 2, hours: 9),
        nickname: 'Flash sale',
        title: 'Flash sale: 30% off today',
        body: 'Only until midnight. Tap to shop the deals.',
        data: {'screen': 'sale', 'discount': '30'},
        condition: "'promotions' in topics && 'beta_testers' in topics",
      ),
      n(
        id: '4',
        appId: _dev,
        ago: const Duration(days: 2, hours: 2),
        nickname: 'Stale token check',
        title: 'Debug ping',
        body: 'Checking delivery to an old test device.',
        deviceName: 'iPhone 17',
        success: false,
        error: '404 UNREGISTERED: Requested entity was not found.',
      ),
      n(
        id: '5',
        appId: _pulse,
        ago: const Duration(days: 1, hours: 7),
        nickname: 'New plan',
        title: 'New workout plan ready',
        body: 'Your 4-week strength plan is ready. Let us get moving!',
        data: {'screen': 'plan', 'plan_id': 'str-4w'},
        deviceName: 'iPhone 17',
      ),
      n(
        id: '6',
        appId: _shop,
        ago: const Duration(days: 1, hours: 1),
        nickname: 'Back in stock',
        title: 'Back in stock: Trail Runner 2',
        body: 'The sneakers you saved are available again in your size.',
        data: {'product_id': 'SKU-88120', 'screen': 'product'},
        topic: 'news',
      ),
      n(
        id: '7',
        appId: _shop,
        ago: const Duration(hours: 5),
        nickname: 'Order delivered',
        title: 'Delivered to your door 🎉',
        body: 'Order #A-10288 was delivered. Enjoy!',
        data: {'order_id': 'A-10288', 'screen': 'order_detail'},
        deviceName: 'Pixel 9 Pro',
      ),
      n(
        id: '8',
        appId: _shop,
        ago: const Duration(minutes: 42),
        nickname: 'Order shipped',
        title: 'Your order has shipped 📦',
        body: 'Order #A-10293 is on its way and should arrive Thursday.',
        data: {'order_id': 'A-10293', 'screen': 'order_detail'},
        topic: 'order_updates',
      ),
    ];
    for (final item in items) {
      await history.saveNotification(item);
    }
  }

  static AppModel get shopApp => buildApps(DateTime.now()).first;

  /// Prefill for the Create Notification screen.
  static NotificationModel createPrefill({bool useCondition = false}) {
    final app = shopApp;
    return NotificationModel(
      id: 'demo_prefill',
      app: app,
      nickname: 'Order shipped',
      title: 'Your order has shipped 📦',
      body: 'Order #A-10293 is on its way and should arrive Thursday.',
      data: {'order_id': 'A-10293'},
      topic: useCondition ? null : 'order_updates',
      condition: useCondition ? "'promotions' in topics && 'beta_testers' in topics" : null,
      createdAt: DateTime.now(),
    );
  }
}

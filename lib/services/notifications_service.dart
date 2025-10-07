import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationsService {
  static final _fln = FlutterLocalNotificationsPlugin();
  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  static final List<Map<String, String>> _inbox = <Map<String, String>>[];

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _fln.initialize(const InitializationSettings(android: android));
  }

  static List<Map<String, String>> list() =>
      List<Map<String, String>>.from(_inbox.reversed);

  static Future<void> markAllRead() async {
    unreadCount.value = 0;
  }

  static Future<void> add(String title, String body) async {
    _inbox.add({
      'title': title,
      'body': body,
      'ts': DateTime.now().toIso8601String(),
    });
    unreadCount.value = unreadCount.value + 1;
    await _fln.show(
      title.hashCode ^ body.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'inbox',
          'Notificações',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> lowStock(String product, int qty) async {
    await add('Estoque baixo', '$product com apenas $qty unidade(s)');
  }

  static Future<void> fiadoDue(String clientName) async {
    await add('Lembrete de Fiado', 'Pagamento pendente: $clientName');
  }
}

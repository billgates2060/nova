import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsService {
  static final _fln = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _fln.initialize(const InitializationSettings(android: android));
  }

  static Future<void> lowStock(String product, int qty) async {
    await _fln.show(
      product.hashCode,
      'Estoque baixo',
      '$product com apenas $qty unidade(s)',
      const NotificationDetails(
        android: AndroidNotificationDetails('stock', 'Estoque', importance: Importance.high, priority: Priority.high),
      ),
    );
  }

  static Future<void> fiadoDue(String clientName) async {
    await _fln.show(
      clientName.hashCode,
      'Lembrete de Fiado',
      'Pagamento pendente: $clientName',
      const NotificationDetails(
        android: AndroidNotificationDetails('fiado', 'Fiado', importance: Importance.high, priority: Priority.high),
      ),
    );
  }
}



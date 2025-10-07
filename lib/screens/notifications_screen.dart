import 'package:flutter/material.dart';
import '../services/notifications_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = NotificationsService.list();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          TextButton(
            onPressed: () async {
              await NotificationsService.markAllRead();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              'Marcar lidas',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text('Sem notificações'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final n = items[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_active,
                        color: Colors.orange,
                      ),
                    ),
                    title: Text(n['title'] ?? ''),
                    subtitle: Text(n['body'] ?? ''),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await NotificationsService.add(
            'Teste de notificação',
            'Isto é um exemplo.',
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notificação enviada')),
            );
          }
        },
        icon: const Icon(Icons.send),
        label: const Text('Testar'),
      ),
    );
  }
}

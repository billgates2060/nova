import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _users = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final users = await AdminService.listUsers();
    setState(() {
      _users = users;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestão de Usuários')),
      floatingActionButton: FloatingActionButton(
        onPressed: _createUser,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _users.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final u = _users[i];
                  final id = u['id']?.toString() ?? '';
                  final name = u['name']?.toString() ?? '';
                  final email = u['email']?.toString() ?? '';
                  final role = u['role']?.toString() ?? 'user';
                  final storeId = (u['storeId'] ?? u['store_id'] ?? '').toString();
                  final storeName = (u['storeName'] ?? u['store_name'] ?? '').toString();

                  return ListTile(
                    leading: CircleAvatar(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?')),
                    title: Text('$name ($role)'),
                    subtitle: Text('$email\n$storeName • $storeId'),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'block') {
                          await AdminService.blockUser(id);
                          await _load();
                        } else if (v == 'unblock') {
                          await AdminService.unblockUser(id);
                          await _load();
                        } else if (v == 'make_admin') {
                          await AdminService.updateUser(id, role: 'admin');
                          await _load();
                        } else if (v == 'make_user') {
                          await AdminService.updateUser(id, role: 'user');
                          await _load();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'block', child: Text('Bloquear')),
                        PopupMenuItem(value: 'unblock', child: Text('Desbloquear')),
                        PopupMenuItem(value: 'make_admin', child: Text('Tornar Admin')),
                        PopupMenuItem(value: 'make_user', child: Text('Tornar Lojista')),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Future<void> _createUser() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String role = 'user';
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Criar conta (cada usuário é uma loja)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: 'Nome'), controller: nameCtrl),
            TextField(decoration: const InputDecoration(labelText: 'Email'), controller: emailCtrl),
            TextField(decoration: const InputDecoration(labelText: 'Senha'), controller: passCtrl, obscureText: true),
            DropdownButtonFormField<String>(
              value: role,
              decoration: const InputDecoration(labelText: 'Perfil'),
              items: const [
                DropdownMenuItem(value: 'user', child: Text('Lojista')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (v) => role = v ?? 'user',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              try {
                final created = await AdminService.createStoreUser(
                  storeId: '',
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  password: passCtrl.text,
                  role: role,
                );
                if (created.isNotEmpty) {
                  if (context.mounted) Navigator.pop(ctx);
                  await _load();
                }
              } catch (_) {}
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../services/hive_service.dart';
import '../../models/user_profile.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  Box? _usersBox;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _usersBox = await HiveService.openGlobalUsersBox();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final users = _usersBox!.values.cast<UserProfile>().toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Gestão de Contas')),
      floatingActionButton: FloatingActionButton(
        onPressed: _createUserDialog,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (_, i) {
          final u = users[i];
          return ListTile(
            title: Text('${u.name} (${u.role})'),
            subtitle: Text('${u.email} • Loja: ${u.storeId}'),
            trailing: PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'edit') {
                  _editUserDialog(u);
                } else if (v == 'delete') {
                  await u.delete();
                  setState(() {});
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'delete', child: Text('Excluir')),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _createUserDialog() async {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final storeCtrl = TextEditingController();
    String role = 'user';
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo Usuário'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: storeCtrl,
              decoration: const InputDecoration(labelText: 'ID da Loja (UUID)'),
            ),
            DropdownButtonFormField<String>(
              value: role,
              items: const [
                DropdownMenuItem(value: 'user', child: Text('Lojista')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (v) => role = v ?? 'user',
              decoration: const InputDecoration(labelText: 'Perfil'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final u = UserProfile(
                uid: DateTime.now().millisecondsSinceEpoch.toString(),
                email: emailCtrl.text.trim(),
                name: nameCtrl.text.trim(),
                role: role,
                storeId: storeCtrl.text.trim(),
              );
              await _usersBox!.put(u.uid, u);
              if (mounted) setState(() {});
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _editUserDialog(UserProfile user) async {
    final emailCtrl = TextEditingController(text: user.email);
    final nameCtrl = TextEditingController(text: user.name);
    final storeCtrl = TextEditingController(text: user.storeId);
    String role = user.role;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Usuário'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: storeCtrl,
              decoration: const InputDecoration(labelText: 'ID da Loja (UUID)'),
            ),
            DropdownButtonFormField<String>(
              value: role,
              items: const [
                DropdownMenuItem(value: 'user', child: Text('Lojista')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (v) => role = v ?? 'user',
              decoration: const InputDecoration(labelText: 'Perfil'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              user
                ..email = emailCtrl.text.trim()
                ..name = nameCtrl.text.trim()
                ..role = role
                ..storeId = storeCtrl.text.trim();
              await user.save();
              if (mounted) setState(() {});
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/admin_service.dart';
import 'admin_create_user_screen.dart';
import '../services/auth_service.dart';
import '../services/currency.dart';

class AdminUsersScreen extends StatefulWidget {
  final StoreInfo? selectedStore;

  const AdminUsersScreen({super.key, this.selectedStore});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _loading = true;
  List<dynamic> _users = [];
  Map<String, dynamic>? _stats;

  // Inline creation form removed; creation moved to AdminCreateUserScreen

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
    });
    try {
      if (widget.selectedStore != null) {
        final storeId = widget.selectedStore!.storeId;
        final users = await AdminService.getStoreUsers(storeId);
        final storeStats = await AdminService.getStoreStats(storeId);
        setState(() {
          _users = users;
          _stats = {
            'users': storeStats.users,
            'activeUsers': storeStats.activeUsers,
            'salesCount': storeStats.salesCount,
            'revenue': storeStats.revenue,
          };
          _loading = false;
        });
      } else {
        final usersResp = await ApiClient.get('/users', auth: true);
        final statsResp = await ApiClient.get('/admin/stats', auth: true);
        setState(() {
          _users = jsonDecode(usersResp.body) as List<dynamic>;
          _stats = jsonDecode(statsResp.body) as Map<String, dynamic>;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
      }
    }
  }

  Future<void> _goToCreateUser() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            AdminCreateUserScreen(selectedStore: widget.selectedStore),
      ),
    );
    if (created == true) {
      await _loadAll();
    }
  }

  Future<void> _toggleBlock(int id, bool block) async {
    final path = block ? '/users/$id/block' : '/users/$id/unblock';
    final resp = await ApiClient.patch(path, {}, auth: true);
    if (resp.statusCode == 200) {
      await _loadAll();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: ${resp.body}')));
    }
  }

  Future<void> _changePasswordDialog(int userId) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alterar senha'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Nova senha (>= 6)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final newPassword = ctrl.text;
      if (newPassword.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha deve ter ao menos 6 caracteres')),
        );
        return;
      }
      final resp = await ApiClient.patch('/users/$userId/password', {
        'newPassword': newPassword,
      }, auth: true);
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Senha alterada')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: ${resp.body}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.selectedStore != null
              ? 'Admin - ${widget.selectedStore!.storeName}'
              : 'Admin - Contas',
        ),
        actions: [
          IconButton(onPressed: _loadAll, icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: _goToCreateUser,
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Criar usuário',
          ),
          IconButton(
            onPressed: () async {
              await AuthService.logout();
              if (!mounted) return;
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_stats != null) _buildStatsCard(_stats!),
                  const SizedBox(height: 16),
                  Expanded(child: _buildUsersList()),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            _stat('Usuários', '${stats['users']}'),
            _stat('Ativos', '${stats['activeUsers']}'),
            _stat('Vendas', '${stats['salesCount']}'),
            _stat('Receita', Currency.fcfa((stats['revenue'] ?? 0) as num)),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(color: Colors.grey[700])),
      ],
    );
  }

  // Inline create-user UI removed

  Widget _buildUsersList() {
    return Card(
      child: ListView.separated(
        itemCount: _users.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final u = _users[index] as Map<String, dynamic>;
          final blocked = u['status'] == 'blocked';
          final displayName = (u['name'] as String?)?.trim();
          final primary = (displayName != null && displayName.isNotEmpty)
              ? displayName
              : (u['email'] as String);
          final initial = primary.substring(0, 1).toUpperCase();
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              child: Text(initial),
            ),
            title: Text(
              primary,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u['email'] as String),
                if ((u['storeName'] as String?)?.isNotEmpty == true)
                  Text(
                    'Loja: ${u['storeName']}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: Text('Role: ${u['role']}'),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    Chip(
                      label: Text('Status: ${u['status']}'),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      backgroundColor: blocked
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      labelStyle: TextStyle(
                        color: blocked ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Alterar senha',
                  icon: const Icon(Icons.password),
                  onPressed: () => _changePasswordDialog(u['id'] as int),
                ),
                ElevatedButton(
                  onPressed: () => _toggleBlock(u['id'] as int, !blocked),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blocked ? Colors.green : Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(blocked ? 'Desbloquear' : 'Bloquear'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _loading = true;
  List<dynamic> _users = [];
  Map<String, dynamic>? _stats;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _storeIdController = TextEditingController();
  DateTime? _blockedUntil;
  String _role = 'user';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
    });
    final usersResp = await ApiClient.get('/users', auth: true);
    final statsResp = await ApiClient.get('/admin/stats', auth: true);
    setState(() {
      _users = jsonDecode(usersResp.body) as List<dynamic>;
      _stats = jsonDecode(statsResp.body) as Map<String, dynamic>;
      _loading = false;
    });
  }

  Future<void> _createUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();
    final storeId = _storeIdController.text.trim();
    if (name.isEmpty || email.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha nome, email e senha (>= 6)')),
      );
      return;
    }
    final body = {
      'name': name,
      'email': email,
      'password': password,
      'role': _role,
      if (storeId.isNotEmpty) 'store_id': storeId,
      if (_blockedUntil != null)
        'blockedUntil': _blockedUntil!.toIso8601String(),
    };
    final resp = await ApiClient.post('/users', body, auth: true);
    if (resp.statusCode == 201) {
      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
      _storeIdController.clear();
      setState(() {
        _role = 'user';
      });
      await _loadAll();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Usuário criado')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: ${resp.body}')));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Contas'),
        actions: [
          IconButton(onPressed: _loadAll, icon: const Icon(Icons.refresh)),
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
                  _buildCreateUserCard(),
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
            _stat('Receita', 'R\$ ${stats['revenue']}'),
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

  Widget _buildCreateUserCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Criar usuário',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Senha',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _storeIdController,
              decoration: const InputDecoration(
                labelText: 'Store ID (opcional)',
                border: OutlineInputBorder(),
                helperText: 'Vincula o usuário a uma loja específica',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Bloqueado até (opcional)',
                      border: OutlineInputBorder(),
                      helperText: 'Defina a data para bloquear até lá',
                    ),
                    child: InkWell(
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _blockedUntil ?? now,
                          firstDate: now,
                          lastDate: DateTime(now.year + 5),
                        );
                        if (picked != null) {
                          setState(() {
                            _blockedUntil = picked;
                          });
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          _blockedUntil == null
                              ? 'Selecionar data'
                              : _blockedUntil!.toString().split(' ').first,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _blockedUntil = null;
                    });
                  },
                  icon: const Icon(Icons.clear),
                  tooltip: 'Limpar',
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButton<String>(
              value: _role,
              items: const [
                DropdownMenuItem(value: 'user', child: Text('User')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (v) {
                if (v != null)
                  setState(() {
                    _role = v;
                  });
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _createUser,
              icon: const Icon(Icons.add),
              label: const Text('Criar'),
            ),
          ],
        ),
      ),
    );
  }

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
            trailing: ElevatedButton(
              onPressed: () => _toggleBlock(u['id'] as int, !blocked),
              style: ElevatedButton.styleFrom(
                backgroundColor: blocked ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(blocked ? 'Desbloquear' : 'Bloquear'),
            ),
          );
        },
      ),
    );
  }
}

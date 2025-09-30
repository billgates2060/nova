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
    if (email.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha email e senha (>= 6)')),
      );
      return;
    }
    final resp = await ApiClient.post('/users', {
      'email': email,
      'password': password,
      'role': _role,
    }, auth: true);
    if (resp.statusCode == 201) {
      _emailController.clear();
      _passwordController.clear();
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          return ListTile(
            leading: CircleAvatar(
              child: Text((u['email'] as String).substring(0, 1).toUpperCase()),
            ),
            title: Text(u['email'] as String),
            subtitle: Text('Role: ${u['role']} • Status: ${u['status']}'),
            trailing: Wrap(
              spacing: 8,
              children: [
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nova/l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _clients = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final path = _query.trim().isEmpty
        ? '/clients'
        : '/clients?q=${Uri.encodeQueryComponent(_query)}';
    final resp = await ApiClient.get(path, auth: true);
    if (resp.statusCode == 200) {
      final list = (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>();
      setState(() {
        _clients = list;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.clients),
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _showSearch, icon: const Icon(Icons.search)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _clients.isEmpty
          ? const Center(child: Text('Nenhum cliente'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _clients.length,
              itemBuilder: (_, i) {
                final c = _clients[i];
                final initial = (c['name'] as String)
                    .trim()
                    .substring(0, 1)
                    .toUpperCase();
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
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo[50],
                      foregroundColor: Colors.indigo[700],
                      child: Text(initial),
                    ),
                    title: Text(
                      c['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text((c['phone'] ?? '').toString()),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') _editClient(c);
                        if (v == 'delete') _deleteClient(c);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(value: 'delete', child: Text('Excluir')),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createClient,
        backgroundColor: Colors.indigo[600],
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Future<void> _showSearch() async {
    final ctrl = TextEditingController(text: _query);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buscar cliente'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Nome/Telefone',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _query = ctrl.text);
      await _load();
    }
  }

  Future<void> _createClient() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo Cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Telefone',
                border: OutlineInputBorder(),
              ),
            ),
          ],
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
      final user = await AuthService.getCurrentUser();
      final storeId = user != null ? (user['storeId'] ?? '') : '';
      final body = {
        'name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        if (storeId.isNotEmpty) 'storeId': storeId,
      };
      final resp = await ApiClient.post('/clients', body, auth: true);
      if (resp.statusCode == 201) await _load();
      if (resp.statusCode == 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro: preencha loja (storeId)')),
        );
      }
    }
  }

  Future<void> _editClient(Map<String, dynamic> c) async {
    final nameCtrl = TextEditingController(text: c['name'] as String);
    final phoneCtrl = TextEditingController(
      text: (c['phone'] ?? '').toString(),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Telefone',
                border: OutlineInputBorder(),
              ),
            ),
          ],
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
      final resp = await ApiClient.put('/clients/${c['id']}', {
        'name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
      }, auth: true);
      if (resp.statusCode == 200) await _load();
    }
  }

  Future<void> _deleteClient(Map<String, dynamic> c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Cliente'),
        content: Text('Tem certeza que deseja excluir "${c['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final resp = await ApiClient.delete('/clients/${c['id']}', auth: true);
      if (resp.statusCode == 200) await _load();
    }
  }
}

import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../repositories/users_repository.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class AdminUsersScreen extends StatefulWidget {
  final StoreInfo? selectedStore;
  const AdminUsersScreen({super.key, this.selectedStore});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _users = const [];
  String _query = '';
  bool _isOfflineMode = false;
  final _usersRepo = UsersRepository();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _isOfflineMode = false;
    });

    // Primeiro: carregar dados locais
    try {
      final localUsers = await _usersRepo.getLocalUsers();
      
        setState(() {
        _users = localUsers;
        _isOfflineMode = true;
          _loading = false;
        });
      
      if (localUsers.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.info, color: Colors.white),
                SizedBox(width: 8),
                Text('Nenhum usuário encontrado localmente'),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
    } catch (localError) {
      if (kDebugMode) {
        print('❌ Erro ao carregar usuários locais: $localError');
      }
      
      setState(() {
        _users = [];
        _isOfflineMode = true;
        _loading = false;
      });
    }

    // Segundo: tentar sincronizar com backend
    try {
      List<Map<String, dynamic>> remoteUsers;
      
      if (widget.selectedStore != null) {
        remoteUsers = await AdminService.getStoreUsers(widget.selectedStore!.storeId);
      } else {
        remoteUsers = await AdminService.listUsers();
      }
      
      if (remoteUsers.isNotEmpty) {
        setState(() {
          _users = remoteUsers;
          _isOfflineMode = false;
        });
        
        // Sincronizar dados locais
        await _usersRepo.syncFromRemote();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.sync, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Usuários sincronizados com sucesso'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao sincronizar usuários: $e');
      }
      
      // Não mostrar erro se já temos dados locais
      if (_users.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.white),
                SizedBox(width: 8),
                Text('Modo offline - dados locais'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.selectedStore != null
            ? Text('Usuários • ${widget.selectedStore!.storeName}')
            : TextField(
          decoration: const InputDecoration(
            hintText: 'Buscar por nome, email ou loja...',
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        actions: [
          // Indicador de status offline
          if (_isOfflineMode)
          IconButton(
              icon: const Icon(Icons.wifi_off, color: Colors.orange),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Modo offline - dados locais'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              tooltip: 'Modo offline',
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _load,
            tooltip: 'Sincronizar',
          ),
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => _query = ''),
          ),
        ],
      ),
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
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final u = _filtered[i];
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
                        } else if (v == 'edit') {
                          await _editUserDialog(u);
                          await _load();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
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

  List<Map<String, dynamic>> get _filtered {
    if (_query.trim().isEmpty) return _users;
    final q = _query.toLowerCase();
    return _users.where((u) {
      return (u['name']?.toString().toLowerCase().contains(q) ?? false) ||
             (u['email']?.toString().toLowerCase().contains(q) ?? false) ||
             (u['storeName']?.toString().toLowerCase().contains(q) ?? false) ||
             (u['storeId']?.toString().toLowerCase().contains(q) ?? false) ||
             (u['store_id']?.toString().toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<void> _editUserDialog(Map<String, dynamic> user) async {
    String role = user['role']?.toString() ?? 'user';
    String status = user['status']?.toString() ?? 'active';
    final nameCtrl = TextEditingController(text: (user['name'] ?? '').toString());
    final storeIdCtrl = TextEditingController(text: (user['storeId'] ?? user['store_id'] ?? '').toString());
    final storeNameCtrl = TextEditingController(text: (user['storeName'] ?? user['store_name'] ?? '').toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar usuário'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: 'Nome'), controller: nameCtrl),
            DropdownButtonFormField<String>(
              value: role,
              decoration: const InputDecoration(labelText: 'Perfil'),
              items: const [
                DropdownMenuItem(value: 'user', child: Text('Lojista')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (v) => role = v ?? 'user',
            ),
            DropdownButtonFormField<String>(
              value: status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Ativo')),
                DropdownMenuItem(value: 'blocked', child: Text('Bloqueado')),
              ],
              onChanged: (v) => status = v ?? 'active',
            ),
            TextField(decoration: const InputDecoration(labelText: 'Store ID'), controller: storeIdCtrl),
            TextField(decoration: const InputDecoration(labelText: 'Store Name'), controller: storeNameCtrl),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar')),
        ],
      ),
    );
    if (ok == true) {
      await AdminService.updateUser(
        user['id'].toString(),
        role: role,
        status: status,
        storeId: storeIdCtrl.text.trim().isEmpty ? null : storeIdCtrl.text.trim(),
        storeName: storeNameCtrl.text.trim().isEmpty ? null : storeNameCtrl.text.trim(),
        name: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
      );
    }
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
                final userData = {
                  'name': nameCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'password': passCtrl.text,
                  'role': role,
                };
                
                await _usersRepo.createUser(userData);
                
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
              children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Usuário criado com sucesso'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  await _load();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Erro ao criar usuário: $e')),
                        ],
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }
}

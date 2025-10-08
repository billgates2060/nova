import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../repositories/users_repository.dart';

class AdminCreateUserScreen extends StatefulWidget {
  final StoreInfo? selectedStore;
  const AdminCreateUserScreen({super.key, this.selectedStore});

  @override
  State<AdminCreateUserScreen> createState() => _AdminCreateUserScreenState();
}

class _AdminCreateUserScreenState extends State<AdminCreateUserScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _storeNameController = TextEditingController();
  DateTime? _blockedUntil;
  String _role = 'user';
  bool _submitting = false;
  final _usersRepo = UsersRepository();

  Future<void> _createUser() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    final String name = _nameController.text.trim();
    final String storeName = _storeNameController.text.trim();

    if (name.isEmpty || email.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha nome, email e senha (>= 6)')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });
    final Map<String, dynamic> body = {
      'name': name,
      'email': email,
      'password': password,
      'role': _role,
      if (widget.selectedStore != null)
        'store_id': widget.selectedStore!.storeId,
      if (widget.selectedStore != null)
        'store_name': widget.selectedStore!.storeName,
      if (widget.selectedStore == null && storeName.isNotEmpty)
        'store_name': storeName,
      if (_blockedUntil != null)
        'blockedUntil': _blockedUntil!.toIso8601String(),
    };
    try {
      await _usersRepo.createUser(body);
      
      setState(() {
        _submitting = false;
      });
      
      if (!mounted) return;
      
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
      Navigator.of(context).pop(true);
      
    } catch (e) {
      setState(() {
        _submitting = false;
      });
      
      if (!mounted) return;
      
      final message = e.toString().contains('email_exists') 
          ? 'Email já existe'
          : 'Erro ao criar usuário: $e';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar usuário')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
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
            if (widget.selectedStore == null) ...[
              TextField(
                controller: _storeNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Loja (opcional)',
                  border: OutlineInputBorder(),
                  helperText: 'Se vazio, o backend definirá automaticamente',
                ),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Bloqueado até (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    child: InkWell(
                      onTap: () async {
                        final DateTime now = DateTime.now();
                        final DateTime? picked = await showDatePicker(
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
                  onPressed: () => setState(() {
                    _blockedUntil = null;
                  }),
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _createUser,
                icon: const Icon(Icons.add),
                label: Text(_submitting ? 'Criando...' : 'Criar usuário'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

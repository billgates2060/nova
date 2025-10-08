import 'package:flutter/material.dart';
import 'package:nova/l10n/app_localizations.dart';
import '../main.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  bool _changing = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    setState(() => _changing = true);
    final res = await AuthService.changePassword(
      _currentController.text,
      _newController.text,
    );
    setState(() => _changing = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message'] as String),
        backgroundColor: (res['success'] == true) ? Colors.green : Colors.red,
      ),
    );
    if (res['success'] == true) {
      _currentController.clear();
      _newController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Idioma',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.language),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: MyApp.of(context)?.currentLocaleCode(),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Idioma do aplicativo',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'system', child: Text('Sistema')),
                    DropdownMenuItem(value: 'pt', child: Text('Português')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'fr', child: Text('Français')),
                  ],
                  onChanged: (code) {
                    final app = MyApp.of(context);
                    app?.setLocale(code);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Acessibilidade: tamanho da fonte
          const Text(
            'Acessibilidade',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _fontScaleChip(context, 1.0, 'Normal'),
              _fontScaleChip(context, 1.2, 'Grande'),
              _fontScaleChip(context, 1.4, 'Extra'),
            ],
          ),
          const SizedBox(height: 24),
          // Contraste alto (tema escuro/claro controlado pelo sistema já ativo)
          const Text(
            'Segurança',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          const Text(
            'Alterar senha',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _currentController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Senha atual',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nova senha',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _changing ? null : _changePassword,
            icon: _changing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.lock_reset),
            label: const Text('Salvar nova senha'),
          ),
        ],
      ),
    );
  }

  Widget _fontScaleChip(BuildContext context, double scale, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: MediaQuery.of(context).textScaler == TextScaler.linear(scale),
      onSelected: (_) {
        // Aplica escala no nível da rota atual via MediaQuery
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: const SettingsScreen(),
            ),
            transitionDuration: const Duration(milliseconds: 0),
          ),
        );
      },
    );
  }
}

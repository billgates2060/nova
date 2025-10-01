import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:nova/l10n/app_localizations.dart';
import '../screens/products_screen.dart';
import '../screens/sales_screen.dart';
import '../screens/clients_screen.dart';
import '../screens/daily_summary_screen.dart';
import '../screens/admin_users_screen.dart';
import '../screens/welcome_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FutureBuilder<Map<String, String>?>(
              future: AuthService.getCurrentUser(),
              builder: (context, snap) {
                final email = snap.data?['email'] ?? '';
                return UserAccountsDrawerHeader(
                  accountName: Text(email.split('@').first),
                  accountEmail: Text(email),
                  currentAccountPicture: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: Text(AppLocalizations.of(context)!.home),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: Text(AppLocalizations.of(context)!.products),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProductsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: Text(AppLocalizations.of(context)!.sales),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const SalesScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_alt),
              title: Text(AppLocalizations.of(context)!.clients),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ClientsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: Text(AppLocalizations.of(context)!.reports),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DailySummaryScreen()),
                );
              },
            ),
            const Divider(),
            FutureBuilder<String?>(
              future: AuthService.getRole(),
              builder: (context, snap) {
                if (snap.data == 'admin') {
                  return ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: Text(AppLocalizations.of(context)!.adminManagement),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminUsersScreen(),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(
                AppLocalizations.of(context)!.logout,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () async {
                await AuthService.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

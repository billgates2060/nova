// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'NOVA - Gestion des Ventes';

  @override
  String get login => 'Connexion';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get products => 'Produits';

  @override
  String get sales => 'Ventes';

  @override
  String get clients => 'Clients';

  @override
  String get reports => 'Rapports';

  @override
  String get admin => 'Admin';

  @override
  String get lowStock => 'Stock faible';

  @override
  String get newSale => 'Nouvelle Vente';

  @override
  String get newProduct => 'Nouveau Produit';

  @override
  String get settings => 'Paramètres';

  @override
  String get logout => 'Déconnexion';

  @override
  String get home => 'Accueil';

  @override
  String get dailySummary => 'Résumé Quotidien';

  @override
  String get adminManagement => 'Gestion des Comptes (Admin)';

  @override
  String get notifications => 'Notifications';

  @override
  String get product => 'Produit';

  @override
  String get client => 'Client';

  @override
  String get selectClient => 'Sélectionner Client';

  @override
  String get quantity => 'Quantité';

  @override
  String get unitPrice => 'Prix Unitaire';

  @override
  String get totalPrice => 'Prix Total';

  @override
  String get discountPercent => 'Remise (%)';

  @override
  String get discountFixed => 'Remise Fixe (FCFA)';

  @override
  String get newSaleTitle => 'Nouvelle Vente';

  @override
  String get selectProduct => 'Sélectionner Produit';

  @override
  String get stockExceeded => 'Quantité supérieure au stock disponible';

  @override
  String get pleaseSelectProduct => 'Veuillez sélectionner un produit';

  @override
  String get saleSaved => 'Vente sauvegardée avec succès!';

  @override
  String get saleSavedOffline => 'Vente sauvegardée localement. Sera synchronisée quand la connexion reviendra.';

  @override
  String get syncError => 'Erreur de synchronisation des données';

  @override
  String get offlineMode => 'Mode hors ligne - données locales';

  @override
  String get syncData => 'Synchroniser les données';

  @override
  String get tryAgain => 'Réessayer';
}

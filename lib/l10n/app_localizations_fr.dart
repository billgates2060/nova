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
  String get productInfo => 'Informations sur le produit';
  @override
  String get productNameField => 'Nom du produit';
  @override
  String get skuManualField => 'Code (SKU manuel)';
  @override
  String get priceFcfaField => 'Prix (FCFA)';
  @override
  String get stockQtyField => 'Quantité en stock';
  @override
  String get lowStockAlertField => 'Alerte de stock bas (unités)';
  @override
  String get registerProductBtn => 'Enregistrer le produit';
  @override
  String get updateProductBtn => 'Mettre à jour le produit';
  @override
  String get productCreatedMsg => 'Produit créé avec succès !';
  @override
  String get productUpdatedMsg => 'Produit mis à jour avec succès !';
  @override
  String get updateTooltip => 'Actualiser';
  @override
  String get searchTooltip => 'Rechercher';
  @override
  String get searchProductsTitle => 'Rechercher des produits';
  @override
  String get nameOrCode => 'Nom ou code';
  @override
  String get homeNav => 'Accueil';
  @override
  String get productsNav => 'Produits';
  @override
  String get salesNav => 'Ventes';
  @override
  String get summaryNav => 'Résumé';
  @override
  String get clientsNav => 'Clients';
  @override
  String get noProducts => 'Aucun produit enregistré';
  @override
  String get tapPlusToAddProduct =>
      'Appuyez sur + pour ajouter votre premier produit';
  @override
  String get confirmDeletion => 'Confirmer la suppression';
  @override
  String get confirmDeleteProductPrompt =>
      'Voulez-vous vraiment supprimer le produit';
  @override
  String get deletedSuccess => 'Produit supprimé avec succès !';
  @override
  String get viewReports => 'Voir les rapports';
  @override
  String get receipts => 'Reçus';
  @override
  String get administration => 'Administration';
  @override
  String get manageStores => 'Gérer les magasins';
  @override
  String get recentSales => 'Ventes récentes';
  @override
  String get quickActions => 'Actions rapides';
  @override
  String get settingsLabel => 'Paramètres';
  @override
  String get noRecentSales => 'Aucune vente récente.';
  @override
  String get loadErrorPrefix => 'Erreur de chargement :';
  @override
  String get allGoodNoLowStock => 'Tout est bon ! Aucun article en stock bas.';
  @override
  String get priceLabel => 'Prix';
  @override
  String get stockLabel => 'Stock';
  @override
  String get alertLabel => 'Alerte';
  @override
  String get lowShort => 'Bas';
  @override
  String get nameOrPhone => 'Nom/Téléphone';
  @override
  String get confirmDeleteClientTitle => 'Supprimer le client';
  @override
  String get confirmDeleteClientPrompt => 'Voulez-vous vraiment supprimer';
  @override
  String get errorFillStoreId => 'Erreur : renseignez le magasin (storeId)';
  @override
  String get preview => 'Aperçu';
  @override
  String get printLabel => 'Imprimer';
  @override
  String get share => 'Partager';
  @override
  String get saveLabel => 'Enregistrer';
  @override
  String get receiptPrintSent => 'Reçu envoyé à l\'imprimante !';
  @override
  String get receiptSharedSuccess => 'Reçu partagé avec succès !';
  @override
  String get receiptSavedSuccess => 'Reçu enregistré avec succès !';
  @override
  String get receiptGeneratedSharedSuccess =>
      'Reçu généré et partagé avec succès !';
  @override
  String get errorGeneratingReceipt => 'Erreur lors de la génération du reçu :';
  @override
  String get errorProcessingReceipt => 'Erreur lors du traitement du reçu :';
  @override
  String get currentPassword => 'Mot de passe actuel';
  @override
  String get newPasswordLabel => 'Nouveau mot de passe';
  @override
  String get saveNewPassword => 'Enregistrer le nouveau mot de passe';

  // Added strings
  @override
  String get today => 'Aujourd\'hui';
  @override
  String get selectedDate => 'Date sélectionnée';
  @override
  String get daySummaryTitle => 'Résumé du jour';
  @override
  String get totalSold => 'Total vendu';
  @override
  String get productsSold => 'Produits vendus';
  @override
  String get salesCount => 'Ventes';
  @override
  String get receiptsHistory => 'Historique des reçus';
  @override
  String get filters => 'Filtres';
  @override
  String get noSales => 'Aucune vente enregistrée';
  @override
  String get tapPlusToAddSale =>
      'Appuyez sur + pour ajouter votre première vente';
  @override
  String get quantity => 'Quantité';
  @override
  String get client => 'Client';
  @override
  String get selectClient => 'Sélectionner un client';
  @override
  String get newSaleTitle => 'Nouvelle Vente';
  @override
  String get updateProducts => 'Mettre à jour les produits';
  @override
  String get noClients => 'Aucun client';
  @override
  String get searchClient => 'Rechercher un client';
  @override
  String get newClient => 'Nouveau Client';
  @override
  String get name => 'Nom';
  @override
  String get phone => 'Téléphone';
  @override
  String get save => 'Enregistrer';
  @override
  String get cancel => 'Annuler';
  @override
  String get edit => 'Modifier';
  @override
  String get delete => 'Supprimer';
}

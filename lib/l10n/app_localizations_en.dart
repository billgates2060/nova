// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'NOVA - Sales Management';

  @override
  String get login => 'Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get products => 'Products';

  @override
  String get sales => 'Sales';

  @override
  String get clients => 'Clients';

  @override
  String get reports => 'Reports';

  @override
  String get admin => 'Admin';

  @override
  String get lowStock => 'Low stock';

  @override
  String get newSale => 'New Sale';

  @override
  String get newProduct => 'New Product';

  @override
  String get settings => 'Settings';

  @override
  String get logout => 'Logout';

  @override
  String get home => 'Home';

  @override
  String get dailySummary => 'Daily Summary';

  @override
  String get adminManagement => 'Account Management (Admin)';

  @override
  String get notifications => 'Notifications';

  // Added strings
  @override
  String get today => 'Today';
  @override
  String get selectedDate => 'Selected Date';
  @override
  String get daySummaryTitle => 'Daily Summary';
  @override
  String get totalSold => 'Total Sold';
  @override
  String get productsSold => 'Products Sold';
  @override
  String get salesCount => 'Sales';
  @override
  String get receiptsHistory => 'Receipts History';
  @override
  String get filters => 'Filters';
  @override
  String get noSales => 'No sales recorded';
  @override
  String get tapPlusToAddSale => 'Tap + to add your first sale';
  @override
  String get quantity => 'Quantity';
  @override
  String get client => 'Client';
  @override
  String get selectClient => 'Select client';
  @override
  String get newSaleTitle => 'New Sale';
  @override
  String get updateProducts => 'Update products';
  @override
  String get noClients => 'No clients';
  @override
  String get searchClient => 'Search client';
  @override
  String get newClient => 'New Client';
  @override
  String get name => 'Name';
  @override
  String get phone => 'Phone';
  @override
  String get save => 'Save';
  @override
  String get cancel => 'Cancel';
  @override
  String get edit => 'Edit';
  @override
  String get delete => 'Delete';
  @override
  String get productInfo => 'Product Information';
  @override
  String get productNameField => 'Product Name';
  @override
  String get skuManualField => 'Code (manual SKU)';
  @override
  String get priceFcfaField => 'Price (FCFA)';
  @override
  String get stockQtyField => 'Stock Quantity';
  @override
  String get lowStockAlertField => 'Low stock alert (units)';
  @override
  String get registerProductBtn => 'Register Product';
  @override
  String get updateProductBtn => 'Update Product';
  @override
  String get productCreatedMsg => 'Product created successfully!';
  @override
  String get productUpdatedMsg => 'Product updated successfully!';
  @override
  String get updateTooltip => 'Refresh';
  @override
  String get searchTooltip => 'Search';
  @override
  String get searchProductsTitle => 'Search products';
  @override
  String get nameOrCode => 'Name or code';
  @override
  String get homeNav => 'Home';
  @override
  String get productsNav => 'Products';
  @override
  String get salesNav => 'Sales';
  @override
  String get summaryNav => 'Summary';
  @override
  String get clientsNav => 'Clients';
  @override
  String get noProducts => 'No products yet';
  @override
  String get tapPlusToAddProduct => 'Tap + to add your first product';
  @override
  String get confirmDeletion => 'Confirm Deletion';
  @override
  String get confirmDeleteProductPrompt =>
      'Are you sure you want to delete the product';
  @override
  String get deletedSuccess => 'Product deleted successfully!';
  @override
  String get viewReports => 'View Reports';
  @override
  String get receipts => 'Receipts';
  @override
  String get administration => 'Administration';
  @override
  String get manageStores => 'Manage Stores';
  @override
  String get recentSales => 'Recent Sales';
  @override
  String get quickActions => 'Quick Actions';
  @override
  String get settingsLabel => 'Settings';
  @override
  String get noRecentSales => 'No recent sales.';
  @override
  String get loadErrorPrefix => 'Load error:';
  @override
  String get allGoodNoLowStock => 'All good! No low stock items.';
  @override
  String get priceLabel => 'Price';
  @override
  String get stockLabel => 'Stock';
  @override
  String get alertLabel => 'Alert';
  @override
  String get lowShort => 'Low';
  @override
  String get nameOrPhone => 'Name/Phone';
  @override
  String get confirmDeleteClientTitle => 'Delete Client';
  @override
  String get confirmDeleteClientPrompt => 'Are you sure you want to delete';
  @override
  String get errorFillStoreId => 'Error: fill store (storeId)';
  @override
  String get preview => 'Preview';
  @override
  String get printLabel => 'Print';
  @override
  String get share => 'Share';
  @override
  String get saveLabel => 'Save';
  @override
  String get receiptPrintSent => 'Receipt sent to printer!';
  @override
  String get receiptSharedSuccess => 'Receipt shared successfully!';
  @override
  String get receiptSavedSuccess => 'Receipt saved successfully!';
  @override
  String get receiptGeneratedSharedSuccess =>
      'Receipt generated and shared successfully!';
  @override
  String get errorGeneratingReceipt => 'Error generating receipt:';
  @override
  String get errorProcessingReceipt => 'Error processing receipt:';
  @override
  String get currentPassword => 'Current password';
  @override
  String get newPasswordLabel => 'New password';
  @override
  String get saveNewPassword => 'Save new password';

  // Settings (language & accessibility)
  @override
  String get language => 'Language';
  @override
  String get appLanguageLabel => 'App language';
  @override
  String get systemOption => 'System';
  @override
  String get portuguese => 'Portuguese';
  @override
  String get englishLabel => 'English';
  @override
  String get frenchLabel => 'French';
  @override
  String get accessibility => 'Accessibility';
  @override
  String get fontSizeNormal => 'Normal';
  @override
  String get fontSizeLarge => 'Large';
  @override
  String get fontSizeExtra => 'Extra';
  @override
  String get security => 'Security';
  @override
  String get changePasswordTitle => 'Change password';

  // Receipts/messages
  @override
  String get errorLoadingReceipts => 'Error loading receipts';
  @override
  String get receiptPrefix => 'Receipt';
  @override
  String get shareReceiptTextPrefix => 'Sale receipt #';
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('pt')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'NOVA - Sales Management'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @sales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sales;

  /// No description provided for @clients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clients;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get lowStock;

  /// No description provided for @newSale.
  ///
  /// In en, this message translates to:
  /// **'New Sale'**
  String get newSale;

  /// No description provided for @newProduct.
  ///
  /// In en, this message translates to:
  /// **'New Product'**
  String get newProduct;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @dailySummary.
  ///
  /// In en, this message translates to:
  /// **'Daily Summary'**
  String get dailySummary;

  /// No description provided for @adminManagement.
  ///
  /// In en, this message translates to:
  /// **'Account Management (Admin)'**
  String get adminManagement;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @selectClient.
  ///
  /// In en, this message translates to:
  /// **'Select Client'**
  String get selectClient;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get unitPrice;

  /// No description provided for @totalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Price'**
  String get totalPrice;

  /// No description provided for @discountPercent.
  ///
  /// In en, this message translates to:
  /// **'Discount (%)'**
  String get discountPercent;

  /// No description provided for @discountFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed Discount (FCFA)'**
  String get discountFixed;

  /// No description provided for @newSaleTitle.
  ///
  /// In en, this message translates to:
  /// **'New Sale'**
  String get newSaleTitle;

  /// No description provided for @selectProduct.
  ///
  /// In en, this message translates to:
  /// **'Select Product'**
  String get selectProduct;

  /// No description provided for @stockExceeded.
  ///
  /// In en, this message translates to:
  /// **'Quantity greater than available stock'**
  String get stockExceeded;

  /// No description provided for @pleaseSelectProduct.
  ///
  /// In en, this message translates to:
  /// **'Please select a product'**
  String get pleaseSelectProduct;

  /// No description provided for @saleSaved.
  ///
  /// In en, this message translates to:
  /// **'Sale saved successfully!'**
  String get saleSaved;

  /// No description provided for @saleSavedOffline.
  ///
  /// In en, this message translates to:
  /// **'Sale saved locally. Will be synced when connection returns.'**
  String get saleSavedOffline;

  /// No description provided for @syncError.
  ///
  /// In en, this message translates to:
  /// **'Error syncing data'**
  String get syncError;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline mode - local data'**
  String get offlineMode;

  /// No description provided for @syncData.
  ///
  /// In en, this message translates to:
  /// **'Sync data'**
  String get syncData;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @homeNav.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeNav;

  /// No description provided for @productsNav.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsNav;

  /// No description provided for @salesNav.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get salesNav;

  /// No description provided for @summaryNav.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summaryNav;

  /// No description provided for @clientsNav.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clientsNav;

  /// No description provided for @daySummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Summary'**
  String get daySummaryTitle;

  /// No description provided for @totalSold.
  ///
  /// In en, this message translates to:
  /// **'Total Sold'**
  String get totalSold;

  /// No description provided for @viewReports.
  ///
  /// In en, this message translates to:
  /// **'View Reports'**
  String get viewReports;

  /// No description provided for @receipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get receipts;

  /// No description provided for @administration.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get administration;

  /// No description provided for @manageStores.
  ///
  /// In en, this message translates to:
  /// **'Manage Stores'**
  String get manageStores;

  /// No description provided for @recentSales.
  ///
  /// In en, this message translates to:
  /// **'Recent Sales'**
  String get recentSales;

  /// No description provided for @noRecentSales.
  ///
  /// In en, this message translates to:
  /// **'No recent sales'**
  String get noRecentSales;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @settingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsLabel;

  /// No description provided for @updateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateTooltip;

  /// No description provided for @searchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTooltip;

  /// No description provided for @searchProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Products'**
  String get searchProductsTitle;

  /// No description provided for @nameOrCode.
  ///
  /// In en, this message translates to:
  /// **'Name or code'**
  String get nameOrCode;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// No description provided for @stockLabel.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stockLabel;

  /// No description provided for @lowShort.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get lowShort;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @noProducts.
  ///
  /// In en, this message translates to:
  /// **'No products'**
  String get noProducts;

  /// No description provided for @tapPlusToAddProduct.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add product'**
  String get tapPlusToAddProduct;

  /// No description provided for @receiptsHistory.
  ///
  /// In en, this message translates to:
  /// **'Receipts History'**
  String get receiptsHistory;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @printLabel.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get printLabel;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @saveLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveLabel;

  /// No description provided for @receiptGeneratedSharedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Receipt generated, shared and saved successfully!'**
  String get receiptGeneratedSharedSuccess;

  /// No description provided for @errorGeneratingReceipt.
  ///
  /// In en, this message translates to:
  /// **'Error generating receipt'**
  String get errorGeneratingReceipt;

  /// No description provided for @receiptPrintSent.
  ///
  /// In en, this message translates to:
  /// **'Receipt sent to print'**
  String get receiptPrintSent;

  /// No description provided for @receiptSharedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Receipt shared successfully'**
  String get receiptSharedSuccess;

  /// No description provided for @receiptSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Receipt saved successfully'**
  String get receiptSavedSuccess;

  /// No description provided for @errorProcessingReceipt.
  ///
  /// In en, this message translates to:
  /// **'Error processing receipt'**
  String get errorProcessingReceipt;

  /// No description provided for @selectedDate.
  ///
  /// In en, this message translates to:
  /// **'Selected date'**
  String get selectedDate;

  /// No description provided for @productsSold.
  ///
  /// In en, this message translates to:
  /// **'Products sold'**
  String get productsSold;

  /// No description provided for @salesCount.
  ///
  /// In en, this message translates to:
  /// **'Sales count'**
  String get salesCount;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @appLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguageLabel;

  /// No description provided for @systemOption.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemOption;

  /// No description provided for @portuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get portuguese;

  /// No description provided for @englishLabel.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLabel;

  /// No description provided for @frenchLabel.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get frenchLabel;

  /// No description provided for @accessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accessibility;

  /// No description provided for @fontSizeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get fontSizeNormal;

  /// No description provided for @fontSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get fontSizeLarge;

  /// No description provided for @fontSizeExtra.
  ///
  /// In en, this message translates to:
  /// **'Extra Large'**
  String get fontSizeExtra;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitle;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordLabel;

  /// No description provided for @saveNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Save new password'**
  String get saveNewPassword;

  /// No description provided for @noClients.
  ///
  /// In en, this message translates to:
  /// **'No clients'**
  String get noClients;

  /// No description provided for @searchClient.
  ///
  /// In en, this message translates to:
  /// **'Search client'**
  String get searchClient;

  /// No description provided for @nameOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Name or phone'**
  String get nameOrPhone;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @errorFillStoreId.
  ///
  /// In en, this message translates to:
  /// **'Error: Fill store ID'**
  String get errorFillStoreId;

  /// No description provided for @newClient.
  ///
  /// In en, this message translates to:
  /// **'New client'**
  String get newClient;

  /// No description provided for @confirmDeleteClientTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm deletion'**
  String get confirmDeleteClientTitle;

  /// No description provided for @confirmDeleteClientPrompt.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the client'**
  String get confirmDeleteClientPrompt;

  /// No description provided for @errorLoadingReceipts.
  ///
  /// In en, this message translates to:
  /// **'Error loading receipts'**
  String get errorLoadingReceipts;

  /// No description provided for @receiptPrefix.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptPrefix;

  /// No description provided for @confirmDeletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm deletion'**
  String get confirmDeletion;

  /// No description provided for @confirmDeleteProductPrompt.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item?'**
  String get confirmDeleteProductPrompt;

  /// No description provided for @deletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get deletedSuccess;

  /// No description provided for @loadErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error loading'**
  String get loadErrorPrefix;

  /// No description provided for @noSales.
  ///
  /// In en, this message translates to:
  /// **'No sales'**
  String get noSales;

  /// No description provided for @productInfo.
  ///
  /// In en, this message translates to:
  /// **'Product information'**
  String get productInfo;

  /// No description provided for @productNameField.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productNameField;

  /// No description provided for @skuManualField.
  ///
  /// In en, this message translates to:
  /// **'SKU/Manual code'**
  String get skuManualField;

  /// No description provided for @priceFcfaField.
  ///
  /// In en, this message translates to:
  /// **'Price (FCFA)'**
  String get priceFcfaField;

  /// No description provided for @stockQtyField.
  ///
  /// In en, this message translates to:
  /// **'Stock quantity'**
  String get stockQtyField;

  /// No description provided for @lowStockAlertField.
  ///
  /// In en, this message translates to:
  /// **'Low stock alert'**
  String get lowStockAlertField;

  /// No description provided for @registerProductBtn.
  ///
  /// In en, this message translates to:
  /// **'Register product'**
  String get registerProductBtn;

  /// No description provided for @updateProductBtn.
  ///
  /// In en, this message translates to:
  /// **'Update product'**
  String get updateProductBtn;

  /// No description provided for @productCreatedMsg.
  ///
  /// In en, this message translates to:
  /// **'Product created successfully!'**
  String get productCreatedMsg;

  /// No description provided for @productUpdatedMsg.
  ///
  /// In en, this message translates to:
  /// **'Product updated successfully!'**
  String get productUpdatedMsg;

  /// No description provided for @updateProducts.
  ///
  /// In en, this message translates to:
  /// **'Update products'**
  String get updateProducts;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'fr', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
    case 'pt': return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}

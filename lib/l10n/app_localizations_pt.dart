// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'NOVA - Gestão de Vendas';

  @override
  String get login => 'Entrar';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Senha';

  @override
  String get products => 'Produtos';

  @override
  String get sales => 'Vendas';

  @override
  String get clients => 'Clientes';

  @override
  String get reports => 'Relatórios';

  @override
  String get admin => 'Admin';

  @override
  String get lowStock => 'Estoque Baixo';

  @override
  String get newSale => 'Nova Venda';

  @override
  String get newProduct => 'Novo Produto';

  @override
  String get settings => 'Configurações';

  @override
  String get logout => 'Sair';

  @override
  String get home => 'Início';

  @override
  String get dailySummary => 'Resumo Diário';

  @override
  String get adminManagement => 'Gestão de Contas (Admin)';

  @override
  String get notifications => 'Notificações';

  // Added strings
  @override
  String get today => 'Hoje';
  @override
  String get selectedDate => 'Data Selecionada';
  @override
  String get daySummaryTitle => 'Resumo do Dia';
  @override
  String get totalSold => 'Total Vendido';
  @override
  String get productsSold => 'Produtos Vendidos';
  @override
  String get salesCount => 'Vendas';
  @override
  String get receiptsHistory => 'Histórico de Recibos';
  @override
  String get filters => 'Filtros';
  @override
  String get noSales => 'Nenhuma venda registrada';
  @override
  String get tapPlusToAddSale => 'Toque no + para registrar sua primeira venda';
  @override
  String get quantity => 'Quantidade';
  @override
  String get client => 'Cliente';
  @override
  String get selectClient => 'Selecionar cliente';
  @override
  String get newSaleTitle => 'Nova Venda';
  @override
  String get updateProducts => 'Atualizar produtos';
  @override
  String get noClients => 'Nenhum cliente';
  @override
  String get searchClient => 'Buscar cliente';
  @override
  String get newClient => 'Novo Cliente';
  @override
  String get name => 'Nome';
  @override
  String get phone => 'Telefone';
  @override
  String get save => 'Salvar';
  @override
  String get cancel => 'Cancelar';
  @override
  String get edit => 'Editar';
  @override
  String get delete => 'Excluir';
  @override
  String get productInfo => 'Informações do Produto';
  @override
  String get productNameField => 'Nome do Produto';
  @override
  String get skuManualField => 'Código (SKU manual)';
  @override
  String get priceFcfaField => 'Preço (FCFA)';
  @override
  String get stockQtyField => 'Quantidade em Estoque';
  @override
  String get lowStockAlertField => 'Alerta de estoque baixo (unidades)';
  @override
  String get registerProductBtn => 'Cadastrar Produto';
  @override
  String get updateProductBtn => 'Atualizar Produto';
  @override
  String get productCreatedMsg => 'Produto cadastrado com sucesso!';
  @override
  String get productUpdatedMsg => 'Produto atualizado com sucesso!';
  @override
  String get updateTooltip => 'Atualizar';
  @override
  String get searchTooltip => 'Buscar';
  @override
  String get searchProductsTitle => 'Buscar produtos';
  @override
  String get nameOrCode => 'Nome ou código';
  @override
  String get homeNav => 'Início';
  @override
  String get productsNav => 'Produtos';
  @override
  String get salesNav => 'Vendas';
  @override
  String get summaryNav => 'Resumo';
  @override
  String get clientsNav => 'Clientes';
  @override
  String get noProducts => 'Nenhum produto cadastrado';
  @override
  String get tapPlusToAddProduct =>
      'Toque no + para adicionar seu primeiro produto';
  @override
  String get confirmDeletion => 'Confirmar Exclusão';
  @override
  String get confirmDeleteProductPrompt =>
      'Tem certeza que deseja excluir o produto';
  @override
  String get deletedSuccess => 'Produto excluído com sucesso!';
  @override
  String get viewReports => 'Ver Relatórios';
  @override
  String get receipts => 'Recibos';
  @override
  String get administration => 'Administração';
  @override
  String get manageStores => 'Gerenciar Lojas';
  @override
  String get recentSales => 'Vendas Recentes';
  @override
  String get quickActions => 'Ações Rápidas';
  @override
  String get settingsLabel => 'Configurações';
  @override
  String get noRecentSales => 'Sem vendas recentes.';
  @override
  String get loadErrorPrefix => 'Erro ao carregar:';
  @override
  String get allGoodNoLowStock => 'Tudo certo! Nenhum item com estoque baixo.';
  @override
  String get priceLabel => 'Preço';
  @override
  String get stockLabel => 'Estoque';
  @override
  String get alertLabel => 'Alerta';
  @override
  String get lowShort => 'Baixo';
  @override
  String get nameOrPhone => 'Nome/Telefone';
  @override
  String get confirmDeleteClientTitle => 'Excluir Cliente';
  @override
  String get confirmDeleteClientPrompt => 'Tem certeza que deseja excluir';
  @override
  String get errorFillStoreId => 'Erro: preencha loja (storeId)';
  @override
  String get preview => 'Visualizar';
  @override
  String get printLabel => 'Imprimir';
  @override
  String get share => 'Compartilhar';
  @override
  String get saveLabel => 'Salvar';
  @override
  String get receiptPrintSent => 'Recibo enviado para impressão!';
  @override
  String get receiptSharedSuccess => 'Recibo compartilhado com sucesso!';
  @override
  String get receiptSavedSuccess => 'Recibo salvo com sucesso!';
  @override
  String get receiptGeneratedSharedSuccess =>
      'Recibo gerado e compartilhado com sucesso!';
  @override
  String get errorGeneratingReceipt => 'Erro ao gerar recibo:';
  @override
  String get errorProcessingReceipt => 'Erro ao processar recibo:';
  @override
  String get currentPassword => 'Senha atual';
  @override
  String get newPasswordLabel => 'Nova senha';
  @override
  String get saveNewPassword => 'Salvar nova senha';

  // Settings (language & accessibility)
  @override
  String get language => 'Idioma';
  @override
  String get appLanguageLabel => 'Idioma do aplicativo';
  @override
  String get systemOption => 'Sistema';
  @override
  String get portuguese => 'Português';
  @override
  String get englishLabel => 'English';
  @override
  String get frenchLabel => 'Français';
  @override
  String get accessibility => 'Acessibilidade';
  @override
  String get fontSizeNormal => 'Normal';
  @override
  String get fontSizeLarge => 'Grande';
  @override
  String get fontSizeExtra => 'Extra';
  @override
  String get security => 'Segurança';
  @override
  String get changePasswordTitle => 'Alterar senha';

  // Receipts/messages
  @override
  String get errorLoadingReceipts => 'Erro ao carregar recibos';
  @override
  String get receiptPrefix => 'Recibo';
  @override
  String get shareReceiptTextPrefix => 'Recibo da venda #';
}

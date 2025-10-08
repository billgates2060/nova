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

  @override
  String get product => 'Produto';

  @override
  String get client => 'Cliente';

  @override
  String get selectClient => 'Selecionar Cliente';

  @override
  String get quantity => 'Quantidade';

  @override
  String get unitPrice => 'Preço Unitário';

  @override
  String get totalPrice => 'Preço Total';

  @override
  String get discountPercent => 'Desconto (%)';

  @override
  String get discountFixed => 'Desconto Fixo (FCFA)';

  @override
  String get newSaleTitle => 'Nova Venda';

  @override
  String get selectProduct => 'Selecionar Produto';

  @override
  String get stockExceeded => 'Quantidade maior que o estoque disponível';

  @override
  String get pleaseSelectProduct => 'Por favor, selecione um produto';

  @override
  String get saleSaved => 'Venda salva com sucesso!';

  @override
  String get saleSavedOffline => 'Venda salva localmente. Será sincronizada quando a conexão voltar.';

  @override
  String get syncError => 'Erro ao sincronizar dados';

  @override
  String get offlineMode => 'Modo offline - dados locais';

  @override
  String get syncData => 'Sincronizar dados';

  @override
  String get tryAgain => 'Tentar novamente';
}

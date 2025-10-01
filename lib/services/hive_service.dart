import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';
import '../models/store_ref.dart';

class HiveService {
  static const String boxUsers = 'users_global';
  static const String boxInventoryPrefix = 'inv_';
  static const String boxSalesPrefix = 'sales_';
  static const String boxClientsPrefix = 'clients_';
  static const String boxConfig = 'app_config';

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(UserProfileAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(StoreRefAdapter());
    await Hive.openBox(boxConfig);
  }

  static Future<Box> openStoreBox(String prefix, String storeId) async {
    final name = '$prefix$storeId';
    if (Hive.isBoxOpen(name)) return Hive.box(name);
    return Hive.openBox(name);
  }

  static Future<Box> openGlobalUsersBox() async {
    if (Hive.isBoxOpen(boxUsers)) return Hive.box(boxUsers);
    return Hive.openBox(boxUsers);
  }
}



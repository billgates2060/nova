import 'package:hive/hive.dart';

part 'client.g.dart';

@HiveType(typeId: 4)
class Client extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String storeId;

  @HiveField(2)
  String name;

  @HiveField(3)
  String phone;

  Client({required this.id, required this.storeId, required this.name, required this.phone});
}



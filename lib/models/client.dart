import 'package:hive/hive.dart';

part 'client.g.dart';

@HiveType(typeId: 4)
class Client extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String? storeId;

  @HiveField(2)
  String name;

  @HiveField(3)
  String phone;

  @HiveField(4)
  String? email;

  @HiveField(5)
  String? address;

  Client({
    this.id,
    this.storeId,
    required this.name,
    required this.phone,
    this.email,
    this.address,
  });
}



import 'package:hive/hive.dart';

part 'store_ref.g.dart';

@HiveType(typeId: 2)
class StoreRef extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  StoreRef({required this.id, required this.name});
}



import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 1)
class UserProfile extends HiveObject {
  @HiveField(0)
  String uid;

  @HiveField(1)
  String email;

  @HiveField(2)
  String name;

  @HiveField(3)
  String role; // 'admin' | 'user'

  @HiveField(4)
  String storeId;

  UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.storeId,
  });

  bool get isAdmin => role == 'admin';
}



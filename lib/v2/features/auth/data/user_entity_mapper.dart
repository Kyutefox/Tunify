import 'package:tunify/v2/features/auth/domain/entities/user_entity.dart';

UserEntity userEntityFromProfileJson(Map<String, dynamic> json) {
  final id = json['id'] as String? ?? '';
  final email = json['email'] as String? ?? '';
  final username = json['username'] as String? ?? '';
  final avatar = json['avatar'] as String?;
  return UserEntity(
    id: id,
    email: email,
    username: username,
    photoUrl: avatar,
  );
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AuthUserDtoImpl _$$AuthUserDtoImplFromJson(Map<String, dynamic> json) =>
    _$AuthUserDtoImpl(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      role: json['role'] as String,
    );

Map<String, dynamic> _$$AuthUserDtoImplToJson(_$AuthUserDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'displayName': instance.displayName,
      'role': instance.role,
    };

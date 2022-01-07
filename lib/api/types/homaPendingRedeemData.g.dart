// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'homaPendingRedeemData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomaPendingRedeemData _$HomaPendingRedeemDataFromJson(Map json) {
  return HomaPendingRedeemData()
    ..currentRelayEra = json['currentRelayEra'] as int?
    ..totalUnbonding = (json['totalUnbonding'] as num? ?? 0).toDouble()
    ..claimable = (json['claimable'] as num? ?? 0).toDouble()
    ..redeemRequest = json['redeemRequest'] as Map? ?? {}
    ..unbondings = List<Map>.from(json['unbondings'] as List? ?? []);
}

Map<String, dynamic> _$HomaPendingRedeemDataToJson(
        HomaPendingRedeemData instance) =>
    <String, dynamic>{
      'currentRelayEra': instance.currentRelayEra,
      'totalUnbonding': instance.totalUnbonding,
      'claimable': instance.claimable,
      'redeemRequest': instance.redeemRequest,
      'unbondings': instance.unbondings,
    };

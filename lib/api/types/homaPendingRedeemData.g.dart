// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'homaPendingRedeemData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomaPendingRedeemData _$HomaPendingRedeemDataFromJson(
    Map<String, dynamic> json) {
  return HomaPendingRedeemData(
    totalUnbonding: json['totalUnbonding'] as num?,
    claimable: json['claimable'] as num?,
    redeemRequest: json['redeemRequest'] as Map<String, dynamic>?,
    currentRelayEra: json['currentRelayEra'] as int?,
  )..unbondings = (json['unbondings'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList();
}

Map<String, dynamic> _$HomaPendingRedeemDataToJson(
        HomaPendingRedeemData instance) =>
    <String, dynamic>{
      'totalUnbonding': instance.totalUnbonding,
      'claimable': instance.claimable,
      'unbondings': instance.unbondings,
      'redeemRequest': instance.redeemRequest,
      'currentRelayEra': instance.currentRelayEra,
    };

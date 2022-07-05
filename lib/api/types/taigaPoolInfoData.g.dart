// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'taigaPoolInfoData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaigaPoolInfoData _$TaigaPoolInfoDataFromJson(Map<String, dynamic> json) {
  return TaigaPoolInfoData(
    (json['apy'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, (e as num).toDouble()),
    ),
    (json['reward'] as List<dynamic>).map((e) => e as String).toList(),
    (json['rewardTokens'] as List<dynamic>).map((e) => e as String).toList(),
    json['totalShares'] as String,
    json['userShares'] as String,[]
    // (json['balances'] as List<dynamic>).map((e) => e as String).toList(),
  );
}

Map<String, dynamic> _$TaigaPoolInfoDataToJson(TaigaPoolInfoData instance) =>
    <String, dynamic>{
      'apy': instance.apy,
      'reward': instance.reward,
      'rewardTokens': instance.rewardTokens,
      'userShares': instance.userShares,
      'totalShares': instance.totalShares,
      'balances': instance.balances,
    };

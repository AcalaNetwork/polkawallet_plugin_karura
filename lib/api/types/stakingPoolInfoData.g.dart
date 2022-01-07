// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stakingPoolInfoData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StakingPoolInfoData _$StakingPoolInfoDataFromJson(Map<String, dynamic> json) {
  return StakingPoolInfoData()
    ..rewardRate = json['rewardRate'] as String?
    ..freeList = (json['freeList'] as List<dynamic>)
        .map((e) => StakingPoolFreeItemData.fromJson(e as Map<String, dynamic>))
        .toList()
    ..unbondingDuration = (json['unbondingDuration'] as num).toDouble()
    ..freePool = (json['freePool'] as num).toDouble()
    ..unbondingToFree = (json['unbondingToFree'] as num).toDouble()
    ..liquidTokenIssuance = json['liquidTokenIssuance'] as String?
    ..defaultExchangeRate = (json['defaultExchangeRate'] as num).toDouble()
    ..bondingDuration = (json['bondingDuration'] as num).toDouble()
    ..currentEra = (json['currentEra'] as num).toDouble()
    ..communalBonded = (json['communalBonded'] as num).toDouble()
    ..communalTotal = (json['communalTotal'] as num).toDouble()
    ..communalBondedRatio = (json['communalBondedRatio'] as num).toDouble()
    ..liquidExchangeRate = (json['liquidExchangeRate'] as num).toDouble();
}

Map<String, dynamic> _$StakingPoolInfoDataToJson(
        StakingPoolInfoData instance) =>
    <String, dynamic>{
      'rewardRate': instance.rewardRate,
      'freeList': instance.freeList,
      'unbondingDuration': instance.unbondingDuration,
      'freePool': instance.freePool,
      'unbondingToFree': instance.unbondingToFree,
      'liquidTokenIssuance': instance.liquidTokenIssuance,
      'defaultExchangeRate': instance.defaultExchangeRate,
      'bondingDuration': instance.bondingDuration,
      'currentEra': instance.currentEra,
      'communalBonded': instance.communalBonded,
      'communalTotal': instance.communalTotal,
      'communalBondedRatio': instance.communalBondedRatio,
      'liquidExchangeRate': instance.liquidExchangeRate,
    };

StakingPoolFreeItemData _$StakingPoolFreeItemDataFromJson(
    Map<String, dynamic> json) {
  return StakingPoolFreeItemData()
    ..era = json['era'] as int?
    ..free = (json['free'] as num).toDouble();
}

Map<String, dynamic> _$StakingPoolFreeItemDataToJson(
        StakingPoolFreeItemData instance) =>
    <String, dynamic>{
      'era': instance.era,
      'free': instance.free,
    };

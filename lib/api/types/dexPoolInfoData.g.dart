// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dexPoolInfoData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DexPoolData _$DexPoolDataFromJson(Map<String, dynamic> json) {
  return DexPoolData()
    ..tokenNameId = json['tokenNameId'] as String?
    ..tokens = json['tokens'] as List<dynamic>?
    ..provisioning = json['provisioning'] == null
        ? null
        : ProvisioningData.fromJson(
            json['provisioning'] as Map<String, dynamic>)
    ..rewards = (json['rewards'] as num?)?.toDouble()
    ..rewardsLoyalty = (json['rewardsLoyalty'] as num?)?.toDouble()
    ..balances = json['balances'] as List<dynamic>?;
}

Map<String, dynamic> _$DexPoolDataToJson(DexPoolData instance) =>
    <String, dynamic>{
      'tokenNameId': instance.tokenNameId,
      'tokens': instance.tokens,
      'provisioning': instance.provisioning,
      'rewards': instance.rewards,
      'rewardsLoyalty': instance.rewardsLoyalty,
      'balances': instance.balances,
    };

ProvisioningData _$ProvisioningDataFromJson(Map<String, dynamic> json) {
  return ProvisioningData()
    ..minContribution = json['minContribution'] as List<dynamic>?
    ..targetProvision = json['targetProvision'] as List<dynamic>?
    ..accumulatedProvision = json['accumulatedProvision'] as List<dynamic>?
    ..notBefore = json['notBefore'] as int?;
}

Map<String, dynamic> _$ProvisioningDataToJson(ProvisioningData instance) =>
    <String, dynamic>{
      'minContribution': instance.minContribution,
      'targetProvision': instance.targetProvision,
      'accumulatedProvision': instance.accumulatedProvision,
      'notBefore': instance.notBefore,
    };

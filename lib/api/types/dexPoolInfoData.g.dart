// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dexPoolInfoData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DexPoolData _$DexPoolDataFromJson(Map<String, dynamic> json) {
  return DexPoolData()
    ..decimals = json['decimals'] as int
    ..tokens = json['tokens'] as List<dynamic>
    ..pairDecimals = json['pairDecimals'] != null
        ? List<int>.from(json['pairDecimals'])
        : null
    ..provisioning = json['provisioning'] == null
        ? null
        : ProvisioningData.fromJson(
            json['provisioning'] as Map<String, dynamic>);
}

Map<String, dynamic> _$DexPoolDataToJson(DexPoolData instance) =>
    <String, dynamic>{
      'decimals': instance.decimals,
      'tokens': instance.tokens,
      'pairDecimals': instance.pairDecimals,
      'provisioning':
          instance.provisioning == null ? null : instance.provisioning.toJson(),
    };

ProvisioningData _$ProvisioningDataFromJson(Map<String, dynamic> json) {
  return ProvisioningData()
    ..minContribution = json['minContribution'] as List<dynamic>
    ..targetProvision = json['targetProvision'] as List<dynamic>
    ..accumulatedProvision = json['accumulatedProvision'] as List<dynamic>
    ..notBefore = json['notBefore'] as int;
}

Map<String, dynamic> _$ProvisioningDataToJson(ProvisioningData instance) =>
    <String, dynamic>{
      'minContribution': instance.minContribution,
      'targetProvision': instance.targetProvision,
      'accumulatedProvision': instance.accumulatedProvision,
      'notBefore': instance.notBefore,
    };

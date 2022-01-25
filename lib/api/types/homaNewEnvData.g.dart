// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'homaNewEnvData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomaNewEnvData _$HomaNewEnvDataFromJson(Map<String, dynamic> json) {
  return HomaNewEnvData(
      (json['totalStaking'] as num).toDouble(),
      (json['totalLiquidity'] as num).toDouble(),
      (json['exchangeRate'] as num).toDouble(),
      json['apy'] != null ? (json['apy'] as num).toDouble() : 0.0,
      (json['fastMatchFeeRate'] as num).toDouble(),
      (json['mintThreshold'] as num).toDouble(),
      (json['redeemThreshold'] as num).toDouble(),
      json['stakingSoftCap'] as int?,
      json['eraFrequency'] as int?);
}

Map<String, dynamic> _$HomaNewEnvDataToJson(HomaNewEnvData instance) =>
    <String, dynamic>{
      'totalStaking': instance.totalLiquidity,
      'totalLiquidity': instance.totalLiquidity,
      'exchangeRate': instance.exchangeRate,
      'apy': instance.apy,
      'fastMatchFeeRate': instance.fastMatchFeeRate,
      'mintThreshold': instance.mintThreshold,
      'redeemThreshold': instance.redeemThreshold,
      'stakingSoftCap': instance.stakingSoftCap,
      'eraFrequency': instance.eraFrequency
    };

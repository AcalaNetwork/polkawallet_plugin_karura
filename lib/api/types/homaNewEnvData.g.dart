// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'homaNewEnvData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomaNewEnvData _$HomaNewEnvDataFromJson(Map<String, dynamic> json) {
  return HomaNewEnvData(
      json['totalStaking'] as double,
      json['totalLiquidity'] as double,
      json['exchangeRate'] as double,
      json['apy'] as double,
      json['fastMatchFeeRate'] as double,
      json['mintThreshold'] as double,
      json['redeemThreshold'] as double,
      json['stakingSoftCap'] as int,
      json['eraFrequency'] as int);
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

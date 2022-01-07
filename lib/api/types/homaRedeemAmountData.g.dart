// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'homaRedeemAmountData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomaRedeemAmountData _$HomaRedeemAmountDataFromJson(Map<String, dynamic> json) {
  return HomaRedeemAmountData()
    ..atEra = json['atEra'] as int?
    ..amount = (json['amount'] as num? ?? 0).toDouble()
    ..demand = (json['demand'] as num? ?? 0).toDouble()
    ..fee = (json['fee'] as num? ?? 0).toDouble()
    ..received = (json['received'] as num? ?? 0).toDouble();
}

Map<String, dynamic> _$HomaRedeemAmountDataToJson(
        HomaRedeemAmountData instance) =>
    <String, dynamic>{
      'atEra': instance.atEra,
      'amount': instance.amount,
      'demand': instance.demand,
      'fee': instance.fee,
      'received': instance.received,
    };

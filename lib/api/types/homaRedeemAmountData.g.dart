// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'homaRedeemAmountData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomaRedeemAmountData _$HomaRedeemAmountDataFromJson(Map<String, dynamic> json) {
  return HomaRedeemAmountData()
    ..atEra = json['atEra'] as int?
    ..amount = (json['amount'] as num?)?.toDouble()
    ..demand = (json['demand'] as num?)?.toDouble()
    ..fee = (json['fee'] as num?)?.toDouble()
    ..received = (json['received'] as num?)?.toDouble();
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

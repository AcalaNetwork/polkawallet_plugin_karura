// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calcHomaMintAmountData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalcHomaMintAmountData _$CalcHomaMintAmountDataFromJson(
    Map<String, dynamic> json) {
  return CalcHomaMintAmountData(
    json['fee'] as String?,
    json['received'] as String?,
    json['suggestRedeemRequests'] as List?,
  );
}

Map<String, dynamic> _$CalcHomaMintAmountDataToJson(
        CalcHomaMintAmountData instance) =>
    <String, dynamic>{
      'fee': instance.fee,
      'received': instance.received,
      'suggestRedeemRequests': instance.suggestRedeemRequests,
    };

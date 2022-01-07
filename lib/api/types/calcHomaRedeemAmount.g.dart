// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calcHomaRedeemAmount.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalcHomaRedeemAmount _$CalcHomaRedeemAmountFromJson(Map<String, dynamic> json) {
  return CalcHomaRedeemAmount(
    json['fee'] as String?,
    json['expected'] as String?,
    json['newRedeemBalance'] as String?,
  );
}

Map<String, dynamic> _$CalcHomaRedeemAmountToJson(
        CalcHomaRedeemAmount instance) =>
    <String, dynamic>{
      'fee': instance.fee,
      'expected': instance.expected,
      'newRedeemBalance': instance.newRedeemBalance,
    };

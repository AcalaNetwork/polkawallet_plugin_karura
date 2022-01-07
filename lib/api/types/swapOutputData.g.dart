// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swapOutputData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SwapOutputData _$SwapOutputDataFromJson(Map<String, dynamic> json) {
  return SwapOutputData()
    ..path = json['path'] as List<dynamic>?
    ..amount = (json['amount'] as num).toDouble()
    ..priceImpact = (json['priceImpact'] as num).toDouble()
    ..fee = (json['fee'] as num).toDouble();
}

Map<String, dynamic> _$SwapOutputDataToJson(SwapOutputData instance) =>
    <String, dynamic>{
      'path': instance.path,
      'amount': instance.amount,
      'priceImpact': instance.priceImpact,
      'fee': instance.fee,
    };

LPTokenData _$LPTokenDataFromJson(Map<String, dynamic> json) {
  return LPTokenData()
    ..currencyId =
        (json['currencyId'] as List<dynamic>).map((e) => e as String).toList()
    ..free = json['free'] as String?;
}

Map<String, dynamic> _$LPTokenDataToJson(LPTokenData instance) =>
    <String, dynamic>{
      'currencyId': instance.currencyId,
      'free': instance.free,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swapOutputData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SwapOutputData _$SwapOutputDataFromJson(Map<String, dynamic> json) {
  return SwapOutputData()
    ..path = (json['path'] as List<dynamic>?)
        ?.map((e) => PathData.fromJson(e as Map<String, dynamic>))
        .toList()
    ..amount = (json['amount'] as num?)?.toDouble()
    ..priceImpact = (json['priceImpact'] as List<dynamic>?)
        ?.map((e) => (e as num).toDouble())
        .toList()
    ..fee = (json['fee'] as List<dynamic>?)
        ?.map((e) => (e as num).toDouble())
        .toList()
    ..feeToken =
        (json['feeToken'] as List<dynamic>?)?.map((e) => e as String).toList()
    ..tx = json['tx'] as Map<String, dynamic>?;
}

Map<String, dynamic> _$SwapOutputDataToJson(SwapOutputData instance) =>
    <String, dynamic>{
      'path': instance.path?.map((e) => e.toJson()).toList(),
      'amount': instance.amount,
      'priceImpact': instance.priceImpact,
      'fee': instance.fee,
      'feeToken': instance.feeToken,
      'tx': instance.tx,
    };

PathData _$PathDataFromJson(Map<String, dynamic> json) {
  return PathData()
    ..path = (json['path'] as List<dynamic>?)?.map((e) => e as String).toList()
    ..dex = json['dex'] as String?;
}

Map<String, dynamic> _$PathDataToJson(PathData instance) => <String, dynamic>{
      'path': instance.path,
      'dex': instance.dex,
    };

LPTokenData _$LPTokenDataFromJson(Map<String, dynamic> json) {
  return LPTokenData()
    ..currencyId =
        (json['currencyId'] as List<dynamic>?)?.map((e) => e as String).toList()
    ..free = json['free'] as String?;
}

Map<String, dynamic> _$LPTokenDataToJson(LPTokenData instance) =>
    <String, dynamic>{
      'currencyId': instance.currencyId,
      'free': instance.free,
    };

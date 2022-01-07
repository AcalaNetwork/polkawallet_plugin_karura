import 'package:json_annotation/json_annotation.dart';

part 'homaRedeemAmountData.g.dart';

@JsonSerializable()
class HomaRedeemAmountData extends _HomaRedeemAmountData {
  static HomaRedeemAmountData fromJson(Map json) =>
      _$HomaRedeemAmountDataFromJson(json as Map<String, dynamic>);
}

abstract class _HomaRedeemAmountData {
  int? atEra;
  double? amount;
  double? demand;
  double? fee;
  double? received;
}

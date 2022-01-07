import 'package:json_annotation/json_annotation.dart';

part 'calcHomaRedeemAmount.g.dart';

@JsonSerializable()
class CalcHomaRedeemAmount {
  String? fee;
  String? expected;
  String? newRedeemBalance;

  CalcHomaRedeemAmount(this.fee, this.expected, this.newRedeemBalance);

  factory CalcHomaRedeemAmount.fromJson(Map<String, dynamic> json) =>
      _$CalcHomaRedeemAmountFromJson(json);

  Map<String, dynamic> toJson() => _$CalcHomaRedeemAmountToJson(this);
}

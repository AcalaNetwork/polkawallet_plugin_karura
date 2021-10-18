import 'package:json_annotation/json_annotation.dart';

part 'calcHomaRedeemAmount.g.dart';

@JsonSerializable()
class CalcHomaRedeemAmount {
  String fee;
  String expected;

  CalcHomaRedeemAmount(this.fee, this.expected);

  factory CalcHomaRedeemAmount.fromJson(Map<String, dynamic> json) =>
      _$CalcHomaRedeemAmountFromJson(json);

  Map<String, dynamic> toJson() => _$CalcHomaRedeemAmountToJson(this);
}

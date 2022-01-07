import 'package:json_annotation/json_annotation.dart';

part 'calcHomaMintAmountData.g.dart';

@JsonSerializable()
class CalcHomaMintAmountData {
  String? fee;
  String? received;
  List<dynamic>? suggestRedeemRequests;

  CalcHomaMintAmountData(this.fee, this.received, this.suggestRedeemRequests);

  factory CalcHomaMintAmountData.fromJson(Map<String, dynamic> json) =>
      _$CalcHomaMintAmountDataFromJson(json);

  Map<String, dynamic> toJson() => _$CalcHomaMintAmountDataToJson(this);
}

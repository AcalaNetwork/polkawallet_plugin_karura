import 'package:json_annotation/json_annotation.dart';

part 'homaPendingRedeemData.g.dart';

@JsonSerializable()
class HomaPendingRedeemData {
  num? totalUnbonding;
  num? claimable;
  List<Map>? unbondings;
  Map? redeemRequest;
  int? currentRelayEra;

  HomaPendingRedeemData(
      {this.totalUnbonding,
      this.claimable,
      this.redeemRequest,
      this.currentRelayEra});

  factory HomaPendingRedeemData.fromJson(Map json) =>
      _$HomaPendingRedeemDataFromJson(json);

  Map<String, dynamic> toJson() => _$HomaPendingRedeemDataToJson(this);
}

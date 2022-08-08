import 'package:json_annotation/json_annotation.dart';

part 'taigaPoolInfoData.g.dart';

@JsonSerializable()
class TaigaPoolInfoData {
  Map<String, double> apy;
  List<String> reward;
  List<String> rewardTokens;
  String userShares;
  String totalShares;

  TaigaPoolInfoData(this.apy, this.reward, this.rewardTokens, this.totalShares,
      this.userShares);

  factory TaigaPoolInfoData.fromJson(Map<String, dynamic> json) =>
      _$TaigaPoolInfoDataFromJson(json);

  Map<String, dynamic> toJson() => _$TaigaPoolInfoDataToJson(this);
}

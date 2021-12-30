import 'package:json_annotation/json_annotation.dart';

part 'homaNewEnvData.g.dart';

@JsonSerializable()
class HomaNewEnvData {
  double totalStaking;
  double totalLiquidity;
  double exchangeRate;
  double apy;
  double fastMatchFeeRate;
  double mintThreshold;
  double redeemThreshold;
  int stakingSoftCap;
  int eraFrequency;

  HomaNewEnvData(
      this.totalStaking,
      this.totalLiquidity,
      this.exchangeRate,
      this.apy,
      this.fastMatchFeeRate,
      this.mintThreshold,
      this.redeemThreshold,
      this.stakingSoftCap,
      this.eraFrequency);

  factory HomaNewEnvData.fromJson(Map<String, dynamic> json) =>
      _$HomaNewEnvDataFromJson(json);

  Map<String, dynamic> toJson() => _$HomaNewEnvDataToJson(this);
}

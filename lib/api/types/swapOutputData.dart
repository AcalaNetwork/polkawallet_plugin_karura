import 'package:json_annotation/json_annotation.dart';

part 'swapOutputData.g.dart';

@JsonSerializable(explicitToJson: true)
class SwapOutputData extends _SwapOutputData {
  static SwapOutputData fromJson(Map json) =>
      _$SwapOutputDataFromJson(json as Map<String, dynamic>);
}

abstract class _SwapOutputData {
  List<PathData>? path;
  double? amount;
  List<double>? priceImpact;
  List<double>? fee;
  List<String>? feeToken;
  Map? tx;
  //tx:{section: aggregatedDex, method: swapWithExactSupply, params: [[{taiga: [0, 0, 1]}, {dex: [{token: LKSM}, {token: KUSD}, {foreignAsset: 2}]}], 1000000000000, 0x000000000000029248175b6cd4ca32e3]}
}

@JsonSerializable()
class PathData extends _PathData {
  static PathData fromJson(Map json) =>
      _$PathDataFromJson(json as Map<String, dynamic>);

  String toJson() => _$PathDataToJson(this).toString();
}

abstract class _PathData {
  List<String>? path;
  String? dex;
}

@JsonSerializable()
class LPTokenData extends _LPTokenData {
  static LPTokenData fromJson(Map json) =>
      _$LPTokenDataFromJson(json as Map<String, dynamic>);
}

abstract class _LPTokenData {
  List<String>? currencyId;
  String? free;
}

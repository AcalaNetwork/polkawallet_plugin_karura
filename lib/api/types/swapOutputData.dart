import 'package:json_annotation/json_annotation.dart';

part 'swapOutputData.g.dart';

@JsonSerializable(explicitToJson: true)
class SwapOutputData extends _SwapOutputData {
  static SwapOutputData fromJson(Map json) => _$SwapOutputDataFromJson(json as Map<String, dynamic>);
}

abstract class _SwapOutputData {
  List? path;
  double? amount;
  double? priceImpact;
  double? fee;
}

@JsonSerializable()
class LPTokenData extends _LPTokenData {
  static LPTokenData fromJson(Map json) => _$LPTokenDataFromJson(json as Map<String, dynamic>);
}

abstract class _LPTokenData {
  List<String>? currencyId;
  String? free;
}

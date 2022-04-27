import 'package:json_annotation/json_annotation.dart';

part 'swapPageParams.g.dart';

@JsonSerializable()
class SwapPageParams extends _SwapPageParams {
  static SwapPageParams fromJson(Map json) =>
      _$SwapPageParamsFromJson(Map<String, dynamic>.from(json));
  Map toJson() => _$SwapPageParamsToJson(this);
}

abstract class _SwapPageParams {
  String? tab;
}

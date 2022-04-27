import 'package:json_annotation/json_annotation.dart';

part 'loanPageParams.g.dart';

@JsonSerializable()
class LoanPageParams extends _LoanPageParams {
  static LoanPageParams fromJson(Map json) =>
      _$LoanPageParamsFromJson(Map<String, dynamic>.from(json));
  Map toJson() => _$LoanPageParamsToJson(this);
}

abstract class _LoanPageParams {
  String? loanType;
}

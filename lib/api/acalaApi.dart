import 'package:polkawallet_plugin_karura/api/acalaService.dart';
import 'package:polkawallet_plugin_karura/api/assets/acalaApiAssets.dart';
import 'package:polkawallet_plugin_karura/api/homa/acalaApiHoma.dart';
import 'package:polkawallet_plugin_karura/api/loan/acalaApiLoan.dart';
import 'package:polkawallet_plugin_karura/api/swap/acalaApiSwap.dart';

class AcalaApi {
  AcalaApi(AcalaService service)
      : assets = AcalaApiAssets(service.assets),
        loan = AcalaApiLoan(service.loan),
        swap = AcalaApiSwap(service.swap),
        homa = AcalaApiHoma(service.homa);

  final AcalaApiAssets assets;
  final AcalaApiLoan loan;
  final AcalaApiSwap swap;
  final AcalaApiHoma homa;
}

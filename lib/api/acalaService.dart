import 'package:polkawallet_plugin_karura/api/assets/acalaServiceAssets.dart';
import 'package:polkawallet_plugin_karura/api/earn/acalaServiceEarn.dart';
import 'package:polkawallet_plugin_karura/api/history/acalaServiceHistory.dart';
import 'package:polkawallet_plugin_karura/api/homa/acalaServiceHoma.dart';
import 'package:polkawallet_plugin_karura/api/loan/acalaServiceLoan.dart';
import 'package:polkawallet_plugin_karura/api/swap/acalaServiceSwap.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';

class AcalaService {
  AcalaService(PluginKarura plugin)
      : assets = AcalaServiceAssets(plugin),
        loan = AcalaServiceLoan(plugin),
        swap = AcalaServiceSwap(plugin),
        homa = AcalaServiceHoma(plugin),
        earn = AcalaServiceEarn(plugin),
        history = AcalaServiceHistory(plugin);

  final AcalaServiceAssets assets;
  final AcalaServiceLoan loan;
  final AcalaServiceSwap swap;
  final AcalaServiceHoma homa;
  final AcalaServiceEarn earn;
  final AcalaServiceHistory history;
}

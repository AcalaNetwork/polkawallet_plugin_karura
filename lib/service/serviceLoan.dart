import 'package:polkawallet_plugin_karura/api/acalaApi.dart';
import 'package:polkawallet_plugin_karura/api/types/homaNewEnvData.dart';
import 'package:polkawallet_plugin_karura/api/types/loanType.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/store/index.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_ui/utils/format.dart';

class ServiceLoan {
  ServiceLoan(this.plugin, this.keyring)
      : api = plugin.api,
        store = plugin.store;

  final PluginKarura plugin;
  final Keyring keyring;
  final AcalaApi? api;
  final PluginStore? store;

  void _calcLiquidTokenPrice(
      Map<String?, BigInt> prices, HomaNewEnvData homaEnv) {
    // LDOT price may lost precision here
    final relayToken = relay_chain_token_symbol;
    prices['L$relayToken'] = Fmt.tokenInt(
        (Fmt.bigIntToDouble(
                    prices[relayToken], plugin.networkState.tokenDecimals![0]) *
                homaEnv.exchangeRate)
            .toString(),
        plugin.networkState.tokenDecimals![0]);
  }

  Map<String?, LoanData> _calcLoanData(
    List loans,
    List<LoanType> loanTypes,
    Map<String?, BigInt> prices,
  ) {
    final data = Map<String?, LoanData>();
    loans.forEach((i) {
      final token = AssetsUtils.tokenDataFromCurrencyId(plugin, i['currency']);
      final loanTypeIndex = loanTypes
          .indexWhere((t) => t.token!.tokenNameId == token.tokenNameId);
      if (loanTypeIndex > -1) {
        data[token.tokenNameId] = LoanData.fromJson(
          Map<String, dynamic>.from(i),
          loanTypes[loanTypeIndex],
          prices[token.tokenNameId] ?? BigInt.zero,
          plugin,
        );
      }
    });
    return data;
  }

  Future<void> queryLoanTypes(String? address) async {
    if (address == null) return;

    await plugin.service!.earn.updateAllDexPoolInfo();
    final res = await api!.loan.queryLoanTypes();
    res?.removeWhere((e) => e.requiredCollateralRatio == BigInt.zero);
    store!.loan.setLoanTypes(res ?? []);

    queryTotalCDPs();
  }

  Future<void> subscribeAccountLoans(String? address) async {
    if (address == null) return;

    store!.loan.setLoansLoading(true);

    // 1. subscribe all token prices, callback triggers per 5s.
    api!.assets.subscribeTokenPrices((Map<String, BigInt> prices) async {
      // 2. we need homa staking pool info to calculate price of LDOT
      final homaEnv = await plugin.service!.homa.queryHomaEnv();
      _calcLiquidTokenPrice(prices, homaEnv);
      store!.assets.setPrices(prices);

      // 3. update collateral incentive rewards
      queryCollateralRewards(address);

      // 4. we need loanTypes & prices to get account loans
      final loans = await api!.loan.queryAccountLoans(address);
      if (store!.loan.loansLoading) {
        store!.loan.setLoansLoading(false);
      }
      if (loans != null &&
          loans.length > 0 &&
          store!.loan.loanTypes.length > 0 &&
          keyring.current.address == address) {
        store!.loan.setAccountLoans(
            _calcLoanData(loans, store!.loan.loanTypes, prices));
      }
    });
  }

  Future<void> queryTotalCDPs() async {
    final res = await api!.loan.queryTotalCDPs(
        store!.loan.loanTypes.map((e) => e.token!.currencyId).toList());
    store!.loan.setTotalCDPs(res);
  }

  Future<void> queryCollateralRewards(String address) async {
    final res = await api!.loan.queryCollateralRewards(address);

    // query with timer may cause account mismatch here
    if (address != keyring.current.address) return;

    store!.loan.setCollateralRewards(res);
  }

  void unsubscribeAccountLoans() {
    api!.assets.unsubscribeTokenPrices();
    store!.loan.setLoansLoading(true);
  }
}

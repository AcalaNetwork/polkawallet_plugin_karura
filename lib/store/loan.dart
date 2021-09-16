import 'package:mobx/mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/loanType.dart';
import 'package:polkawallet_plugin_karura/store/cache/storeCache.dart';

part 'loan.g.dart';

class LoanStore extends _LoanStore with _$LoanStore {
  LoanStore(StoreCache cache) : super(cache);
}

abstract class _LoanStore with Store {
  _LoanStore(this.cache);

  final StoreCache cache;

  @observable
  List<LoanType> loanTypes = [];

  @observable
  Map<String, TotalCDPData> totalCDPs = Map<String, TotalCDPData>();

  @observable
  Map<String, LoanData> loans = Map<String, LoanData>();

  @observable
  Map<String, double> collateralIncentives = Map<String, double>();

  @observable
  Map<String, CollateralRewardData> collateralRewards =
      Map<String, CollateralRewardData>();

  @observable
  Map<String, CollateralRewardDataV2> collateralRewardsV2 =
      Map<String, CollateralRewardDataV2>();

  @observable
  Map<String, double> loyaltyBonus = Map<String, double>();

  @observable
  bool loansLoading = true;

  @action
  void setLoanTypes(List<LoanType> list) {
    loanTypes = list;
  }

  @action
  void setTotalCDPs(List<TotalCDPData> list) {
    final dataMap = Map<String, TotalCDPData>();
    list.forEach((e) {
      dataMap[e.token] = e;
    });
    totalCDPs = dataMap;
  }

  @action
  void setCollateralIncentives(
      Map<String, double> data, Map<String, double> bonus) {
    collateralIncentives = data;
    loyaltyBonus = bonus;
  }

  @action
  void setCollateralRewards(List<CollateralRewardData> data) {
    final dataMap = Map<String, CollateralRewardData>();
    data.forEach((e) {
      dataMap[e.token] = e;
    });
    collateralRewards = dataMap;
  }

  @action
  void setCollateralRewardsV2(List<CollateralRewardDataV2> data) {
    final dataMap = Map<String, CollateralRewardDataV2>();
    data.forEach((e) {
      dataMap[e.token] = e;
    });
    collateralRewardsV2 = dataMap;
  }

  @action
  void setAccountLoans(Map<String, LoanData> data) {
    loans = data;
  }

  @action
  void setLoansLoading(bool loading) {
    loansLoading = loading;
  }

  @action
  void loadCache(String pubKey) {
    if (pubKey == null || pubKey.isEmpty) return;

    setAccountLoans(Map<String, LoanData>());
  }
}

import 'package:mobx/mobx.dart';
import 'package:polkawallet_plugin_karura/store/cache/storeCache.dart';
import 'package:polkawallet_sdk/api/types/gov/proposalInfoData.dart';
import 'package:polkawallet_sdk/api/types/gov/referendumInfoData.dart';
import 'package:polkawallet_sdk/api/types/gov/treasuryOverviewData.dart';
import 'package:polkawallet_sdk/api/types/gov/treasuryTipData.dart';

part 'governance.g.dart';

class GovernanceStore extends _GovernanceStore with _$GovernanceStore {
  GovernanceStore(StoreCache? cache) : super(cache);
}

abstract class _GovernanceStore with Store {
  _GovernanceStore(this.cache);

  final StoreCache? cache;

  @observable
  BigInt bestNumber = BigInt.zero;

  @observable
  List<ReferendumInfo>? referendums;

  @observable
  List? voteConvictions;

  @observable
  List<ProposalInfoData> proposals = [];

  TreasuryOverviewData treasuryOverview = TreasuryOverviewData();

  late List<TreasuryTipData> treasuryTips;

  @action
  void setBestNumber(BigInt number) {
    bestNumber = number;
  }

  @action
  void setReferendums(List<ReferendumInfo> ls) {
    referendums = ls;
  }

  @action
  void setReferendumVoteConvictions(List? ls) {
    voteConvictions = ls;
  }

  @action
  void setProposals(List<ProposalInfoData> ls) {
    proposals = ls;
  }

  void setTreasuryOverview(TreasuryOverviewData data) {
    treasuryOverview = data;
  }

  void setTreasuryTips(List<TreasuryTipData> data) {
    treasuryTips = data;
  }

  @action
  void clearState() {
    referendums = [];
    proposals = [];
    treasuryOverview = TreasuryOverviewData();
    treasuryTips = [];
  }
}

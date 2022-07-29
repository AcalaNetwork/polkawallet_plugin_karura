import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:polkawallet_plugin_karura/api/types/txIncentiveData.dart';
import 'package:polkawallet_plugin_karura/pages/earnNew/earnTxDetailPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/TransferIcon.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginPopLoadingWidget.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginFilterWidget.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class EarnHistoryPage extends StatefulWidget {
  EarnHistoryPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/earn/txs';

  @override
  State<EarnHistoryPage> createState() => _EarnHistoryPageState();
}

class _EarnHistoryPageState extends State<EarnHistoryPage> {
  String filterString = PluginFilterWidget.pluginAllFilter;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.plugin.service?.history.getEarns();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;

    return PluginScaffold(
        appBar: PluginAppBar(
          title: Text(dic['loan.txs']!),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Observer(
            builder: (_) {
              final originList = widget.plugin.store?.history.earns;
              if (originList == null) {
                return PluginPopLoadingContainer(loading: true);
              }

              final list;
              switch (filterString) {
                case TxDexIncentiveData.actionStakeFilter:
                  list = originList
                      .where((element) =>
                          element.event == TxDexIncentiveData.actionStake)
                      .toList();
                  break;
                case TxDexIncentiveData.actionUnStakeFilter:
                  list = originList
                      .where((element) =>
                          element.event == TxDexIncentiveData.actionUnStake)
                      .toList();
                  break;
                case TxDexIncentiveData.actionClaimRewardsFilter:
                  list = originList
                      .where((element) =>
                          element.event ==
                          TxDexIncentiveData.actionClaimRewards)
                      .toList();
                  break;
                case TxDexIncentiveData.actionPayoutRewardsFilter:
                  list = originList
                      .where((element) =>
                          element.event ==
                          TxDexIncentiveData.actionPayoutRewards)
                      .toList();
                  break;
                default:
                  list = originList;
              }

              return Column(children: [
                PluginFilterWidget(
                  options: [
                    PluginFilterWidget.pluginAllFilter,
                    TxDexIncentiveData.actionStakeFilter,
                    TxDexIncentiveData.actionUnStakeFilter,
                    TxDexIncentiveData.actionClaimRewardsFilter,
                  ],
                  filter: (option) {
                    setState(() {
                      filterString = option;
                    });
                  },
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: list.length + 1,
                    itemBuilder: (BuildContext context, int i) {
                      if (i == list.length) {
                        return ListTail(
                          isEmpty: list.length == 0,
                          isLoading: false,
                          color: Colors.white,
                        );
                      }

                      final history = list[i];
                      final detail = TxDexIncentiveData.fromHistory(
                          history, widget.plugin);

                      TransferIconType icon = TransferIconType.unstake;
                      switch (detail.event) {
                        case TxDexIncentiveData.actionStake:
                          icon = TransferIconType.stake;
                          break;
                        case TxDexIncentiveData.actionClaimRewards:
                        case TxDexIncentiveData.actionPayoutRewards:
                          icon = TransferIconType.claim_rewards;
                          break;
                        case TxDexIncentiveData.actionUnStake:
                          break;
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: Color(0x14ffffff),
                          border: Border(
                              bottom: BorderSide(
                                  width: 0.5, color: Color(0x24ffffff))),
                        ),
                        child: ListTile(
                          dense: true,
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dic[earn_actions_map[detail.event]] ?? "",
                                style: Theme.of(context)
                                    .textTheme
                                    .headline5
                                    ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                              ),
                              Text(history.message ?? "",
                                  textAlign: TextAlign.start,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headline5
                                      ?.copyWith(color: Colors.white))
                            ],
                          ),
                          subtitle: Text(
                              Fmt.dateTime(DateFormat("yyyy-MM-ddTHH:mm:ss")
                                  .parse(detail.time, true)),
                              style: Theme.of(context)
                                  .textTheme
                                  .headline5
                                  ?.copyWith(
                                      color: Colors.white,
                                      fontSize: UI.getTextSize(10, context))),
                          leading: TransferIcon(
                              type: icon, bgColor: Color(0x57FFFFFF)),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              EarnTxDetailPage.route,
                              arguments: detail,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ]);
            },
          ),
        ));
  }
}

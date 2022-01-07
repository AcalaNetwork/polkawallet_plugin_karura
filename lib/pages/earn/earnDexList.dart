import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_karura/pages/earn/earnDetailPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/currencyWithIcon.dart';
import 'package:polkawallet_ui/components/infoItem.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/utils/format.dart';

class EarnDexList extends StatefulWidget {
  EarnDexList(this.plugin);
  final PluginKarura plugin;

  @override
  _EarnDexListState createState() => _EarnDexListState();
}

class _EarnDexListState extends State<EarnDexList> {
  Timer? _timer;

  bool _loading = true;

  Future<void> _fetchData() async {
    await widget.plugin.service!.earn.updateAllDexPoolInfo();

    widget.plugin.service!.gov.updateBestNumber();
    if (mounted) {
      setState(() {
        _loading = false;
      });

      _timer = Timer(Duration(seconds: 30), () {
        _fetchData();
      });
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala');

    return Observer(builder: (_) {
      var dexPools = widget.plugin.store!.earn.dexPools.toList();
      dexPools.retainWhere((e) => e.provisioning == null);

      final incentivesV2 = widget.plugin.store!.earn.incentives;
      if (dexPools.length > 0) {
        final List<DexPoolData> datas = [];
        final List<DexPoolData> otherDatas = [];
        for (int i = 0; i < dexPools.length; i++) {
          double rewards = 0;
          double savingRewards = 0;
          double? loyaltyBonus = 0;
          double? savingLoyaltyBonus = 0;

          if (incentivesV2.dex != null) {
            (incentivesV2.dex![dexPools[i].tokenNameId!] ?? []).forEach((e) {
              rewards += e.apr;
              loyaltyBonus = e.deduction;
            });
            (incentivesV2.dexSaving[dexPools[i].tokenNameId!] ?? [])
                .forEach((e) {
              savingRewards += e.apr;
              savingLoyaltyBonus = e.deduction;
            });
          }

          dexPools[i].rewards = rewards + savingRewards;
          dexPools[i].rewardsLoyalty = rewards * (1 - loyaltyBonus!) +
              savingRewards * (1 - savingLoyaltyBonus!);

          if (dexPools[i].tokenNameId!.indexOf("KAR") >= 0) {
            datas.add(dexPools[i]);
          } else {
            otherDatas.add(dexPools[i]);
          }
        }

        otherDatas.sort((left, right) => right.rewards!.compareTo(left.rewards!));
        datas.addAll(otherDatas);
        dexPools = datas;
      }
      return dexPools.length == 0
          ? ListView(
              padding: EdgeInsets.all(16),
              children: [
                Center(
                  child: Container(
                    height: MediaQuery.of(context).size.width,
                    child: ListTail(isEmpty: true, isLoading: _loading),
                  ),
                )
              ],
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: dexPools.length,
              itemBuilder: (_, i) {
                final poolToken = AssetsUtils.getBalanceFromTokenNameId(
                    widget.plugin, dexPools[i].tokenNameId)!;

                final BigInt sharesTotal = widget.plugin.store!.earn
                        .dexPoolInfoMap[dexPools[i].tokenNameId]?.sharesTotal ??
                    BigInt.zero;

                final rewardsEmpty = incentivesV2.dex == null;

                final poolInfo = widget
                    .plugin.store!.earn.dexPoolInfoMap[dexPools[i].tokenNameId];
                return GestureDetector(
                  child: RoundedCard(
                    margin: EdgeInsets.only(bottom: 16),
                    padding: EdgeInsets.all(16),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Visibility(
                            visible: (poolInfo?.shares ?? BigInt.zero) !=
                                BigInt.zero,
                            child: Image.asset(
                              "packages/polkawallet_plugin_karura/assets/images/staked.png",
                              width: 35,
                            )),
                        Column(
                          children: [
                            CurrencyWithIcon(
                              PluginFmt.tokenView(poolToken.symbol ?? ''),
                              TokenIcon(poolToken.symbol ?? '',
                                  widget.plugin.tokenIcons),
                              textStyle: Theme.of(context).textTheme.headline4,
                              mainAxisAlignment: MainAxisAlignment.center,
                            ),
                            Divider(height: 24),
                            Text(
                              Fmt.token(sharesTotal, poolToken.decimals ?? 18),
                              style: Theme.of(context).textTheme.headline4,
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 4),
                              child: Text('staked'),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  InfoItem(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    title: dic!['earn.apy'],
                                    content: rewardsEmpty
                                        ? '--.--%'
                                        : Fmt.ratio(dexPools[i].rewards),
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  InfoItem(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    title: dic['earn.apy.0'],
                                    content: rewardsEmpty
                                        ? '--.--%'
                                        : Fmt.ratio(dexPools[i].rewardsLoyalty),
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  onTap: () => Navigator.of(context)
                      .pushNamed(EarnDetailPage.route, arguments: dexPools[i]),
                );
              },
            );
    });
  }
}

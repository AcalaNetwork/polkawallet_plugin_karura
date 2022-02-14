import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_karura/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/earn/earnDetailPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTokenIcon.dart';
import 'package:polkawallet_ui/components/v3/plugin/roundedPluginCard.dart';
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
              rewards += e.apr ?? 0;
              loyaltyBonus = e.deduction;
            });
            (incentivesV2.dexSaving[dexPools[i].tokenNameId!] ?? [])
                .forEach((e) {
              savingRewards += e.apr ?? 0;
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

        datas.sort((left, right) => right.rewards!.compareTo(left.rewards!));
        otherDatas
            .sort((left, right) => right.rewards!.compareTo(left.rewards!));
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
                    child: ListTail(
                      isEmpty: true,
                      isLoading: _loading,
                      color: Colors.white,
                    ),
                  ),
                )
              ],
            )
          : GridView.builder(
              padding: EdgeInsets.all(16),
              itemCount: dexPools.length,
              itemBuilder: (_, i) {
                final tokenPair = dexPools[i]
                    .tokens!
                    .map((e) =>
                        AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
                    .toList();
                final tokenSymbol = tokenPair.map((e) => e!.symbol).join('-');

                final rewardsEmpty = incentivesV2.dex == null;

                final poolInfo = widget
                    .plugin.store!.earn.dexPoolInfoMap[dexPools[i].tokenNameId];
                final leftPrice = Fmt.bigIntToDouble(
                        poolInfo?.amountLeft ?? BigInt.zero,
                        tokenPair[0]!.decimals!) *
                    widget.plugin.store!.assets
                        .marketPrices[tokenPair[0]!.symbol]!;
                final rightPrice = Fmt.bigIntToDouble(
                        poolInfo?.amountRight ?? BigInt.zero,
                        tokenPair[1]!.decimals!) *
                    widget.plugin.store!.assets
                        .marketPrices[tokenPair[1]!.symbol]!;

                bool canClaim = false;
                double? savingLoyaltyBonus = 0;
                final incentiveV2 = widget.plugin.store!.earn.incentives;
                if (incentiveV2.dex != null) {
                  (incentiveV2.dexSaving[dexPools[i].tokenNameId!] ?? [])
                      .forEach((e) {
                    savingLoyaltyBonus = e.deduction;
                  });
                }
                var rewardSaving = (poolInfo?.reward?.saving ?? 0) *
                    (1 - (savingLoyaltyBonus ?? 0));
                if (rewardSaving < 0) {
                  rewardSaving = 0;
                }
                final savingRewardTokenMin = Fmt.balanceDouble(
                    widget.plugin.store!.assets
                        .tokenBalanceMap[karura_stable_coin]!.minBalance!,
                    widget.plugin.networkState.tokenDecimals![widget
                        .plugin.networkState.tokenSymbol!
                        .indexOf(karura_stable_coin)]);
                canClaim = rewardSaving > savingRewardTokenMin;

                (poolInfo?.reward?.incentive ?? []).forEach((e) {
                  final amount = double.parse(e['amount']);
                  if (amount > 0.001) {
                    canClaim = true;
                  }
                });

                bool unstaked = false;
                final balance = AssetsUtils.getBalanceFromTokenNameId(
                    widget.plugin, dexPools[i].tokenNameId);
                if (balance != null &&
                    Fmt.balanceInt(balance.amount) > BigInt.zero) {
                  unstaked = true;
                }

                return GestureDetector(
                  child: RoundedPluginCard(
                      borderRadius:
                          const BorderRadius.all(const Radius.circular(9)),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(9),
                                  topRight: Radius.circular(9)),
                            ),
                            padding: EdgeInsets.only(
                                left: 12, top: 7, right: 8, bottom: 9),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                PluginTokenIcon(
                                  tokenSymbol,
                                  widget.plugin.tokenIcons,
                                  size: 24,
                                ),
                                Row(
                                  children: [
                                    Visibility(
                                        visible: unstaked,
                                        child: Padding(
                                            padding: EdgeInsets.only(left: 4),
                                            child: Image.asset(
                                              "packages/polkawallet_plugin_karura/assets/images/unstaked.png",
                                              width: 24,
                                            ))),
                                    Visibility(
                                        visible:
                                            (poolInfo?.shares ?? BigInt.zero) !=
                                                BigInt.zero,
                                        child: Padding(
                                            padding: EdgeInsets.only(left: 4),
                                            child: SvgPicture.asset(
                                              "packages/polkawallet_plugin_karura/assets/images/staked.svg",
                                              color: Colors.white,
                                              width: 24,
                                            ))),
                                    Visibility(
                                        visible: canClaim,
                                        child: Padding(
                                            padding: EdgeInsets.only(left: 4),
                                            child: Image.asset(
                                              "packages/polkawallet_plugin_karura/assets/images/rewards.png",
                                              width: 24,
                                            ))),
                                  ],
                                )
                              ],
                            ),
                          ),
                          Expanded(
                              child: Container(
                            width: double.infinity,
                            padding:
                                EdgeInsets.only(left: 12, top: 6, right: 12),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(9),
                                    bottomRight: Radius.circular(9)),
                                color: Color(0xFF494b4e)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  PluginFmt.tokenView(tokenSymbol),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headline4
                                      ?.copyWith(
                                          color: Color(0xBDFFFFFF),
                                          fontWeight: FontWeight.w600),
                                ),
                                Padding(
                                    padding: EdgeInsets.only(top: 17),
                                    child: Text(
                                      dic!['earn.apy']!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline3
                                          ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              height: 1.0,
                                              fontSize: 24),
                                    )),
                                Text(
                                  rewardsEmpty
                                      ? '--.--%'
                                      : Fmt.ratio(dexPools[i].rewards),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headline3
                                      ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          height: 1.0,
                                          fontSize: 24),
                                ),
                                Text(
                                  'TVL \$ ${Fmt.priceCeil(leftPrice + rightPrice)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headline5
                                      ?.copyWith(color: Color(0xBDFFFFFF)),
                                ),
                                // Container(
                                //   margin: EdgeInsets.only(top: 4),
                                //   child: Text('staked'),
                                // ),
                                // Container(
                                //   margin: EdgeInsets.only(top: 8),
                                //   child: Row(
                                //     children: [
                                //       InfoItem(
                                //         crossAxisAlignment:
                                //             CrossAxisAlignment.center,
                                //         title: dic!['earn.apy'],
                                //         content: rewardsEmpty
                                //             ? '--.--%'
                                //             : Fmt.ratio(dexPools[i].rewards),
                                //         color: Theme.of(context).primaryColor,
                                //       ),
                                //       InfoItem(
                                //         crossAxisAlignment:
                                //             CrossAxisAlignment.center,
                                //         title: dic['earn.apy.0'],
                                //         content: rewardsEmpty
                                //             ? '--.--%'
                                //             : Fmt.ratio(
                                //                 dexPools[i].rewardsLoyalty),
                                //         color: Theme.of(context).primaryColor,
                                //       ),
                                //     ],
                                //   ),
                                // ),
                              ],
                            ),
                          )),
                        ],
                      )),
                  onTap: () => Navigator.of(context)
                      .pushNamed(EarnDetailPage.route, arguments: dexPools[i]),
                );
              },
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 20,
                  childAspectRatio: 168 / 176.0),
            );
    });
  }
}

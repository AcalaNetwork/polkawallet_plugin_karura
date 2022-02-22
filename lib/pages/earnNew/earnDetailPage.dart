import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:polkawallet_plugin_karura/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/common/constants/subQuery.dart';
import 'package:polkawallet_plugin_karura/pages/earnNew/LPStakePage.dart';
import 'package:polkawallet_plugin_karura/pages/earnNew/RewardsChart.dart';
import 'package:polkawallet_plugin_karura/pages/earnNew/inviteFriendsPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInfoItem.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginOutlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTagCard.dart';
import 'package:polkawallet_ui/components/v3/plugin/roundedPluginCard.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';

class EarnDetailPage extends StatelessWidget {
  EarnDetailPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/earn/detail';

  Future<void> _onStake(
      BuildContext context, String action, DexPoolData pool) async {
    Navigator.of(context).pushNamed(
      LPStakePage.route,
      arguments: LPStakePageParams(pool, action),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    final symbols = plugin.networkState.tokenSymbol;

    final DexPoolData pool =
        ModalRoute.of(context)!.settings.arguments as DexPoolData;
    final balancePair = pool.tokens!
        .map((e) => AssetsUtils.tokenDataFromCurrencyId(plugin, e))
        .toList();
    return PluginScaffold(
      appBar: PluginAppBar(
          title: Text(
              PluginFmt.tokenView(balancePair.map((e) => e!.symbol).join('-'))),
          centerTitle: true),
      body: Observer(
        builder: (_) {
          BigInt? issuance = BigInt.zero;
          BigInt? shareTotal = BigInt.zero;
          BigInt? share = BigInt.zero;
          double stakeShare = 0;
          double poolShare = 0;

          String lpAmountString = '~';

          final poolInfo = plugin.store!.earn.dexPoolInfoMap[pool.tokenNameId];
          double leftPrice = 0, rightPrice = 0;

          if (poolInfo != null) {
            issuance = poolInfo.issuance;
            shareTotal = poolInfo.sharesTotal;
            share = poolInfo.shares;
            stakeShare = share! / shareTotal!;
            poolShare = share / issuance!;

            final lpAmount = Fmt.bigIntToDouble(
                    poolInfo.amountLeft, balancePair[0]!.decimals!) *
                poolShare;
            final lpAmount2 = Fmt.bigIntToDouble(
                    poolInfo.amountRight, balancePair[1]!.decimals!) *
                poolShare;

            leftPrice = Fmt.bigIntToDouble(
                    poolInfo.amountLeft, balancePair[0]!.decimals!) *
                plugin.store!.assets.marketPrices[balancePair[0]!.symbol]!;

            rightPrice = Fmt.bigIntToDouble(
                    poolInfo.amountRight, balancePair[1]!.decimals!) *
                plugin.store!.assets.marketPrices[balancePair[1]!.symbol]!;

            lpAmountString =
                '${Fmt.priceFloor(lpAmount)} ${PluginFmt.tokenView(balancePair[0]!.symbol)} + ${Fmt.priceFloor(lpAmount2)} ${PluginFmt.tokenView(balancePair[1]!.symbol)}';
          }

          double rewardAPR = 0;
          double savingRewardAPR = 0;
          double? loyaltyBonus = 0;
          double? savingLoyaltyBonus = 0;
          final incentiveV2 = plugin.store!.earn.incentives;
          if (incentiveV2.dex != null) {
            (incentiveV2.dex![pool.tokenNameId!] ?? []).forEach((e) {
              rewardAPR += e.apr ?? 0;
              loyaltyBonus = e.deduction;
            });
            (incentiveV2.dexSaving[pool.tokenNameId!] ?? []).forEach((e) {
              savingRewardAPR += e.apr ?? 0;
              savingLoyaltyBonus = e.deduction;
            });
          }

          final balance = Fmt.balanceInt(
              plugin.store!.assets.tokenBalanceMap[pool.tokenNameId]?.amount ??
                  '0');

          return SafeArea(
              child: Stack(
            children: [
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                      child: Column(
                    children: <Widget>[
                      PluginTagCard(
                        titleTag: dic['v3.earn.totalValueLocked'],
                        radius: const Radius.circular(14),
                        backgroundColor: Color(0x1AFFFFFF),
                        margin: EdgeInsets.only(bottom: 20),
                        padding: EdgeInsets.symmetric(vertical: 11),
                        child: Column(
                          children: [
                            Query(
                                options: QueryOptions(
                                  document: gql(queryPoolDetail),
                                  variables: <String, String?>{
                                    'pool': poolInfo!.tokenNameId,
                                  },
                                ),
                                builder: (
                                  QueryResult result, {
                                  Future<QueryResult?> Function()? refetch,
                                  FetchMore? fetchMore,
                                }) {
                                  if (result.data != null &&
                                      result.data!["pools"]["nodes"].length >
                                          0 &&
                                      result
                                              .data!["pools"]["nodes"][0]
                                                  ["dayData"]["nodes"]
                                              .length >
                                          0) {
                                    final List<TimeSeriesAmount> datas = [];
                                    result
                                        .data!["pools"]["nodes"][0]["dayData"]
                                            ["nodes"]
                                        .reversed
                                        .toList()
                                        .forEach((element) {
                                      datas.add(TimeSeriesAmount(
                                          DateTime.parse(element["date"]),
                                          Fmt.balanceDouble(
                                              element["tvlUSD"], 18)));
                                    });
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(left: 50),
                                          child: Text(
                                            "TVL: \$ ${Fmt.priceCeil(leftPrice + rightPrice)}; ${dic['earn.staked']}: \$ ${Fmt.priceCeil(Fmt.bigIntToDouble(shareTotal, balancePair[0]!.decimals!) * plugin.store!.assets.marketPrices[balancePair[0]!.symbol]!)}",
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline5
                                                ?.copyWith(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w600),
                                          ),
                                        ),
                                        Container(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              2.4,
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: RewardsChart.withData(datas),
                                        )
                                      ],
                                    );
                                  }
                                  return Container(
                                    alignment: Alignment.centerLeft,
                                    padding:
                                        EdgeInsets.only(left: 16, bottom: 10),
                                    child: Text(
                                      "TVL: \$ ${Fmt.priceCeil(leftPrice + rightPrice)}; ${dic['v3.earn.stakedValue']}: ",
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline5
                                          ?.copyWith(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600),
                                    ),
                                  );
                                }),
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              color: Color(0xFF494b4e),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      PluginInfoItem(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        title: 'APR',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline5
                                            ?.copyWith(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600),
                                        titleStyle: Theme.of(context)
                                            .textTheme
                                            .headline5
                                            ?.copyWith(color: Colors.white),
                                        content: Fmt.ratio(
                                            rewardAPR + savingRewardAPR),
                                      ),
                                      PluginInfoItem(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        title: dic['v3.earn.extraEarn'],
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline5
                                            ?.copyWith(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600),
                                        titleStyle: Theme.of(context)
                                            .textTheme
                                            .headline5
                                            ?.copyWith(color: Colors.white),
                                        content: Fmt.ratio(
                                            plugin.service!.earn.getSwapFee()),
                                      ),
                                      PluginInfoItem(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        title: '${dic['v3.earn.staked']} LP',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline5
                                            ?.copyWith(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600),
                                        titleStyle: Theme.of(context)
                                            .textTheme
                                            .headline5
                                            ?.copyWith(color: Colors.white),
                                        content: Fmt.priceFloorBigInt(
                                            share, balancePair[0]!.decimals!,
                                            lengthFixed: 4),
                                      ),
                                      PluginInfoItem(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        title: '${dic['earn.share']} LP',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline5
                                            ?.copyWith(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600),
                                        titleStyle: Theme.of(context)
                                            .textTheme
                                            .headline5
                                            ?.copyWith(color: Colors.white),
                                        content: Fmt.ratio(
                                            shareTotal > BigInt.zero
                                                ? share / shareTotal
                                                : 0),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(
                                        top: 12, bottom: 6, left: 27),
                                    child: Row(
                                      children: [
                                        Padding(
                                            padding: EdgeInsets.only(top: 1),
                                            child: Image.asset(
                                                'packages/polkawallet_plugin_karura/assets/images/info.png',
                                                width: 14)),
                                        Padding(
                                          padding: EdgeInsets.only(left: 2),
                                          child: Text(
                                              "${dic['v3.earn.stakedLpInfo']}: $lpAmountString",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline5
                                                  ?.copyWith(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Padding(
                                padding: EdgeInsets.only(
                                    left: 10, right: 10, top: 13),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: PluginOutlinedButtonSmall(
                                        content: dic['earn.stake']!,
                                        margin: EdgeInsets.zero,
                                        active: balance > BigInt.zero,
                                        color: Color(0xFFFF7849),
                                        onPressed: balance > BigInt.zero
                                            ? () => _onStake(context,
                                                LPStakePage.actionStake, pool)
                                            : null,
                                      ),
                                    ),
                                    Container(width: 20),
                                    Expanded(
                                      child: PluginOutlinedButtonSmall(
                                        active: share > BigInt.zero,
                                        margin: EdgeInsets.zero,
                                        color: Color(0xFFFF7849),
                                        content: dic['earn.unStake']!,
                                        onPressed: share > BigInt.zero
                                            ? () => _onStake(context,
                                                LPStakePage.actionUnStake, pool)
                                            : null,
                                      ),
                                    )
                                  ],
                                ))
                          ],
                        ),
                      ),
                      _UserCard(
                          plugin: plugin,
                          share: stakeShare,
                          poolInfo: poolInfo,
                          poolSymbol: pool.tokens!
                              .map((e) => AssetsUtils.tokenDataFromCurrencyId(
                                      plugin, e)!
                                  .symbol)
                              .join('-'),
                          rewardAPY: rewardAPR,
                          rewardSavingAPY: savingRewardAPR,
                          loyaltyBonus: loyaltyBonus,
                          savingLoyaltyBonus: savingLoyaltyBonus,
                          fee: plugin.service!.earn.getSwapFee(),
                          incentiveCoinSymbol: symbols![0],
                          stableCoinSymbol: karura_stable_coin,
                          stableCoinDecimal: plugin.networkState.tokenDecimals![
                              symbols.indexOf(karura_stable_coin)],
                          bestNumber: plugin.store!.gov.bestNumber,
                          dexIncentiveLoyaltyEndBlock: this
                              .plugin
                              .store!
                              .earn
                              .dexIncentiveLoyaltyEndBlock),
                    ],
                  ))),
              InviteFriendsBtn(
                  onTap: () => Navigator.of(context)
                      .pushNamed(InviteFriendsPage.route, arguments: pool)),
            ],
          ));
        },
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  _UserCard({
    this.plugin,
    this.share,
    this.poolInfo,
    this.poolSymbol,
    this.rewardAPY,
    this.rewardSavingAPY,
    this.loyaltyBonus,
    this.savingLoyaltyBonus,
    this.fee,
    this.incentiveCoinSymbol,
    this.stableCoinSymbol,
    this.stableCoinDecimal,
    this.bestNumber,
    this.dexIncentiveLoyaltyEndBlock,
  });
  final PluginKarura? plugin;
  final double? share;
  final DexPoolInfoData? poolInfo;
  final String? poolSymbol;
  final double? rewardAPY;
  final double? rewardSavingAPY;
  final double? loyaltyBonus;
  final double? savingLoyaltyBonus;
  final double? fee;
  final String? incentiveCoinSymbol;
  final String? stableCoinSymbol;
  final int? stableCoinDecimal;
  final BigInt? bestNumber;
  final List<dynamic>? dexIncentiveLoyaltyEndBlock;

  Future<void> _onClaim(BuildContext context, String rewardV2,
      double rewardSaving, dynamic blocksToEnd) async {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    if (loyaltyBonus != 0) {
      showCupertinoDialog(
          context: context,
          builder: (_) {
            return CupertinoAlertDialog(
              title: Text(dic['earn.claim']!),
              content: Text.rich(TextSpan(children: [
                TextSpan(
                    text: I18n.of(context)!.locale.toString().contains('zh')
                        ? "即刻领取收益将造成"
                        : "The immediate claim will burn ",
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        ?.copyWith(color: Colors.black, fontSize: 13)),
                TextSpan(
                    text: Fmt.ratio(loyaltyBonus),
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        ?.copyWith(color: Color(0xFFFF3B30), fontSize: 13)),
                TextSpan(
                    text: I18n.of(context)!.locale.toString().contains('zh')
                        ? "的收益损失。"
                        : " of the total rewards.You will be able to claim the full reward in ",
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        ?.copyWith(color: Colors.black, fontSize: 13)),
                TextSpan(
                    text: Fmt.blockToTime(blocksToEnd ?? 0, 12500,
                        locale: I18n.of(context)!.locale.toString()),
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        ?.copyWith(color: Color(0xFFFF3B30), fontSize: 13)),
                I18n.of(context)!.locale.toString().contains('zh')
                    ? TextSpan(
                        text: "后，您可以领取全额收益",
                        style: Theme.of(context)
                            .textTheme
                            .bodyText1
                            ?.copyWith(color: Colors.black, fontSize: 13))
                    : TextSpan(),
              ])),
              actions: <Widget>[
                CupertinoDialogAction(
                  child: Text(dic['homa.redeem.cancel']!),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                CupertinoDialogAction(
                  child: Text(dic['homa.confirm']!),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _onWithdrawReward(context, rewardV2, rewardSaving);
                  },
                )
              ],
            );
          });
    } else {
      _onWithdrawReward(context, rewardV2, rewardSaving);
    }
  }

  void _onWithdrawReward(
      BuildContext context, String rewardV2, double rewardSaving) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    final DexPoolData pool =
        ModalRoute.of(context)!.settings.arguments as DexPoolData;
    final tokenPair = pool.tokens!
        .map((e) => AssetsUtils.tokenDataFromCurrencyId(plugin, e))
        .toList();
    final poolTokenSymbol =
        tokenPair.map((e) => PluginFmt.tokenView(e?.symbol)).toList().join('-');

    Navigator.of(context).pushNamed(TxConfirmPage.route,
        arguments: TxConfirmParams(
          module: 'incentives',
          call: 'claimRewards',
          txTitle: dic['earn.claim'],
          txDisplay: {
            dic['loan.amount']: '≈ $rewardV2' +
                (rewardSaving >= 0.01
                    ? ' + ${Fmt.priceFloor(rewardSaving)} $karura_stable_coin_view'
                    : ''),
            dic['earn.pool']: poolTokenSymbol,
          },
          params: [],
          rawParams: '[{Dex: {DEXShare: ${jsonEncode(pool.tokens)}}}]',
          isPlugin: true,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    bool canClaim = false;

    var rewardSaving =
        (poolInfo?.reward?.saving ?? 0) * (1 - (savingLoyaltyBonus ?? 0));
    if (rewardSaving < 0) {
      rewardSaving = 0;
    }

    final Color primary = Theme.of(context).primaryColor;
    final TextStyle primaryText = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: primary,
      letterSpacing: -0.8,
    );

    final savingRewardTokenMin = Fmt.balanceDouble(
        plugin!.store!.assets.tokenBalanceMap[stableCoinSymbol]!.minBalance!,
        stableCoinDecimal!);
    canClaim = rewardSaving > savingRewardTokenMin;
    var rewardPrice = 0.0;
    final String rewardV2 = poolInfo!.reward!.incentive.map((e) {
      double amount = double.parse(e['amount']);
      if (amount < 0) {
        amount = 0;
      }
      if (amount > 0.001) {
        canClaim = true;
      }
      rewardPrice += plugin!.store!.assets.marketPrices[e['tokenNameId']]! *
          amount *
          (1 - (loyaltyBonus ?? 0));
      return Fmt.priceFloor(amount * (1 - (loyaltyBonus ?? 0)), lengthMax: 4) +
          ' ${e['tokenNameId']}';
    }).join(' + ');

    var blockNumber;
    dexIncentiveLoyaltyEndBlock?.forEach((e) {
      if (poolSymbol == PluginFmt.getPool(plugin, e['pool'])) {
        blockNumber = e['blockNumber'];
        return;
      }
    });

    final blocksToEnd =
        blockNumber != null ? blockNumber - bestNumber!.toInt() : null;

    var reward = rewardV2.isEmpty ? '0' : rewardV2;

    final rewardsRow = <Widget>[
      Column(
        children: <Widget>[
          Text(
            dic['earn.incentive']!,
            style: TextStyle(fontSize: 12),
          ),
          Padding(
            padding: EdgeInsets.only(top: 8, bottom: 8),
            child: Text(rewardV2.isEmpty ? '0' : rewardV2, style: primaryText),
          ),
        ],
      )
    ];
    if (rewardSaving > 0) {
      reward =
          "$reward + ${Fmt.priceFloor(rewardSaving, lengthMax: 2)} $stableCoinSymbol";
      rewardPrice += rewardSaving;
      rewardsRow.add(Column(
        children: <Widget>[
          Text(
            '${dic['earn.saving']} ($stableCoinSymbol)',
            style: TextStyle(fontSize: 12),
          ),
          Padding(
            padding: EdgeInsets.only(top: 8, bottom: 8),
            child: Text(Fmt.priceFloor(rewardSaving, lengthMax: 2),
                style: primaryText),
          ),
        ],
      ));
    }

    return Visibility(
        visible: canClaim,
        child: Container(
            width: double.infinity,
            child: RoundedPluginCard(
              padding: EdgeInsets.only(top: 24, bottom: 16),
              margin: EdgeInsets.zero,
              borderRadius: const BorderRadius.all(const Radius.circular(14)),
              child: Column(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(bottom: 12),
                    child: Image.asset(
                      "packages/polkawallet_plugin_karura/assets/images/lp_detail_rewards.png",
                      width: 100,
                    ),
                  ),
                  Text(
                    "\$ ${Fmt.doubleFormat(rewardPrice)}",
                    style: Theme.of(context)
                        .textTheme
                        .headline1
                        ?.copyWith(color: Colors.white),
                  ),
                  Text(
                    reward,
                    style: Theme.of(context).textTheme.headline5?.copyWith(
                        color: Color(0xFFFFFFFF).withAlpha(178), fontSize: 12),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 20),
                    child: PluginOutlinedButtonSmall(
                        padding:
                            EdgeInsets.symmetric(horizontal: 33, vertical: 3),
                        color: Color(0xFFFF7849),
                        active: canClaim,
                        content: dic['earn.claim'],
                        onPressed: canClaim
                            ? () => _onClaim(
                                context, rewardV2, rewardSaving, blocksToEnd)
                            : null),
                  ),
                ],
              ),
            )));
  }
}

class InviteFriendsBtn extends StatefulWidget {
  InviteFriendsBtn({Key? key, this.onTap}) : super(key: key);
  Function()? onTap;

  @override
  State<InviteFriendsBtn> createState() => _InviteFriendsBtnState();
}

class _InviteFriendsBtnState extends State<InviteFriendsBtn> {
  Offset? offset;
  final GlobalKey globalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    if (offset == null) {
      offset = Offset(MediaQuery.of(context).size.width - 48, 0);
    }
    return Container(
        key: globalKey,
        child: Stack(
          children: [
            Positioned(
                left: offset!.dx,
                top: offset!.dy,
                child: GestureDetector(
                    onTap: widget.onTap,
                    onPanUpdate: (details) {
                      var dx = offset!.dx + details.delta.dx;
                      if (dx < 0) {
                        dx = 0;
                      } else if (dx >
                          globalKey.currentContext!.size!.width - 48) {
                        dx = globalKey.currentContext!.size!.width - 48;
                      }
                      var dy = offset!.dy + details.delta.dy;
                      if (dy < -40) {
                        dy = -40;
                      } else if (dy >
                          globalKey.currentContext!.size!.height - 40 - 48) {
                        dy = globalKey.currentContext!.size!.height - 40 - 48;
                      }
                      setState(() {
                        offset = Offset(dx, dy);
                      });
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      margin: EdgeInsets.only(top: 40),
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(const Radius.circular(24)),
                        color: Color(0xFFFF7849),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFF9A77),
                            blurRadius: 8.0,
                            spreadRadius: 0.0,
                            offset: Offset(
                              0.0,
                              0.0,
                            ),
                          )
                        ],
                      ),
                      child: Image.asset(
                        "packages/polkawallet_plugin_karura/assets/images/invite_icon.png",
                        width: 37,
                      ),
                    )))
          ],
        ));
  }
}

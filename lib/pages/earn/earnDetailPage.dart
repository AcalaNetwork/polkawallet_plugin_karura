import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/earn/LPStakePage.dart';
import 'package:polkawallet_plugin_karura/pages/earn/addLiquidityPage.dart';
import 'package:polkawallet_plugin_karura/pages/earn/withdrawLiquidityPage.dart';
import 'package:polkawallet_plugin_karura/pages/loan/loanPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/infoItem.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/tapTooltip.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
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
    final poolId = pool.tokenNameId;
    return Scaffold(
      appBar: AppBar(
        title: Text(dic['earn.title']!),
        centerTitle: true,
        leading: BackBtn(),
      ),
      body: Observer(
        builder: (_) {
          final balancePair = pool.tokens!
              .map((e) => AssetsUtils.tokenDataFromCurrencyId(plugin, e))
              .toList();

          BigInt? issuance = BigInt.zero;
          BigInt? shareTotal = BigInt.zero;
          BigInt? share = BigInt.zero;
          double stakeShare = 0;
          double poolShare = 0;

          String lpAmountString = '~';

          final poolInfo = plugin.store!.earn.dexPoolInfoMap[pool.tokenNameId];
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

          Color cardColor = Theme.of(context).cardColor;
          Color primaryColor = Theme.of(context).primaryColor;

          return SafeArea(
            child: AccountCardLayout(
                keyring.current,
                Column(
                  children: <Widget>[
                    Expanded(
                      child: ListView(
                        children: <Widget>[
                          _SystemCard(
                            poolSymbol:
                                balancePair.map((e) => e!.symbol).join('-'),
                            total: shareTotal,
                            userStaked: share,
                            decimals: balancePair[0]!.decimals,
                            lpAmountString: lpAmountString,
                            actions: Row(
                              children: [
                                Expanded(
                                  child: RoundedButton(
                                    color: Colors.redAccent,
                                    text: dic['earn.stake'],
                                    onPressed: balance > BigInt.zero
                                        ? () => _onStake(context,
                                            LPStakePage.actionStake, pool)
                                        : null,
                                  ),
                                ),
                                Visibility(
                                    visible: share > BigInt.zero,
                                    child: Container(width: 16)),
                                Visibility(
                                    visible: share > BigInt.zero,
                                    child: Expanded(
                                      child: RoundedButton(
                                        text: dic['earn.unStake'],
                                        onPressed: () => _onStake(context,
                                            LPStakePage.actionUnStake, pool),
                                      ),
                                    ))
                              ],
                            ),
                          ),
                          _UserCard(
                              plugin: plugin,
                              share: stakeShare,
                              poolInfo: poolInfo,
                              poolSymbol: pool.tokens!
                                  .map((e) =>
                                      AssetsUtils.tokenDataFromCurrencyId(
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
                              stableCoinDecimal:
                                  plugin.networkState.tokenDecimals![
                                      symbols.indexOf(karura_stable_coin)],
                              bestNumber: plugin.store!.gov.bestNumber,
                              dexIncentiveLoyaltyEndBlock: this
                                  .plugin
                                  .store!
                                  .earn
                                  .dexIncentiveLoyaltyEndBlock)
                        ],
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            color: Colors.redAccent,
                            child: TextButton(
                                child: Text(
                                  dic['earn.add']!,
                                  style: TextStyle(color: cardColor),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pushNamed(
                                    AddLiquidityPage.route,
                                    arguments: {'poolId': pool.tokenNameId},
                                  );
                                }),
                          ),
                        ),
                        Visibility(
                            visible: balance > BigInt.zero,
                            child: Expanded(
                              child: Container(
                                color: primaryColor,
                                child: TextButton(
                                  child: Text(
                                    dic['earn.remove']!,
                                    style: TextStyle(color: cardColor),
                                  ),
                                  onPressed: () =>
                                      Navigator.of(context).pushNamed(
                                    WithdrawLiquidityPage.route,
                                    arguments: pool,
                                  ),
                                ),
                              ),
                            )),
                      ],
                    ),
                  ],
                )),
          );
        },
      ),
    );
  }
}

class _SystemCard extends StatelessWidget {
  _SystemCard({
    this.poolSymbol,
    this.total,
    this.userStaked,
    this.decimals,
    this.lpAmountString,
    this.actions,
  });
  final String? poolSymbol;
  final BigInt? total;
  final BigInt? userStaked;
  final int? decimals;
  final String? lpAmountString;
  final Widget? actions;
  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    final primary = Theme.of(context).primaryColor;
    final TextStyle primaryText = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: primary,
      letterSpacing: -0.8,
    );
    return RoundedCard(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          Column(
            children: <Widget>[
              Text('${dic['earn.staked']} ${PluginFmt.tokenView(poolSymbol)}'),
              Padding(
                padding: EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                    Fmt.priceFloorBigInt(userStaked, decimals!, lengthFixed: 4),
                    style: primaryText),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              '≈ $lpAmountString',
              style: TextStyle(fontSize: 12),
            ),
          ),
          Row(
            children: <Widget>[
              InfoItem(
                crossAxisAlignment: CrossAxisAlignment.center,
                title: dic['earn.stake.pool'],
                content: Fmt.priceFloorBigInt(total, decimals!, lengthFixed: 4),
              ),
              InfoItem(
                crossAxisAlignment: CrossAxisAlignment.center,
                title: dic['earn.share'],
                content:
                    Fmt.ratio(total! > BigInt.zero ? userStaked! / total! : 0),
              ),
            ],
          ),
          Divider(height: 24),
          actions!
        ],
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
      double rewardSaving, bool withLoyalty) async {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala');
    if (withLoyalty) {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext ctx) {
          return CupertinoAlertDialog(
            title: Text(dic!['earn.claim']!),
            content: Text(dic['earn.claim.info']!),
            actions: <Widget>[
              CupertinoButton(
                child: Text(I18n.of(context)!
                    .getDic(i18n_full_dic_karura, 'common')!['cancel']!),
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
              ),
              CupertinoButton(
                child: Text(I18n.of(context)!
                    .getDic(i18n_full_dic_karura, 'common')!['ok']!),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _onWithdrawReward(context, rewardV2, rewardSaving);
                },
              ),
            ],
          );
        },
      );
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
    final String rewardV2 = poolInfo!.reward!.incentive.map((e) {
      final amount = double.parse(e['amount']);
      if (amount > 0.001) {
        canClaim = true;
      }
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

    return RoundedCard(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: EdgeInsets.all(16),
      child: Stack(
        alignment: AlignmentDirectional.topEnd,
        children: <Widget>[
          Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(dic['earn.reward']!),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: rewardsRow,
              ),
              Container(
                margin: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    InfoItem(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      title: 'APR',
                      content: Fmt.ratio(rewardAPY! + rewardSavingAPY!),
                    ),
                    InfoItem(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      title: dic['earn.apy.0'],
                      content: Fmt.ratio(rewardAPY! * (1 - loyaltyBonus!) +
                          rewardSavingAPY! * (1 - savingLoyaltyBonus!)),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TapTooltip(
                      message: dic['earn.fee.info']!,
                      child: Center(
                          child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info,
                            color: Theme.of(context).disabledColor,
                            size: 14,
                          ),
                          Container(
                            margin: EdgeInsets.only(left: 4),
                            child: Text(dic['earn.fee']! + ':',
                                style: TextStyle(fontSize: 12)),
                          )
                        ],
                      )),
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 8),
                      child: Text(
                        Fmt.ratio(fee),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).unselectedWidgetColor,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TapTooltip(
                      message: dic['earn.loyal.info']!,
                      child: Center(
                          child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info,
                            color: Theme.of(context).disabledColor,
                            size: 14,
                          ),
                          Container(
                            margin: EdgeInsets.only(left: 4),
                            child: Text(dic['earn.loyal']! + ':',
                                style: TextStyle(fontSize: 12)),
                          )
                        ],
                      )),
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 8),
                      child: Text(
                        Fmt.ratio(loyaltyBonus),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).unselectedWidgetColor,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Visibility(
                  visible: blocksToEnd != null && blocksToEnd > 0,
                  child: Container(
                    margin: EdgeInsets.only(top: 8),
                    child: Text(
                      '${dic['earn.loyal.end']}: ${Fmt.blockToTime(blocksToEnd, 12500)}',
                      style: TextStyle(fontSize: 10),
                    ),
                  )),
              Visibility(
                  visible: canClaim,
                  child: Container(
                    margin: EdgeInsets.only(top: 16),
                    child: RoundedButton(
                        text: dic['earn.claim'],
                        onPressed: () => _onClaim(context, rewardV2,
                            rewardSaving, loyaltyBonus != 0)),
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

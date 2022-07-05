import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_karura/pages/loanNew/loanDepositPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/infoItemRow.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginAccountInfoAction.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginOutlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTagCard.dart';
import 'package:polkawallet_ui/components/v3/plugin/roundedPluginCard.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:polkawallet_ui/pages/DAppWrapperPage.dart';

class EarnTaigaDetailPage extends StatefulWidget {
  EarnTaigaDetailPage(this.plugin, this.keyring, {Key? key}) : super(key: key);
  final Keyring keyring;
  final PluginKarura plugin;

  static const String route = '/karura/earn/taigaDetail';

  @override
  State<EarnTaigaDetailPage> createState() => _EarnTaigaDetailPageState();
}

class _EarnTaigaDetailPageState extends State<EarnTaigaDetailPage> {
  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    final argsJson = ModalRoute.of(context)!.settings.arguments as Map;
    final taigaPool =
        widget.plugin.store!.earn.taigaPoolInfoMap[argsJson['poolId']];
    final taigaData = widget.plugin.store!.earn.taigaTokenPairs
        .firstWhere((element) => element.tokenNameId == argsJson['poolId']);
    final balance = AssetsUtils.getBalanceFromTokenNameId(
        widget.plugin, argsJson['poolId']);
    final price = AssetsUtils.getMarketPrice(widget.plugin, balance.symbol!);

    final tokenPair = taigaData.tokens!
        .map((e) => AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
        .toList();

    final tokenSymbol = balance.symbol;
    var totalStaked = 0.0;
    if (tokenSymbol == "taiKSM") {
      totalStaked =
          Fmt.balanceDouble(taigaPool?.totalShares ?? "", balance.decimals!) *
              price;
    } else if (tokenSymbol == "3USD") {
      taigaData.balances!.forEach((element) {
        final index = taigaData.balances!.indexOf(element);
        totalStaked += Fmt.balanceDouble(element, tokenPair[index].decimals!);
      });
    }

    var apy = 0.0;
    taigaPool?.apy.forEach((key, value) {
      apy += value;
    });

    final labelStyle = Theme.of(context)
        .textTheme
        .headline5
        ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600);
    final valueStyle = Theme.of(context)
        .textTheme
        .headline5
        ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600);

    var canClaim = false;
    var claim = 0.0;
    List<String> claimString = [];
    taigaPool!.reward.forEach((e) {
      final index = taigaPool.reward.indexOf(e);
      final rewardBalance = AssetsUtils.getBalanceFromTokenNameId(
          widget.plugin, taigaPool.rewardTokens[index]);
      final rewardPrice =
          AssetsUtils.getMarketPrice(widget.plugin, rewardBalance.symbol!);
      claim += Fmt.balanceDouble(e, rewardBalance.decimals!) * rewardPrice;
      claimString.add(
          "${Fmt.balance(e, rewardBalance.decimals!)} ${PluginFmt.tokenView(rewardBalance.symbol)}");
    });
    if (claim > 0) {
      canClaim = true;
    }
    return PluginScaffold(
      appBar: PluginAppBar(
        title: Text(PluginFmt.tokenView(tokenSymbol)),
        centerTitle: true,
        actions: [PluginAccountInfoAction(widget.keyring)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 25),
            child: Column(
              children: [
                PluginTagCard(
                  titleTag: dic['dex.lp']!,
                  padding: EdgeInsets.only(top: 18, bottom: 14),
                  child: Center(
                    child: Text(
                      "\$${Fmt.priceFloorFormatter(totalStaked)}",
                      style: Theme.of(context)
                          .textTheme
                          .headline1
                          ?.copyWith(fontSize: 44, color: Colors.white),
                    ),
                  ),
                ),
                Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: InfoItemRow(
                      dic['earn.apy']!,
                      Fmt.ratio(apy),
                      labelStyle: labelStyle,
                      contentStyle: valueStyle,
                    )),
                Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: InfoItemRow(
                      dic['earn.staked']!,
                      "${Fmt.balance(taigaPool.userShares, balance.decimals!)} ${PluginFmt.tokenView(tokenSymbol)}",
                      labelStyle: labelStyle,
                      contentStyle: valueStyle,
                    )),
                Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: InfoItemRow(
                      dic['earn.share']!,
                      "${Fmt.ratio(BigInt.parse(taigaPool.userShares) / BigInt.parse(taigaPool.totalShares))}",
                      labelStyle: labelStyle,
                      contentStyle: valueStyle,
                    )),
                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: tokenSymbol == "3USD"
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Container(
                              width: 182,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 17, vertical: 5),
                              decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(51),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(4))),
                              child: Center(
                                child: Text(
                                  dic['earn.taiga.stakeNotRequired']!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headline3
                                      ?.copyWith(
                                          fontSize: UI.getTextSize(18, context),
                                          color: Color(0xFF171620)),
                                ),
                              ),
                            )
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: PluginOutlinedButtonSmall(
                                content: dic['loan.withdraw'],
                                color: Color(0xFFFF7849),
                                active: true,
                                padding: EdgeInsets.only(top: 8, bottom: 8),
                                margin: EdgeInsets.zero,
                                onPressed: BigInt.parse(taigaPool.userShares) >
                                        BigInt.zero
                                    ? () => Navigator.of(context).pushNamed(
                                          LoanDepositPage.route,
                                          arguments: {
                                            "type": LoanDepositPage
                                                .actionTypeWithdraw,
                                            "tokenNameId": argsJson['poolId']
                                          },
                                        )
                                    : null,
                              ),
                            ),
                            Container(width: 15),
                            Expanded(
                              child: PluginOutlinedButtonSmall(
                                content: dic['loan.deposit'],
                                color: Color(0xFFFF7849),
                                active: true,
                                padding: EdgeInsets.only(top: 8, bottom: 8),
                                margin: EdgeInsets.zero,
                                onPressed: () =>
                                    Navigator.of(context).pushNamed(
                                  LoanDepositPage.route,
                                  arguments: {
                                    "type": LoanDepositPage.actionTypeDeposit,
                                    "tokenNameId": argsJson['poolId']
                                  },
                                ),
                              ),
                            )
                          ],
                        ),
                ),
                Visibility(
                    visible: canClaim,
                    child: RoundedPluginCard(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 39),
                      padding: EdgeInsets.only(
                          top: 5, bottom: 16, left: 16, right: 16),
                      child: Column(
                        children: [
                          Container(
                            margin: EdgeInsets.only(bottom: 12),
                            child: Image.asset(
                              "packages/polkawallet_plugin_karura/assets/images/lp_detail_reward.png",
                              width: 150,
                            ),
                          ),
                          Text(
                            "\$ ${Fmt.priceFloorFormatter(claim)}",
                            style: Theme.of(context)
                                .textTheme
                                .headline1
                                ?.copyWith(color: Colors.white),
                          ),
                          Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Text(
                                claimString.join(" + "),
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headline5
                                    ?.copyWith(
                                        color: Colors.white.withAlpha(191),
                                        fontSize: 12),
                              )),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context)
                                  .pushNamed(DAppWrapperPage.route, arguments: {
                                'url': "https://app.taigaprotocol.io/"
                              });
                            },
                            child: Container(
                              margin: EdgeInsets.only(top: 12),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 29, vertical: 5),
                              decoration: BoxDecoration(
                                  color: PluginColorsDark.primary,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(4))),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    dic['earn.taiga.claimAirdrop']!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline3
                                        ?.copyWith(
                                            fontSize:
                                                UI.getTextSize(18, context),
                                            color: Color(0xFF171620)),
                                  ),
                                  Icon(Icons.open_in_new,
                                      size: 16, color: Color(0xFF171620))
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 17),
                            child: Text(
                              dic['earn.taiga.claimMessage']!,
                              style: Theme.of(context)
                                  .textTheme
                                  .headline5
                                  ?.copyWith(
                                      color: PluginColorsDark.primary,
                                      fontSize: 12),
                            ),
                          )
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/loanType.dart';
import 'package:polkawallet_plugin_karura/api/types/swapOutputData.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/loanNew/loanHistoryPage.dart';
import 'package:polkawallet_plugin_karura/pages/types/loanPageParams.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/circularProgressBar.dart';
import 'package:polkawallet_ui/components/jumpToBrowserLink.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/dialog.dart';
import 'package:polkawallet_ui/components/v3/infoItemRow.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginAccountInfoAction.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginIconButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:rive/rive.dart';

class LoanPage extends StatefulWidget {
  LoanPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/loan';

  @override
  _LoanPageState createState() => _LoanPageState();
}

class _LoanPageState extends State<LoanPage> {
  final colorSafe = [Colors.transparent, Color(0xFF60FFA7), Colors.transparent];
  final colorWarn = [Color(0xFFFFCA4D), Color(0xFFFFCA4D), Color(0x33FFCA4D)];
  final colorDanger = [Color(0xFFFF7849), Color(0xFFFF6D37), Color(0x66FF6D37)];

  var _isQueryCollateraling = true;
  double _totalMinted = 0.0;

  Future<void> _fetchData() async {
    widget.plugin.service!.earn.getDexIncentiveLoyaltyEndBlock();
    widget.plugin.service!.gov.updateBestNumber();
    if (widget.plugin.store!.loan.loanTypes.length == 0) {
      await widget.plugin.service!.loan
          .queryLoanTypes(widget.keyring.current.address);
    }

    widget.plugin.service!.assets.queryMarketPrices();

    widget.plugin.service!.loan
        .subscribeAccountLoans(widget.keyring.current.address);
  }

  @override
  void dispose() {
    super.dispose();
    widget.plugin.service!.loan.unsubscribeAccountLoans();
  }

  Future<SwapOutputData> _queryReceiveAmount(
      BuildContext ctx, TokenBalanceData collateral, double debit) async {
    return widget.plugin.api!.swap.queryTokenSwapAmount(
      null,
      debit.toStringAsFixed(2),
      [
        collateral.tokenNameId!,
        karura_stable_coin,
      ],
      '0.01',
    );
  }

  Future<void> _closeVault(
      LoanData loan, int? collateralDecimal, double debit) async {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala');
    final dicCommon = I18n.of(context)!.getDic(i18n_full_dic_ui, 'common');
    final confirmed = debit > 0
        ? await showCupertinoDialog(
            context: context,
            builder: (BuildContext ctx) {
              return PolkawalletAlertDialog(
                title: Text(dic!['loan.close']!),
                content: Column(
                  children: [
                    Text(dic['loan.close.dex.info']!),
                    Divider(),
                    FutureBuilder<SwapOutputData>(
                      future: _queryReceiveAmount(ctx, loan.token!, debit),
                      builder: (_, AsyncSnapshot<SwapOutputData> snapshot) {
                        if (snapshot.hasData) {
                          final left = Fmt.bigIntToDouble(
                                  loan.collaterals, collateralDecimal!) -
                              snapshot.data!.amount!;
                          return InfoItemRow(
                            dic['loan.close.receive']!,
                            "${Fmt.priceFloor(left)} ${loan.token!.symbol}",
                            labelStyle: Theme.of(context)
                                .textTheme
                                .headline5!
                                .copyWith(color: Color(0xFF565554)),
                            contentStyle: Theme.of(context)
                                .textTheme
                                .headline5!
                                .copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF565554)),
                          );
                        } else {
                          return Container();
                        }
                      },
                    ),
                  ],
                ),
                actions: <Widget>[
                  PolkawalletActionSheetAction(
                    child: Text(dicCommon!['cancel']!),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  PolkawalletActionSheetAction(
                    isDefaultAction: true,
                    child: Text(dicCommon['ok']!),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              );
            },
          )
        : await UI.confirm(context, dic!['v3.loan.closeVault']!);
    if (confirmed) {
      var res;
      if (debit > 0) {
        final params = [loan.token!.currencyId, loan.collaterals.toString()];

        res = await Navigator.of(context).pushNamed(
          TxConfirmPage.route,
          arguments: TxConfirmParams(
            module: 'honzon',
            call: 'closeLoanHasDebitByDex',
            txTitle: dic!['loan.close'],
            txDisplay: {
              'collateral': loan.token!.symbol,
              'payback': "${Fmt.priceCeil(debit)} $karura_stable_coin_view",
            },
            params: params,
            isPlugin: true,
          ),
        );
      } else {
        final params = [
          loan.token!.currencyId,
          (loan.collaterals * BigInt.from(-1)).toString(),
          loan.debits.toString()
        ];

        res = await Navigator.of(context).pushNamed(
          TxConfirmPage.route,
          arguments: TxConfirmParams(
            module: 'honzon',
            call: "adjustLoanByDebitValue",
            txTitle: "adjust Vault",
            txDisplay: {
              dic!['loan.withdraw']:
                  "${Fmt.priceFloorBigInt(loan.collaterals, collateralDecimal!, lengthMax: 4)} ${PluginFmt.tokenView(loan.token!.symbol)}",
            },
            params: params,
            isPlugin: true,
          ),
        );
      }
      if (res != null) {
        Future.delayed(Duration(milliseconds: 500), () {
          _fetchData();
        });
        Navigator.of(context).pop(res);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala');
    final argsJson = ModalRoute.of(context)!.settings.arguments as Map? ?? {};
    final args = LoanPageParams.fromJson(argsJson);

    return Observer(builder: (_) {
      final loans = widget.plugin.store!.loan.loans.values.toList();
      loans.retainWhere((loan) =>
          loan.debits > BigInt.zero || loan.collaterals > BigInt.zero);
      final isDataLoading = widget.plugin.store!.loan.loansLoading &&
          (loans.length == 0 ||
              // do not show loan card if collateralRatio was not calculated.
              (loans.length > 0 && loans[0].collateralRatio <= 0));

      final loanTypes = [], ortherType = [];
      widget.plugin.store!.loan.loanTypes.forEach((element) {
        if (element.token?.symbol != 'tKSM') {
          if (loans.indexWhere((loan) =>
                  loan.token?.tokenNameId == element.token?.tokenNameId) >=
              0) {
            loanTypes.add(element);
          } else {
            ortherType.add(element);
          }
        }
      });

      /// hide other loanType for aSEED upgrade.
      // loanTypes.addAll(ortherType);
      loanTypes.removeWhere((e) =>
          collateralFilterList.indexWhere((i) => e.token?.symbol == i) > -1);

      /// The initial tab index will be from arguments or user's vault.
      int initialLoanTypeIndex = 0;
      if (args.loanType != null) {
        initialLoanTypeIndex =
            loanTypes.indexWhere((e) => e.token?.tokenNameId == args.loanType);
      }

      return PluginScaffold(
          appBar: PluginAppBar(
            title: Text(dic!['loan.title']!),
            actions: [
              Container(
                margin: EdgeInsets.only(right: 12),
                child: PluginIconButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(LoanHistoryPage.route),
                  icon: Image.asset(
                    'packages/polkawallet_plugin_karura/assets/images/history.png',
                    width: 16,
                  ),
                ),
              ),
              PluginAccountInfoAction(widget.keyring)
            ],
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            margin: EdgeInsets.only(top: 16),
            child: ASEEDLinkWidget(),
          ));
    });
  }

  Widget headView(LoanData loan, double requiredCollateralRatio) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;

    final balancePair = AssetsUtils.getBalancePairFromTokenNameId(
        widget.plugin, [loan.token!.tokenNameId, karura_stable_coin]);

    final debitRatio = loan.collateralInUSD == BigInt.zero
        ? 0.0
        : loan.debits / loan.collateralInUSD;

    final availablePrice = Fmt.bigIntToDouble(
        widget.plugin.store!.assets.prices[loan.token!.tokenNameId],
        acala_price_decimals);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          "${dic['v3.loan.annualStabilityFee']} ~${Fmt.ratio(widget.plugin.store!.loan.loanTypes.firstWhere((i) => i.token!.symbol == loan.token!.symbol).stableFeeYear)}",
          style: Theme.of(context).textTheme.headline5?.copyWith(
              fontSize: UI.getTextSize(12, context),
              color: PluginColorsDark.headline1),
        ),
        Container(
          margin: EdgeInsets.only(top: 6),
          padding: EdgeInsets.only(top: 8, left: 8, bottom: 15),
          width: double.infinity,
          decoration: BoxDecoration(
              color: Color(0xFFFFFFFF).withAlpha(25),
              borderRadius: const BorderRadius.all(Radius.circular(6))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                debitRatio == 0 ||
                        loan.collateralRatio > requiredCollateralRatio + 0.2
                    ? ""
                    : loan.collateralRatio > requiredCollateralRatio
                        ? dic['v3.loan.needAdjust']!
                        : dic['loan.multiply.highRisk']!,
                style: Theme.of(context).textTheme.headline5?.copyWith(
                    fontSize: UI.getTextSize(12, context),
                    fontWeight: FontWeight.w600,
                    color: debitRatio == 0 ||
                            loan.collateralRatio > requiredCollateralRatio + 0.2
                        ? colorSafe[0]
                        : loan.collateralRatio > requiredCollateralRatio
                            ? colorWarn[0]
                            : colorDanger[0]),
              ),
              SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                            padding: EdgeInsets.all(20),
                            width: 130,
                            height: 130,
                            child: Container(
                                decoration: BoxDecoration(
                                    color: debitRatio == 0 ||
                                            loan.collateralRatio >
                                                requiredCollateralRatio + 0.2
                                        ? colorSafe[2]
                                        : loan.collateralRatio >
                                                requiredCollateralRatio
                                            ? colorWarn[2]
                                            : colorDanger[2],
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(125))),
                                child: Center(
                                  child: Text(
                                    "Vault\n${PluginFmt.tokenView(loan.token!.symbol)}",
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline3
                                        ?.copyWith(
                                            color: PluginColorsDark.headline1,
                                            height: 1.3),
                                  ),
                                ))),
                        AnimationCircularProgressBar(
                            progress: Fmt.bigIntToDouble(
                                    loan.debits, balancePair[1].decimals!) /
                                (Fmt.balanceDouble(loan.collaterals.toString(),
                                        balancePair[0].decimals!) *
                                    availablePrice),
                            width: 10,
                            bgWidth: 7,
                            lineColor: debitRatio == 0 ||
                                    loan.collateralRatio >
                                        requiredCollateralRatio + 0.2
                                ? [colorSafe[1], colorSafe[1]]
                                : loan.collateralRatio > requiredCollateralRatio
                                    ? [colorWarn[1], colorWarn[1]]
                                    : [colorDanger[1], colorDanger[1]],
                            size: 130,
                            startAngle: pi * 3 / 2,
                            bgColor: const Color(0x4cFFFFFF))
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 16,
                            height: 9,
                            margin: EdgeInsets.only(right: 17),
                            decoration: BoxDecoration(
                                color: debitRatio == 0 ||
                                        loan.collateralRatio >
                                            requiredCollateralRatio + 0.2
                                    ? colorSafe[1]
                                    : loan.collateralRatio >
                                            requiredCollateralRatio
                                        ? colorWarn[1]
                                        : colorDanger[1],
                                borderRadius:
                                    BorderRadius.all(Radius.circular(4.44))),
                          ),
                          Text(
                            "${dic['loan.multiply.debt']} ${Fmt.priceFloorFormatter(Fmt.bigIntToDouble(loan.debits, balancePair[1].decimals!))} ${PluginFmt.tokenView(karura_stable_coin_view)} (~ \$${Fmt.priceFloorFormatter(Fmt.bigIntToDouble(loan.debits, balancePair[1].decimals!))})",
                            style: Theme.of(context)
                                .textTheme
                                .headline5
                                ?.copyWith(
                                    fontSize: UI.getTextSize(12, context),
                                    color: PluginColorsDark.headline1),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 16,
                            height: 9,
                            margin: EdgeInsets.only(right: 17),
                            decoration: BoxDecoration(
                                color: Color(0x4cFFFFFF),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(4.44))),
                          ),
                          Text(
                            "${dic['loan.collateral']} ${Fmt.priceFloorBigIntFormatter(loan.collaterals, balancePair[0].decimals!)} ${PluginFmt.tokenView(loan.token!.symbol)} (~ \$${Fmt.priceFloorFormatter(Fmt.balanceDouble(loan.collaterals.toString(), balancePair[0].decimals!) * availablePrice)})",
                            style: Theme.of(context)
                                .textTheme
                                .headline5
                                ?.copyWith(
                                    fontSize: UI.getTextSize(12, context),
                                    color: PluginColorsDark.headline1),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}

class LoanItemView extends StatelessWidget {
  const LoanItemView({Key? key, required this.title, required this.child})
      : super(key: key);

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 98,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          child: Column(
            children: [
              Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  width: double.infinity,
                  color: Colors.white.withAlpha(13),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headline5?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: PluginColorsDark.headline1,
                        ),
                  )),
              Expanded(
                  child: Container(
                width: double.infinity,
                color: Colors.white.withAlpha(25),
                padding: EdgeInsets.only(left: 11, top: 18),
                child: child,
              ))
            ],
          ),
        ));
  }
}

class CreateVaultWidget extends StatelessWidget {
  const CreateVaultWidget(
      this.symbol, this.plugin, this.isQueryCollateraling, this._totalMinted,
      {this.onPressed, Key? key})
      : super(key: key);
  final String symbol;
  final Function()? onPressed;
  final PluginKarura plugin;
  final isQueryCollateraling;
  final double _totalMinted;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    final loanType = plugin.store!.loan.loanTypes
        .firstWhere((i) => i.token!.symbol == symbol);

    final _amountCollateral = 100.0;

    final balancePair = AssetsUtils.getBalancePairFromTokenNameId(
        plugin, [loanType.token!.tokenNameId, karura_stable_coin]);

    final style = Theme.of(context)
        .textTheme
        .headline5
        ?.copyWith(color: PluginColorsDark.headline1);

    final _maxToBorrow = loanType.calcMaxToBorrow(
        Fmt.tokenInt(_amountCollateral.toString(), balancePair[0].decimals!),
        plugin.store!.assets.prices[loanType.token!.tokenNameId] ?? BigInt.zero,
        stableCoinDecimals: balancePair[1].decimals,
        collateralDecimals: balancePair[0].decimals);
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(children: [
            Container(
                margin: EdgeInsets.only(top: 30, bottom: 14),
                width: 120,
                height: 120,
                child: Stack(
                  children: [
                    RiveAnimation.asset(
                        'packages/polkawallet_plugin_karura/assets/images/cdp_multiply.riv'),
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      margin: EdgeInsets.all(10),
                      child: FittedBox(
                          fit: BoxFit.fill,
                          child: plugin.tokenIcons[symbol.toUpperCase()]),
                    )
                  ],
                )),
            Text(
              "Vault ${PluginFmt.tokenView(symbol)}",
              style: Theme.of(context).textTheme.headline1?.copyWith(
                  fontSize: UI.getTextSize(26, context),
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6D37)),
            ),
            Container(
              margin: EdgeInsets.only(top: 36),
              padding: EdgeInsets.symmetric(vertical: 29),
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${dic['loan.multiply.with']} ${Fmt.priceFloor(_amountCollateral)} ${PluginFmt.tokenView(symbol)}",
                    style: Theme.of(context).textTheme.headline3?.copyWith(
                        color: PluginColorsDark.headline1,
                        fontSize: UI.getTextSize(18, context),
                        fontWeight: FontWeight.w300),
                  ),
                  Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        "${dic['v3.loan.message1']} ${Fmt.priceFloorBigInt(_maxToBorrow, balancePair[1].decimals!)} ${PluginFmt.tokenView(karura_stable_coin_view)} ${dic['loan.multiply.message2']}",
                        style: Theme.of(context).textTheme.headline3?.copyWith(
                            color: PluginColorsDark.headline1,
                            fontSize: UI.getTextSize(18, context),
                            fontWeight: FontWeight.w600),
                      )),
                ],
              ),
            ),
            Padding(
                padding: EdgeInsets.only(top: 24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        dic['v3.loan.totalMinted']!,
                        style: style,
                      ),
                      isQueryCollateraling
                          ? CupertinoActivityIndicator(
                              color: Colors.white,
                            )
                          : Text(
                              "${Fmt.priceFloorFormatter(_totalMinted)}",
                              textAlign: TextAlign.right,
                              style: style,
                            ),
                    ],
                  ),
                )),
            InfoItemRow(
              dic['liquid.ratio']!,
              "${Fmt.ratio(Fmt.bigIntToDouble(loanType.liquidationRatio, 18))}",
              labelStyle: style,
              contentStyle: style,
            ),
            InfoItemRow(
              dic['loan.multiply.variableAnnualFee']!,
              "${Fmt.ratio(loanType.stableFeeYear)}",
              labelStyle: style,
              contentStyle: style,
            ),
          ]),
          Container(
              margin: EdgeInsets.only(bottom: 38),
              child: PluginButton(
                title: dic['loan.create']!,
                onPressed: onPressed,
              ))
        ],
      ),
    );
  }
}

class ASEEDLinkWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          JumpToBrowserLink(
            'https://wiki.acala.network/acala-exodus-upgrade/ausd-seed-aseed',
            text: 'More info',
            color: Colors.blue,
          ),
          Text(' about aSEED', style: TextStyle(fontSize: 12)),
          Image.network(
              'https://resources.acala.network/_next/image?url=%2Ftokens%2FASEED.png&w=96&q=75',
              width: 20)
        ],
      ),
    );
  }
}

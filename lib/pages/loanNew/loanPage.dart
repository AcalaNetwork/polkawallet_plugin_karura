import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/loanType.dart';
import 'package:polkawallet_plugin_karura/api/types/swapOutputData.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/loanNew/loanAdjustPage.dart';
import 'package:polkawallet_plugin_karura/pages/loanNew/loanCreatePage.dart';
import 'package:polkawallet_plugin_karura/pages/loanNew/loanHistoryPage.dart';
import 'package:polkawallet_plugin_karura/pages/loanNew/loanTabBarWidget.dart';
import 'package:polkawallet_plugin_karura/pages/types/loanPageParams.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/circularProgressBar.dart';
import 'package:polkawallet_ui/components/connectionChecker.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/infoItemRow.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginIconButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginLoadingWidget.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginOutlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTokenIcon.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:wave/config.dart';
import 'package:wave/wave.dart';

class LoanPage extends StatefulWidget {
  LoanPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/loan';

  @override
  _LoanPageState createState() => _LoanPageState();
}

class _LoanPageState extends State<LoanPage> {
  final colorSafe = [Color(0xFF60FFA7), Color(0x8860FFA7)];
  final colorWarn = [Color(0xFFE59831), Color(0x88FFD479)];
  final colorDanger = [Color(0xFFE3542E), Color(0x88F27863)];

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

  Future<bool?> _confirmPaybackParams(String message) async {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    final bool? res = await showCupertinoDialog(
        context: context,
        builder: (_) {
          return CupertinoAlertDialog(
            content: Text(message),
            actions: <Widget>[
              CupertinoDialogAction(
                child: Text(dic['loan.warn.back']!),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              CupertinoDialogAction(
                child: Text(I18n.of(context)!
                    .getDic(i18n_full_dic_karura, 'common')!['ok']!),
                onPressed: () => Navigator.of(context).pop(true),
              )
            ],
          );
        });
    return res;
  }

  Future<SwapOutputData> _queryReceiveAmount(
      BuildContext ctx, TokenBalanceData collateral, double debit) async {
    return widget.plugin.api!.swap.queryTokenSwapAmount(
      null,
      debit.toStringAsFixed(2),
      [
        {...collateral.currencyId!, 'decimals': collateral.decimals},
        {
          'Token': karura_stable_coin,
          'decimals': AssetsUtils.getBalanceFromTokenNameId(
                  widget.plugin, karura_stable_coin)
              .decimals
        }
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
              return CupertinoAlertDialog(
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
                          return InfoItemRow(dic['loan.close.receive']!,
                              "${Fmt.priceFloor(left)} ${loan.token!.symbol}");
                        } else {
                          return Container();
                        }
                      },
                    ),
                  ],
                ),
                actions: <Widget>[
                  CupertinoButton(
                    child: Text(dicCommon!['cancel']!),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  CupertinoButton(
                    child: Text(dicCommon['ok']!),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              );
            },
          )
        : await _confirmPaybackParams(dic!['v3.loan.closeVault']!);
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

      /// The initial tab index will be from arguments or user's vault.
      int initialLoanTypeIndex = 0;
      if (args.loanType != null) {
        initialLoanTypeIndex = widget.plugin.store!.loan.loanTypes
            .indexWhere((e) => e.token?.tokenNameId == args.loanType);
      } else if (loans.length > 0) {
        initialLoanTypeIndex = widget.plugin.store!.loan.loanTypes.indexWhere(
            (e) => e.token?.tokenNameId == loans[0].token?.tokenNameId);
      }

      final headCardWidth = MediaQuery.of(context).size.width - 16 * 2 - 6 * 2;
      final headCardHeight = headCardWidth / 694 * 420;
      return PluginScaffold(
          appBar: PluginAppBar(
            title: Text(dic!['loan.title']!),
            actions: [
              Container(
                margin: EdgeInsets.only(right: 16),
                child: PluginIconButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(LoanHistoryPage.route),
                  icon: Icon(
                    Icons.history,
                    size: 22,
                    color: Color(0xFF17161F),
                  ),
                ),
              )
            ],
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            margin: EdgeInsets.only(top: 16),
            child: SafeArea(
                child: isDataLoading
                    ? Column(
                        children: [
                          ConnectionChecker(widget.plugin,
                              onConnected: _fetchData),
                          Container(
                            height: MediaQuery.of(context).size.height / 2,
                            child: PluginLoadingWidget(),
                          )
                        ],
                      )
                    : LoanTabBarWidget(
                        initialTab: initialLoanTypeIndex > -1
                            ? initialLoanTypeIndex
                            : 0,
                        data: widget.plugin.store!.loan.loanTypes.map((e) {
                          final _loans = loans.where(
                              (data) => data.token!.symbol == e.token!.symbol);
                          LoanData? loan =
                              _loans.length > 0 ? _loans.first : null;
                          Widget child = CreateVaultWidget(onPressed: () async {
                            final res = await Navigator.of(context).pushNamed(
                                LoanCreatePage.route,
                                arguments: e.token);
                            if (res != null) {
                              Future.delayed(Duration(milliseconds: 500), () {
                                _fetchData();
                              });
                            }
                          });
                          if (loan != null) {
                            final balancePair =
                                AssetsUtils.getBalancePairFromTokenNameId(
                                    widget.plugin, [
                              loan.token!.tokenNameId,
                              karura_stable_coin
                            ]);

                            final available = Fmt.bigIntToDouble(
                                loan.collaterals, balancePair[0].decimals!);
                            final BigInt balanceBigInt =
                                Fmt.balanceInt(balancePair[0].amount);
                            final balance = Fmt.bigIntToDouble(
                                balanceBigInt, balancePair[0].decimals!);

                            final debits = Fmt.bigIntToDouble(
                                loan.debits, balancePair[1].decimals!);
                            final maxToBorrow = Fmt.bigIntToDouble(
                                loan.maxToBorrow, balancePair[1].decimals!);

                            final availablePrice = Fmt.bigIntToDouble(
                                widget.plugin.store!.assets
                                    .prices[loan.token!.tokenNameId],
                                acala_price_decimals);

                            final BigInt balanceStableCoin =
                                Fmt.balanceInt(balancePair[1].amount);

                            final originalDebitsValue =
                                loan.type.debitShareToDebit(loan.debitShares);

                            final canMint =
                                loan.maxToBorrow - loan.debits > BigInt.zero
                                    ? loan.maxToBorrow - loan.debits
                                    : BigInt.zero;
                            final canPayback = balanceStableCoin -
                                        Fmt.balanceInt(
                                            balancePair[1].minBalance) >
                                    originalDebitsValue
                                ? originalDebitsValue
                                : balanceStableCoin -
                                            Fmt.balanceInt(
                                                balancePair[1].minBalance) >
                                        BigInt.zero
                                    ? balanceStableCoin -
                                        Fmt.balanceInt(
                                            balancePair[1].minBalance)
                                    : BigInt.zero;

                            final itemStype = Theme.of(context)
                                .textTheme
                                .headline5
                                ?.copyWith(
                                    color: PluginColorsDark.headline1,
                                    fontSize: UI.getTextSize(12, context));

                            child = SingleChildScrollView(
                                physics: BouncingScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    headView(
                                        headCardHeight,
                                        headCardWidth,
                                        loan,
                                        double.parse(Fmt.token(
                                            loan.type.requiredCollateralRatio,
                                            18))),
                                    LoanItemView(
                                      progress:
                                          available / (available + balance),
                                      progressText:
                                          "${Fmt.priceFloorBigIntFormatter(loan.collaterals, balancePair[0].decimals!)} ${PluginFmt.tokenView(loan.token!.symbol)} ${dic['v3.loan.inCollateral']}",
                                      btnText:
                                          "${dic['loan.deposit']}/${dic['loan.withdraw']}",
                                      detailWidget: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                dic['v3.totalBalance']!,
                                                style: itemStype,
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    "${Fmt.priceFloorFormatter(balance)} ${PluginFmt.tokenView(loan.token!.symbol)}",
                                                    style: itemStype,
                                                  ),
                                                  Text(
                                                    "≈ \$${Fmt.priceFloorFormatter(balance * availablePrice)}",
                                                    style: itemStype,
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                          InfoItemRow(
                                              dic['collateral.price.current']!,
                                              '≈ \$${Fmt.priceFloorBigInt(widget.plugin.store!.assets.prices[loan.token!.tokenNameId] ?? BigInt.zero, acala_price_decimals)}',
                                              labelStyle: itemStype,
                                              contentStyle: itemStype),
                                          InfoItemRow(dic['liquid.price']!,
                                              '≈ \$${Fmt.priceFloorBigInt(loan.liquidationPrice, acala_price_decimals)}',
                                              labelStyle: itemStype,
                                              contentStyle: itemStype)
                                        ],
                                      ),
                                      onTap: () async {
                                        final res = await Navigator.of(context)
                                            .pushNamed(LoanAdjustPage.route,
                                                arguments: {
                                              "type": "collateral",
                                              "loan": loan
                                            });
                                        if (res != null) {
                                          Future.delayed(
                                              Duration(milliseconds: 500), () {
                                            _fetchData();
                                          });
                                        }
                                      },
                                    ),
                                    LoanItemView(
                                      progress: debits / maxToBorrow > 1
                                          ? 1
                                          : debits / maxToBorrow,
                                      progressText:
                                          "${Fmt.priceFloorFormatter(debits)} ${PluginFmt.tokenView(karura_stable_coin)} ${dic['v3.loan.minted']}",
                                      btnText:
                                          "${dic['loan.mint']}/${dic['loan.payback']}",
                                      detailWidget: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InfoItemRow(dic['v3.totalBalance']!,
                                              "${Fmt.priceFloorBigIntFormatter(balanceStableCoin, balancePair[1].decimals!)} ${PluginFmt.tokenView(karura_stable_coin)}",
                                              labelStyle: itemStype,
                                              contentStyle: itemStype),
                                          InfoItemRow(dic['v3.loan.canMint']!,
                                              '${Fmt.priceFloorBigInt(canMint, balancePair[1].decimals!)} ${PluginFmt.tokenView(karura_stable_coin)}',
                                              labelStyle: itemStype,
                                              contentStyle: itemStype),
                                          InfoItemRow(
                                              dic['v3.loan.canPayback']!,
                                              '${Fmt.priceFloorBigIntFormatter(canPayback, balancePair[1].decimals!)} ${PluginFmt.tokenView(karura_stable_coin)}',
                                              labelStyle: itemStype,
                                              contentStyle: itemStype)
                                        ],
                                      ),
                                      onTap: () async {
                                        final res = await Navigator.of(context)
                                            .pushNamed(LoanAdjustPage.route,
                                                arguments: {
                                              "type": "debits",
                                              "loan": loan
                                            });
                                        if (res != null) {
                                          Future.delayed(
                                              Duration(milliseconds: 500), () {
                                            _fetchData();
                                          });
                                        }
                                      },
                                    ),
                                    // todo: remove this visibility if 'sa://0' can do 'closeLoanHasDebitByDex'
                                    Visibility(
                                      visible: !(loan.debits > BigInt.zero &&
                                          loan.token?.tokenNameId == 'sa://0'),
                                      child: GestureDetector(
                                        child: Padding(
                                            padding: EdgeInsets.only(bottom: 5),
                                            child: Text(dic['loan.close.dex']!,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headline6
                                                    ?.copyWith(
                                                        color: Colors.white,
                                                        fontSize:
                                                            UI.getTextSize(
                                                                10, context)))),
                                        onTap: () => _closeVault(
                                            loan,
                                            balancePair[0].decimals,
                                            Fmt.bigIntToDouble(loan.debits,
                                                balancePair[1].decimals!)),
                                      ),
                                    ),
                                  ],
                                ));
                          }
                          return LoanTabBarWidgetData(
                            PluginTokenIcon(
                              e.token?.symbol ?? "",
                              widget.plugin.tokenIcons,
                              size: 34,
                            ),
                            child,
                          );
                        }).toList(),
                      )),
          ));
    });
  }

  Widget headView(double headCardHeight, double headCardWidth, LoanData loan,
      double requiredCollateralRatio) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;

    final balancePair = AssetsUtils.getBalancePairFromTokenNameId(
        widget.plugin, [loan.token!.tokenNameId, karura_stable_coin]);
    final availableView =
        "${Fmt.priceFloorBigIntFormatter(loan.debits, balancePair[1].decimals!, lengthMax: 4)} ${PluginFmt.tokenView(karura_stable_coin)}";
    var availableViewRight = 3 / 347 * headCardWidth +
        85 / 347 * headCardWidth -
        PluginFmt.boundingTextSize(
            '$availableView',
            Theme.of(context).textTheme.headline5?.copyWith(
                  color: Colors.white,
                  fontSize: UI.getTextSize(12, context),
                )).width;
    availableViewRight = availableViewRight < 0 ? 0 : availableViewRight;

    final debitRatio = loan.collateralInUSD == BigInt.zero
        ? 0.0
        : loan.debits / loan.collateralInUSD;

    return Container(
      padding: EdgeInsets.only(left: 6, top: 6, right: 6, bottom: 10),
      margin: EdgeInsets.only(bottom: 19),
      decoration: BoxDecoration(
          color: Color(0x1AFFFFFF),
          borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8))),
      width: double.infinity,
      child: Container(
        width: double.infinity,
        height: headCardHeight,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                  margin: EdgeInsets.only(
                      right: 5 / 347 * headCardWidth,
                      bottom: 47 / 210 * headCardHeight),
                  width: 128 / 347 * headCardWidth,
                  height: 128 / 347 * headCardWidth,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipOval(
                          child: WaveWidget(
                        config: CustomConfig(
                          colors: debitRatio == 0 ||
                                  loan.collateralRatio >
                                      requiredCollateralRatio + 0.2
                              ? colorSafe
                              : loan.collateralRatio > requiredCollateralRatio
                                  ? colorWarn
                                  : colorDanger,
                          durations: [8000, 6000],
                          heightPercentages: [
                            debitRatio == 0 ? 1 : 1 - debitRatio - 0.04,
                            debitRatio == 0 ? 1 : 1 - debitRatio - 0.04,
                          ],
                          blur: MaskFilter.blur(BlurStyle.solid, 5),
                        ),
                        waveAmplitude: 5,
                        size: Size(
                          double.infinity,
                          double.infinity,
                        ),
                      )),
                      Container(
                        padding: EdgeInsets.only(bottom: 18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(dic['v3.loan.loanRatio']!,
                                style: Theme.of(context)
                                    .textTheme
                                    .headline3
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontSize: UI.getTextSize(18, context),
                                    )),
                            Text(Fmt.ratio(debitRatio),
                                style: Theme.of(context)
                                    .textTheme
                                    .headline3
                                    ?.copyWith(
                                      color: Colors.white,
                                      height: 1.0,
                                      fontSize: UI.getTextSize(26.5, context),
                                    ))
                          ],
                        ),
                      )
                    ],
                  )),
            ),
            Image.asset(
              "packages/polkawallet_plugin_karura/assets/images/mint_kusd_head.png",
              width: double.infinity,
            ),
            Container(
              padding: EdgeInsets.only(top: 4 / 210 * headCardHeight, left: 5),
              alignment: Alignment.topLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${dic['v3.loan.annualStabilityFee']!}',
                      style: Theme.of(context).textTheme.headline3?.copyWith(
                            color: Colors.white,
                            fontSize: UI.getTextSize(10, context),
                          )),
                  Text('≈ ${Fmt.ratio(loan.type.stableFeeYear)}',
                      style: Theme.of(context).textTheme.headline3?.copyWith(
                            color: colorSafe[0],
                            height: 1.1,
                            fontSize: UI.getTextSize(12, context),
                          ))
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.only(
                  top: 4 / 210 * headCardHeight,
                  right: 13 / 347 * headCardWidth),
              alignment: Alignment.topRight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(dic['v3.loan.liquidRatio']!,
                      style: Theme.of(context).textTheme.headline3?.copyWith(
                            color: Colors.white,
                            fontSize: UI.getTextSize(10, context),
                          )),
                  Text(
                      '${Fmt.ratio(1 / Fmt.bigIntToDouble(loan.type.liquidationRatio, 18))}',
                      style: Theme.of(context).textTheme.headline3?.copyWith(
                            color: Color(0xFFFC8156),
                            height: 1.1,
                            fontSize: UI.getTextSize(12, context),
                          ))
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.only(
                  left: 20 / 347 * headCardWidth,
                  bottom: (I18n.of(context)!.locale.languageCode == 'zh'
                          ? 26
                          : 25) /
                      210 *
                      headCardHeight),
              alignment: Alignment.bottomLeft,
              child: Text('${dic['loan.collateral']!}:',
                  style: Theme.of(context).textTheme.headline3?.copyWith(
                        color: Color(0xFF26282d),
                        fontSize: UI.getTextSize(10, context),
                      )),
            ),
            Container(
              padding: EdgeInsets.only(
                  left: 26 / 347 * headCardWidth,
                  bottom: 5 / 210 * headCardHeight),
              alignment: Alignment.bottomLeft,
              child: Text(
                  '${Fmt.priceFloorBigIntFormatter(loan.collaterals, loan.token!.decimals!)} ${PluginFmt.tokenView(loan.token!.symbol)}',
                  style: Theme.of(context).textTheme.headline5?.copyWith(
                        color: Colors.white,
                        fontSize: UI.getTextSize(12, context),
                      )),
            ),
            Container(
              padding: EdgeInsets.only(
                  right: 15 / 347 * headCardWidth +
                      77 / 347 * headCardWidth -
                      PluginFmt.boundingTextSize(
                          '${dic['v3.loan.currentMinted']!}:',
                          Theme.of(context).textTheme.headline3?.copyWith(
                                color: Color(0xFF26282d),
                                fontSize: UI.getTextSize(10, context),
                              )).width,
                  bottom: (I18n.of(context)!.locale.languageCode == 'zh'
                          ? 51
                          : 50) /
                      210 *
                      headCardHeight),
              alignment: Alignment.bottomRight,
              child: Text('${dic['v3.loan.currentMinted']!}:',
                  style: Theme.of(context).textTheme.headline3?.copyWith(
                        color: Color(0xFF26282d),
                        fontSize: UI.getTextSize(10, context),
                      )),
            ),
            Container(
              padding: EdgeInsets.only(
                  right: availableViewRight, bottom: 30 / 210 * headCardHeight),
              alignment: Alignment.bottomRight,
              child: Text('$availableView',
                  style: Theme.of(context).textTheme.headline5?.copyWith(
                        color: Colors.white,
                        fontSize: UI.getTextSize(12, context),
                      )),
            ),
          ],
        ),
      ),
    );
  }
}

class LoanItemView extends StatelessWidget {
  const LoanItemView(
      {Key? key,
      required this.progress,
      required this.progressText,
      required this.btnText,
      required this.detailWidget,
      required this.onTap})
      : super(key: key);
  final double progress;
  final String progressText;
  final String btnText;
  final Widget detailWidget;
  final Function onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 172,
        padding: EdgeInsets.symmetric(vertical: 15),
        child: Row(
          children: [
            Expanded(
                child: Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                            padding: EdgeInsets.only(bottom: 20),
                            child: AnimationCircularProgressBar(
                                progress: progress,
                                width: 8,
                                lineColor: [
                                  Color(0x4DFFFFFF),
                                  Color(0xFF81FEB9)
                                ],
                                size: 96,
                                startAngle: pi * 3 / 2,
                                bgColor: Colors.white.withAlpha(38))),
                        Text(
                          progressText,
                          style: Theme.of(context)
                              .textTheme
                              .headline4
                              ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                        ),
                      ],
                    ))),
            Expanded(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                detailWidget,
                PluginOutlinedButtonSmall(
                  padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  margin: EdgeInsets.all(0),
                  content: btnText,
                  color: PluginColorsDark.primary,
                  active: true,
                  fontSize: UI.getTextSize(14, context),
                  onPressed: () {
                    onTap();
                  },
                )
              ],
            ))
          ],
        ));
  }
}

class CreateVaultWidget extends StatelessWidget {
  const CreateVaultWidget({this.onPressed, Key? key}) : super(key: key);
  final Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Color(0x1AFFFFFF),
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8))),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "packages/polkawallet_plugin_karura/assets/images/create_vault_logo.png",
                    width: 116,
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 12),
                    child: Text(
                      dic['v3.createVaultText']!,
                      style: Theme.of(context)
                          .textTheme
                          .headline5
                          ?.copyWith(color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          ),
          Container(
              margin: EdgeInsets.only(top: 131, bottom: 38),
              child: PluginButton(
                title: dic['loan.create']!,
                onPressed: onPressed,
              ))
        ],
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:liquid_progress_indicator/liquid_progress_indicator.dart';
import 'package:polkawallet_plugin_karura/api/earn/types/incentivesData.dart';
import 'package:polkawallet_plugin_karura/api/types/loanType.dart';
import 'package:polkawallet_plugin_karura/common/constants/base.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/loan/loanCreatePage.dart';
import 'package:polkawallet_plugin_karura/pages/loan/loanDepositPage.dart';
import 'package:polkawallet_plugin_karura/pages/loan/loanDetailPage.dart';
import 'package:polkawallet_plugin_karura/pages/loan/loanHistoryPage.dart';
import 'package:polkawallet_plugin_karura/pages/loanNew/loanTabBarWidget.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/addressIcon.dart';
import 'package:polkawallet_ui/components/infoItem.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/outlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/tapTooltip.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginIconButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginSliderThumbShape.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginSliderTrackShape.dart';
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
  final colorSafe = [Color(0xFF61D49F), Color(0xCCA1FBBE)];
  final colorWarn = [Color(0xFFE59831), Color(0xCCFFD479)];
  final colorDanger = [Color(0xFFE3542E), Color(0xCCF27863)];

  final Map<String, LoanData?> _editorLoans = Map<String, LoanData?>();
  final Map<String, double?> _collaterals = Map<String, double?>();

  Future<void> _fetchData() async {
    widget.plugin.service!.gov.updateBestNumber();
    await widget.plugin.service!.loan
        .queryLoanTypes(widget.keyring.current.address);

    final priceQueryTokens = widget.plugin.store!.loan.loanTypes
        .map((e) => e.token!.symbol)
        .toList();
    priceQueryTokens.add(widget.plugin.networkState.tokenSymbol![0]);
    widget.plugin.service!.assets.queryMarketPrices(priceQueryTokens);

    if (mounted) {
      widget.plugin.service!.loan
          .subscribeAccountLoans(widget.keyring.current.address);
    }
  }

  @override
  void initState() {
    super.initState();

    widget.plugin.store!.earn.getdexIncentiveLoyaltyEndBlock(widget.plugin);

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      // todo: fix this after new acala online
      final bool enabled = widget.plugin.basic.name == 'acala'
          ? ModalRoute.of(context)!.settings.arguments as bool
          : true;
      if (enabled) {
        _fetchData();
      } else {
        widget.plugin.store!.loan.setLoansLoading(false);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    widget.plugin.service!.loan.unsubscribeAccountLoans();
  }

  Future<void> _onSubmit(LoanData loan, int? stableCoinDecimals) async {
    final params = await _getTxParams(loan, stableCoinDecimals);
    if (params == null) return null;

    final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
        arguments: TxConfirmParams(
          module: 'honzon',
          call: 'adjustLoan',
          txTitle: "adjust Vault",
          txDisplayBold: params['detail'],
          params: params['params'],
        ))) as Map?;
    if (res != null) {
      Navigator.of(context).pop(res);
    }
  }

  Future<Map?> _getTxParams(LoanData loan, int? stableCoinDecimals) async {
    final loans = widget.plugin.store!.loan.loans.values.toList();
    loans.retainWhere(
        (loan) => loan.debits > BigInt.zero || loan.collaterals > BigInt.zero);

    final originalLoan =
        loans.where((data) => data.token!.symbol == loan.token!.symbol).first;

    final collaterals = loan.collaterals - originalLoan.collaterals;
    final debitShares = loan.debitShares - originalLoan.debitShares;
    final debits = loan.type.debitShareToDebit(debitShares);

    if (collaterals == BigInt.zero && debitShares == BigInt.zero) {
      return null;
    }

    final balancePair = AssetsUtils.getBalancePairFromTokenNameId(
        widget.plugin, [loan.token!.symbol, karura_stable_coin]);
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala');
    final Map<String, Widget> detail = Map<String, Widget>();
    if (collaterals != BigInt.zero) {
      var dicValue = 'loan.deposit';
      if (collaterals < BigInt.zero) {
        dicValue = 'loan.withdraw';
      }
      detail[dic![dicValue]!] = Text(
        '${Fmt.priceFloorBigInt(collaterals.abs(), balancePair[0]!.decimals!, lengthMax: 4)} ${PluginFmt.tokenView(loan.token!.symbol)}',
        style: Theme.of(context).textTheme.headline1,
      );
    }

    BigInt debitSubtract = debitShares;
    if (debitShares != BigInt.zero) {
      var dicValue = 'loan.mint';
      debitSubtract = loan.type.debitToDebitShare(
          originalLoan.debits == BigInt.zero &&
                  debits <= loan.type.minimumDebitValue
              ? (loan.type.minimumDebitValue + BigInt.from(10000))
              : debits);
      if (debitShares < BigInt.zero) {
        dicValue = 'loan.payback';

        final BigInt balanceStableCoin = Fmt.balanceInt(balancePair[1]!.amount);
        if (balanceStableCoin <= debits) {
          debitSubtract = loan.type.debitToDebitShare(debits *
              Fmt.tokenInt("${1 - 0.000001}", balancePair[1]!.decimals!));
        }

        // pay less if less than 1 debit(aUSD) will be left,
        // make sure tx success by leaving more than 1 debit(aUSD).
        final debitValueOne = Fmt.tokenInt('1', stableCoinDecimals!);
        if (loan.debits + debitSubtract > BigInt.zero &&
            loan.debits + debitSubtract < debitValueOne) {
          final bool canContinue =
              await (_confirmPaybackParams() as Future<bool>);
          if (!canContinue) return null;
          debitSubtract =
              debitSubtract + loan.type.debitToDebitShare(debitValueOne);
        }
      }
      detail[dic![dicValue]!] = Text(
        '${Fmt.priceFloorBigInt(debits.abs(), balancePair[0]!.decimals!, lengthMax: 4)} ${PluginFmt.tokenView(loan.token!.symbol)}',
        style: Theme.of(context).textTheme.headline1,
      );
    }

    return {
      'detail': detail,
      'params': [
        loan.token!.currencyId,
        collaterals != BigInt.zero ? collaterals.toString() : 0,
        debitSubtract.toString()
      ]
    };
  }

  Future<bool?> _confirmPaybackParams() async {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala');
    final bool? res = await showCupertinoDialog(
        context: context,
        builder: (_) {
          return CupertinoAlertDialog(
            content: Text(dic![
                'loan.warn${widget.plugin.basic.name == plugin_name_karura ? '.KSM' : ''}']!),
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

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala');

    return Observer(builder: (_) {
      final stableCoinDecimals = widget.plugin.networkState.tokenDecimals![
          widget.plugin.networkState.tokenSymbol!.indexOf(karura_stable_coin)];

      final loans = widget.plugin.store!.loan.loans.values.toList();
      loans.retainWhere((loan) =>
          loan.debits > BigInt.zero || loan.collaterals > BigInt.zero);
      final isDataLoading =
          widget.plugin.store!.loan.loansLoading && loans.length == 0 ||
              // do not show loan card if collateralRatio was not calculated.
              (loans.length > 0 && loans[0].collateralRatio <= 0);

      final headCardWidth = MediaQuery.of(context).size.width - 16 * 2 - 6 * 2;
      final headCardHeight = headCardWidth / 694 * 420;
      return PluginScaffold(
          appBar: PluginAppBar(
            title: Text(dic!['loan.title.KSM']!),
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
            margin: EdgeInsets.only(top: 20),
            child: isDataLoading
                ? Container(
                    height: MediaQuery.of(context).size.width / 2,
                    child: CupertinoActivityIndicator(),
                    color: Colors.white,
                  )
                : LoanTabBarWidget(
                    datas: widget.plugin.store!.loan.loanTypes.map((e) {
                      LoanData? loan = _editorLoans[e.token!.symbol];
                      if (loan == null) {
                        final _loans = loans.where(
                            (data) => data.token!.symbol == e.token!.symbol);
                        loan = _loans.length > 0 ? _loans.first : null;
                        _editorLoans[e.token!.symbol!] = loan;
                      }
                      Widget child = CreateVaultWidget(onPressed: () {
                        Navigator.of(context).pushNamed(LoanCreatePage.route);
                      });
                      if (loan != null) {
                        final balancePair =
                            AssetsUtils.getBalancePairFromTokenNameId(
                                widget.plugin,
                                [loan.token!.symbol, karura_stable_coin]);

                        final available = Fmt.bigIntToDouble(
                            loan.collaterals, balancePair[0]!.decimals!);
                        final BigInt balanceBigInt =
                            Fmt.balanceInt(balancePair[0]!.amount);
                        final balance = Fmt.bigIntToDouble(
                            balanceBigInt, balancePair[0]!.decimals!);

                        if (_collaterals[e.token!.symbol] == null) {
                          _collaterals[e.token!.symbol!] = Fmt.bigIntToDouble(
                              loan.collaterals, balancePair[0]!.decimals!);
                        }

                        final loans =
                            widget.plugin.store!.loan.loans.values.toList();
                        loans.retainWhere((loan) =>
                            loan.debits > BigInt.zero ||
                            loan.collaterals > BigInt.zero);
                        final originalLoan = loans
                            .where((data) =>
                                data.token!.symbol == loan!.token!.symbol)
                            .first;

                        final debits = Fmt.bigIntToDouble(
                            loan.debits, balancePair[1]!.decimals!);
                        final maxToBorrow = Fmt.bigIntToDouble(
                            loan.maxToBorrow, stableCoinDecimals);

                        final availablePrice = Fmt.bigIntToDouble(
                            widget.plugin.store!.assets
                                .prices[loan.token!.symbol],
                            acala_price_decimals);

                        final BigInt balanceStableCoin =
                            Fmt.balanceInt(balancePair[1]!.amount);

                        final collateralsValue =
                            loan.collaterals - originalLoan.collaterals;
                        final debitsSharesValue =
                            loan.debitShares - originalLoan.debitShares;
                        final debitsValue =
                            loan.type.debitShareToDebit(debitsSharesValue);

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
                                Container(
                                  padding: EdgeInsets.all(7),
                                  margin: EdgeInsets.only(bottom: 2),
                                  decoration: BoxDecoration(
                                    color: Color(0x1AFFFFFF),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(14)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      LoanCollateral(
                                        title:
                                            '${dic['loan.collateral']} (${PluginFmt.tokenView(loan.token!.symbol)})',
                                        maxNumber:
                                            _collaterals[e.token!.symbol]! +
                                                balance,
                                        minNumber: Fmt.bigIntToDouble(
                                            loan.requiredCollateral,
                                            balancePair[0]!.decimals!),
                                        subtitleLeft: dic['loan.withdraw']!,
                                        subtitleRight: dic['loan.deposit']!,
                                        value: available,
                                        price: availablePrice,
                                        onChanged: (value) {
                                          final collaterals = Fmt.tokenInt(
                                              "$value",
                                              balancePair[0]!.decimals!);
                                          final maxToBorrow =
                                              Fmt.bigIntToDouble(
                                                      collaterals,
                                                      balancePair[0]!
                                                          .decimals!) *
                                                  availablePrice /
                                                  double.parse(
                                                    Fmt.token(
                                                        loan!.type
                                                            .requiredCollateralRatio,
                                                        acala_price_decimals),
                                                  );
                                          if (maxToBorrow >= debits) {
                                            loan.collaterals = collaterals;
                                            loan.maxToBorrow = Fmt.tokenInt(
                                                "$maxToBorrow",
                                                balancePair[0]!.decimals!);
                                            loan.collateralRatio =
                                                loan.maxToBorrow / loan.debits;
                                          }
                                          setState(() {});
                                        },
                                      ),
                                      Container(
                                          margin: EdgeInsets.only(top: 12),
                                          child: LoanCollateral(
                                            title:
                                                '${dic['loan.borrowed']} (${PluginFmt.tokenView(karura_stable_coin)})',
                                            maxNumber: maxToBorrow,
                                            minNumber: balanceStableCoin >
                                                    loan.debits
                                                ? 0
                                                : Fmt.bigIntToDouble(
                                                    loan.debits -
                                                        balanceStableCoin,
                                                    balancePair[1]!.decimals!),
                                            subtitleLeft: dic['loan.payback']!,
                                            subtitleRight: dic['loan.mint']!,
                                            price: 1.0,
                                            value: debits,
                                            onChanged: (value) {
                                              setState(() {
                                                loan!.debits = Fmt.tokenInt(
                                                    "$value",
                                                    balancePair[0]!.decimals!);
                                                loan.debitShares = loan.type
                                                    .debitToDebitShare(
                                                        loan.debits);
                                                loan.collateralRatio =
                                                    loan.maxToBorrow /
                                                        loan.debits;
                                                loan.requiredCollateral =
                                                    Fmt.tokenInt(
                                                        "${value * double.parse(
                                                              Fmt.token(
                                                                  loan.type
                                                                      .requiredCollateralRatio,
                                                                  acala_price_decimals),
                                                            ) / availablePrice}",
                                                        balancePair[0]!
                                                            .decimals!);
                                              });
                                            },
                                          ))
                                    ],
                                  ),
                                ),
                                Padding(
                                    padding: EdgeInsets.only(bottom: 5),
                                    child: Text(dic['loan.close.dex']!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline6
                                            ?.copyWith(
                                                color: Colors.white,
                                                fontSize: 10))),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        "${debitsSharesValue < BigInt.zero ? dic['loan.payback']! : dic['loan.mint']!}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline4
                                            ?.copyWith(
                                                color: Colors.white,
                                                height: 2.0,
                                                fontWeight: FontWeight.w600)),
                                    Text(
                                        "${Fmt.priceCeilBigInt(debitsValue.abs(), balancePair[1]!.decimals!, lengthMax: 4)} ${PluginFmt.tokenView(loan.token!.symbol)}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline4
                                            ?.copyWith(
                                              color: Colors.white,
                                              height: 1.5,
                                            ))
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        "${collateralsValue > BigInt.zero ? dic['loan.deposit']! : dic['loan.withdraw']!}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline4
                                            ?.copyWith(
                                                color: Colors.white,
                                                height: 2.0,
                                                fontWeight: FontWeight.w600)),
                                    Text(
                                        "${Fmt.priceCeilBigInt(collateralsValue.abs(), balancePair[0]!.decimals!, lengthMax: 4)} ${PluginFmt.tokenView(karura_stable_coin)}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline4
                                            ?.copyWith(
                                              color: Colors.white,
                                              height: 1.5,
                                            ))
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(dic['v3.loan.loanRatio']!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline4
                                            ?.copyWith(
                                                color: Colors.white,
                                                height: 2.0,
                                                fontWeight: FontWeight.w600)),
                                    Text(
                                        '${((1 / loan.collateralRatio) * 100).toStringAsFixed(2)}%',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline4
                                            ?.copyWith(
                                              color: Colors.white,
                                              height: 1.5,
                                            ))
                                  ],
                                ),
                                Padding(
                                    padding:
                                        EdgeInsets.only(top: 37, bottom: 38),
                                    child: PluginButton(
                                      title: '${dic['v3.loan.submit']}',
                                      onPressed: () {
                                        _onSubmit(loan!, stableCoinDecimals);
                                      },
                                    )),
                              ],
                            ));
                      }
                      return LoanTabBarWidgetData(
                          TokenIcon(e.token!.symbol!, widget.plugin.tokenIcons),
                          child);
                    }).toList(),
                  ),
          ));
    });
  }

  Widget headView(double headCardHeight, double headCardWidth, LoanData loan,
      double requiredCollateralRatio) {
    final price = widget.plugin.store!.assets.prices[loan.token!.symbol]!;
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;

    final balancePair = AssetsUtils.getBalancePairFromTokenNameId(
        widget.plugin, [loan.token!.tokenNameId, karura_stable_coin]);
    final available = loan.collaterals - loan.requiredCollateral > BigInt.zero
        ? loan.collaterals - loan.requiredCollateral
        : BigInt.zero;
    final availableView =
        "${Fmt.priceFloorBigInt(available, balancePair[0]!.decimals!, lengthMax: 7)}${loan.token!.symbol}";
    var availableViewRight = 3 / 347 * headCardWidth +
        85 -
        PluginFmt.boundingTextSize(
            '$availableView',
            Theme.of(context).textTheme.headline5?.copyWith(
                  color: Colors.white,
                  fontSize: 12,
                )).width;
    availableViewRight = availableViewRight < 0 ? 0 : availableViewRight;

    final maxToBorrow = loan.maxToBorrow - loan.debits > BigInt.zero
        ? loan.maxToBorrow - loan.debits
        : BigInt.zero;
    final maxToBorrowView =
        Fmt.priceFloorBigInt(maxToBorrow, balancePair[1]!.decimals!);
    return Container(
      padding: EdgeInsets.all(6),
      margin: EdgeInsets.only(bottom: 19),
      decoration: BoxDecoration(
          color: Color(0x1AFFFFFF),
          borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              topRight: Radius.circular(24),
              bottomRight: Radius.circular(24))),
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
                          colors: loan.collateralRatio > requiredCollateralRatio
                              ? loan.collateralRatio >
                                      requiredCollateralRatio + 0.2
                                  ? colorSafe
                                  : colorWarn
                              : colorDanger,
                          durations: [8000, 6000],
                          heightPercentages: [
                            1 - 1 / loan.collateralRatio,
                            1 - 1 / loan.collateralRatio,
                          ],
                          blur: MaskFilter.blur(BlurStyle.solid, 5),
                        ),
                        waveAmplitude: 0,
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
                                      fontSize: 18,
                                    )),
                            Text(
                                '${((1 / loan.collateralRatio) * 100).toStringAsFixed(2)}%',
                                style: Theme.of(context)
                                    .textTheme
                                    .headline3
                                    ?.copyWith(
                                      color: Colors.white,
                                      height: 0.9,
                                      fontSize: 26.5,
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
                  Text('${dic['liquid.price']!}(${loan.token!.symbol})',
                      style: Theme.of(context).textTheme.headline3?.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                          )),
                  Text(
                      '≈ \$${Fmt.priceFloorBigInt(loan.liquidationPrice, acala_price_decimals)}',
                      style: Theme.of(context).textTheme.headline3?.copyWith(
                            color: Color(0xFFFC8156),
                            height: 1.1,
                            fontSize: 12,
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
                  Text(
                      '${dic['collateral.price.current']!}(${loan.token!.symbol})',
                      style: Theme.of(context).textTheme.headline3?.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                          )),
                  Text(
                      '≈ \$${Fmt.priceFloorBigInt(price, acala_price_decimals)}',
                      style: Theme.of(context).textTheme.headline3?.copyWith(
                            color: Color(0xFFA1FBBE),
                            height: 1.1,
                            fontSize: 12,
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
              child: Text('${dic['v3.loan.canMint']!}:',
                  style: Theme.of(context).textTheme.headline3?.copyWith(
                        color: Color(0xFF26282d),
                        fontSize: 10,
                      )),
            ),
            Container(
              padding: EdgeInsets.only(
                  left: 26 / 347 * headCardWidth,
                  bottom: 5 / 210 * headCardHeight),
              alignment: Alignment.bottomLeft,
              child: Text('$maxToBorrowView ${loan.token!.symbol}',
                  style: Theme.of(context).textTheme.headline5?.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                      )),
            ),
            Container(
              padding: EdgeInsets.only(
                  right: 15 / 347 * headCardWidth +
                      77 -
                      PluginFmt.boundingTextSize(
                          '${dic['withdraw.able']!}:',
                          Theme.of(context).textTheme.headline3?.copyWith(
                                color: Color(0xFF26282d),
                                fontSize: 10,
                              )).width,
                  bottom: I18n.of(context)!.locale.languageCode == 'zh'
                      ? 51
                      : 50 / 210 * headCardHeight),
              alignment: Alignment.bottomRight,
              child: Text('${dic['withdraw.able']!}:',
                  style: Theme.of(context).textTheme.headline3?.copyWith(
                        color: Color(0xFF26282d),
                        fontSize: 10,
                      )),
            ),
            Container(
              padding: EdgeInsets.only(
                  right: availableViewRight, bottom: 30 / 210 * headCardHeight),
              alignment: Alignment.bottomRight,
              child: Text('$availableView',
                  style: Theme.of(context).textTheme.headline5?.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                      )),
            ),
          ],
        ),
      ),
    );
  }
}

class LoanCollateral extends StatefulWidget {
  LoanCollateral(
      {required this.title,
      required this.maxNumber,
      required this.value,
      required this.subtitleLeft,
      required this.subtitleRight,
      required this.price,
      this.minNumber = 0,
      this.onChanged,
      Key? key})
      : super(key: key);
  final Function(double)? onChanged;
  String title;
  double maxNumber;
  double minNumber;
  double value;
  double price;
  String subtitleLeft;
  String subtitleRight;

  @override
  _LoanCollateralState createState() => _LoanCollateralState();
}

class _LoanCollateralState extends State<LoanCollateral> {
  double _value = 0;

  @override
  void initState() {
    _value = widget.value;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.title,
                style: Theme.of(context).textTheme.headline5?.copyWith(
                    fontWeight: FontWeight.w600, color: Colors.white)),
            Row(
              children: [
                GestureDetector(
                    onTap: () {
                      showCupertinoDialog(
                          context: context,
                          builder: (context) {
                            final _controller =
                                TextEditingController(text: "$_value");
                            return CupertinoAlertDialog(
                              content: Card(
                                elevation: 0.0,
                                child: CupertinoTextField(
                                  controller: _controller,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              actions: <Widget>[
                                CupertinoDialogAction(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(I18n.of(context)!.getDic(
                                      i18n_full_dic_karura,
                                      'common')!['cancel']!),
                                ),
                                CupertinoDialogAction(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      _value = double.parse(_controller.text);
                                    });
                                    if (widget.onChanged != null) {
                                      widget.onChanged!(_value);
                                    }
                                  },
                                  child: Text(I18n.of(context)!.getDic(
                                      i18n_full_dic_karura, 'common')!['ok']!),
                                ),
                              ],
                            );
                          });
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: 2),
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: Color(0x24FFFFFF),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(4)),
                      ),
                      child: Text(
                        Fmt.priceFloorFormatter(_value, lengthMax: 4),
                        style: Theme.of(context).textTheme.bodyText1?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    )),
                Text(
                  "/${Fmt.priceFloorFormatter(widget.maxNumber, lengthMax: 4)}",
                  style: Theme.of(context).textTheme.bodyText1?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w600),
                )
              ],
            )
          ],
        ),
        Text(
          "Value \$${Fmt.priceFloorFormatter(_value * widget.price, lengthMax: 4)}",
          style: Theme.of(context)
              .textTheme
              .headline5
              ?.copyWith(color: Color(0xFFFFFBF9), fontSize: 12),
        ),
        ClipRect(
            child: Align(
                heightFactor: 0.6,
                alignment: Alignment.center,
                child: SliderTheme(
                    data: SliderThemeData(
                        trackHeight: 11,
                        activeTrackColor: Color(0xFFFC8156),
                        inactiveTrackColor: Color(0xFFA1FBBE),
                        overlayColor: Colors.transparent,
                        trackShape: const PluginSliderTrackShape(),
                        thumbShape: const PluginSliderThumbShape()),
                    child: Slider(
                      min: widget.minNumber,
                      max: widget.maxNumber,
                      // divisions: 19,
                      value: _value,
                      onChanged: (value) {
                        setState(() {
                          _value = value;
                        });
                        if (widget.onChanged != null) {
                          widget.onChanged!(_value);
                        }
                      },
                    )))),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
            widget.subtitleLeft,
            style: Theme.of(context)
                .textTheme
                .headline5
                ?.copyWith(color: Color(0xFFFFFBF9), height: 0.9, fontSize: 12),
          ),
          Text(
            widget.subtitleRight,
            style: Theme.of(context)
                .textTheme
                .headline5
                ?.copyWith(color: Color(0xFFFFFBF9), height: 0.9, fontSize: 12),
          )
        ])
      ],
    );
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
                      bottomLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                      bottomRight: Radius.circular(24))),
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
              margin: EdgeInsets.only(bottom: 34, top: 131),
              child: PluginButton(
                title: dic['loan.create']!,
                onPressed: onPressed,
              ))
        ],
      ),
    );
  }
}

class LoanOverviewCard extends StatelessWidget {
  LoanOverviewCard(
    this.loan,
    this.stableCoinSymbol,
    this.stableCoinDecimals,
    this.collateralDecimals,
    this.tokenIcons,
    this.prices,
  );
  final LoanData loan;
  final String stableCoinSymbol;
  final int stableCoinDecimals;
  final int? collateralDecimals;
  final Map<String, Widget> tokenIcons;
  final Map<String?, BigInt> prices;

  final colorSafe = Color(0xFFB9F6CA);
  final colorWarn = Color(0xFFFFD180);
  final colorDanger = Color(0xFFFF8A80);

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;

    final requiredCollateralRatio =
        double.parse(Fmt.token(loan.type.requiredCollateralRatio, 18));
    final borrowedRatio = 1 / loan.collateralRatio;

    final collateralValue = Fmt.bigIntToDouble(
            prices[loan.token!.tokenNameId], acala_price_decimals) *
        Fmt.bigIntToDouble(loan.collaterals, collateralDecimals!);

    return GestureDetector(
      child: Stack(children: [
        RoundedCard(
          margin: EdgeInsets.only(bottom: 16),
          child: Container(
            width: double.infinity,
            height: 176,
            child: LiquidLinearProgressIndicator(
              value: borrowedRatio,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation(
                  loan.collateralRatio > requiredCollateralRatio
                      ? loan.collateralRatio > requiredCollateralRatio + 0.2
                          ? colorSafe
                          : colorWarn
                      : colorDanger),
              borderRadius: 16,
              direction: Axis.vertical,
            ),
          ),
        ),
        Container(
          color: Colors.transparent,
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.only(bottom: 8),
                child: Text(
                    '${dic['loan.collateral']}(${PluginFmt.tokenView(loan.token!.symbol)})'),
              ),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                    margin: EdgeInsets.only(right: 8),
                    child: TokenIcon(loan.token!.symbol!, tokenIcons)),
                Text(
                    Fmt.priceFloorBigInt(loan.collaterals, collateralDecimals!,
                        lengthMax: 4),
                    style: TextStyle(
                      fontSize: 26,
                      letterSpacing: -0.8,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    )),
                Container(
                  margin: EdgeInsets.only(left: 8, bottom: 4),
                  child: Text(
                    '≈ \$${Fmt.priceFloor(collateralValue)}',
                    style: TextStyle(
                        letterSpacing: -0.8,
                        color: Theme.of(context).disabledColor),
                  ),
                ),
              ]),
              Row(children: [
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        margin: EdgeInsets.only(top: 24, bottom: 8),
                        child: Text(dic['loan.borrowed']! +
                            '(${PluginFmt.tokenView(stableCoinSymbol)})')),
                    Text(
                      Fmt.priceCeilBigInt(loan.debits, stableCoinDecimals),
                      style: Theme.of(context).textTheme.headline4,
                    )
                  ],
                )),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        margin: EdgeInsets.only(top: 24, bottom: 8),
                        child: Text(dic['loan.ratio']!)),
                    Text(
                      Fmt.ratio(loan.collateralRatio),
                      style: Theme.of(context).textTheme.headline4,
                    )
                  ],
                )),
              ])
            ],
          ),
        ),
      ]),
      onTap: () => Navigator.of(context)
          .pushNamed(LoanDetailPage.route, arguments: loan),
    );
  }
}

class AccountCard extends StatelessWidget {
  AccountCard(this.account);
  final KeyPairData account;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16.0,
            spreadRadius: 4.0,
            offset: Offset(2.0, 2.0),
          )
        ],
      ),
      child: ListTile(
        dense: true,
        leading: AddressIcon(account.address, svg: account.icon, size: 36),
        title: Text(account.name!.toUpperCase()),
        subtitle: Text(Fmt.address(account.address)!),
      ),
    );
  }
}

class AccountCardLayout extends StatelessWidget {
  AccountCardLayout(this.account, this.child);
  final KeyPairData account;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        margin: EdgeInsets.only(top: 64),
        child: child,
      ),
      AccountCard(account),
    ]);
  }
}

class CollateralIncentiveList extends StatelessWidget {
  CollateralIncentiveList({
    this.plugin,
    this.loans,
    this.incentives,
    this.rewards,
    this.totalCDPs,
    this.tokenIcons,
    this.marketPrices,
    this.collateralDecimals,
    this.incentiveTokenSymbol,
    this.dexIncentiveLoyaltyEndBlock,
  });

  final PluginKarura? plugin;
  final Map<String?, LoanData>? loans;
  final Map<String?, List<IncentiveItemData>>? incentives;
  final Map<String?, CollateralRewardData>? rewards;
  final Map<String?, TotalCDPData>? totalCDPs;
  final Map<String, Widget>? tokenIcons;
  final Map<String?, double>? marketPrices;
  final int? collateralDecimals;
  final String? incentiveTokenSymbol;
  final List<dynamic>? dexIncentiveLoyaltyEndBlock;

  Future<void> _onClaimReward(
      BuildContext context, TokenBalanceData token, String rewardView) async {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    final pool = {'Loans': token.currencyId};
    final params = TxConfirmParams(
      module: 'incentives',
      call: 'claimRewards',
      txTitle: dic['earn.claim'],
      txDisplay: {
        dic['loan.amount']: '≈ $rewardView $incentiveTokenSymbol',
        dic['earn.stake.pool']: token.symbol,
      },
      params: [pool],
    );
    Navigator.of(context).pushNamed(TxConfirmPage.route, arguments: params);
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala');
    final List<String?> tokensAll = incentives!.keys.toList();
    tokensAll.addAll(rewards!.keys.toList());
    final tokenIds = tokensAll.toSet().toList();
    tokenIds.removeWhere((e) => e == 'KSM');
    tokenIds.retainWhere((e) =>
        incentives![e] != null ||
        (rewards![e]?.reward != null && rewards![e]!.reward!.length > 0));

    if (tokenIds.length == 0) {
      return ListTail(isEmpty: true, isLoading: false);
    }
    final tokens = tokenIds
        .map((e) => AssetsUtils.getBalanceFromTokenNameId(plugin!, e))
        .toList();
    return ListView.builder(
        padding: EdgeInsets.only(bottom: 32),
        itemCount: tokens.length,
        itemBuilder: (_, i) {
          final token = tokens[i]!;
          final collateralValue = Fmt.bigIntToDouble(
              loans![token.tokenNameId]?.collateralInUSD, collateralDecimals!);
          double apy = 0;
          if (totalCDPs![token.tokenNameId]!.collateral > BigInt.zero &&
              marketPrices![token.symbol] != null &&
              incentives![token.tokenNameId] != null) {
            incentives![token.tokenNameId]!.forEach((e) {
              if (e.tokenNameId != 'Any') {
                final rewardToken = AssetsUtils.getBalanceFromTokenNameId(
                    plugin!, e.tokenNameId)!;
                apy += (marketPrices![rewardToken.symbol] ?? 0) *
                    e.amount! /
                    Fmt.bigIntToDouble(rewards![token.tokenNameId]?.sharesTotal,
                        collateralDecimals!) /
                    marketPrices![token.symbol]!;
              }
            });
          }
          final deposit = Fmt.priceFloorBigInt(
              loans![token.tokenNameId]?.collaterals, collateralDecimals!);

          bool canClaim = false;
          double? loyaltyBonus = 0;
          if (incentives![token.tokenNameId] != null) {
            loyaltyBonus = incentives![token.tokenNameId]![0].deduction;
          }

          final reward = rewards![token.tokenNameId];
          final rewardView = reward != null && reward.reward!.length > 0
              ? reward.reward!.map((e) {
                  final amount = double.parse(e['amount']);
                  if (amount > 0.0001) {
                    canClaim = true;
                  }
                  return '${Fmt.priceFloor(amount * (1 - loyaltyBonus!))}';
                }).join(' + ')
              : '0.00';

          final bestNumber = plugin!.store!.gov.bestNumber;
          var blockNumber;
          dexIncentiveLoyaltyEndBlock!.forEach((e) {
            if (token.tokenNameId == PluginFmt.getPool(plugin, e['pool'])) {
              blockNumber = e['blockNumber'];
              return;
            }
          });
          final blocksToEnd =
              blockNumber != null ? blockNumber - bestNumber.toInt() : null;

          return RoundedCard(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Container(
                          margin: EdgeInsets.only(right: 8),
                          child: TokenIcon(token.symbol!, tokenIcons!)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dic!['loan.collateral']!,
                              style: TextStyle(fontSize: 12)),
                          Text('$deposit ${PluginFmt.tokenView(token.symbol)}',
                              style: TextStyle(
                                fontSize: 20,
                                letterSpacing: -0.8,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              )),
                          Text(
                            '≈ \$${Fmt.priceFloor(collateralValue)}',
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      Expanded(child: Container(width: 2)),
                      OutlinedButtonSmall(
                        margin: EdgeInsets.all(0),
                        active: canClaim,
                        content: dic['earn.claim'],
                        onPressed: canClaim
                            ? () => _onClaimReward(context, token, rewardView)
                            : null,
                      )
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${dic['earn.reward']} ($incentiveTokenSymbol)',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                Text(
                  rewardView,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.8,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      InfoItem(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        title: '${dic['earn.apy']} ($incentiveTokenSymbol)',
                        content: Fmt.ratio(apy),
                        color: Theme.of(context).primaryColor,
                      ),
                      InfoItem(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        title: '${dic['earn.apy.0']} ($incentiveTokenSymbol)',
                        content: Fmt.ratio(apy * (1 - loyaltyBonus!)),
                        color: Theme.of(context).primaryColor,
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
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ),
                Visibility(
                    visible: blocksToEnd != null,
                    child: Container(
                      margin: EdgeInsets.only(top: 4),
                      child: Text(
                        '${dic['earn.loyal.end']}: ${Fmt.blockToTime(blocksToEnd ?? 0, 12500)}',
                        style: TextStyle(fontSize: 10),
                      ),
                    )),
                Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButtonSmall(
                        content: dic['loan.withdraw'],
                        active: false,
                        padding: EdgeInsets.only(top: 8, bottom: 8),
                        margin: EdgeInsets.only(right: 8),
                        onPressed: (loans![token.tokenNameId]?.collaterals ??
                                    BigInt.zero) >
                                BigInt.zero
                            ? () => Navigator.of(context).pushNamed(
                                  LoanDepositPage.route,
                                  arguments: LoanDepositPageParams(
                                      LoanDepositPage.actionTypeWithdraw,
                                      token),
                                )
                            : null,
                      ),
                    ),
                    Expanded(
                      child: OutlinedButtonSmall(
                        content: dic['loan.deposit'],
                        active: true,
                        padding: EdgeInsets.only(top: 8, bottom: 8),
                        margin: EdgeInsets.only(left: 8),
                        onPressed: () => Navigator.of(context).pushNamed(
                          LoanDepositPage.route,
                          arguments: LoanDepositPageParams(
                              LoanDepositPage.actionTypeDeposit, token),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
  }
}

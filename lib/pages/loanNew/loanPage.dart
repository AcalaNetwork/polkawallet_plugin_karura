import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/loanType.dart';
import 'package:polkawallet_plugin_karura/api/types/swapOutputData.dart';
import 'package:polkawallet_plugin_karura/common/components/connectionChecker.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/loan/loanCreatePage.dart';
import 'package:polkawallet_plugin_karura/pages/loan/loanHistoryPage.dart';
import 'package:polkawallet_plugin_karura/pages/loanNew/loanTabBarWidget.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/infoItemRow.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginIconButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginLoadingWidget.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginSliderThumbShape.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginSliderTrackShape.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTokenIcon.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:toast/toast.dart';
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

  Map<String, LoanData?> _editorLoans = Map<String, LoanData?>();
  Map<String, BigInt?> _collaterals = Map<String, BigInt?>();
  Map<String, BigInt?> _debitsShares = Map<String, BigInt?>();

  bool isInit = true;

  Future<void> _fetchData() async {
    widget.plugin.store!.earn.getdexIncentiveLoyaltyEndBlock(widget.plugin);
    widget.plugin.service!.gov.updateBestNumber();
    await widget.plugin.service!.loan
        .queryLoanTypes(widget.keyring.current.address);

    final priceQueryTokens = widget.plugin.store!.loan.loanTypes
        .map((e) => e.token!.symbol)
        .toList();
    priceQueryTokens.add(widget.plugin.networkState.tokenSymbol![0]);
    await widget.plugin.service!.assets.queryMarketPrices(priceQueryTokens);

    if (mounted) {
      await widget.plugin.service!.loan
          .subscribeAccountLoans(widget.keyring.current.address);
    }

    setState(() {
      _editorLoans = Map<String, LoanData?>();
      _collaterals = Map<String, BigInt?>();
      _debitsShares = Map<String, BigInt?>();
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
      Future.delayed(Duration(milliseconds: 500), () {
        _fetchData();
      });
    }
  }

  Future<Map?> _getTxParams(LoanData loan, int? stableCoinDecimals) async {
    final collaterals = loan.collaterals - _collaterals[loan.token!.symbol]!;
    final debitShares = loan.debitShares - _debitsShares[loan.token!.symbol]!;
    final debits = loan.type.debitShareToDebit(debitShares);

    if (collaterals == BigInt.zero && debitShares == BigInt.zero) {
      return null;
    }

    if (loan.type.debitShareToDebit(loan.debitShares) == BigInt.zero &&
        loan.collaterals > BigInt.zero) {
      final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala');
      await showCupertinoDialog(
          context: context,
          builder: (_) {
            return CupertinoAlertDialog(
              content: Text(dic!['v3.loan.paybackMessage']!),
              actions: <Widget>[
                CupertinoDialogAction(
                  child: Text(dic['v3.loan.iUnderstand']!),
                  onPressed: () => Navigator.of(context).pop(false),
                )
              ],
            );
          });
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
      debitSubtract =
          loan.type.debitShareToDebit(_debitsShares[loan.token!.symbol]!) ==
                      BigInt.zero &&
                  debits <= loan.type.minimumDebitValue
              ? loan.type.debitToDebitShare(
                  (loan.type.minimumDebitValue + BigInt.from(10000)))
              : debitShares;
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
        if (loan.type.debitShareToDebit(debits).abs() -
                    loan.type
                        .debitShareToDebit(_debitsShares[loan.token!.symbol]!)
                        .abs() >
                BigInt.zero &&
            loan.type.debitShareToDebit(debits).abs() -
                    loan.type
                        .debitShareToDebit(_debitsShares[loan.token!.symbol]!)
                        .abs() <
                debitValueOne) {
          final bool canContinue =
              await (_confirmPaybackParams() as Future<bool>);
          if (!canContinue) return null;
          debitSubtract =
              debitSubtract + loan.type.debitToDebitShare(debitValueOne);
        }
      }
      detail[dic![dicValue]!] = Text(
        '${Fmt.priceFloorBigInt(loan.type.debitShareToDebit(debitSubtract).abs(), balancePair[0]!.decimals!, lengthMax: 4)} ${PluginFmt.tokenView(karura_stable_coin)}',
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
            content: Text(dic!['loan.warn.KSM']!),
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
                  widget.plugin, karura_stable_coin)!
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
    SwapOutputData? output;
    final confirmed = await showCupertinoDialog(
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
                    output = snapshot.data;
                    final left = Fmt.bigIntToDouble(
                            loan.collaterals, collateralDecimal!) -
                        snapshot.data!.amount!;
                    return InfoItemRow(dic['loan.close.receive']!,
                        Fmt.priceFloor(left) + loan.token!.symbol!);
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
    );
    if (confirmed) {
      final params = [
        loan.token!.currencyId,
        loan.collaterals.toString(),
        output != null
            ? output!.path!
                .map((e) => AssetsUtils.getBalanceFromTokenNameId(
                        widget.plugin, e['name'])!
                    .currencyId)
                .toList()
            : null
      ];

      final isRuntimeOld = await widget.plugin.sdk.webView!.evalJavascript(
          '(api.tx.honzon.closeLoanHasDebitByDex.meta.args.length > 2);',
          wrapPromise: false);
      final res = await Navigator.of(context).pushNamed(
        TxConfirmPage.route,
        arguments: TxConfirmParams(
            module: 'honzon',
            call: 'closeLoanHasDebitByDex',
            txTitle: dic!['loan.close'],
            txDisplay: {
              'collateral': loan.token!.symbol,
              'payback': Fmt.priceCeil(debit) + karura_stable_coin_view,
            },
            params: isRuntimeOld ? params : params.sublist(0, 2)),
      );
      if (res != null) {
        Navigator.of(context).pop(res);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala');
    final args = ModalRoute.of(context)?.settings.arguments as Map?;

    return Observer(builder: (_) {
      final stableCoinDecimals = widget.plugin.networkState.tokenDecimals![
          widget.plugin.networkState.tokenSymbol!.indexOf(karura_stable_coin)];

      final loans = widget.plugin.store!.loan.loans.values.toList();
      loans.retainWhere((loan) =>
          loan.debits > BigInt.zero || loan.collaterals > BigInt.zero);
      final isDataLoading = isInit
          ? true
          : widget.plugin.store!.loan.loansLoading && loans.length == 0 ||
              // do not show loan card if collateralRatio was not calculated.
              (loans.length > 0 && loans[0].collateralRatio <= 0);
      isInit = false;

      /// The initial tab index will be from arguments or user's vault.
      int initialLoanTypeIndex = 0;
      if (args != null && args['loanType'] != null) {
        initialLoanTypeIndex = widget.plugin.store!.loan.loanTypes
            .indexWhere((e) => e.token?.tokenNameId == args['loanType']);
      } else if (loans.length > 0) {
        initialLoanTypeIndex = widget.plugin.store!.loan.loanTypes.indexWhere(
            (e) => e.token?.tokenNameId == loans[0].token?.tokenNameId);
      }

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
                          LoanData? loan = _editorLoans[e.token!.symbol];
                          if (loan == null) {
                            final _loans = loans.where((data) =>
                                data.token!.symbol == e.token!.symbol);
                            loan = _loans.length > 0 ? _loans.first : null;
                            _editorLoans[e.token!.symbol!] = loan;
                          }
                          Widget child = CreateVaultWidget(onPressed: () {
                            Navigator.of(context).pushNamed(
                                LoanCreatePage.route,
                                arguments: e.token);
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
                              _collaterals[e.token!.symbol!] = loan.collaterals;
                            }
                            if (_debitsShares[e.token!.symbol] == null) {
                              _debitsShares[e.token!.symbol!] =
                                  loan.debitShares;
                            }

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

                            final collateralsValue = loan.collaterals -
                                _collaterals[e.token!.symbol!]!;
                            final debitsSharesValue = loan.debitShares -
                                _debitsShares[e.token!.symbol!]!;
                            final debitsValue =
                                loan.type.debitShareToDebit(debitsSharesValue);

                            final originalDebitsValue = loan.type
                                .debitShareToDebit(
                                    _debitsShares[e.token!.symbol!]!);

                            final debitRatio = loan.debits /
                                loan.collateralInUSD *
                                Fmt.bigIntToDouble(
                                    loan.type.liquidationRatio, 18);

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
                                      padding:
                                          EdgeInsets.symmetric(vertical: 9),
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
                                            maxNumber: Fmt.bigIntToDouble(
                                                    _collaterals[
                                                        e.token!.symbol]!,
                                                    balancePair[0]!.decimals!) +
                                                balance,
                                            minNumber: Fmt.bigIntToDouble(
                                                        loan.requiredCollateral,
                                                        balancePair[0]!
                                                            .decimals!) >
                                                    available
                                                ? available
                                                : Fmt.bigIntToDouble(
                                                    loan.requiredCollateral,
                                                    balancePair[0]!.decimals!),
                                            subtitleLeft: dic['loan.withdraw']!,
                                            subtitleRight: dic['loan.deposit']!,
                                            error:
                                                "${dic['v3.loan.errorMessage1']} ${PluginFmt.tokenView(loan.token!.symbol)} ${dic['v3.loan.errorMessage2']}",
                                            isShowError: Fmt.bigIntToDouble(
                                                        loan.requiredCollateral,
                                                        balancePair[0]!
                                                            .decimals!) >=
                                                    available &&
                                                balance == 0,
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
                                                // loan.collateralInUSD =
                                                //     loan.tokenToUSD(
                                                //         collaterals,
                                                //         tokenPrice,
                                                //         stableCoinDecimals: widget
                                                //             .plugin
                                                //             .store!
                                                //             .assets
                                                //             .tokenBalanceMap[
                                                //                 karura_stable_coin]!
                                                //             .decimals!,
                                                //         collateralDecimals: loan
                                                //             .token!.decimals!);
                                                loan.maxToBorrow = Fmt.tokenInt(
                                                    "$maxToBorrow",
                                                    balancePair[0]!.decimals!);
                                                loan.collateralRatio =
                                                    Fmt.bigIntToDouble(
                                                            collaterals,
                                                            balancePair[0]!
                                                                .decimals!) *
                                                        availablePrice /
                                                        debits;
                                                loan.liquidationPrice =
                                                    Fmt.tokenInt(
                                                        '${debits * Fmt.bigIntToDouble(e.liquidationRatio, acala_price_decimals) / value}',
                                                        acala_price_decimals);
                                              }
                                              setState(() {});
                                            },
                                          ),
                                          Container(
                                              margin: EdgeInsets.only(top: 12),
                                              child: LoanCollateral(
                                                title:
                                                    '${dic['loan.borrowed']} (${PluginFmt.tokenView(karura_stable_coin)})',
                                                maxNumber: maxToBorrow < debits
                                                    ? debits
                                                    : maxToBorrow,
                                                minNumber: balanceStableCoin >
                                                        originalDebitsValue
                                                    ? 0
                                                    : Fmt.bigIntToDouble(
                                                        originalDebitsValue -
                                                            balanceStableCoin,
                                                        balancePair[1]!
                                                            .decimals!),
                                                subtitleLeft:
                                                    dic['loan.payback']!,
                                                subtitleRight:
                                                    dic['loan.mint']!,
                                                error:
                                                    "${dic['v3.loan.errorMessage3']}  ${PluginFmt.tokenView(karura_stable_coin)} ${dic['v3.loan.errorMessage4']} ",
                                                isShowError: maxToBorrow <=
                                                        debits &&
                                                    Fmt.bigIntToDouble(
                                                            balanceStableCoin,
                                                            balancePair[1]!
                                                                .decimals!) ==
                                                        0,
                                                price: 1.0,
                                                value: debits,
                                                onChanged: (value) {
                                                  setState(() {
                                                    loan!.debits = Fmt.tokenInt(
                                                        "$value",
                                                        balancePair[0]!
                                                            .decimals!);
                                                    loan.debitShares = loan.type
                                                        .debitToDebitShare(
                                                            loan.debits);
                                                    loan.collateralRatio =
                                                        Fmt.bigIntToDouble(
                                                                loan
                                                                    .collaterals,
                                                                balancePair[0]!
                                                                    .decimals!) *
                                                            availablePrice /
                                                            value;
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
                                                    loan.liquidationPrice =
                                                        Fmt.tokenInt(
                                                            '${value * Fmt.bigIntToDouble(e.liquidationRatio, acala_price_decimals) / Fmt.bigIntToDouble(loan.collaterals, balancePair[0]!.decimals!)}',
                                                            acala_price_decimals);
                                                  });
                                                },
                                              ))
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      child: Padding(
                                          padding: EdgeInsets.only(bottom: 5),
                                          child: Text(dic['loan.close.dex']!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline6
                                                  ?.copyWith(
                                                      color: Colors.white,
                                                      fontSize: 10))),
                                      onTap: () => _closeVault(
                                          loan!,
                                          balancePair[0]!.decimals,
                                          Fmt.bigIntToDouble(loan.debits,
                                              balancePair[1]!.decimals!)),
                                    ),
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
                                                    fontWeight:
                                                        FontWeight.w600)),
                                        Text(
                                            "${Fmt.priceCeilBigInt(debitsValue.abs(), balancePair[1]!.decimals!, lengthMax: 4)} ${PluginFmt.tokenView(karura_stable_coin)}",
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
                                                    fontWeight:
                                                        FontWeight.w600)),
                                        Text(
                                            "${Fmt.priceCeilBigInt(collateralsValue.abs(), balancePair[0]!.decimals!, lengthMax: 4)} ${PluginFmt.tokenView(loan.token!.symbol)}",
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
                                                    fontWeight:
                                                        FontWeight.w600)),
                                        Text('${Fmt.ratio(debitRatio)}',
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
                                        padding: EdgeInsets.only(
                                            top: 37, bottom: 38),
                                        child: PluginButton(
                                          title: '${dic['v3.loan.submit']}',
                                          onPressed: () {
                                            _onSubmit(
                                                loan!, stableCoinDecimals);
                                          },
                                        )),
                                  ],
                                ));
                          }
                          return LoanTabBarWidgetData(
                            PluginTokenIcon(
                                e.token!.symbol!, widget.plugin.tokenIcons),
                            child,
                          );
                        }).toList(),
                      )),
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
        "${Fmt.priceFloorBigIntFormatter(available, balancePair[0]!.decimals!, lengthMax: 4)} ${loan.token!.symbol}";
    var availableViewRight = 3 / 347 * headCardWidth +
        85 / 347 * headCardWidth -
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
        Fmt.priceFloorBigIntFormatter(maxToBorrow, balancePair[1]!.decimals!);
    final debitRatio = loan.debits /
        loan.collateralInUSD *
        Fmt.bigIntToDouble(loan.type.liquidationRatio, 18);

    return Container(
      padding: EdgeInsets.only(left: 6, top: 6, right: 6, bottom: 10),
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
                            1 - debitRatio - 0.04,
                            1 - debitRatio - 0.04,
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
                                      fontSize: 18,
                                    )),
                            Text(Fmt.ratio(debitRatio),
                                style: Theme.of(context)
                                    .textTheme
                                    .headline3
                                    ?.copyWith(
                                      color: Colors.white,
                                      height: 1.0,
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
              child: Text(
                  '$maxToBorrowView ${PluginFmt.tokenView(karura_stable_coin)}',
                  style: Theme.of(context).textTheme.headline5?.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                      )),
            ),
            Container(
              padding: EdgeInsets.only(
                  right: 15 / 347 * headCardWidth +
                      77 / 347 * headCardWidth -
                      PluginFmt.boundingTextSize(
                          '${dic['withdraw.able']!}:',
                          Theme.of(context).textTheme.headline3?.copyWith(
                                color: Color(0xFF26282d),
                                fontSize: 10,
                              )).width,
                  bottom: (I18n.of(context)!.locale.languageCode == 'zh'
                          ? 51
                          : 50) /
                      210 *
                      headCardHeight),
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
            Container(
              padding: EdgeInsets.only(left: 3, bottom: 5),
              alignment: Alignment.bottomCenter,
              child: Text(
                  '${dic['collateral.interest']}:${Fmt.ratio(loan.stableFeeYear)}',
                  style: Theme.of(context).textTheme.headline3?.copyWith(
                        color: Color(0xFFFF7849),
                        fontSize: 11,
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
      this.error = '',
      this.isShowError = false,
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
  String error;
  bool isShowError;

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
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 9),
            child: Row(
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
                                  content: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                              "min:${Fmt.priceCeil(widget.minNumber, lengthMax: 4)}"),
                                          Text(
                                              "max:${Fmt.priceCeil(widget.maxNumber, lengthMax: 4)}"),
                                        ],
                                      ),
                                      CupertinoTextField(
                                        controller: _controller,
                                        keyboardType:
                                            TextInputType.numberWithOptions(
                                                decimal: true),
                                        clearButtonMode:
                                            OverlayVisibilityMode.editing,
                                      )
                                    ],
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
                                        if (double.parse(_controller.text) >=
                                                widget.minNumber &&
                                            double.parse(_controller.text) <=
                                                widget.maxNumber) {
                                          setState(() {
                                            _value =
                                                double.parse(_controller.text);
                                          });
                                          if (widget.onChanged != null) {
                                            widget.onChanged!(_value);
                                          }
                                        } else {
                                          Toast.show(
                                              I18n.of(context)!.getDic(
                                                  i18n_full_dic_ui,
                                                  'common')!['amount.error']!,
                                              context,
                                              duration: Toast.LENGTH_SHORT,
                                              gravity: Toast.CENTER);
                                        }
                                      },
                                      child: Text(I18n.of(context)!.getDic(
                                          i18n_full_dic_karura,
                                          'common')!['ok']!),
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
                            style: Theme.of(context)
                                .textTheme
                                .bodyText1
                                ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
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
            )),
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 9),
            child: Text(
              "Value \$${Fmt.priceFloorFormatter(_value * widget.price, lengthMax: 4)}",
              style: Theme.of(context)
                  .textTheme
                  .headline5
                  ?.copyWith(color: Color(0xFFFFFBF9), fontSize: 12),
            )),
        !widget.isShowError
            ? Padding(
                padding: EdgeInsets.symmetric(horizontal: 9),
                child: ClipRect(
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
                              value: _value,
                              onChanged: (value) {
                                setState(() {
                                  _value = value;
                                });
                                if (widget.onChanged != null) {
                                  widget.onChanged!(_value);
                                }
                              },
                            )))))
            : Container(
                color: Color(0xFF292A2C),
                padding: EdgeInsets.symmetric(vertical: 2, horizontal: 9),
                margin: EdgeInsets.symmetric(vertical: 5),
                width: double.infinity,
                child: Text(
                  widget.error,
                  style: Theme.of(context).textTheme.headline5?.copyWith(
                      color: Color(0xFFFF7849),
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              ),
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 9),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.subtitleLeft,
                    style: Theme.of(context).textTheme.headline5?.copyWith(
                        color: Color(0xFFFFFBF9), height: 0.9, fontSize: 12),
                  ),
                  Text(
                    widget.subtitleRight,
                    style: Theme.of(context).textTheme.headline5?.copyWith(
                        color: Color(0xFFFFFBF9), height: 0.9, fontSize: 12),
                  )
                ]))
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

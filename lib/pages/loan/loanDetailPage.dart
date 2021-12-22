import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/loanType.dart';
import 'package:polkawallet_plugin_karura/api/types/swapOutputData.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/loan/loanCard.dart';
import 'package:polkawallet_plugin_karura/pages/loan/loanChart.dart';
import 'package:polkawallet_plugin_karura/pages/loan/loanPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/infoItemRow.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

class LoanDetailPage extends StatefulWidget {
  LoanDetailPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/loan/detail';

  @override
  _LoanDetailPageState createState() => _LoanDetailPageState();
}

class _LoanDetailPageState extends State<LoanDetailPage> {
  Future<SwapOutputData> _queryReceiveAmount(
      BuildContext ctx, TokenBalanceData collateral, double debit) async {
    return widget.plugin.api.swap.queryTokenSwapAmount(
      null,
      debit.toStringAsFixed(2),
      [
        {...collateral.currencyId, 'decimals': collateral.decimals},
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
      LoanData loan, int collateralDecimal, double debit) async {
    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
    final dicCommon = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
    SwapOutputData output;
    final confirmed = await showCupertinoDialog(
      context: context,
      builder: (BuildContext ctx) {
        return CupertinoAlertDialog(
          title: Text(dic['loan.close']),
          content: Column(
            children: [
              Text(dic['loan.close.dex.info']),
              Divider(),
              FutureBuilder<SwapOutputData>(
                future: _queryReceiveAmount(ctx, loan.token, debit),
                builder: (_, AsyncSnapshot<SwapOutputData> snapshot) {
                  if (snapshot.hasData) {
                    output = snapshot.data;
                    final left = Fmt.bigIntToDouble(
                            loan.collaterals, collateralDecimal) -
                        snapshot.data.amount;
                    return InfoItemRow(dic['loan.close.receive'],
                        Fmt.priceFloor(left) + loan.token.symbol);
                  } else {
                    return Container();
                  }
                },
              ),
            ],
          ),
          actions: <Widget>[
            CupertinoButton(
              child: Text(dicCommon['cancel']),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            CupertinoButton(
              child: Text(dicCommon['ok']),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
    if (confirmed) {
      final params = [
        loan.token.currencyId,
        loan.collaterals.toString(),
        output != null
            ? output.path
                .map((e) => AssetsUtils.getBalanceFromTokenNameId(
                        widget.plugin, e['name'])
                    .currencyId)
                .toList()
            : null
      ];

      final isRuntimeOld = await widget.plugin.sdk.webView.evalJavascript(
          '(api.tx.honzon.closeLoanHasDebitByDex.meta.args.length > 2);',
          wrapPromise: false);
      print('isRuntimeOld');
      print(isRuntimeOld);
      final res = await Navigator.of(context).pushNamed(
        TxConfirmPage.route,
        arguments: TxConfirmParams(
            module: 'honzon',
            call: 'closeLoanHasDebitByDex',
            txTitle: dic['loan.close'],
            txDisplay: {
              'collateral': loan.token.symbol,
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
    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');

    return Observer(
      builder: (_) {
        final LoanData loan = ModalRoute.of(context).settings.arguments;

        final balancePair = AssetsUtils.getBalancePairFromTokenNameId(
            widget.plugin, [loan.token.tokenNameId, karura_stable_coin]);

        final dataChartDebit = [
          Fmt.bigIntToDouble(loan.debitInUSD, balancePair[1].decimals),
          Fmt.bigIntToDouble(
              loan.maxToBorrow - loan.debitInUSD > BigInt.zero
                  ? loan.maxToBorrow - loan.debitInUSD
                  : BigInt.zero,
              balancePair[1].decimals),
        ];
        final price = widget.plugin.store.assets.prices[loan.token.tokenNameId];
        final dataChartPrice = [
          Fmt.bigIntToDouble(loan.liquidationPrice, balancePair[1].decimals),
          Fmt.bigIntToDouble(
              price - loan.liquidationPrice > BigInt.zero
                  ? price - loan.liquidationPrice
                  : BigInt.zero,
              balancePair[1].decimals),
          Fmt.bigIntToDouble(
              price ~/ (BigInt.one + BigInt.two), balancePair[1].decimals),
        ];
        final requiredCollateralRatio =
            double.parse(Fmt.token(loan.type.requiredCollateralRatio, 18));
        final colorType = loan.collateralRatio > requiredCollateralRatio
            ? loan.collateralRatio > requiredCollateralRatio + 0.2
                ? 0
                : 1
            : loan.collateralRatio > 1
                ? 2
                : 0;

        final debitDouble =
            Fmt.bigIntToDouble(loan.debits, balancePair[1].decimals);
        final needSwap = Fmt.balanceInt(balancePair[1].amount) < loan.debits;

        final titleStyle = TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).unselectedWidgetColor,
          letterSpacing: -0.8,
        );
        final subtitleStyle = TextStyle(fontSize: 12);

        return Scaffold(
          backgroundColor: Theme.of(context).cardColor,
          appBar: AppBar(
              title: Text(PluginFmt.tokenView(loan.token.symbol)),
              centerTitle: true),
          body: SafeArea(
            child: AccountCardLayout(
              widget.keyring.current,
              Column(
                children: <Widget>[
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.all(16),
                      children: [
                        Container(
                            margin: EdgeInsets.only(bottom: 16),
                            child: Row(children: [
                              Expanded(
                                  child: RoundedCard(
                                      padding:
                                          EdgeInsets.only(top: 8, bottom: 16),
                                      child: Column(
                                        children: [
                                          LoanDonutChart(
                                            dataChartDebit,
                                            title: Fmt.priceCeilBigInt(
                                                loan.debits,
                                                balancePair[1].decimals),
                                            subtitle: dic['loan.borrowed'],
                                            colorType: colorType,
                                          ),
                                          Text(
                                              Fmt.priceFloorBigInt(
                                                  loan.maxToBorrow,
                                                  balancePair[1].decimals),
                                              style: titleStyle),
                                          Text(
                                              '${dic['borrow.limit']}($karura_stable_coin_view)',
                                              style: subtitleStyle)
                                        ],
                                      ))),
                              Container(width: 16),
                              Expanded(
                                  child: RoundedCard(
                                      padding:
                                          EdgeInsets.only(top: 8, bottom: 16),
                                      child: Column(
                                        children: [
                                          LoanDonutChart(
                                            dataChartPrice,
                                            title: Fmt.priceCeilBigInt(
                                                loan.liquidationPrice, 18),
                                            subtitle: dic['liquid.price'],
                                            colorType: colorType,
                                          ),
                                          Text(Fmt.priceFloorBigInt(price, 18),
                                              style: titleStyle),
                                          Text(
                                              '${PluginFmt.tokenView(loan.token.symbol)} ${dic['collateral.price']}(\$)',
                                              style: subtitleStyle)
                                        ],
                                      ))),
                            ])),
                        LoanCollateralCard(
                            loan,
                            Fmt.priceFloorBigInt(
                                Fmt.balanceInt(balancePair[0].amount),
                                balancePair[0].decimals),
                            balancePair[1].decimals,
                            balancePair[0].decimals,
                            widget.plugin.tokenIcons),
                        LoanDebtCard(
                            loan,
                            Fmt.priceFloorBigInt(
                                Fmt.balanceInt(balancePair[1].amount),
                                balancePair[1].decimals),
                            karura_stable_coin,
                            balancePair[1].decimals,
                            balancePair[0].decimals,
                            widget.plugin.tokenIcons),
                        Container(
                          margin: EdgeInsets.only(bottom: 16),
                          child: Visibility(
                              visible: needSwap,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  GestureDetector(
                                    child: Text(
                                      dic['loan.close.dex'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        decoration: TextDecoration.underline,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    onTap: () => _closeVault(loan,
                                        balancePair[0].decimals, debitDouble),
                                  )
                                ],
                              )),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

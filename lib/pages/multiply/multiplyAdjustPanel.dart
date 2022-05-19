import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/loanType.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/loanNew/loanInfoPanel.dart';
import 'package:polkawallet_plugin_karura/pages/swapNew/bootstrapPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';

class MultiplyAdjustPanel extends StatefulWidget {
  MultiplyAdjustPanel(this.plugin, this.keyring, this.loanType);
  final PluginKarura plugin;
  final Keyring keyring;
  final LoanType loanType;

  @override
  _MultiplyAdjustPanelState createState() => _MultiplyAdjustPanelState();
}

class _MultiplyAdjustPanelState extends State<MultiplyAdjustPanel> {
  double _slider = 0;

  Map _getBuyingParams(LoanType loanType, List<TokenBalanceData> balancePair,
      double collateralChange, double debitChange, double debitNew) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    const slippage = 0.05;
    final buyingWithSlippage = collateralChange * (1 - slippage);
    print('buyingWithSlippage');
    print(buyingWithSlippage);

    return {
      'detail': {
        'buying': Text(
          '≈ ${Fmt.priceFloor(collateralChange, lengthMax: 4)} ${PluginFmt.tokenView(widget.loanType.token?.symbol)}',
          style: Theme.of(context)
              .textTheme
              .headline1
              ?.copyWith(color: PluginColorsDark.headline1),
        ),
        'outstanding debt': Text(
          '${Fmt.priceCeil(debitNew)} $karura_stable_coin_view',
          style: Theme.of(context)
              .textTheme
              .headline1
              ?.copyWith(color: PluginColorsDark.headline1),
        ),
      },
      'params': [
        widget.loanType.token?.currencyId,
        Fmt.tokenInt(debitChange.abs().toString(), balancePair[1].decimals!)
            .toString(),
        Fmt.tokenInt(
                buyingWithSlippage.abs().toString(), balancePair[0].decimals!)
            .toString()
      ]
    };
  }

  Map _getSellingParams(LoanType loanType, List<TokenBalanceData> balancePair,
      double collateralChange, double debitChange, double debitNew) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    const slippage = 0.05;
    final debitChangeWithSlippage = debitChange * (1 - slippage);
    print('debitChangeWithSlippage');
    print(debitChangeWithSlippage);
    print(Fmt.tokenInt(
        debitChangeWithSlippage.abs().toString(), balancePair[1].decimals!));
    print(loanType.debitToDebitShare(Fmt.tokenInt(
        debitChangeWithSlippage.abs().toString(), balancePair[1].decimals!)));

    final detail = {
      'selling': Text(
        '${Fmt.priceFloor(collateralChange.abs(), lengthMax: 4)} ${PluginFmt.tokenView(widget.loanType.token?.symbol)}',
        style: Theme.of(context)
            .textTheme
            .headline1
            ?.copyWith(color: PluginColorsDark.headline1),
      ),
      'outstanding debt': Text(
        '≈ ${Fmt.priceCeil(debitNew)} $karura_stable_coin_view',
        style: Theme.of(context)
            .textTheme
            .headline1
            ?.copyWith(color: PluginColorsDark.headline1),
      ),
    };

    return {
      'call': 'shrinkPositionDebit',
      'detail': detail,
      'params': [
        widget.loanType.token?.currencyId,
        Fmt.tokenInt(
                collateralChange.abs().toString(), balancePair[0].decimals!)
            .toString(),
        Fmt.tokenInt(debitChangeWithSlippage.abs().toString(),
                balancePair[1].decimals!)
            .toString()
      ]
    };
  }

  Future<void> _onSubmit(LoanType loanType, double collateralChange,
      double debitChange, double debitNew) async {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;

    final balancePair = AssetsUtils.getBalancePairFromTokenNameId(widget.plugin,
        [widget.loanType.token?.tokenNameId, karura_stable_coin]);

    final params = collateralChange > 0
        ? _getBuyingParams(
            loanType, balancePair, collateralChange, debitChange, debitNew)
        : _getSellingParams(
            loanType, balancePair, collateralChange, debitChange, debitNew);

    Navigator.of(context).pushNamed(TxConfirmPage.route,
        arguments: TxConfirmParams(
          module: 'honzon',
          call: collateralChange > 0
              ? 'expandPositionCollateral'
              : 'shrinkPositionDebit',
          txTitle:
              'Adjust Multiply ${PluginFmt.tokenView(loanType.token?.symbol)}',
          txDisplayBold: params['detail'],
          params: params['params'],
          isPlugin: true,
        ));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      final loan =
          widget.plugin.store!.loan.loans[widget.loanType.token?.tokenNameId];
      final ratioLeft =
          Fmt.bigIntToDouble(widget.loanType.requiredCollateralRatio, 18) * 100;
      if ((loan?.collateralRatio ?? 2) > 1 &&
          (loan?.collateralRatio ?? 2) * 100 < ratioLeft) {
        setState(() {
          _slider = ratioLeft - loan!.collateralRatio * 100;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
      final assetDic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common');

      final loanType = widget.plugin.store!.loan.loanTypes.firstWhere(
          (i) => i.token?.tokenNameId == widget.loanType.token?.tokenNameId);
      final token = widget.loanType.token!;
      final loan = widget.plugin.store!.loan.loans[token.tokenNameId];

      final balancePair = AssetsUtils.getBalancePairFromTokenNameId(
          widget.plugin, [token.tokenNameId, karura_stable_coin]);
      final collateralDouble =
          Fmt.bigIntToDouble(loan?.collaterals, balancePair[0].decimals!);
      final collateralView =
          Fmt.priceFloorBigInt(loan?.collaterals, balancePair[0].decimals!);

      final price = widget.plugin.store!.assets.prices[token.tokenNameId];
      final priceDouble = Fmt.bigIntToDouble(price, acala_price_decimals);

      final balance = Fmt.balanceInt(balancePair[0].amount);
      final available = balance;

      final minToBorrow = Fmt.bigIntToDouble(
          loanType.minimumDebitValue, balancePair[1].decimals!);

      final ratioLeft =
          Fmt.bigIntToDouble(loanType.requiredCollateralRatio, 18) * 100;
      final ratioRight =
          Fmt.bigIntToDouble(loanType.liquidationRatio, 18) * 100;
      final steps = (ratioLeft - ratioRight) / 5;

      final ratioNew = (ratioLeft - _slider) / 100;
      final collateralValueChange =
          (Fmt.bigIntToDouble(loan?.collateralInUSD, balancePair[1].decimals!) -
                  Fmt.bigIntToDouble(loan?.debits, balancePair[1].decimals!) *
                      ratioNew) /
              (ratioNew - 1);
      final collateralChange = collateralValueChange / priceDouble;
      final debitDouble =
          Fmt.bigIntToDouble(loan?.debits, balancePair[1].decimals!);
      final debitNew = debitDouble + collateralValueChange;
      final liquidationPriceNew = loanType.calcLiquidationPrice(
          Fmt.tokenInt(debitNew.toString(), balancePair[1].decimals!),
          Fmt.tokenInt((collateralDouble + collateralChange).toString(),
              balancePair[0].decimals!),
          collateralDecimals: balancePair[0].decimals!,
          stableCoinDecimals: balancePair[1].decimals!);
      final minDebitDouble = Fmt.bigIntToDouble(
          loanType.minimumDebitValue, balancePair[1].decimals!);
      const slippage = 0.05;
      final multiple = (collateralDouble + collateralChange) / collateralDouble;

      return SingleChildScrollView(
        child: Column(
          children: <Widget>[
            LoanInfoItemRow(dic['loan.collateral']!, collateralView),

            /// ----------------- slider start --------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('$ratioLeft%'), Text('$ratioRight%')],
            ),
            Stack(
              children: [
                Slider(
                  min: 0,
                  max: ratioLeft - ratioRight,
                  divisions: steps.toInt(),
                  value: (loan?.collateralRatio ?? 2) < 1 ||
                          (loan?.collateralRatio ?? 2) * 100 >= ratioLeft
                      ? 0
                      : ratioLeft - loan!.collateralRatio * 100,
                  label: Fmt.ratio(loan?.collateralRatio ?? 2),
                  activeColor: PluginColorsDark.headline2,
                  inactiveColor: PluginColorsDark.headline2,
                  onChanged: (v) => null,
                ),
                Slider(
                  min: 0,
                  max: ratioLeft - ratioRight,
                  divisions: steps.toInt(),
                  value: _slider,
                  label: '${ratioLeft - _slider}%',
                  onChanged: (value) {
                    setState(() {
                      _slider = value;
                    });
                  },
                ),
              ],
            ),
            Text(
                'liquidation price ------- \$${Fmt.priceFloorBigInt(loan?.liquidationPrice, acala_price_decimals)}'),
            Text(
                'new liquidation price ------- \$${Fmt.priceFloorBigInt(liquidationPriceNew, acala_price_decimals)}'),

            /// ----------------- slider end --------------------
            Padding(
                padding: EdgeInsets.only(bottom: 23, top: 15),
                child: Image.asset(
                    "packages/polkawallet_plugin_karura/assets/images/divider.png")),

            LoanInfoItemRow(
              'multiple',
              '1x -> ' + multiple.toStringAsFixed(2) + 'x',
            ),
            LoanInfoItemRow(
              collateralChange < 0 ? 'selling' : 'buying',
              '${Fmt.priceFloor(collateralChange.abs().toDouble(), lengthMax: 4)} (\$${Fmt.priceFloor((collateralChange.abs() * priceDouble).toDouble())})',
            ),
            LoanInfoItemRow(
              'total exp',
              '$collateralView -> ' +
                  Fmt.priceFloor(collateralDouble + collateralChange,
                      lengthMax: 4),
            ),
            LoanInfoItemRow(
              'debt',
              '${Fmt.priceFloor(debitDouble)} -> ' +
                  Fmt.priceFloor(debitDouble + collateralValueChange,
                      lengthMax: 4),
            ),
            LoanInfoItemRow('slippage', Fmt.ratio(slippage)),
            ErrorMessage(
                debitNew < minDebitDouble
                    ? '${assetDic!['min']} ${minToBorrow.toStringAsFixed(2)}'
                    : null,
                margin: EdgeInsets.symmetric(vertical: 2)),
            Padding(
                padding: EdgeInsets.only(top: 37, bottom: 38),
                child: PluginButton(
                  title: '${dic['v3.loan.submit']}',
                  onPressed: () {
                    if (debitNew > minDebitDouble && collateralChange != 0) {
                      _onSubmit(loanType, collateralChange,
                          collateralValueChange, debitNew);
                    }
                  },
                )),
          ],
        ),
      );
    });
  }
}

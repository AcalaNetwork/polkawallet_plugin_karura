import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/loanType.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/loanNew/loanInfoPanel.dart';
import 'package:polkawallet_plugin_karura/pages/multiply/slider/multiplySliderOverlayShape.dart';
import 'package:polkawallet_plugin_karura/pages/multiply/slider/multiplySliderThumbShape.dart';
import 'package:polkawallet_plugin_karura/pages/multiply/slider/multiplySliderTickMarkShape.dart';
import 'package:polkawallet_plugin_karura/pages/multiply/slider/multiplySliderTrackShape.dart';
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
import 'package:polkawallet_ui/components/v3/plugin/pluginInfoItem.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInputBalance.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTextTag.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';

class MultiplyCreatePage extends StatefulWidget {
  MultiplyCreatePage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/multiply/create';

  @override
  _MultiplyCreatePageState createState() => _MultiplyCreatePageState();
}

class _MultiplyCreatePageState extends State<MultiplyCreatePage> {
  final TextEditingController _amountCtrl = new TextEditingController();

  BigInt _amountCollateral = BigInt.zero;
  BigInt _amountDebit = BigInt.zero;
  double _slider = 0;

  bool _autoValidate = false;

  String? _error1;

  void _onAmount1Change(String value, LoanType loanType, BigInt? price,
      BigInt available, List<TokenBalanceData> balancePair) {
    String v = value.trim();

    var error = _validateAmount1(value, available, balancePair[0].decimals);
    setState(() {
      _error1 = error;
    });
    if (error != null) {
      return;
    }

    BigInt collateral = Fmt.tokenInt(v, balancePair[0].decimals!);
    setState(() {
      _amountCollateral = collateral;
    });

    if (v.isEmpty) return;

    _onSliderChanged(balancePair, loanType, 0);

    _checkAutoValidate();
  }

  void _onSliderChanged(
      List<TokenBalanceData> balancePair, LoanType loanType, double value) {
    final ratioLeft =
        Fmt.bigIntToDouble(loanType.requiredCollateralRatio, 18) * 100;
    setState(() {
      _slider = value;
      if (_amountCollateral > BigInt.zero) {
        final inputCollateralRatio = ratioLeft - value - 100;
        final price =
            widget.plugin.store!.assets.prices[loanType.token!.tokenNameId];
        _amountDebit = loanType.tokenToUSD(_amountCollateral, price,
                stableCoinDecimals: balancePair[1].decimals!,
                collateralDecimals: loanType.token!.decimals!) *
            BigInt.from(100) ~/
            BigInt.from(inputCollateralRatio);
      }
    });
  }

  void _checkAutoValidate({String? value1, String? value2}) {
    if (_autoValidate) return;
    if (value1 == null) {
      value1 = _amountCtrl.text.trim();
    }
    if (value1.isNotEmpty) {
      setState(() {
        _autoValidate = true;
      });
    }
  }

  String? _validateAmount1(
      String value, BigInt available, int? collateralDecimals) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common');

    String v = value.trim();
    final error = Fmt.validatePrice(v, context);
    if (error != null) {
      return error;
    }
    BigInt collateral = Fmt.tokenInt(v, collateralDecimals!);
    if (collateral > available) {
      return dic!['amount.low'];
    }
    return null;
  }

  Future<void> _onSubmit(
      String pageTitle, LoanType loanType, double multiple) async {
    final token =
        ModalRoute.of(context)?.settings.arguments as TokenBalanceData;
    final balancePair = AssetsUtils.getBalancePairFromTokenNameId(
        widget.plugin, [token.tokenNameId, karura_stable_coin]);
    var error = _validateAmount1(_amountCtrl.text,
        Fmt.balanceInt(balancePair[0].amount), balancePair[0].decimals!);
    setState(() {
      _error1 = error;
    });
    if (error != null) {
      return;
    }

    const slippage = 5;
    final ratioLeft =
        Fmt.bigIntToDouble(loanType.requiredCollateralRatio, 18) * 100;
    final buyingWithSlippage = _amountCollateral *
        BigInt.from(100) ~/
        BigInt.from(ratioLeft - _slider - 100) *
        BigInt.from(100 - slippage) ~/
        BigInt.from(100);
    final batchTxs = [
      'api.tx.honzon.adjustLoan(...${jsonEncode([
            token.currencyId,
            _amountCollateral.toString(),
            '0'
          ])})',
      'api.tx.honzon.expandPositionCollateral(...${jsonEncode([
            token.currencyId,
            _amountDebit.toString(),
            buyingWithSlippage.toString()
          ])})',
    ];
    final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
        arguments: TxConfirmParams(
          module: 'utility',
          call: 'batchAll',
          txTitle: pageTitle,
          txDisplayBold: {
            'buying': Text(
              '≈ ${Fmt.priceFloor(Fmt.bigIntToDouble(_amountCollateral, balancePair[0].decimals!) * (multiple - 1), lengthMax: 4)} ${PluginFmt.tokenView(token.symbol)}',
              style: Theme.of(context)
                  .textTheme
                  .headline1
                  ?.copyWith(color: PluginColorsDark.headline1),
            ),
            'debt': Text(
              '${Fmt.priceCeilBigInt(_amountDebit, balancePair[1].decimals!)} $karura_stable_coin_view',
              style: Theme.of(context)
                  .textTheme
                  .headline1
                  ?.copyWith(color: PluginColorsDark.headline1),
            ),
          },
          params: [],
          rawParams: '[[${batchTxs.join(',')}]]',
          isPlugin: true,
        ))) as Map?;
    if (res != null) {
      Navigator.of(context).pop(res);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
      final assetDic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common');

      final token =
          ModalRoute.of(context)?.settings.arguments as TokenBalanceData;

      final pageTitle =
          '${dic['loan.create']} ${PluginFmt.tokenView(token.symbol)}';

      final balancePair = AssetsUtils.getBalancePairFromTokenNameId(
          widget.plugin, [token.tokenNameId, karura_stable_coin]);

      final price = widget.plugin.store!.assets.prices[token.tokenNameId];
      final priceDouble = Fmt.bigIntToDouble(price, acala_price_decimals);

      final loanType = widget.plugin.store!.loan.loanTypes
          .firstWhere((i) => i.token!.tokenNameId == token.tokenNameId);
      final balance = Fmt.balanceInt(balancePair[0].amount);
      final available = balance;

      final minToBorrow = Fmt.bigIntToDouble(
          loanType.minimumDebitValue, balancePair[1].decimals!);

      final ratioLeft =
          Fmt.bigIntToDouble(loanType.requiredCollateralRatio, 18) * 100;
      final ratioRight =
          Fmt.bigIntToDouble(loanType.liquidationRatio, 18) * 100;
      final steps = (ratioLeft - ratioRight) / 5;

      const slippage = 0.05;
      final multiple = (ratioLeft - _slider) / (ratioLeft - _slider - 100);
      final buyingCollateral = _amountCollateral > BigInt.zero
          ? Fmt.bigIntToDouble(_amountCollateral, balancePair[0].decimals!) *
              (multiple - 1)
          : 0;

      final collateralNew =
          Fmt.bigIntToDouble(_amountCollateral, balancePair[0].decimals!) +
              buyingCollateral.toDouble();
      final liquidationPriceNew = loanType.calcLiquidationPrice(_amountDebit,
          Fmt.tokenInt(collateralNew.toString(), balancePair[0].decimals!),
          collateralDecimals: balancePair[0].decimals!,
          stableCoinDecimals: balancePair[1].decimals!);

      return PluginScaffold(
        appBar: PluginAppBar(title: Text(pageTitle), centerTitle: true),
        body: Builder(builder: (BuildContext context) {
          return SafeArea(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(bottom: 28),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  decoration: BoxDecoration(
                      color: Color(0x24FFFFFF),
                      borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4))),
                  child: Row(
                    children: [
                      PluginInfoItem(
                        title: dic['collateral.interest']!,
                        content: Fmt.ratio(loanType.stableFeeYear),
                        titleStyle: Theme.of(context)
                            .textTheme
                            .headline5
                            ?.copyWith(
                                color: PluginColorsDark.headline1,
                                fontSize: 12),
                        style: Theme.of(context).textTheme.bodyText1?.copyWith(
                            color: PluginColorsDark.headline1,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            height: 1.7),
                      ),
                      PluginInfoItem(
                        title: dic['liquid.ratio']!,
                        content: Fmt.ratio(ratioRight / 100),
                        titleStyle: Theme.of(context)
                            .textTheme
                            .headline5
                            ?.copyWith(
                                color: PluginColorsDark.headline1,
                                fontSize: 12),
                        style: Theme.of(context).textTheme.bodyText1?.copyWith(
                            color: PluginColorsDark.headline1,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            height: 1.7),
                      ),
                      PluginInfoItem(
                        title: dic['collateral.price.current']!,
                        content: '\$${Fmt.priceFloor(priceDouble)}',
                        titleStyle: Theme.of(context)
                            .textTheme
                            .headline5
                            ?.copyWith(
                                color: PluginColorsDark.headline1,
                                fontSize: 12),
                        style: Theme.of(context).textTheme.bodyText1?.copyWith(
                            color: PluginColorsDark.headline1,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            height: 1.7),
                      ),
                      PluginInfoItem(
                        title: dic['borrow.min']!,
                        content:
                            '${minToBorrow.toStringAsFixed(2)} $karura_stable_coin_view',
                        titleStyle: Theme.of(context)
                            .textTheme
                            .headline5
                            ?.copyWith(
                                color: PluginColorsDark.headline1,
                                fontSize: 12),
                        style: Theme.of(context).textTheme.bodyText1?.copyWith(
                            color: PluginColorsDark.headline1,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            height: 1.7),
                      ),
                    ],
                  ),
                ),
                PluginInputBalance(
                  tokenViewFunction: (value) {
                    return PluginFmt.tokenView(value);
                  },
                  inputCtrl: _amountCtrl,
                  margin: EdgeInsets.only(bottom: 2),
                  titleTag: dic['loan.collateral'],
                  onInputChange: (v) => _onAmount1Change(
                      v, loanType, price, available, balancePair),
                  balance: token,
                  tokenIconsMap: widget.plugin.tokenIcons,
                  marketPrices: widget.plugin.store!.assets.marketPrices,
                  onClear: () {
                    setState(() {
                      _amountCtrl.text = '';
                      _amountCollateral = BigInt.zero;
                    });
                  },
                ),
                ErrorMessage(_error1,
                    margin: EdgeInsets.symmetric(vertical: 2)),
                ErrorMessage(
                    _amountDebit > BigInt.zero &&
                            _amountDebit < loanType.minimumDebitValue
                        ? '${assetDic!['min']} ${minToBorrow.toStringAsFixed(2)}'
                        : null,
                    margin: EdgeInsets.symmetric(vertical: 2)),
                PluginTextTag(
                  title: dic['loan.multiply.adjustYourMultiply']!,
                  margin: EdgeInsets.only(top: 18),
                ),
                Container(
                    margin: EdgeInsets.only(bottom: 24),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                    decoration: BoxDecoration(
                        color: Color(0x24FFFFFF),
                        borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4))),
                    child: Column(
                      children: [
                        SliderTheme(
                            data: SliderThemeData(
                                trackHeight: 12,
                                activeTrackColor: PluginColorsDark.green,
                                disabledActiveTrackColor:
                                    PluginColorsDark.primary,
                                inactiveTrackColor: Color(0x4DFFFFFF),
                                disabledInactiveTrackColor: Color(0x4DFFFFFF),
                                overlayColor: Colors.transparent,
                                trackShape: const MultiplySliderTrackShape(),
                                thumbShape: MultiplySliderThumbShape(),
                                tickMarkShape:
                                    const MultiplySliderTickMarkShape(),
                                overlayShape:
                                    const MultiplySliderOverlayShape(),
                                valueIndicatorColor: Color(0xFFC9C9C9),
                                valueIndicatorTextStyle: Theme.of(context)
                                    .textTheme
                                    .headline3
                                    ?.copyWith(
                                        color: Colors.black, fontSize: 14)),
                            child: Slider(
                              min: 0,
                              max: ratioLeft - ratioRight,
                              divisions: steps.toInt(),
                              value: _slider,
                              label:
                                  '${dic['loan.ratio']} ${ratioLeft - _slider}%\n(${dic['liquid.price']} \$${Fmt.priceFloorBigInt(liquidationPriceNew, acala_price_decimals)})',
                              onChanged: (v) =>
                                  _onSliderChanged(balancePair, loanType, v),
                            )),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$ratioLeft%',
                              style: Theme.of(context)
                                  .textTheme
                                  .headline4
                                  ?.copyWith(
                                      color: PluginColorsDark.green,
                                      fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '$ratioRight%',
                              style: Theme.of(context)
                                  .textTheme
                                  .headline4
                                  ?.copyWith(
                                      color: PluginColorsDark.primary,
                                      fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                      ],
                    )),
                PluginTextTag(
                  title: dic['loan.multiply.orderInfo']!,
                  margin: EdgeInsets.only(top: 18),
                ),
                Container(
                    margin: EdgeInsets.only(bottom: 24),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                    decoration: BoxDecoration(
                        color: Color(0x24FFFFFF),
                        borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4))),
                    child: Column(
                      children: [
                        LoanInfoItemRow(
                          I18n.of(context)!.getDic(i18n_full_dic_karura,
                              'common')!['multiply.title']!,
                          multiple.toStringAsFixed(2) + 'x',
                        ),
                        LoanInfoItemRow(
                          "${dic['loan.multiply.buying']} ${PluginFmt.tokenView(token.symbol)}",
                          '${Fmt.priceFloor(buyingCollateral.toDouble(), lengthMax: 4)} ${PluginFmt.tokenView(token.symbol)} (\$${Fmt.priceFloor((buyingCollateral * priceDouble).toDouble())})',
                        ),
                        LoanInfoItemRow(
                          dic['loan.multiply.totalExposure']!,
                          "${Fmt.priceFloor(collateralNew, lengthMax: 4)} ${PluginFmt.tokenView(token.symbol)}",
                        ),
                        LoanInfoItemRow(
                          dic['loan.multiply.outstandingDebt']!,
                          "${Fmt.priceFloor(Fmt.bigIntToDouble(_amountDebit, balancePair[1].decimals!), lengthMax: 4)} ${PluginFmt.tokenView(karura_stable_coin_view)}",
                        ),
                        LoanInfoItemRow(dic['loan.multiply.slippageLimit']!,
                            Fmt.ratio(slippage)),
                      ],
                    )),
                Padding(
                    padding: EdgeInsets.only(top: 37, bottom: 38),
                    child: PluginButton(
                      title: '${dic['v3.loan.submit']}',
                      onPressed: () {
                        if (_error1 == null &&
                            _amountDebit > loanType.minimumDebitValue) {
                          _onSubmit(pageTitle, loanType, multiple);
                        }
                      },
                    )),
              ],
            ),
          );
        }),
      );
    });
  }
}

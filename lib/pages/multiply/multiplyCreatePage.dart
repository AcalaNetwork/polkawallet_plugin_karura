import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/loanType.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
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
  double _slider = 0;

  double _dexPrice = 1;

  String? _error1;

  Future<void> _updateDexBuyingPrice() async {
    final token =
        ModalRoute.of(context)?.settings.arguments as TokenBalanceData;
    final res = await widget.plugin.api!.swap.queryTokenSwapAmount(
        null,
        '1',
        [karura_stable_coin, token.tokenNameId!].map((e) {
          final token = AssetsUtils.getBalanceFromTokenNameId(widget.plugin, e);
          return {...token.currencyId!, 'decimals': token.decimals};
        }).toList(),
        '0.05');
    setState(() {
      _dexPrice = res.amount ?? 0;
    });
  }

  void _onAmount1Change(String value, LoanType loanType, BigInt available,
      List<TokenBalanceData> balancePair) {
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

    _onSliderChanged(_slider);
  }

  void _onSliderChanged(double value) {
    if (_slider != value && mounted) {
      setState(() {
        _slider = value;
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

  Future<void> _onSubmit(String pageTitle, LoanType loanType,
      BigInt buyingCollateral, BigInt debitChange) async {
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
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;

    const slippage = 50;
    final buyingWithSlippage =
        buyingCollateral * BigInt.from(1000 - slippage) ~/ BigInt.from(1000);
    final batchTxs = [
      'api.tx.honzon.adjustLoan(...${jsonEncode([
            token.currencyId,
            _amountCollateral.toString(),
            '0'
          ])})',
      'api.tx.honzon.expandPositionCollateral(...${jsonEncode([
            token.currencyId,
            debitChange.toString(),
            buyingWithSlippage.toString()
          ])})',
    ];
    final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
        arguments: TxConfirmParams(
          module: 'utility',
          call: 'batchAll',
          txTitle: pageTitle,
          txDisplayBold: {
            dic['loan.multiply.buying']!: Text(
              '≈ ${Fmt.priceFloorBigInt(buyingCollateral, balancePair[0].decimals!, lengthMax: 4)} ${PluginFmt.tokenView(token.symbol)}',
              style: Theme.of(context)
                  .textTheme
                  .headline1
                  ?.copyWith(color: PluginColorsDark.headline1),
            ),
            dic['loan.multiply.debt']!: Text(
              '${Fmt.priceCeilBigInt(debitChange, balancePair[1].decimals!)} $karura_stable_coin_view',
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
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _updateDexBuyingPrice();
    });
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

      final oraclePrice =
          widget.plugin.store!.assets.prices[token.tokenNameId] ?? BigInt.zero;
      final dexPrice = Fmt.tokenInt(_dexPrice.toString(), acala_price_decimals);

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

      final debitChange = loanType.tokenToUSD(_amountCollateral, oraclePrice,
              collateralDecimals: balancePair[0].decimals!,
              stableCoinDecimals: balancePair[1].decimals!) *
          BigInt.from(100) ~/
          BigInt.from(ratioLeft - _slider - 100) *
          oraclePrice ~/
          dexPrice;
      final buyingCollateral = debitChange *
          BigInt.from(pow(10, balancePair[0].decimals!)) ~/
          BigInt.from(pow(10, balancePair[1].decimals!)) *
          BigInt.from(pow(10, acala_price_decimals)) ~/
          dexPrice;
      final collateralNew = _amountCollateral + buyingCollateral;

      final liquidationPriceNew = loanType.calcLiquidationPrice(
          debitChange, collateralNew,
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
                  margin: EdgeInsets.only(bottom: 25, top: 10),
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
                        content:
                            '\$${Fmt.priceFloorBigInt(oraclePrice, acala_price_decimals)}',
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
                  onInputChange: (v) =>
                      _onAmount1Change(v, loanType, available, balancePair),
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
                PluginTextTag(
                  title: dic['loan.multiply.adjustYourMultiply']!,
                  margin: EdgeInsets.only(top: 25),
                ),
                Container(
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
                                valueIndicatorColor: Color(0xFF7D7D7D),
                                valueIndicatorTextStyle: Theme.of(context)
                                    .textTheme
                                    .headline3
                                    ?.copyWith(
                                        color: PluginColorsDark.headline1,
                                        fontSize: 14)),
                            child: Slider(
                              min: 0,
                              max: ratioLeft - ratioRight,
                              divisions: steps.toInt(),
                              value: _slider,
                              label:
                                  '${dic['loan.ratio']} ${ratioLeft - _slider}%\n(${dic['liquid.price']} \$${Fmt.priceFloorBigInt(liquidationPriceNew, acala_price_decimals)})',
                              onChanged: _onSliderChanged,
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
                ErrorMessage(
                    ratioLeft - _slider <= ratioRight + 10
                        ? dic['loan.multiply.message3']
                        : null,
                    margin: EdgeInsets.symmetric(vertical: 2),
                    isRight: true),
                ErrorMessage(
                    debitChange > BigInt.zero &&
                            debitChange < loanType.minimumDebitValue
                        ? '${assetDic!['min']} ${minToBorrow.toStringAsFixed(2)}  ${PluginFmt.tokenView(karura_stable_coin_view)}'
                        : null,
                    margin: EdgeInsets.symmetric(vertical: 2),
                    isRight: true),
                PluginTextTag(
                  margin: EdgeInsets.only(top: 25),
                  title: dic['loan.multiply.orderInfo']!,
                ),
                Container(
                    margin: EdgeInsets.only(bottom: 25),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                    decoration: BoxDecoration(
                        color: Color(0x24FFFFFF),
                        borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4))),
                    child: Column(
                      children: [
                        MultiplyInfoItemRow(
                          dic['loan.ratio']!,
                          "${ratioLeft - _slider}%",
                        ),
                        MultiplyInfoItemRow(
                          dic['liquid.price']!,
                          "\$${Fmt.priceFloorBigInt(liquidationPriceNew, acala_price_decimals)}",
                        ),
                        MultiplyInfoItemRow(
                          I18n.of(context)!.getDic(i18n_full_dic_karura,
                              'common')!['multiply.title']!,
                          multiple.toStringAsFixed(2) + 'x',
                          oldContent: '0.00',
                        ),
                        MultiplyInfoItemRow(
                          "${dic['loan.multiply.buying']} ${PluginFmt.tokenView(token.symbol)}",
                          '${Fmt.priceFloorBigInt(buyingCollateral, balancePair[0].decimals!, lengthMax: 4)} ${PluginFmt.tokenView(token.symbol)} (\$${Fmt.priceFloorBigInt(debitChange, balancePair[1].decimals!)})',
                        ),
                        MultiplyInfoItemRow(
                          dic['loan.multiply.totalExposure']!,
                          "${Fmt.priceFloorBigInt(collateralNew, balancePair[0].decimals!, lengthMax: 4)} ${PluginFmt.tokenView(token.symbol)}",
                          oldContent: '0.00',
                        ),
                        MultiplyInfoItemRow(
                          dic['loan.multiply.outstandingDebt']!,
                          "${Fmt.priceFloor(Fmt.bigIntToDouble(debitChange, balancePair[1].decimals!), lengthMax: 4)} ${PluginFmt.tokenView(karura_stable_coin_view)}",
                          oldContent: '0.00',
                        ),
                        MultiplyInfoItemRow(dic['loan.multiply.slippageLimit']!,
                            Fmt.ratio(slippage)),
                      ],
                    )),
                Padding(
                    padding: EdgeInsets.only(top: 37, bottom: 38),
                    child: PluginButton(
                      title: '${dic['v3.loan.submit']}',
                      onPressed: () {
                        if (_error1 == null &&
                            debitChange > loanType.minimumDebitValue) {
                          _onSubmit(pageTitle, loanType, buyingCollateral,
                              debitChange);
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

class MultiplyInfoItemRow extends StatelessWidget {
  MultiplyInfoItemRow(this.title, this.content,
      {this.oldContent = '', this.contentColor = Colors.white});
  final String title;
  final String content;
  final String oldContent;
  final Color contentColor;
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(bottom: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.headline5?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            Row(
              children: [
                Visibility(
                    visible: oldContent.trim().length > 0,
                    child: Text(
                      oldContent,
                      style: Theme.of(context)
                          .textTheme
                          .headline5
                          ?.copyWith(color: Colors.white, fontSize: 12),
                    )),
                Visibility(
                    visible: oldContent.trim().length > 0,
                    child: Padding(
                        padding: EdgeInsets.only(left: 3, right: 3),
                        child: Image.asset(
                            "packages/polkawallet_plugin_karura/assets/images/multiply_update.png",
                            width: 11))),
                Text(
                  content,
                  style: Theme.of(context)
                      .textTheme
                      .headline5
                      ?.copyWith(color: this.contentColor, fontSize: 12),
                ),
              ],
            )
          ],
        ));
  }
}

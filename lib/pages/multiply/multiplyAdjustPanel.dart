import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_karura/api/types/loanType.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/pages/loanNew/loanPage.dart';
import 'package:polkawallet_plugin_karura/pages/multiply/multiplyCreatePage.dart';
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
import 'package:polkawallet_ui/components/v3/plugin/pluginInputBalance.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTextTag.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';

class MultiplyAdjustPanel extends StatefulWidget {
  MultiplyAdjustPanel(this.plugin, this.keyring, this.loanType, this.onRefresh);
  final PluginKarura plugin;
  final Keyring keyring;
  final LoanType loanType;
  final Function onRefresh;

  @override
  _MultiplyAdjustPanelState createState() => _MultiplyAdjustPanelState();
}

class _MultiplyAdjustPanelState extends State<MultiplyAdjustPanel> {
  double _slider = 0;
  bool _isInfoOpen = false;

  Map _getBuyingParams(LoanType loanType, List<TokenBalanceData> balancePair,
      BigInt collateralChange, BigInt debitChange, BigInt debitNew) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    const slippage = 0.005;
    final buyingWithSlippage =
        collateralChange * BigInt.from(1000 - 5) ~/ BigInt.from(1000);

    /// loan.debits * 1/1000000 covers interests raise in about 10 minutes.
    final raisingDebit = (debitNew - debitChange) ~/ BigInt.from(1000000);

    return {
      'detail': {
        'buying': Text(
          '≈ ${Fmt.priceFloorBigInt(collateralChange, balancePair[0].decimals!, lengthMax: 4)} ${PluginFmt.tokenView(widget.loanType.token?.symbol)}',
          style: Theme.of(context)
              .textTheme
              .headline1
              ?.copyWith(color: PluginColorsDark.headline1),
        ),
        'outstanding debt': Text(
          '${Fmt.priceCeilBigInt(debitNew - raisingDebit, balancePair[1].decimals!)} $karura_stable_coin_view',
          style: Theme.of(context)
              .textTheme
              .headline1
              ?.copyWith(color: PluginColorsDark.headline1),
        ),
      },
      'params': [
        widget.loanType.token?.currencyId,
        (debitChange - raisingDebit).toString(),
        buyingWithSlippage.toString()
      ]
    };
  }

  Map _getSellingParams(LoanType loanType, List<TokenBalanceData> balancePair,
      BigInt collateralChange, BigInt debitChange, BigInt debitNew) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    const slippage = 0.005;
    final debitChangeWithSlippage =
        debitChange * BigInt.from(1000 - 5) ~/ BigInt.from(1000);

    final detail = {
      'selling': Text(
        '${Fmt.priceFloorBigInt(collateralChange.abs(), balancePair[0].decimals!, lengthMax: 4)} ${PluginFmt.tokenView(widget.loanType.token?.symbol)}',
        style: Theme.of(context)
            .textTheme
            .headline1
            ?.copyWith(color: PluginColorsDark.headline1),
      ),
      'outstanding debt': Text(
        '≈ ${Fmt.priceCeilBigInt(debitNew, balancePair[1].decimals!)} $karura_stable_coin_view',
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
        collateralChange.abs().toString(),
        debitChangeWithSlippage.abs().toString()
      ]
    };
  }

  Future<void> _onSubmit(LoanType loanType, BigInt collateralChange,
      BigInt debitChange, BigInt debitNew) async {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;

    final balancePair = AssetsUtils.getBalancePairFromTokenNameId(widget.plugin,
        [widget.loanType.token?.tokenNameId, karura_stable_coin]);

    final params = collateralChange > BigInt.zero
        ? _getBuyingParams(
            loanType, balancePair, collateralChange, debitChange, debitNew)
        : _getSellingParams(
            loanType, balancePair, collateralChange, debitChange, debitNew);

    final res = await Navigator.of(context).pushNamed(TxConfirmPage.route,
        arguments: TxConfirmParams(
          module: 'honzon',
          call: collateralChange > BigInt.zero
              ? 'expandPositionCollateral'
              : 'shrinkPositionDebit',
          txTitle:
              'Adjust Multiply ${PluginFmt.tokenView(loanType.token?.symbol)}',
          txDisplayBold: params['detail'],
          params: params['params'],
          isPlugin: true,
        ));
    if (res != null) {
      widget.onRefresh();
    }
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

      final ratioLeft =
          Fmt.bigIntToDouble(loanType.requiredCollateralRatio, 18) * 100;
      final ratioRight =
          Fmt.bigIntToDouble(loanType.liquidationRatio, 18) * 100;
      final steps = (ratioLeft - ratioRight) / 5;

      ///      (collaterals + collateralChange) * price
      /// 1： ------------------------------------------- = ratioNew
      ///                 debits + debitChange
      ///
      /// 2： collateralChange * price = debitChange
      ///
      /// so:
      ///                      collaterals * price - debits * ratioNew
      ///     debitChange = ------------------------------------------------
      ///                               ratioNew - 1
      final debitChange = ((loan?.collateralInUSD ?? BigInt.zero) -
              (loan?.debits ?? BigInt.zero) *
                  BigInt.from(ratioLeft - _slider) ~/
                  BigInt.from(100)) *
          BigInt.from(100) ~/
          BigInt.from(ratioLeft - _slider - 100);
      final collateralChange = debitChange *
          BigInt.from(pow(10, acala_price_decimals)) ~/
          (price ?? BigInt.zero);
      final collateralNew =
          (loan?.collaterals ?? BigInt.zero) + collateralChange;
      final debitDouble =
          Fmt.bigIntToDouble(loan?.debits, balancePair[1].decimals!);
      final debitNew = (loan?.debits ?? BigInt.zero) + debitChange;

      final liquidationPriceNew = loanType.calcLiquidationPrice(
          debitNew, collateralNew,
          collateralDecimals: balancePair[0].decimals!,
          stableCoinDecimals: balancePair[1].decimals!);

      const slippage = 0.005;
      final multiple = collateralNew / (loan?.collaterals ?? BigInt.zero);

      final _oldSlider = (loan?.collateralRatio ?? 2) < 1 ||
              (loan?.collateralRatio ?? 2) * 100 >= ratioLeft
          ? 0.0
          : ratioLeft - loan!.collateralRatio * 100;
      final ratioOld = (ratioLeft - _oldSlider) / 100;
      final _oldCollateralValueChange =
          (Fmt.bigIntToDouble(loan?.collateralInUSD, balancePair[1].decimals!) -
                  Fmt.bigIntToDouble(loan?.debits, balancePair[1].decimals!) *
                      ratioOld) /
              (ratioOld - 1);
      final _oldCollateralChange = _oldCollateralValueChange / priceDouble;
      final oldMultiple =
          (collateralDouble + _oldCollateralChange) / collateralDouble;

      return SingleChildScrollView(
        child: Column(
          children: <Widget>[
            PluginInputBalance(
              tokenViewFunction: (value) {
                return PluginFmt.tokenView(value);
              },
              enabled: false,
              inputCtrl: TextEditingController()..text = collateralView,
              margin: EdgeInsets.only(bottom: 25, top: 10),
              titleTag: dic['loan.collateral'],
              balance: token,
              tokenIconsMap: widget.plugin.tokenIcons,
              marketPrices: widget.plugin.store!.assets.marketPrices,
            ),
            PluginTextTag(
              title: dic['loan.multiply.adjustYourMultiply']!,
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
                    Stack(
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                              trackHeight: 12,
                              activeTrackColor: Color(0xFFB9B9B9),
                              disabledActiveTrackColor: Color(0xFFB9B9B9),
                              inactiveTrackColor: Color(0x4DFFFFFF),
                              disabledInactiveTrackColor: Color(0x4DFFFFFF),
                              overlayColor: Colors.transparent,
                              trackShape: const MultiplySliderTrackShape(),
                              thumbShape:
                                  MultiplySliderThumbShape(isShow: false),
                              tickMarkShape:
                                  const MultiplySliderTickMarkShape(),
                              overlayShape: const MultiplySliderOverlayShape(),
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
                            value: _oldSlider,
                            label: Fmt.ratio(loan?.collateralRatio ?? 2),
                            activeColor: PluginColorsDark.headline2,
                            inactiveColor: PluginColorsDark.headline2,
                            onChanged: (v) => null,
                          ),
                        ),
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
                              onChanged: (value) {
                                setState(() {
                                  _slider = value;
                                });
                              },
                            )),
                      ],
                    ),
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
                margin: EdgeInsets.symmetric(vertical: 2)),
            PluginTextTag(
              margin: EdgeInsets.only(top: 25),
              title: dic['loan.multiply.adjustInfo']!,
            ),
            Container(
                margin: EdgeInsets.only(bottom: 25),
                // padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                padding: EdgeInsets.only(top: 15),
                decoration: BoxDecoration(
                    color: Color(0x24FFFFFF),
                    borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4))),
                child: Column(children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        MultiplyInfoItemRow(
                          dic['loan.ratio']!,
                          "${ratioLeft - _slider}%",
                          oldContent: "${ratioLeft - _oldSlider}%",
                          contentColor: _slider > _oldSlider
                              ? PluginColorsDark.primary
                              : _slider < _oldSlider
                                  ? PluginColorsDark.green
                                  : PluginColorsDark.headline1,
                        ),
                        MultiplyInfoItemRow(
                          dic['liquid.price']!,
                          "\$${Fmt.priceFloorBigInt(liquidationPriceNew, acala_price_decimals)}",
                          oldContent:
                              "\$${Fmt.priceFloorBigInt(loan?.liquidationPrice, acala_price_decimals)}",
                          contentColor:
                              loan!.liquidationPrice < liquidationPriceNew
                                  ? PluginColorsDark.primary
                                  : loan.liquidationPrice > liquidationPriceNew
                                      ? PluginColorsDark.green
                                      : PluginColorsDark.headline1,
                        ),
                        MultiplyInfoItemRow(
                          I18n.of(context)!.getDic(i18n_full_dic_karura,
                              'common')!['multiply.title']!,
                          multiple.toStringAsFixed(2) + 'x',
                          oldContent: '${oldMultiple.toStringAsFixed(2)}x',
                          contentColor: multiple > oldMultiple
                              ? PluginColorsDark.primary
                              : multiple < oldMultiple
                                  ? PluginColorsDark.green
                                  : PluginColorsDark.headline1,
                        ),
                        Visibility(
                            visible: _isInfoOpen,
                            child: Column(
                              children: [
                                MultiplyInfoItemRow(
                                  "${collateralChange < BigInt.zero ? dic['loan.multiply.selling']! : dic['loan.multiply.buying']!} ${PluginFmt.tokenView(token.symbol)}",
                                  '${Fmt.priceFloorBigInt(collateralChange, balancePair[0].decimals!, lengthMax: 4)} ${PluginFmt.tokenView(token.symbol)} (\$${Fmt.priceFloorBigInt(debitChange, balancePair[1].decimals!)})',
                                ),
                                MultiplyInfoItemRow(
                                  dic['loan.multiply.totalExposure']!,
                                  "${Fmt.priceFloorBigInt(collateralNew, balancePair[0].decimals!, lengthMax: 4)} ${PluginFmt.tokenView(token.symbol)}",
                                  oldContent: "$collateralView",
                                  contentColor: collateralChange > BigInt.zero
                                      ? PluginColorsDark.primary
                                      : collateralChange < BigInt.zero
                                          ? PluginColorsDark.green
                                          : PluginColorsDark.headline1,
                                ),
                                MultiplyInfoItemRow(
                                  dic['loan.multiply.outstandingDebt']!,
                                  "${Fmt.priceFloorBigInt(debitNew, balancePair[1].decimals!, lengthMax: 4)} ${PluginFmt.tokenView(karura_stable_coin_view)}",
                                  oldContent: Fmt.priceFloor(debitDouble),
                                  contentColor: collateralChange > BigInt.zero
                                      ? PluginColorsDark.primary
                                      : collateralChange < BigInt.zero
                                          ? PluginColorsDark.green
                                          : PluginColorsDark.headline1,
                                ),
                                MultiplyInfoItemRow(
                                    dic['loan.multiply.slippageLimit']!,
                                    Fmt.ratio(slippage)),
                              ],
                            )),
                      ],
                    ),
                  ),
                  GestureDetector(
                      onTap: () {
                        setState(() {
                          _isInfoOpen = !_isInfoOpen;
                        });
                      },
                      child: Container(
                        height: 32,
                        decoration: BoxDecoration(
                            color: Color(0xFF626467),
                            borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(4),
                                bottomRight: Radius.circular(4))),
                        child: Center(
                          child: Transform.rotate(
                              angle: _isInfoOpen ? pi : 0,
                              child: SvgPicture.asset(
                                "packages/polkawallet_ui/assets/images/triangle_bottom.svg",
                                color: PluginColorsDark.headline1,
                              )),
                        ),
                      ))
                ])),
            ErrorMessage(
                debitNew < loanType.minimumDebitValue
                    ? '${assetDic!['min']} ${Fmt.bigIntToDouble(loanType.minimumDebitValue, balancePair[1].decimals!).toStringAsFixed(2)}'
                    : null,
                margin: EdgeInsets.symmetric(vertical: 2)),
            Padding(
                padding: EdgeInsets.only(top: 10),
                child: PluginButton(
                  title: '${dic['v3.loan.submit']}',
                  onPressed: () {
                    if (debitNew > loanType.minimumDebitValue &&
                        collateralChange != BigInt.zero) {
                      _onSubmit(
                          loanType, collateralChange, debitChange, debitNew);
                    }
                  },
                )),
            Padding(
              padding: EdgeInsets.only(top: 9),
              child: GestureDetector(
                child: Text(
                  dic['loan.multiply.manageYourVault']!,
                  style: Theme.of(context).textTheme.headline5?.copyWith(
                      decoration: TextDecoration.underline,
                      color: Color(0xFFFFFFFF).withAlpha(204)),
                ),
                onTap: () {
                  Navigator.of(context).pushNamed(LoanPage.route);
                },
              ),
            )
          ],
        ),
      );
    });
  }
}
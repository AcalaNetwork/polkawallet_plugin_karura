import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/infoItemRow.dart';
import 'package:polkawallet_ui/utils/format.dart';

class LoanInfoPanel extends StatelessWidget {
  LoanInfoPanel({
    this.debits,
    this.collateral,
    this.price,
    this.liquidationRatio,
    this.requiredRatio,
    this.currentRatio,
    this.liquidationPrice,
    this.stableFeeYear,
  });
  final String? debits;
  final String? collateral;
  final BigInt? price;
  final BigInt? liquidationRatio;
  final BigInt? requiredRatio;
  final double? currentRatio;
  final BigInt? liquidationPrice;
  final double? stableFeeYear;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    final priceString = Fmt.token(price, acala_price_decimals);
    final liquidationPriceString =
        Fmt.token(liquidationPrice, acala_price_decimals);
    return Column(
      children: <Widget>[
        Visibility(
            visible: debits != null,
            child: Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: InfoItemRow(
                  dic['loan.borrowed']!,
                  debits ?? '',
                  labelStyle: Theme.of(context).textTheme.headline4?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w600),
                  contentStyle: Theme.of(context).textTheme.headline4?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w400),
                ))),
        Visibility(
            visible: collateral != null,
            child: Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: InfoItemRow(
                  dic['loan.collateral']!,
                  collateral ?? '',
                  labelStyle: Theme.of(context).textTheme.headline4?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w600),
                  contentStyle: Theme.of(context).textTheme.headline4?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w400),
                ))),
        Padding(
            padding: EdgeInsets.only(bottom: 5),
            child: InfoItemRow(
              dic['collateral.price.current']!,
              '\$$priceString',
              labelStyle: Theme.of(context)
                  .textTheme
                  .headline4
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              contentStyle: Theme.of(context)
                  .textTheme
                  .headline4
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w400),
            )),
        Padding(
            padding: EdgeInsets.only(bottom: 5),
            child: InfoItemRow(
              dic['liquid.ratio.require']!,
              Fmt.ratio(
                double.parse(
                  Fmt.token(requiredRatio, acala_price_decimals),
                ),
              ),
              labelStyle: Theme.of(context)
                  .textTheme
                  .headline4
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              contentStyle: Theme.of(context)
                  .textTheme
                  .headline4
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w400),
            )),
        Padding(
            padding: EdgeInsets.only(bottom: 5),
            child: InfoItemRow(
              dic['liquid.ratio.current']!,
              Fmt.ratio(currentRatio),
              colorPrimary: true,
              labelStyle: Theme.of(context)
                  .textTheme
                  .headline4
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              contentStyle: Theme.of(context)
                  .textTheme
                  .headline4
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w400),
            )),
        Padding(
            padding: EdgeInsets.only(bottom: 5),
            child: InfoItemRow(
              dic['liquid.price']!,
              '\$$liquidationPriceString',
              colorPrimary: true,
              labelStyle: Theme.of(context)
                  .textTheme
                  .headline4
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              contentStyle: Theme.of(context)
                  .textTheme
                  .headline4
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w400),
            )),
        Padding(
            padding: EdgeInsets.only(bottom: 5),
            child: InfoItemRow(
              dic['collateral.interest']!,
              Fmt.ratio(stableFeeYear),
              colorPrimary: true,
              labelStyle: Theme.of(context)
                  .textTheme
                  .headline4
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              contentStyle: Theme.of(context)
                  .textTheme
                  .headline4
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w400),
            )),
      ],
    );
  }
}

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
  });
  final String debits;
  final String collateral;
  final BigInt price;
  final BigInt liquidationRatio;
  final BigInt requiredRatio;
  final double currentRatio;
  final BigInt liquidationPrice;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
    final priceString = Fmt.token(price, acala_price_decimals);
    final liquidationPriceString =
        Fmt.token(liquidationPrice, acala_price_decimals);
    return Column(
      children: <Widget>[
        debits != null
            ? InfoItemRow(
                dic['loan.borrowed'],
                debits,
              )
            : Container(),
        collateral != null
            ? InfoItemRow(
                dic['loan.collateral'],
                collateral,
              )
            : Container(),
        InfoItemRow(
          dic['collateral.price.current'],
          '\$$priceString',
        ),
        InfoItemRow(
          dic['liquid.ratio.require'],
          Fmt.ratio(
            double.parse(
              Fmt.token(requiredRatio, acala_price_decimals),
            ),
          ),
        ),
        InfoItemRow(
          dic['liquid.ratio.current'],
          Fmt.ratio(currentRatio),
          colorPrimary: true,
        ),
        InfoItemRow(
          dic['liquid.price'],
          '\$$liquidationPriceString',
          colorPrimary: true,
        ),
      ],
    );
  }
}

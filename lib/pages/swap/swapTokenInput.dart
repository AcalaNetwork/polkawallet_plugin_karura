import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_karura/pages/currencySelectPage.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/currencyWithIcon.dart';
import 'package:polkawallet_ui/components/textTag.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class SwapTokenInput extends StatelessWidget {
  SwapTokenInput({
    this.title,
    this.inputCtrl,
    this.focusNode,
    this.balance,
    this.tokenOptions = const [],
    this.tokenIconsMap,
    this.marketPrice,
    this.onInputChange,
    this.onTokenChange,
    this.onSetMax,
    this.onClear,
  });
  final String title;
  final TextEditingController inputCtrl;
  final FocusNode focusNode;
  final TokenBalanceData balance;
  final List<String> tokenOptions;
  final Map<String, Widget> tokenIconsMap;
  final double marketPrice;
  final Function(String) onInputChange;
  final Function(String) onTokenChange;
  final Function(BigInt) onSetMax;
  final Function onClear;

  Future<void> _selectCurrencyPay(BuildContext context) async {
    var selected = await Navigator.of(context)
        .pushNamed(CurrencySelectPage.route, arguments: tokenOptions);
    if (selected != null) {
      onTokenChange(selected as String);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
    final dicAssets = I18n.of(context).getDic(i18n_full_dic_karura, 'common');

    final max = Fmt.balanceInt(balance?.amount);

    bool priceVisible = marketPrice != null && inputCtrl.text.isNotEmpty;
    double inputAmount = 0;
    try {
      inputAmount = double.parse(inputCtrl.text.trim());
    } catch (e) {
      priceVisible = false;
    }
    final price = priceVisible ? marketPrice * inputAmount : null;

    final colorGray = Theme.of(context).unselectedWidgetColor;
    final colorLightGray = Theme.of(context).disabledColor;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, priceVisible ? 8 : 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: colorLightGray, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title ?? '')),
                Text(
                  '${dicAssets['balance']}: ${Fmt.token(max, balance?.decimals ?? 12)}',
                  style: TextStyle(color: colorGray, fontSize: 14),
                ),
                onSetMax == null
                    ? Container()
                    : GestureDetector(
                        child: Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: TextTag(dic['loan.max']),
                        ),
                        onTap: () => onSetMax(max),
                      )
              ],
            ),
          ),
          Stack(
            alignment: AlignmentDirectional.bottomStart,
            children: [
              Container(
                margin: EdgeInsets.only(bottom: priceVisible ? 8 : 0),
                child: Row(children: [
                  Expanded(
                    child: TextFormField(
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: '0.0',
                        hintStyle: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorLightGray),
                        errorStyle: TextStyle(height: 0.3),
                        contentPadding: EdgeInsets.all(0),
                        border: InputBorder.none,
                        suffix: focusNode != null &&
                                focusNode.hasFocus &&
                                inputCtrl.text.isNotEmpty
                            ? IconButton(
                                padding: EdgeInsets.fromLTRB(0, 0, 4, 0),
                                icon: Icon(Icons.cancel,
                                    size: 16, color: colorGray),
                                onPressed: onClear,
                              )
                            : null,
                      ),
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      inputFormatters: [
                        UI.decimalInputFormatter(balance.decimals)
                      ],
                      controller: inputCtrl,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      onChanged: onInputChange,
                    ),
                  ),
                  GestureDetector(
                    child: CurrencyWithIcon(
                      balance.symbol,
                      TokenIcon(balance.id, tokenIconsMap, small: true),
                      textStyle: Theme.of(context).textTheme.headline4,
                      trailing: onTokenChange != null
                          ? Icon(Icons.keyboard_arrow_down)
                          : null,
                    ),
                    onTap: onTokenChange != null && tokenOptions.length > 0
                        ? () => _selectCurrencyPay(context)
                        : null,
                  )
                ]),
              ),
              priceVisible
                  ? Text(
                      '≈ \$${Fmt.priceFloor(price)}',
                      style: TextStyle(fontSize: 12, color: colorGray),
                    )
                  : Container()
            ],
          ),
        ],
      ),
    );
  }
}

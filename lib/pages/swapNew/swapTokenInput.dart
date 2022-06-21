import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_karura/pages/currencySelectPage.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/textTag.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginCurrencyWithIcon.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTokenIcon.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class SwapTokenInput extends StatefulWidget {
  SwapTokenInput(
      {this.title,
      this.inputCtrl,
      this.balance,
      this.tokenOptions = const [],
      this.tokenIconsMap,
      this.marketPrice,
      this.onInputChange,
      this.onTokenChange,
      this.onSetMax,
      this.onClear,
      this.borderRadius = const BorderRadius.all(Radius.circular(6)),
      this.color = const Color(0x1AFFFFFF)});
  final String? title;
  final TextEditingController? inputCtrl;
  final TokenBalanceData? balance;
  final List<TokenBalanceData?> tokenOptions;
  final Map<String, Widget>? tokenIconsMap;
  final double? marketPrice;
  final Function(String)? onInputChange;
  final Function(TokenBalanceData)? onTokenChange;
  final Function(BigInt)? onSetMax;
  final Function? onClear;
  final BorderRadiusGeometry borderRadius;
  final Color color;

  @override
  _SwapTokenInputState createState() => _SwapTokenInputState();
}

class _SwapTokenInputState extends State<SwapTokenInput> {
  bool _hasFocus = false;

  Future<void> _selectCurrencyPay(BuildContext context) async {
    final selected = await Navigator.of(context)
        .pushNamed(CurrencySelectPage.route, arguments: widget.tokenOptions);
    if (selected != null) {
      widget.onTokenChange!(selected as TokenBalanceData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    final dicAssets = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common')!;

    final max = Fmt.balanceInt(widget.balance?.amount);

    bool priceVisible =
        widget.marketPrice != null && widget.inputCtrl!.text.isNotEmpty;
    double inputAmount = 0;
    try {
      inputAmount = double.parse(widget.inputCtrl!.text.trim());
    } catch (e) {
      priceVisible = false;
    }
    final price = priceVisible ? widget.marketPrice! * inputAmount : null;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, priceVisible ? 8 : 0),
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        color: widget.color,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: Text(
                  widget.title ?? '',
                  style: Theme.of(context)
                      .textTheme
                      .headline5
                      ?.copyWith(color: Colors.white),
                )),
                Text(
                  '${dicAssets['balance']}: ${Fmt.priceFloorBigInt(max, widget.balance?.decimals ?? 12, lengthMax: 4)}',
                  style: Theme.of(context)
                      .textTheme
                      .headline5
                      ?.copyWith(color: Colors.white),
                ),
                Visibility(
                    visible: widget.onSetMax != null,
                    child: GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: TextTag(dic['loan.max']),
                      ),
                      onTap: () => widget.onSetMax!(max),
                    ))
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
                    child: Focus(
                      onFocusChange: (v) {
                        setState(() {
                          _hasFocus = v;
                        });
                      },
                      child: TextFormField(
                        decoration: InputDecoration(
                          hintText: '0.0',
                          hintStyle: Theme.of(context)
                              .textTheme
                              .headline3
                              ?.copyWith(
                                  color: Colors.white,
                                  fontSize: UI.getTextSize(24, context),
                                  fontWeight: FontWeight.bold),
                          errorStyle: TextStyle(height: 0.3),
                          contentPadding: EdgeInsets.all(0),
                          border: InputBorder.none,
                          suffix: _hasFocus && widget.inputCtrl!.text.isNotEmpty
                              ? IconButton(
                                  padding: EdgeInsets.fromLTRB(0, 0, 4, 0),
                                  icon: Icon(Icons.cancel,
                                      size: 16, color: Colors.white),
                                  onPressed: widget.onClear as void Function()?,
                                )
                              : null,
                        ),
                        style: Theme.of(context).textTheme.headline3?.copyWith(
                            color: Colors.white,
                            fontSize: UI.getTextSize(24, context),
                            fontWeight: FontWeight.bold),
                        inputFormatters: [
                          UI.decimalInputFormatter(
                              widget.balance?.decimals ?? 0)!
                        ],
                        controller: widget.inputCtrl,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        onChanged: (value) {
                          try {
                            double.parse(value);
                            widget.onInputChange!(value);
                          } catch (e) {
                            widget.inputCtrl!.text = "";
                          }
                        },
                      ),
                    ),
                  ),
                  GestureDetector(
                    child: PluginCurrencyWithIcon(
                      PluginFmt.tokenView(widget.balance!.symbol),
                      PluginTokenIcon(
                          widget.balance?.symbol ?? "", widget.tokenIconsMap!,
                          size: 24),
                      textStyle: Theme.of(context)
                          .textTheme
                          .headline4
                          ?.copyWith(color: Colors.white),
                      trailing: widget.onTokenChange != null
                          ? Icon(Icons.keyboard_arrow_down)
                          : null,
                    ),
                    onTap: widget.onTokenChange != null &&
                            widget.tokenOptions.length > 0
                        ? () => _selectCurrencyPay(context)
                        : null,
                  )
                ]),
              ),
              Visibility(
                  visible: priceVisible,
                  child: Text(
                    '≈ \$${Fmt.priceFloor(price)}',
                    style: Theme.of(context)
                        .textTheme
                        .headline6
                        ?.copyWith(color: Colors.white),
                  ))
            ],
          ),
        ],
      ),
    );
  }
}

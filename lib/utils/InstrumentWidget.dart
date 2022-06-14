import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:polkawallet_plugin_karura/utils/InstrumentItemWidget.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/SkaletonList.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class InstrumentWidget extends StatefulWidget {
  InstrumentWidget(this.datas, this.onSwitchChange, this.onSwitchHideBalance,
      {Key? key, this.hideBalance = false, this.enabled = true})
      : super(key: key);
  final List<InstrumentData> datas;
  final Function? onSwitchChange;
  final Function? onSwitchHideBalance;
  final bool hideBalance;
  final bool enabled;

  @override
  _InstrumentWidgetState createState() => _InstrumentWidgetState();
}

class _InstrumentWidgetState extends State<InstrumentWidget> {
  InstrumentItemWidgetController controller = InstrumentItemWidgetController();
  int index = 0;
  bool isTapDown = false;

  @override
  void initState() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => controller.switchAction(isOnClick: false));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - (24.w + 11.w + 34.w) * 2;
    return Column(
      children: [
        Container(
            color: Colors.transparent,
            padding: EdgeInsets.symmetric(horizontal: 11.w),
            margin: EdgeInsets.symmetric(horizontal: 34.w),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                InstrumentItemWidget(
                  controller: controller,
                  onChanged: (index, isOnClick) {
                    if (isOnClick) {
                      widget.onSwitchChange!();
                    }
                    setState(() {
                      this.index = index;
                    });
                  },
                  datas: widget.datas,
                  initializeIndex: index,
                  size: Size(width, width / 249 * 168),
                ),
                Container(
                    width: width,
                    height: width / 249 * 168,
                    child: Image.asset(
                      "assets/images/icon_instrument.png",
                      fit: BoxFit.fill,
                    )),
                Container(
                  child: Column(
                    children: [
                      Text(
                          widget.datas[index].title!.length > 0
                              ? "${widget.datas[index].title}:"
                              : "",
                          style: TextStyle(
                              fontFamily: "TitilliumWeb",
                              fontSize: UI.getTextSize(14, context),
                              fontWeight: FontWeight.w400,
                              color: Theme.of(context)
                                  .textSelectionTheme
                                  .selectionColor
                                  ?.withAlpha(191))),
                      GestureDetector(
                          onTap: () {
                            widget.onSwitchHideBalance!();
                          },
                          child: Text(
                              widget.hideBalance
                                  ? "******"
                                  : "${widget.datas[index].currencySymbol}${Fmt.priceFloorFormatter(widget.datas[index].sumValue, lengthMax: widget.datas[index].lengthMax)}",
                              style: TextStyle(
                                  fontFamily: "SF_Pro",
                                  fontSize: UI.getTextSize(18, context),
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .textSelectionTheme
                                      .selectionColor))),
                      Container(
                        margin: EdgeInsets.only(top: 15.h),
                        child: GestureDetector(
                            onTapDown: (detail) {
                              setState(() {
                                isTapDown = true;
                              });
                            },
                            onTapCancel: () {
                              setState(() {
                                isTapDown = false;
                              });
                            },
                            onTapUp: (detail) {
                              setState(() {
                                isTapDown = false;
                              });
                            },
                            onTap: widget.datas.length < 2 || !widget.enabled
                                ? null
                                : () {
                                    controller.switchAction();
                                  },
                            child: Container(
                              width: 46.w,
                              height: 46.w,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFFFF4646),
                                      Color(0xFFFF5D4D),
                                      Color(0xFF323133)
                                    ]),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(46.w / 2)),
                              ),
                              // child: Center(
                              child: Center(
                                  child: Container(
                                width: 40.w,
                                height: 40.w,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(40.w / 2)),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Color(0x4F000000),
                                          offset: Offset(1, 1),
                                          blurRadius: 2,
                                          spreadRadius: 0),
                                    ],
                                    gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        stops: [
                                          0.0,
                                          1.0
                                        ],
                                        colors: [
                                          Color(isTapDown
                                              ? 0xFFBEB9B2
                                              : 0xFFFFFAF1),
                                          Color(isTapDown
                                              ? 0xFF74716C
                                              : 0xFFB1ADA7),
                                        ])),
                                child: Center(
                                  child: Text(
                                    I18n.of(context)!.getDic(
                                        i18n_full_dic_karura,
                                        'acala')!['v3.tap']!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline5
                                        ?.copyWith(
                                            color: isTapDown
                                                ? Colors.white
                                                : Color(0xFF757371),
                                            fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )),
                              // ),
                            )),
                      )
                    ],
                  ),
                )
              ],
            )),
        Container(
          height: 10,
        ),
        getRoundedCardItem(),
      ],
    );
  }

  Widget getRoundedCardItem() {
    if (widget.datas[index].items.length > 0) {
      return Row(
        children: [
          ...widget.datas[index].items.reversed
              .map((e) => Expanded(
                      child: RoundedCard(
                    margin: EdgeInsets.symmetric(horizontal: 3.w),
                    padding:
                        EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              margin: EdgeInsets.only(right: 3),
                              decoration: BoxDecoration(
                                  color: e.color,
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(10 / 2))),
                            ),
                            Text(
                              e.name!,
                              style: TextStyle(
                                  fontFamily: "TitilliumWeb",
                                  fontSize: UI.getTextSize(12, context),
                                  fontWeight: FontWeight.w400,
                                  color: Theme.of(context)
                                      .textSelectionTheme
                                      .selectionColor),
                            )
                          ],
                        ),
                        Text(
                          widget.hideBalance
                              ? "******"
                              : "${widget.datas[index].currencySymbol}${Fmt.priceFloorFormatter(e.value, lengthMax: widget.datas[index].lengthMax)}",
                          style: TextStyle(
                              fontFamily: "TitilliumWeb",
                              fontSize: UI.getTextSize(12, context),
                              fontWeight: FontWeight.w400,
                              color: Theme.of(context)
                                  .textSelectionTheme
                                  .selectionColor),
                        )
                      ],
                    ),
                  )))
              .toList(),
        ],
      );
    } else {
      return SkaletionRow(items: 4);
    }
  }
}

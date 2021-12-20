import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:polkawallet_plugin_karura/utils/InstrumentItemWidget.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/utils/format.dart';

class InstrumentWidget extends StatefulWidget {
  InstrumentWidget(this.datas, this.onSwitchChange, this.onSwitchHideBalance,
      {Key key, this.hideBalance = false, this.enabled = true})
      : super(key: key);
  final List<InstrumentData> datas;
  final Function onSwitchChange;
  final Function onSwitchHideBalance;
  final bool hideBalance;
  final bool enabled;

  @override
  _InstrumentWidgetState createState() => _InstrumentWidgetState();
}

class _InstrumentWidgetState extends State<InstrumentWidget> {
  InstrumentItemWidgetController controller = InstrumentItemWidgetController();
  int index = 0;

  @override
  void initState() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => controller.switchAction(isOnClick: false));
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - (16.w + 11.w + 34.w) * 2;
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
                      widget.onSwitchChange();
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
                          widget.datas[index].title.length > 0
                              ? "${widget.datas[index].title}:"
                              : "",
                          style: TextStyle(
                              fontFamily: "TitilliumWeb",
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                              color: Theme.of(context)
                                  .textSelectionTheme
                                  .selectionColor)),
                      GestureDetector(
                          onTap: () {
                            widget.onSwitchHideBalance();
                          },
                          child: Text(
                              widget.hideBalance
                                  ? "******"
                                  : "${widget.datas[index].currencySymbol}${Fmt.priceFloor(widget.datas[index].sumValue, lengthMax: widget.datas[index].lengthMax)}",
                              style: TextStyle(
                                  fontFamily: "SF_Pro",
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .textSelectionTheme
                                      .selectionColor))),
                      Container(
                        margin: EdgeInsets.only(top: 15.h),
                        child: GestureDetector(
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
                                          Color(0xFFBEB9B2),
                                          Color(0xFF74716C),
                                        ])),
                                child: Center(
                                  child: Container(
                                    margin: EdgeInsets.only(bottom: 5),
                                    width: 22.w,
                                    height: 15.w,
                                    child: Image.asset(
                                        'assets/images/icon_instrument_2.png'),
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
        widget.datas.length < 2
            ? Container(
                margin: EdgeInsets.only(bottom: 8),
              )
            : Container(
                margin: EdgeInsets.only(top: 4, bottom: 8),
                child: Text(widget.datas[index].prompt,
                    style: TextStyle(
                        fontFamily: "SF_Pro",
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context)
                            .textSelectionTheme
                            .selectionColor)),
              ),
        Row(
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
                                e.name,
                                style: TextStyle(
                                    fontFamily: "TitilliumWeb",
                                    fontSize: 12.sp,
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
                                : "${widget.datas[index].currencySymbol}${Fmt.priceFloor(e.value, lengthMax: widget.datas[index].lengthMax)}",
                            style: TextStyle(
                                fontFamily: "TitilliumWeb",
                                fontSize: 12.sp,
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
        )
      ],
    );
  }
}

import 'dart:math';

import 'package:flutter/material.dart';

class InstrumentItemWidget extends StatefulWidget {
  final List<InstrumentData> datas;
  int initializeIndex;
  final Size size;
  InstrumentItemWidgetController controller;
  Function(int, bool isOnClick)? onChanged;
  InstrumentItemWidget(
      {Key? key,
      required this.controller,
      required this.datas,
      required this.size,
      this.onChanged,
      this.initializeIndex = 0})
      : super(key: key);

  @override
  _InstrumentItemWidgetState createState() => _InstrumentItemWidgetState();
}

class _InstrumentItemWidgetState extends State<InstrumentItemWidget>
    with TickerProviderStateMixin {
  final GlobalKey _containerKey = GlobalKey();

  late Animation<double> animation;
  double animationNumber = 1;
  late AnimationController controller;

  bool isSwitching = false;

  @override
  void initState() {
    widget.controller.bindAction(({bool? isOnClick}) {
      _switchAction(isOnClick: isOnClick ?? true);
    });
    super.initState();
  }

  dispose() {
    controller.dispose();
    super.dispose();
  }

  _switchAction({isOnClick = true}) {
    if (isSwitching) return;
    controller = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);
    final CurvedAnimation curve =
        CurvedAnimation(parent: controller, curve: Curves.easeIn);
    animation = Tween(begin: 1.0, end: 0.0).animate(curve)
      ..addListener(() {
        setState(() {
          isSwitching = true;
          animationNumber = animation.value;
          // the state that has changed here is the animation object’s value
        });
      })
      ..addStatusListener((state) {
        //当动画在开始处停止再次从头开始执行动画
        if (state == AnimationStatus.completed) {
          setState(() {
            isSwitching = false;
            this.animationNumber = 1;
            widget.initializeIndex =
                widget.initializeIndex + 1 >= widget.datas.length
                    ? 0
                    : widget.initializeIndex + 1;
            if (widget.onChanged != null) {
              widget.onChanged!(widget.initializeIndex, isOnClick);
            }
          });
        }
      });
    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: _containerKey,
      children: buildItems(),
    );
  }

  List<Widget> buildItems() {
    final List<Widget> currentWidgets = [];
    final List<Widget> widgets = [];
    for (int j = 0; j < widget.datas.length; j++) {
      double angle = 0;
      for (int i = 0; i < widget.datas[j].items.length; i++) {
        if (i > 0) {
          angle += -3.85 *
              widget.datas[j].items[i - 1].value! /
              widget.datas[j].sumValue!;
        }
        if (double.parse(widget.datas[j].items[i].value!
                .toStringAsFixed(widget.datas[j].lengthMax)) >
            0) {
          var angleValue = j == widget.initializeIndex
              ? (angle * animationNumber + 2.4 * (1 - animationNumber))
              : (-3.9 * animationNumber + angle * (1 - animationNumber));
          (j == widget.initializeIndex ? currentWidgets : widgets).add(
              angleValue < -2.45
                  ? ClipRect(
                      child: Align(
                          widthFactor: 0.5,
                          alignment: Alignment.centerLeft,
                          child:
                              buildItem(angleValue, widget.datas[j].items[i])))
                  : buildItem(angleValue, widget.datas[j].items[i]));
        }
      }
    }
    currentWidgets.addAll(widgets);
    return currentWidgets.length > 0 ? currentWidgets : [Container()];
  }

  Widget buildItem(double angleValue, InstrumentItemData data) {
    return ClipRect(
        child: Align(
            widthFactor: 1,
            alignment: Alignment.topCenter,
            child: Transform.rotate(
              angle: angleValue,
              alignment: Alignment.bottomCenter,
              origin: Offset(0, -(43 / 167) * widget.size.height),
              child: SizedBox(
                width: widget.size.width,
                height: widget.size.height,
                child: CustomPaint(
                  painter: MyPainter(data),
                ),
              ),
            )));
  }
}

class MyPainter extends CustomPainter {
  MyPainter(this.data);
  InstrumentItemData data;

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = data.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 17;
    Rect rect = Rect.fromCircle(
        center: Offset(size.width / 2, size.height * 0.743),
        radius: size.height * 0.69);

    canvas.drawArc(rect, pi * (1 - 0.08), pi * 1.16, false, paint);
  }

  @override
  bool shouldRepaint(MyPainter oldDelegate) => oldDelegate.data != data;
}

class InstrumentItemWidgetController {
  late Function({bool? isOnClick}) switchAction;

  void bindAction(Function({bool? isOnClick}) switchAction) {
    this.switchAction = switchAction;
  }
}

class InstrumentItemData {
  final Color color;
  final String? name;
  final double? value;

  InstrumentItemData(this.color, this.name, this.value);
}

class InstrumentData {
  final double? sumValue;
  final int lengthMax;
  final String currencySymbol;
  final String? title;
  List<InstrumentItemData> items;

  InstrumentData(this.sumValue, this.items,
      {this.lengthMax = 2, this.currencySymbol = "\$", this.title = ""});
}

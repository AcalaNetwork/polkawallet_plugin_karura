import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class LoanTabBarWidget extends StatefulWidget {
  LoanTabBarWidget({required this.datas, Key? key}) : super(key: key);
  final List<LoanTabBarWidgetData> datas;

  @override
  _LoanTabBarWidgetState createState() => _LoanTabBarWidgetState();
}

class _LoanTabBarWidgetState extends State<LoanTabBarWidget> {
  int _index = 0;
  int _min = 0, _max = 0;
  bool _isTabBarOnClick = false;
  ItemScrollController _scrollController = ItemScrollController();
  ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  PageController _pageController = PageController();

  void onChange(int index) {
    if (index >= widget.datas.length) {
      index = 0;
    }

    setState(() {
      _index = index;
      if (_index < _min || _index > _max) {
        _scrollController.jumpTo(index: _index);
      }
    });
    _pageController.animateToPage(index,
        duration: Duration(milliseconds: 500), curve: Curves.ease);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          ValueListenableBuilder<Iterable<ItemPosition>>(
            valueListenable: _itemPositionsListener.itemPositions,
            builder: (context, positions, child) {
              int? min;
              int? max;
              if (positions.isNotEmpty) {
                // Determine the first visible item by finding the item with the
                // smallest trailing edge that is greater than 0.  i.e. the first
                // item whose trailing edge in visible in the viewport.
                min = positions
                    .where((ItemPosition position) =>
                        position.itemLeadingEdge >= 0)
                    .reduce((ItemPosition min, ItemPosition position) =>
                        position.itemTrailingEdge < min.itemTrailingEdge
                            ? position
                            : min)
                    .index;
                // Determine the last visible item by finding the item with the
                // greatest leading edge that is less than 1.  i.e. the last
                // item whose leading edge in visible in the viewport.
                max = positions
                    .where((ItemPosition position) =>
                        double.parse(
                            position.itemTrailingEdge.toStringAsFixed(2)) <=
                        1)
                    .reduce((ItemPosition max, ItemPosition position) =>
                        position.itemTrailingEdge > max.itemTrailingEdge
                            ? position
                            : max)
                    .index;
                _min = min;
                _max = max;
              }
              return Container();
            },
          ),
          Container(
            height: 48,
            width: double.infinity,
            margin: EdgeInsets.only(
              right: 96,
              bottom: 12,
              left: 16,
            ),
            decoration: BoxDecoration(
                color: Color(0x66FFFFFF),
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(13),
                    topRight: Radius.circular(13),
                    bottomRight: Radius.circular(13))),
            child: ScrollablePositionedList.builder(
                scrollDirection: Axis.horizontal,
                itemScrollController: _scrollController,
                itemPositionsListener: _itemPositionsListener,
                itemCount: widget.datas.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                      onTap: () {
                        onChange(index);
                        _isTabBarOnClick = true;
                      },
                      child: Center(
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 18),
                          padding: _index == index ? EdgeInsets.all(5) : null,
                          decoration: _index == index
                              ? BoxDecoration(
                                  color: Color(0xCCFFFFFF),
                                  borderRadius: const BorderRadius.all(
                                      const Radius.circular(10)))
                              : null,
                          child: Stack(
                            children: [
                              Container(
                                  width: 30,
                                  height: 30,
                                  child: widget.datas[index].icon),
                              Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                      color: _index == index
                                          ? Colors.transparent
                                          : Color(0x33000000),
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(15))))
                            ],
                          ),
                        ),
                      ));
                }),
          ),
          Expanded(
              child: PageView(
            physics: BouncingScrollPhysics(),
            children: widget.datas
                .map((e) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: e.context,
                    ))
                .toList(),
            controller: _pageController,
            onPageChanged: (index) {
              if (_isTabBarOnClick == false) {
                onChange(index);
              }
              if (index == _index) {
                _isTabBarOnClick = false;
              }
            },
          ))
        ],
      ),
    );
  }
}

class LoanTabBarWidgetData {
  const LoanTabBarWidgetData(this.icon, this.context);
  final Widget icon;
  final Widget context;
}

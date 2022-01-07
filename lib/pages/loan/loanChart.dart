import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

class LoanDonutChart extends StatelessWidget {
  LoanDonutChart(this.data, {this.title, this.subtitle, this.colorType});
  final List<double> data;
  final String? title;
  final String? subtitle;
  final int?
      colorType; // 0 for green(safe), 1 for orange(warn), 2 for red(danger)
  @override
  Widget build(BuildContext context) {
    final color = colorType == 0
        ? charts.MaterialPalette.green
        : colorType == 1
            ? charts.MaterialPalette.yellow
            : charts.MaterialPalette.red;
    final textColor = Color.fromARGB(254, color.shadeDefault.darker.r,
        color.shadeDefault.darker.g, color.shadeDefault.darker.b);
    final titleStyle = TextStyle(
      fontSize: 16,
      color: textColor,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.8,
    );

    final List<charts.Series> seriesList = [
      new charts.Series<num, int?>(
        id: 'chartData',
        domainFn: (_, i) => i,
        colorFn: (_, i) => i == data.length - 1
            ? charts.MaterialPalette.gray.shade100
            : i == 0
                ? color.shadeDefault
                : color.shadeDefault.lighter,
        measureFn: (num i, _) => i,
        data: data,
      )
    ];

    final chartHeight = MediaQuery.of(context).size.width / 2.7;

    return Stack(
      children: <Widget>[
        Container(
          height: chartHeight,
          child: charts.PieChart(seriesList,
              animate: false,
              defaultRenderer: new charts.ArcRendererConfig(arcWidth: 12)),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
              height: chartHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Visibility(
                      visible: title != null,
                      child: Container(
                          margin: EdgeInsets.only(top: 8),
                          child: Text(title ?? '', style: titleStyle))),
                  Visibility(
                      visible: subtitle != null,
                      child: Text(subtitle ?? '',
                          style: TextStyle(fontSize: 10, color: textColor))),
                ],
              ))
        ])
      ],
    );
  }
}

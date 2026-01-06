import 'package:flutter/material.dart';

class ChartContainer extends StatelessWidget {
  final Color color;
  final Widget chart;

  const ChartContainer({
    Key? key,
    required this.color,
    required this.chart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.width * 0.5,
        padding: const EdgeInsets.fromLTRB(0, 20, 20, 10),
        decoration: BoxDecoration(
          color: color,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
                child: Container(
                  child: chart,
                )
            )
          ],
        ),
      ),
    );
  }
}
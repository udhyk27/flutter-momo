import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

// 곡 상세화면 - 주간 방송 차트 - 순위 상시 표시
class RankDotPainter extends FlDotPainter {

  final int rank;
  final Color color;

  RankDotPainter({
    required this.rank,
    required this.color,
  });

  @override
  Color get mainColor => color;

  @override
  List<Object?> get props => [rank, color];

  @override
  FlDotPainter lerp(
      FlDotPainter a,
      FlDotPainter b,
      double t,
      ) {
    if (a is RankDotPainter && b is RankDotPainter) {
      return RankDotPainter(
        rank: t < 0.5 ? a.rank : b.rank,
        color: Color.lerp(a.color, b.color, t) ?? color,
      );
    }
    return this;
  }

  @override
  Size getSize(FlSpot spot) {
    return const Size(40, 28); // 점 + 텍스트 영역
  }

  @override
  void draw(
      Canvas canvas,
      FlSpot spot,
      Offset offset,
      ) {
    // 점
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(offset, 3.5, dotPaint);

    // 순위권 밖이면 텍스트 안 그림
    if (rank <= 0 || rank > 100) return;

    final textPainter = TextPainter(
      text: TextSpan(
        text: '${rank}위',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final textOffset = Offset(
      offset.dx - textPainter.width / 2,
      offset.dy - 18,
    );

    textPainter.paint(canvas, textOffset);
  }
}

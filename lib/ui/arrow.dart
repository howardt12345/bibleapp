
import 'package:flutter/material.dart';

class Arrow extends StatefulWidget {
  final double length;
  final Color color;
  final bool repeat;

  Arrow({this.length, this.color, this.repeat = false});

  @override
  State<Arrow> createState() => new ArrowState();
}
class ArrowState extends State<Arrow> with SingleTickerProviderStateMixin {
  double _fraction = 0.0;
  Animation<double> animation;

  @override
  void initState() {
    super.initState();
    var controller = AnimationController(
        duration: Duration(milliseconds: 1000), vsync: this);

    animation = Tween(begin: 0.0, end: 2.0).animate(controller)
      ..addListener(() {
        setState(() {
          _fraction = animation.value;
        });
      });
    widget.repeat ? controller.repeat(period: Duration(milliseconds: 1500)) : controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return new AspectRatio(aspectRatio: 1/widget.length,
      child: Container(
        child: CustomPaint(
          painter: ArrowPainter(
              _fraction >= 1 ? 1.0 : _fraction,
              1/widget.length,
              widget.color
          ),
        ),
      ),
    );
  }
}
class ArrowPainter extends CustomPainter {
  Paint _paint;
  double _fraction,
      _length;

  ArrowPainter(
      this._fraction,
      this._length,
      Color color
      ) : _paint = Paint()
    ..color = color
    ..strokeWidth = 6.0
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    double lineFraction;

    if (_fraction > 1-_length) {
      lineFraction = (_fraction - (1-_length)) / (_length);
    }
    canvas.drawLine(Offset(size.width/2, 0.0),
        Offset(size.width/2, size.height * _fraction),
        _paint);

    if (_fraction >= (1-_length)) {
      canvas.drawLine(Offset(0.0, size.height*(1-_length)),
          Offset(((size.width/2) * lineFraction),
              size.height*(1-_length) + (size.height*(_length) * lineFraction)), _paint);
      canvas.drawLine(Offset(size.width, size.height*(1-_length)),
          Offset((size.width) - ((size.width/2) * lineFraction),
              size.height*(1-_length) + (size.height*(_length) * lineFraction)), _paint);
    }
  }

  @override
  bool shouldRepaint(ArrowPainter oldDelegate) {
    return oldDelegate._fraction != _fraction;
  }
}

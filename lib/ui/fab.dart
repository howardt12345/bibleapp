import 'package:flutter/material.dart';
import 'dart:math' as math;

class SpeedDialActionButton extends StatefulWidget {
  final List<SpeedDialAction> actions;
  final Icon dismissed,
      active;
  final Duration duration;
  final bool minimize;

  SpeedDialActionButton({
    Key key,
    this.actions,
    this.active: const Icon(Icons.close),
    this.dismissed: const Icon(Icons.add),
    this.duration: const Duration(milliseconds: 100),
    this.minimize: true,
  }) : super(key: key);

  @override _SpeedDialActionButtonState createState() => new _SpeedDialActionButtonState();
}
class _SpeedDialActionButtonState extends State<SpeedDialActionButton> with TickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(
      vsync: this,
      duration: widget.duration,
    );
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Theme.of(context).cardColor;
    Color foregroundColor = Theme.of(context).accentColor;

    return new Column(
      mainAxisSize: MainAxisSize.min,
      children: new List.generate(widget.actions.length, (int index) {
        Widget child = new Container(
          height: 56.0,
          width: 56.0,
          alignment: Alignment.topCenter,
          child: new ScaleTransition(
            scale: new CurvedAnimation(
              parent: _controller,
              curve: new Interval(
                  0.0,
                  1.0 - index / widget.actions.length / 2.0,
                  curve: Curves.easeOut
              ),
            ),
            child: new FloatingActionButton(
              backgroundColor: backgroundColor,
              mini: true,
              child: new Icon(widget.actions[index].icon, color: foregroundColor),
              onPressed: () {
                widget.actions[index].function();
                if(widget.minimize) _controller.reverse();
              },
            ),
          ),
        );
        return child;
      }).toList()..add(
        new FloatingActionButton(
          child: new AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget child) {
              return new Transform(
                transform: new Matrix4.rotationZ(_controller.value * 0.5 * math.pi),
                alignment: Alignment.center,
                child: _controller.isDismissed ? widget.dismissed : widget.active,
              );
            },
          ),
          onPressed: () {
            if (_controller.isDismissed) {
              _controller.forward();
            } else {
              _controller.reverse();
            }
          },
        ),
      ),
    );
  }
}

class SpeedDialAction {

  final IconData icon;
  final Function function;

  SpeedDialAction({
    this.icon,
    this.function,
  });
}
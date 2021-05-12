library flutter_audio_recorder;

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AudioWaveBar {
  AudioWaveBar({
    this.height,
    this.color,
    this.radius = 50.0,
  });

  /// [height] is the height of the bar based. It is percentage rate of widget height.

  /// If it's set to 30, then it will be 30% height from the widget height.

  /// [height] of bar must be between 0 to 100. Or There will be side effect.
  double height;

  /// [color] is the color of the bar
  Color color;

  /// [radius] is the radius of bar
  double radius;
}

class AudioWave extends StatefulWidget {
  AudioWave({
    this.height = 100,
    this.width = 200,
    this.spacing = 5,
    this.crossAxisAlignment = WrapCrossAlignment.center,
    this.animation = true,
    this.animationLoop = 1,
    this.animateDurations = const Duration(milliseconds: 100),
    @required this.bars,
  });

  final List<AudioWaveBar> bars;

  /// [height] is the height of the widget.
  final double height;

  /// [width] is the width of the widget. Input the
  final double width;

  /// [spacing] is the spaces between bars.
  final double spacing;

  final WrapCrossAlignment crossAxisAlignment;

  /// [animation] if it is set to true, then the bar will be animated.
  final bool animation;

  /// [animationLoop] limits no of loops. If it is set to 0, then it loops forever. default is 0.
  final int animationLoop;

  /// [animateDurations] plays how fast/slow the bar animated.
  final Duration animateDurations;

  @override
  _AudioWaveState createState() => _AudioWaveState();
}

class _AudioWaveState extends State<AudioWave> {
  int countBeat = 0;

  List<AudioWaveBar> bars;
  ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    if (widget.animation) {
      bars = widget.bars;
      WidgetsBinding.instance.addPostFrameCallback((x) {
        Timer.periodic(widget.animateDurations, (timer) {
          int mo = countBeat % widget.bars.length;
          bars = List.from(widget.bars.getRange(0, mo + 1));
          if (mounted) setState(() {});
          countBeat++;
          if (widget.animationLoop > 0 && widget.animationLoop <= (countBeat / widget.bars.length)) {
            timer.cancel();
          }
        });
      });
    } else {
      bars = widget.bars;
    }

    Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (mounted) {
        _scrollToBottom();
      } else {
        timer.cancel();
      }
    });
  }

  void _scrollToBottom() {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: widget.width,
      alignment: Alignment.center,
      child: ListView.builder(
        shrinkWrap: true,
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: bars.length,
        itemBuilder: (context, index) {
          return Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            children: [
              Container(
                alignment: Alignment.center,
                height: bars[index].height * widget.height / 100,
                width: 2,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(bars[index].radius),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

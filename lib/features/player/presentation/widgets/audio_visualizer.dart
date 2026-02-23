import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Visualiseur audio animé (barres) pendant la lecture.
/// S'anime quand [isPlaying] est true.
class AudioVisualizer extends StatefulWidget {
  final bool isPlaying;
  final int barCount;
  final double barWidth;
  final double minHeight;
  final double maxHeight;
  final Color? color;

  const AudioVisualizer({
    super.key,
    required this.isPlaying,
    this.barCount = 32,
    this.barWidth = 3,
    this.minHeight = 4,
    this.maxHeight = 24,
    this.color,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    return AnimatedOpacity(
      opacity: widget.isPlaying ? 1.0 : 0.35,
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        height: widget.maxHeight + 8,
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(widget.barCount, (i) {
                  final t = _controller.value + (i / widget.barCount);
                  final wave = (math.sin(t * math.pi * 2) + 1) / 2;
                  final height = widget.isPlaying
                      ? widget.minHeight +
                          wave * (widget.maxHeight - widget.minHeight)
                      : widget.minHeight;
                  return Container(
                    width: widget.barWidth,
                    height: height.clamp(widget.minHeight, widget.maxHeight),
                    margin: EdgeInsets.only(
                      left: i == 0 ? 0 : 2,
                      right: i == widget.barCount - 1 ? 0 : 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(widget.barWidth / 2),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }
}

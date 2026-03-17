import 'package:flutter/material.dart';

/// A widget that bounces (scales down slightly and then back up)
/// when pressed or when the `trigger` value changes.
class AnimatedBounce extends StatefulWidget {
  final Widget child;
  final bool animateOnTap;
  final VoidCallback? onTap;

  /// If provided, the widget will bounce every time this value changes.
  final dynamic trigger;

  const AnimatedBounce({
    super.key,
    required this.child,
    this.animateOnTap = false,
    this.onTap,
    this.trigger,
  });

  @override
  State<AnimatedBounce> createState() => _AnimatedBounceState();
}

class _AnimatedBounceState extends State<AnimatedBounce>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant AnimatedBounce oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != null && oldWidget.trigger != widget.trigger) {
      _playBounce();
    }
  }

  void _playBounce() {
    _controller.forward().then((_) {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );

    if (widget.animateOnTap) {
      return Semantics(
        button: widget.onTap != null,
        child: GestureDetector(
          onTapDown: (_) {
            if (widget.onTap != null) _controller.forward();
          },
          onTapUp: (_) {
            if (widget.onTap != null) _controller.reverse();
            widget.onTap?.call();
          },
          onTapCancel: () {
            if (widget.onTap != null) _controller.reverse();
          },
          child: content,
        ),
      );
    } else if (widget.onTap != null) {
      return Semantics(
        button: true,
        child: GestureDetector(onTap: widget.onTap, child: content),
      );
    }

    return content;
  }
}

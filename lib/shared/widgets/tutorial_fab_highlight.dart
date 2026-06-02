import 'package:flutter/material.dart';

class TutorialFabHighlight extends StatefulWidget {
  final Widget child;
  final bool isHighlighting;

  const TutorialFabHighlight({
    super.key,
    required this.child,
    required this.isHighlighting,
  });

  @override
  State<TutorialFabHighlight> createState() => _TutorialFabHighlightState();
}

class _TutorialFabHighlightState extends State<TutorialFabHighlight>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isHighlighting) {
      _controller.repeat(reverse: false);
    }
  }

  @override
  void didUpdateWidget(TutorialFabHighlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighting != oldWidget.isHighlighting) {
      if (widget.isHighlighting) {
        _controller.repeat(reverse: false);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isHighlighting) {
      return widget.child;
    }

    final color = Theme.of(context).colorScheme.primary;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Efek denyut (Pulse)
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle, // Cocok untuk FAB bulat/oval
                  ),
                ),
              ),
            );
          },
        ),
        // FAB Asli
        widget.child,
      ],
    );
  }
}

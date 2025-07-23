import 'package:fluent_ui/fluent_ui.dart';
import 'design_tokens.dart';

/// Animation system providing consistent animations throughout the app
class AnimationSystem {
  AnimationSystem._();
  
  // =============================================================================
  // FADE ANIMATIONS
  // =============================================================================
  
  /// Fade in animation widget
  static Widget fadeIn({
    required Widget child,
    Duration duration = DesignTokens.animationNormal,
    Duration delay = Duration.zero,
    Curve curve = Curves.easeOut,
  }) {
    return _AnimatedFade(
      duration: duration,
      delay: delay,
      curve: curve,
      child: child,
    );
  }
  
  /// Fade transition between widgets
  static Widget fadeTransition({
    required Widget child,
    required bool show,
    Duration duration = DesignTokens.animationNormal,
    Curve curve = Curves.easeInOut,
  }) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      child: show ? child : const SizedBox.shrink(),
    );
  }
  
  // =============================================================================
  // SLIDE ANIMATIONS
  // =============================================================================
  
  /// Slide in from direction
  static Widget slideIn({
    required Widget child,
    SlideDirection direction = SlideDirection.bottom,
    Duration duration = DesignTokens.animationNormal,
    Duration delay = Duration.zero,
    Curve curve = Curves.easeOut,
    double distance = 50.0,
  }) {
    return _AnimatedSlide(
      direction: direction,
      duration: duration,
      delay: delay,
      curve: curve,
      distance: distance,
      child: child,
    );
  }
  
  /// Slide transition with direction
  static Widget slideTransition({
    required Widget child,
    required bool show,
    SlideDirection direction = SlideDirection.bottom,
    Duration duration = DesignTokens.animationNormal,
    Curve curve = Curves.easeInOut,
    double distance = 50.0,
  }) {
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      transform: Matrix4.translationValues(
        show ? 0 : (direction == SlideDirection.left ? -distance : direction == SlideDirection.right ? distance : 0),
        show ? 0 : (direction == SlideDirection.top ? -distance : direction == SlideDirection.bottom ? distance : 0),
        0,
      ),
      child: AnimatedOpacity(
        duration: duration,
        curve: curve,
        opacity: show ? 1.0 : 0.0,
        child: child,
      ),
    );
  }
  
  // =============================================================================
  // SCALE ANIMATIONS
  // =============================================================================
  
  /// Scale in animation
  static Widget scaleIn({
    required Widget child,
    Duration duration = DesignTokens.animationNormal,
    Duration delay = Duration.zero,
    Curve curve = Curves.easeOutBack,
    double initialScale = 0.8,
  }) {
    return _AnimatedScale(
      duration: duration,
      delay: delay,
      curve: curve,
      initialScale: initialScale,
      child: child,
    );
  }
  
  /// Scale transition
  static Widget scaleTransition({
    required Widget child,
    required bool show,
    Duration duration = DesignTokens.animationNormal,
    Curve curve = Curves.easeInOut,
    double hiddenScale = 0.8,
  }) {
    return AnimatedScale(
      duration: duration,
      curve: curve,
      scale: show ? 1.0 : hiddenScale,
      child: AnimatedOpacity(
        duration: duration,
        curve: curve,
        opacity: show ? 1.0 : 0.0,
        child: child,
      ),
    );
  }
  
  // =============================================================================
  // STAGGERED ANIMATIONS
  // =============================================================================
  
  /// Staggered list animation
  static Widget staggeredList({
    required List<Widget> children,
    Duration staggerDelay = const Duration(milliseconds: 100),
    Duration itemDuration = DesignTokens.animationNormal,
    SlideDirection direction = SlideDirection.bottom,
    double distance = 30.0,
  }) {
    return Column(
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        
        return slideIn(
          direction: direction,
          duration: itemDuration,
          delay: Duration(milliseconds: staggerDelay.inMilliseconds * index),
          distance: distance,
          child: child,
        );
      }).toList(),
    );
  }
  
  /// Staggered grid animation
  static Widget staggeredGrid({
    required List<Widget> children,
    required int columns,
    Duration staggerDelay = const Duration(milliseconds: 50),
    Duration itemDuration = DesignTokens.animationNormal,
    SlideDirection direction = SlideDirection.bottom,
    double distance = 30.0,
  }) {
    return Wrap(
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        
        return slideIn(
          direction: direction,
          duration: itemDuration,
          delay: Duration(milliseconds: staggerDelay.inMilliseconds * index),
          distance: distance,
          child: child,
        );
      }).toList(),
    );
  }
  
  // =============================================================================
  // LOADING ANIMATIONS
  // =============================================================================
  
  /// Pulsing animation for loading states
  static Widget pulse({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
    double minOpacity = 0.5,
    double maxOpacity = 1.0,
  }) {
    return _PulseAnimation(
      duration: duration,
      minOpacity: minOpacity,
      maxOpacity: maxOpacity,
      child: child,
    );
  }
  
  /// Shimmer animation for skeleton loading
  static Widget shimmer({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
    Color? baseColor,
    Color? highlightColor,
  }) {
    return _ShimmerAnimation(
      duration: duration,
      baseColor: baseColor ?? DesignTokens.neutralGray200,
      highlightColor: highlightColor ?? DesignTokens.neutralGray100,
      child: child,
    );
  }
  
  // =============================================================================
  // INTERACTIVE ANIMATIONS
  // =============================================================================
  
  /// Hover scale animation
  static Widget hoverScale({
    required Widget child,
    double scale = 1.05,
    Duration duration = const Duration(milliseconds: 150),
    Curve curve = Curves.easeOut,
  }) {
    return _HoverScaleAnimation(
      scale: scale,
      duration: duration,
      curve: curve,
      child: child,
    );
  }
  
  /// Press animation
  static Widget pressAnimation({
    required Widget child,
    required VoidCallback? onPressed,
    double scale = 0.95,
    Duration duration = const Duration(milliseconds: 100),
  }) {
    return _PressAnimation(
      scale: scale,
      duration: duration,
      onPressed: onPressed,
      child: child,
    );
  }
}

// =============================================================================
// ANIMATION ENUMS
// =============================================================================

enum SlideDirection {
  top,
  bottom,
  left,
  right,
}

// =============================================================================
// ANIMATION WIDGETS
// =============================================================================

class _AnimatedFade extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  const _AnimatedFade({
    required this.child,
    required this.duration,
    required this.delay,
    required this.curve,
  });

  @override
  State<_AnimatedFade> createState() => _AnimatedFadeState();
}

class _AnimatedFadeState extends State<_AnimatedFade>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}

class _AnimatedSlide extends StatefulWidget {
  final Widget child;
  final SlideDirection direction;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final double distance;

  const _AnimatedSlide({
    required this.child,
    required this.direction,
    required this.duration,
    required this.delay,
    required this.curve,
    required this.distance,
  });

  @override
  State<_AnimatedSlide> createState() => _AnimatedSlideState();
}

class _AnimatedSlideState extends State<_AnimatedSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    
    Offset begin;
    switch (widget.direction) {
      case SlideDirection.top:
        begin = Offset(0, -widget.distance / 100);
        break;
      case SlideDirection.bottom:
        begin = Offset(0, widget.distance / 100);
        break;
      case SlideDirection.left:
        begin = Offset(-widget.distance / 100, 0);
        break;
      case SlideDirection.right:
        begin = Offset(widget.distance / 100, 0);
        break;
    }

    _slideAnimation = Tween<Offset>(begin: begin, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}

class _AnimatedScale extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final double initialScale;

  const _AnimatedScale({
    required this.child,
    required this.duration,
    required this.delay,
    required this.curve,
    required this.initialScale,
  });

  @override
  State<_AnimatedScale> createState() => _AnimatedScaleState();
}

class _AnimatedScaleState extends State<_AnimatedScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    
    _scaleAnimation = Tween<double>(begin: widget.initialScale, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}

class _PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minOpacity;
  final double maxOpacity;

  const _PulseAnimation({
    required this.child,
    required this.duration,
    required this.minOpacity,
    required this.maxOpacity,
  });

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: widget.minOpacity, end: widget.maxOpacity).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}

class _ShimmerAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color baseColor;
  final Color highlightColor;

  const _ShimmerAnimation({
    required this.child,
    required this.duration,
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  State<_ShimmerAnimation> createState() => _ShimmerAnimationState();
}

class _ShimmerAnimationState extends State<_ShimmerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _HoverScaleAnimation extends StatefulWidget {
  final Widget child;
  final double scale;
  final Duration duration;
  final Curve curve;

  const _HoverScaleAnimation({
    required this.child,
    required this.scale,
    required this.duration,
    required this.curve,
  });

  @override
  State<_HoverScaleAnimation> createState() => _HoverScaleAnimationState();
}

class _HoverScaleAnimationState extends State<_HoverScaleAnimation> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? widget.scale : 1.0,
        duration: widget.duration,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}

class _PressAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double scale;
  final Duration duration;

  const _PressAnimation({
    required this.child,
    required this.onPressed,
    required this.scale,
    required this.duration,
  });

  @override
  State<_PressAnimation> createState() => _PressAnimationState();
}

class _PressAnimationState extends State<_PressAnimation> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? widget.scale : 1.0,
        duration: widget.duration,
        child: widget.child,
      ),
    );
  }
}
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// A glass-effect text button for navigation bars (Edit/Done style)
/// Uses same structure as LiquidGlassBottomBar for identical appearance
class GlassTextButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final bool enabled;

  const GlassTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.textColor = CupertinoColors.systemOrange,
    this.fontSize = 17.0,
    this.fontWeight = FontWeight.normal,
    this.enabled = true,
  });

  @override
  State<GlassTextButton> createState() => _GlassTextButtonState();
}

class _GlassTextButtonState extends State<GlassTextButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveOpacity = widget.enabled ? (_isPressed ? 0.5 : 1.0) : 0.4;
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;

    final glassSettings = LiquidGlassSettings(
      refractiveIndex: 1.21,
      thickness: 30,
      blur: 8,
      saturation: 1.5,
      lightIntensity: isDark ? .7 : 1,
      ambientStrength: isDark ? .2 : .5,
      lightAngle: math.pi / 4,
      glassColor: const Color(0xFF48484A).withValues(alpha: 0.8),
    );
    
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: widget.enabled ? () => setState(() => _isPressed = false) : null,
      onTap: widget.enabled ? widget.onPressed : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: LiquidGlassLayer(
          settings: glassSettings,
          child: LiquidGlassBlendGroup(
            blend: 10,
            child: LiquidGlass.grouped(
              clipBehavior: Clip.none,
              shape: const LiquidRoundedSuperellipse(borderRadius: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF48484A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color: widget.textColor.withOpacity(effectiveOpacity),
                    fontSize: widget.fontSize,
                    fontWeight: widget.fontWeight,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A glass-effect icon button for navigation bars (Add button style) - circular/oval
class GlassIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color iconColor;
  final double iconSize;
  final bool enabled;

  const GlassIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.iconColor = CupertinoColors.systemOrange,
    this.iconSize = 28.0,
    this.enabled = true,
  });

  @override
  State<GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<GlassIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveOpacity = widget.enabled ? (_isPressed ? 0.5 : 1.0) : 0.4;
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;

    final glassSettings = LiquidGlassSettings(
      refractiveIndex: 1.21,
      thickness: 30,
      blur: 8,
      saturation: 1.5,
      lightIntensity: isDark ? .7 : 1,
      ambientStrength: isDark ? .2 : .5,
      lightAngle: math.pi / 4,
      glassColor: const Color(0xFF48484A).withValues(alpha: 0.8),
    );
    
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: widget.enabled ? () => setState(() => _isPressed = false) : null,
      onTap: widget.enabled ? widget.onPressed : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: LiquidGlassLayer(
          settings: glassSettings,
          child: LiquidGlassBlendGroup(
            blend: 10,
            child: LiquidGlass.grouped(
              clipBehavior: Clip.none,
              shape: const LiquidOval(),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFF48484A),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  widget.icon,
                  color: widget.iconColor.withOpacity(effectiveOpacity),
                  size: widget.iconSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A large glass-effect action button (for screens like alarm ring)
class GlassActionButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool enabled;
  final Color? glassColor;

  const GlassActionButton({
    super.key,
    required this.child,
    this.onPressed,
    this.borderRadius = 32.0,
    this.padding = const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
    this.enabled = true,
    this.glassColor,
  });

  @override
  State<GlassActionButton> createState() => _GlassActionButtonState();
}

class _GlassActionButtonState extends State<GlassActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.glassColor ?? const Color(0xFF48484A);
    final effectiveOpacity = widget.enabled ? (_isPressed ? 0.7 : 1.0) : 0.4;
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;

    final glassSettings = LiquidGlassSettings(
      refractiveIndex: 1.21,
      thickness: 30,
      blur: 8,
      saturation: 1.5,
      lightIntensity: isDark ? .7 : 1,
      ambientStrength: isDark ? .2 : .5,
      lightAngle: math.pi / 4,
      glassColor: baseColor.withValues(alpha: 0.85),
    );
    
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: widget.enabled ? () => setState(() => _isPressed = false) : null,
      onTap: widget.enabled ? widget.onPressed : null,
      child: LiquidGlassLayer(
        settings: glassSettings,
        child: LiquidGlassBlendGroup(
          blend: 10,
          child: LiquidGlass.grouped(
            clipBehavior: Clip.none,
            shape: LiquidRoundedSuperellipse(borderRadius: widget.borderRadius),
            child: Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
              child: Opacity(
                opacity: effectiveOpacity,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

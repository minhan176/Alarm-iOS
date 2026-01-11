import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// A button widget with liquid glass effect
class LiquidGlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? backgroundColor;
  final bool enabled;

  const LiquidGlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 10.0,
    this.backgroundColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      shape: LiquidRoundedSuperellipse(borderRadius: borderRadius),
      child: CupertinoButton(
        padding: padding,
        onPressed: enabled ? onPressed : null,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.5,
          child: child,
        ),
      ),
    );
  }
}

/// A text button with liquid glass effect for navigation bars
class LiquidGlassTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final bool enabled;

  const LiquidGlassTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.textColor = CupertinoColors.systemOrange,
    this.fontSize = 17.0,
    this.fontWeight = FontWeight.normal,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      shape: const LiquidRoundedSuperellipse(borderRadius: 8),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        onPressed: enabled ? onPressed : null,
        child: Text(
          text,
          style: TextStyle(
            color: enabled ? textColor : textColor.withOpacity(0.5),
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        ),
      ),
    );
  }
}

/// An icon button with liquid glass effect for navigation bars
class LiquidGlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color iconColor;
  final double iconSize;
  final bool enabled;

  const LiquidGlassIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.iconColor = CupertinoColors.systemOrange,
    this.iconSize = 28.0,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      shape: const LiquidRoundedSuperellipse(borderRadius: 8),
      child: CupertinoButton(
        padding: const EdgeInsets.all(8),
        onPressed: enabled ? onPressed : null,
        child: Icon(
          icon,
          color: enabled ? iconColor : iconColor.withOpacity(0.5),
          size: iconSize,
        ),
      ),
    );
  }
}

/// A large action button with liquid glass effect (for dialogs, screens)
class LiquidGlassActionButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool enabled;

  const LiquidGlassActionButton({
    super.key,
    required this.child,
    this.onPressed,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.symmetric(vertical: 20),
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      shape: LiquidRoundedSuperellipse(borderRadius: borderRadius),
      child: CupertinoButton(
        padding: padding,
        onPressed: enabled ? onPressed : null,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.5,
          child: child,
        ),
      ),
    );
  }
}

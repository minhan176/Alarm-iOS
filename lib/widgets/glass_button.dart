import 'package:flutter/cupertino.dart';

/// A simple text button for navigation bars (Edit/Done style)
class GlassTextButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      minSize: 0,
      onPressed: enabled ? onPressed : null,
      child: Text(
        text,
        style: TextStyle(
          color: enabled ? textColor : textColor.withOpacity(0.4),
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}

/// A simple icon button for navigation bars (Add button style)
class GlassIconButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.all(6),
      minSize: 0,
      onPressed: enabled ? onPressed : null,
      child: Icon(
        icon,
        color: enabled ? iconColor : iconColor.withOpacity(0.4),
        size: iconSize,
      ),
    );
  }
}

/// A large action button (for screens like alarm ring)
class GlassActionButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: padding,
      borderRadius: BorderRadius.circular(borderRadius),
      color: glassColor ?? const Color(0xFF48484A),
      onPressed: enabled ? onPressed : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: child,
      ),
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// A text button with liquid glass effect for navigation bars (Edit/Done style)
class NavTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final bool enabled;

  const NavTextButton({
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
    return Align(
      alignment: Alignment.centerLeft,
      child: IntrinsicWidth(
        child: LiquidStretch(
          child: LiquidGlass.grouped(
            shape: const LiquidRoundedSuperellipse(borderRadius: 9000),
            child: GlassGlow(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: enabled ? onPressed : null,
                child: SizedBox(
                  height: 40,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Center(
                      child: Text(
                        text,
                        style: TextStyle(
                          color: enabled ? textColor : textColor.withOpacity(0.4),
                          fontSize: fontSize,
                          fontWeight: fontWeight,
                        ),
                      ),
                    ),
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

/// An icon button with liquid glass effect for navigation bars (Add button style)
class NavIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color iconColor;
  final double iconSize;
  final bool enabled;
  final Color? backgroundColor;

  const NavIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.iconColor = CupertinoColors.systemOrange,
    this.iconSize = 28.0,
    this.enabled = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidStretch(
      child: LiquidGlass.grouped(
        shape: const LiquidRoundedSuperellipse(borderRadius: 9000),
        child: GlassGlow(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? onPressed : null,
            child: Container(
              width: 40,
              height: 40,
              decoration: backgroundColor != null
                  ? BoxDecoration(
                      color: backgroundColor,
                      shape: BoxShape.circle,
                    )
                  : null,
              child: Center(
                child: Icon(
                  icon,
                  color: enabled ? iconColor : iconColor.withOpacity(0.4),
                  size: iconSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A navigation button with both icon and text, styled similarly to NavIconButton
class NavTextIconButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onPressed;
  final Color iconColor;
  final double iconSize;
  final Color textColor;
  final double textSize;
  final bool enabled;
  final Color? backgroundColor;

  const NavTextIconButton({
    super.key,
    required this.icon,
    required this.text,
    this.onPressed,
    this.iconColor = CupertinoColors.systemOrange,
    this.iconSize = 24.0,
    this.textColor = CupertinoColors.systemOrange,
    this.textSize = 17.0,
    this.enabled = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidStretch(
      child: LiquidGlass.grouped(
        shape: const LiquidRoundedSuperellipse(borderRadius: 16),
        child: GlassGlow(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? onPressed : null,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: backgroundColor != null
                  ? BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                    )
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: enabled ? iconColor : iconColor.withOpacity(0.4),
                    size: iconSize,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    text,
                    style: TextStyle(
                      color: enabled ? textColor : textColor.withOpacity(0.4),
                      fontSize: textSize,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A large action button with liquid glass effect (for screens like alarm ring)
class ActionButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool enabled;
  final Color? backgroundColor;

  const ActionButton({
    super.key,
    required this.child,
    this.onPressed,
    this.borderRadius = 32.0,
    this.padding = const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
    this.enabled = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidStretch(
      child: LiquidGlass.grouped(
        shape: LiquidRoundedSuperellipse(borderRadius: borderRadius),
        child: GlassGlow(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? onPressed : null,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: backgroundColor?.withOpacity(0.3),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Opacity(
                opacity: enabled ? 1.0 : 0.4,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom navigation bar with liquid glass effect using Row
class CustomNavBar extends StatelessWidget {
  final Widget? leading;
  final Widget? middle;
  final Widget? trailing;
  final Color backgroundColor;
  final double height;

  const CustomNavBar({
    super.key,
    this.leading,
    this.middle,
    this.trailing,
    this.backgroundColor = CupertinoColors.black,
    this.height = 44.0,
  });

  LiquidGlassSettings _getGlassSettings(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    
    return LiquidGlassSettings(
      refractiveIndex: 1.21,
      thickness: 30,
      blur: 8,
      saturation: 1.5,
      lightIntensity: isDark ? .7 : 1,
      ambientStrength: isDark ? .2 : .5,
      lightAngle: math.pi / 4,
      glassColor: CupertinoTheme.of(context).barBackgroundColor.withValues(alpha: 0.2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: backgroundColor,
      child: LiquidGlassLayer(
        fake: true,
        settings: _getGlassSettings(context),
        child: LiquidGlassBlendGroup(
          blend: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Leading section
              SizedBox(
                width: 100,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: leading ?? const SizedBox.shrink(),
                  ),
                ),
              ),
              // Middle section
              Expanded(
                child: Center(
                  child: middle ?? const SizedBox.shrink(),
                ),
              ),
              // Trailing section
              SizedBox(
                width: 100,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: trailing ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

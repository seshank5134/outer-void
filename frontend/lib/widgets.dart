import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_state.dart';

/// Frosted glass card widget — reusable throughout the app
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double? width;
  final double? height;
  final AppState state;
  final Color? borderColor;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    required this.state,
    this.padding = const EdgeInsets.all(28),
    this.width,
    this.height,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(state.cardBorderRadius.toDouble());
    final border = borderColor ?? state.accent.withOpacity(0.15);
    final glass = state.glassOpacity;

    Widget card = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: border, width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(glass),
            Colors.white.withOpacity(glass * 0.4),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: state.accent.withOpacity(0.06),
            blurRadius: 24,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Padding(padding: padding, child: child),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(borderRadius: radius, onTap: onTap, child: card),
      );
    }
    return card;
  }
}

/// Glowing accent button
class GlowButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppState state;
  final bool outline;
  final IconData? icon;
  final bool isLoading;

  const GlowButton({
    super.key,
    required this.label,
    required this.state,
    this.onPressed,
    this.outline = false,
    this.icon,
    this.isLoading = false,
  });

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.state.accent;
    return GestureDetector(
      onTapDown: (_) {
        if (widget.state.showAnimations) _ctrl.forward();
      },
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              widget.state.cardBorderRadius.toDouble(),
            ),
            gradient: widget.outline
                ? null
                : LinearGradient(
                    colors: [accent, accent.withOpacity(0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            border: widget.outline
                ? Border.all(color: accent, width: 1.5)
                : null,
            boxShadow: widget.outline
                ? []
                : [
                    BoxShadow(
                      color: accent.withOpacity(0.4),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.outline ? accent : Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
              ] else if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 18,
                  color: widget.outline ? accent : Colors.white,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 13 * widget.state.uiFontScale,
                  letterSpacing: 1.5,
                  color: widget.outline ? accent : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Label for sections / module headers
class SectionLabel extends StatelessWidget {
  final String text;
  final AppState state;
  final double fontSize;
  final Color? color;

  const SectionLabel(
    this.text, {
    super.key,
    required this.state,
    this.fontSize = 10,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.jetBrainsMono(
        fontSize: fontSize * state.uiFontScale,
        color: color ?? state.accent.withOpacity(0.7),
        letterSpacing: 3,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Animated metric tile
class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final AppState state;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      state: state,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: state.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: state.accent, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 9 * state.uiFontScale,
                    color: Colors.white38,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15 * state.uiFontScale,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated gradient background
class GradientBackground extends StatelessWidget {
  final Widget child;
  final AppState state;

  const GradientBackground({
    super.key,
    required this.child,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final theme = state.currentTheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.7, -0.5),
          radius: 1.4,
          colors: [theme.bgEnd, theme.bgStart],
        ),
      ),
      child: child,
    );
  }
}

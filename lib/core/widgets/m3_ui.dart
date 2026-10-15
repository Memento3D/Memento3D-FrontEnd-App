import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Shared building blocks that mirror the Memento3D Figma screens.

TextStyle m3Text(
  double size, {
  FontWeight weight = FontWeight.w500,
  Color color = AppColors.textPrimary,
  double? height,
  FontStyle? style,
}) => GoogleFonts.plusJakartaSans(
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
  fontStyle: style,
);

/// Top bar: back arrow, title, optional help icon and avatar.
class M3TopBar extends StatelessWidget implements PreferredSizeWidget {
  const M3TopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.showBack = true,
    this.showHelp = false,
    this.showAvatar = true,
    this.onAvatar,
    this.actions = const [],
    this.centerTitle = false,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final bool showBack;
  final bool showHelp;
  final bool showAvatar;
  final VoidCallback? onAvatar;
  final List<Widget> actions;
  final bool centerTitle;
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final titleWidget = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centerTitle
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: m3Text(18, weight: FontWeight.w700),
        ),
        if (subtitle != null)
          Text(subtitle!, style: m3Text(11.5, color: AppColors.textSecondary)),
      ],
    );
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              const SizedBox(width: 6),
              if (leading != null)
                leading!
              else if (showBack && (canPop || onBack != null))
                IconButton(
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 22),
                  color: AppColors.textPrimary,
                )
              else
                const SizedBox(width: 10),
              Expanded(
                child: centerTitle
                    ? Center(child: titleWidget)
                    : Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: titleWidget,
                      ),
              ),
              ...actions,
              if (showHelp)
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.help_outline_rounded, size: 21),
                  color: AppColors.textPrimary,
                ),
              if (showAvatar) M3Avatar(onTap: onAvatar),
              const SizedBox(width: 14),
            ],
          ),
        ),
      ),
    );
  }
}

/// Indigo circular user avatar used on the right of most top bars.
class M3Avatar extends StatelessWidget {
  const M3Avatar({super.key, this.onTap, this.size = 30});

  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person_outline_rounded,
          color: Colors.white,
          size: size * 0.55,
        ),
      ),
    );
  }
}

/// White rounded card with a soft border and shadow.
class M3Card extends StatelessWidget {
  const M3Card({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.color = Colors.white,
    this.radius = 20,
    this.onTap,
    this.borderColor = AppColors.cardBorder,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color color;
  final double radius;
  final VoidCallback? onTap;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

enum M3ButtonStyle { soft, solid, outline, tint, momo }

/// Full-width pill button matching the Figma CTAs.
class M3Button extends StatelessWidget {
  const M3Button({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = M3ButtonStyle.soft,
    this.leading,
    this.trailing,
    this.loading = false,
    this.height = 52,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final M3ButtonStyle style;
  final IconData? leading;
  final IconData? trailing;
  final bool loading;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    final (
      Color fg,
      Color? bg,
      Gradient? gradient,
      Color? border,
    ) = switch (style) {
      M3ButtonStyle.soft => (Colors.white, null, AppColors.softGradient, null),
      M3ButtonStyle.solid => (Colors.white, AppColors.primary, null, null),
      M3ButtonStyle.momo => (Colors.white, AppColors.momo, null, null),
      M3ButtonStyle.outline => (
        AppColors.textPrimary,
        Colors.white,
        null,
        AppColors.cardBorder,
      ),
      M3ButtonStyle.tint => (AppColors.primary, AppColors.tint, null, null),
    };
    final content = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                Icon(leading, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: m3Text(15, weight: FontWeight.w700, color: fg),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Icon(trailing, size: 18, color: fg),
              ],
            ],
          );
    final radius = BorderRadius.circular(height / 2.6);
    return Opacity(
      opacity: disabled && !loading ? 0.55 : 1,
      child: SizedBox(
        width: expand ? double.infinity : null,
        height: height,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: bg,
              gradient: gradient,
              borderRadius: radius,
              border: border == null ? null : Border.all(color: border),
              boxShadow:
                  style == M3ButtonStyle.outline || style == M3ButtonStyle.tint
                  ? null
                  : [
                      BoxShadow(
                        color: (bg ?? AppColors.primaryLight).withValues(
                          alpha: 0.28,
                        ),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: InkWell(
              borderRadius: radius,
              onTap: disabled ? null : onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Center(child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small rounded status/label pill.
class M3Pill extends StatelessWidget {
  const M3Pill(
    this.label, {
    super.key,
    this.color = AppColors.primary,
    this.background,
    this.icon,
    this.dot = false,
    this.fontSize = 11,
  });

  final String label;
  final Color color;
  final Color? background;
  final IconData? icon;
  final bool dot;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: m3Text(fontSize, weight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter chip used in list headers ("Tất cả 4", "Đang in 3D 1", ...).
class M3FilterChip extends StatelessWidget {
  const M3FilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    this.dotColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null && !selected) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: m3Text(12, weight: FontWeight.w600, color: fg),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppColors.tint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: m3Text(
                    10.5,
                    weight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Card section header: optional icon, title, optional trailing widget.
class M3SectionHeader extends StatelessWidget {
  const M3SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
    this.size = 16,
  });

  final String title;
  final IconData? icon;
  final Widget? trailing;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: size + 2, color: AppColors.primary),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(title, style: m3Text(size, weight: FontWeight.w700)),
        ),
        ?trailing,
      ],
    );
  }
}

/// Label + filled input matching the Figma forms.
class M3Field extends StatelessWidget {
  const M3Field({
    super.key,
    this.label,
    this.controller,
    this.hint,
    this.prefixIcon,
    this.suffix,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.maxLength,
    this.maxLines = 1,
    this.labelTrailing,
    this.helper,
    this.enabled = true,
    this.onChanged,
    this.showCounter = false,
    this.filled = false,
  });

  final String? label;
  final TextEditingController? controller;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscure;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final int? maxLength;
  final int maxLines;
  final Widget? labelTrailing;
  final String? helper;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final bool showCounter;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null || labelTrailing != null || showCounter)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label ?? '',
                    style: m3Text(13, weight: FontWeight.w600),
                  ),
                ),
                if (showCounter && controller != null && maxLength != null)
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller!,
                    builder: (_, value, _) => Text(
                      '${value.text.length}/$maxLength',
                      style: m3Text(11.5, color: AppColors.textSecondary),
                    ),
                  ),
                ?labelTrailing,
              ],
            ),
          ),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          maxLength: maxLength,
          maxLines: maxLines,
          enabled: enabled,
          onChanged: onChanged,
          style: m3Text(14),
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            hintStyle: m3Text(14, color: AppColors.textMuted),
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, size: 19, color: const Color(0xFF4B5563)),
            suffixIcon: suffix,
            filled: true,
            fillColor: filled ? AppColors.fieldFill : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            enabledBorder: border(
              filled ? AppColors.fieldFill : AppColors.cardBorder,
            ),
            disabledBorder: border(AppColors.cardBorder),
            focusedBorder: border(AppColors.primary, 1.5),
            errorBorder: border(AppColors.error),
            focusedErrorBorder: border(AppColors.error, 1.5),
          ),
        ),
        if (helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              helper!,
              style: m3Text(11.5, color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }
}

/// "Label ......... value" row used in payment summaries.
class M3KeyValue extends StatelessWidget {
  const M3KeyValue(
    this.label,
    this.value, {
    super.key,
    this.valueColor = AppColors.textPrimary,
    this.bold = false,
    this.valueWidget,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool bold;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: m3Text(
                bold ? 14 : 13,
                weight: bold ? FontWeight.w700 : FontWeight.w500,
                color: bold ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                valueWidget ??
                Text(
                  value,
                  textAlign: TextAlign.right,
                  style: m3Text(
                    bold ? 18 : 13,
                    weight: bold ? FontWeight.w800 : FontWeight.w600,
                    color: valueColor,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

/// Square icon tile with tinted background.
class M3IconTile extends StatelessWidget {
  const M3IconTile(
    this.icon, {
    super.key,
    this.size = 44,
    this.color = AppColors.primary,
    this.background = AppColors.tint,
    this.radius = 14,
  });

  final IconData icon;
  final double size;
  final Color color;
  final Color background;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, color: color, size: size * 0.48),
    );
  }
}

/// Bottom navigation: Studio, Đơn hàng, (+), Keepsakes, Giỏ hàng.
class M3BottomNav extends StatelessWidget {
  const M3BottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.onCreate,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onCreate;

  static const items = [
    (Icons.view_in_ar_outlined, 'Studio'),
    (Icons.receipt_long_outlined, 'Đơn hàng'),
    (Icons.favorite_border_rounded, 'Keepsakes'),
    (Icons.shopping_cart_outlined, 'Giỏ hàng'),
  ];

  @override
  Widget build(BuildContext context) {
    Widget item(int index) {
      final (icon, label) = items[index];
      final selected = index == currentIndex;
      final color = selected ? AppColors.primary : AppColors.textSecondary;
      return Expanded(
        child: InkWell(
          onTap: () => onSelect(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.tint : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 21, color: color),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: m3Text(
                  10.5,
                  weight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.cardBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              item(0),
              item(1),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: onCreate,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.softGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryLight.withValues(
                              alpha: 0.45,
                            ),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
              item(2),
              item(3),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple "Memento3D" header used on the tab screens.
class M3BrandHeader extends StatelessWidget {
  const M3BrandHeader({
    super.key,
    this.subtitle,
    this.actions = const [],
    this.showLogo = false,
  });

  final String? subtitle;
  final List<Widget> actions;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 14, 10),
          child: Row(
            children: [
              if (showLogo) ...[
                const M3IconTile(Icons.view_in_ar_rounded, size: 36),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Memento3D',
                      style: m3Text(18, weight: FontWeight.w700),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: m3Text(11.5, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

/// Round icon button with a light border (e.g. notification bell).
class M3CircleIconButton extends StatelessWidget {
  const M3CircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.badge = false,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool badge;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: filled ? AppColors.tint : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Icon(icon, size: 18, color: AppColors.textPrimary),
          ),
          if (badge)
            Positioned(
              right: 7,
              top: 6,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String m3Money(num value) {
  final digits = value.round().abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '${value < 0 ? '-' : ''}$buffer ₫';
}

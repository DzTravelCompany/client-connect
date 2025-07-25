import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'design_tokens.dart';
import 'component_styles.dart';
import 'accessibility_utils.dart';

/// Comprehensive component library implementing the design system
class DesignSystemComponents {
  DesignSystemComponents._();
  
  // =============================================================================
  // ENHANCED BUTTONS
  // =============================================================================
  
  /// Primary action button with enhanced styling and accessibility
  static Widget primaryButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    String? tooltip,
    String? semanticLabel,
    FocusNode? focusNode,
  }) {
    return AccessibilityUtils.createFocusableWidget(
      onPressed: onPressed,
      semanticLabel: semanticLabel ?? text,
      tooltip: tooltip,
      focusNode: focusNode,
      child: AnimatedContainer(
        duration: DesignTokens.animationNormal,
        child: FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: ComponentStyles.primaryButton,
          child: isLoading
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: DesignTokens.iconSizeSmall,
                      height: DesignTokens.iconSizeSmall,
                      child: const ProgressRing(strokeWidth: 2),
                    ),
                    const SizedBox(width: DesignTokens.space2),
                    Text(text),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: DesignTokens.iconSizeSmall),
                      const SizedBox(width: DesignTokens.space2),
                    ],
                    Text(text),
                  ],
                ),
        ),
      ),
    );
  }
  
  /// Secondary button with enhanced styling
  static Widget secondaryButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    String? tooltip,
    String? semanticLabel,
    FocusNode? focusNode,
  }) {
    return AccessibilityUtils.createFocusableWidget(
      onPressed: onPressed,
      semanticLabel: semanticLabel ?? text,
      tooltip: tooltip,
      focusNode: focusNode,
      child: Button(
        onPressed: isLoading ? null : onPressed,
        style: ComponentStyles.secondaryButton,
        child: isLoading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: DesignTokens.iconSizeSmall,
                    height: DesignTokens.iconSizeSmall,
                    child: const ProgressRing(strokeWidth: 2),
                  ),
                  const SizedBox(width: DesignTokens.space2),
                  Text(text),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: DesignTokens.iconSizeSmall),
                    const SizedBox(width: DesignTokens.space2),
                  ],
                  Text(text),
                ],
              ),
      ),
    );
  }
  
  /// Danger button for destructive actions
  static Widget dangerButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    bool requireConfirmation = true,
    String? confirmationTitle,
    String? confirmationMessage,
    String? tooltip,
    String? semanticLabel,
    FocusNode? focusNode,
  }) {
    return AccessibilityUtils.createFocusableWidget(
      onPressed: onPressed,
      semanticLabel: semanticLabel ?? text,
      tooltip: tooltip,
      focusNode: focusNode,
      child: Button(
        onPressed: isLoading ? null : () async {
          if (requireConfirmation && onPressed != null) {
            final shouldProceed = await _showConfirmationDialog(
              title: confirmationTitle ?? 'Confirm Action',
              message: confirmationMessage ?? 'Are you sure you want to proceed?',
            );
            if (shouldProceed == true) {
              onPressed();
            }
          } else {
            onPressed?.call();
          }
        },
        style: ComponentStyles.dangerButton,
        child: isLoading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: DesignTokens.iconSizeSmall,
                    height: DesignTokens.iconSizeSmall,
                    child: const ProgressRing(strokeWidth: 2),
                  ),
                  const SizedBox(width: DesignTokens.space2),
                  Text(text),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: DesignTokens.iconSizeSmall),
                    const SizedBox(width: DesignTokens.space2),
                  ],
                  Text(text),
                ],
              ),
      ),
    );
  }
  
  // =============================================================================
  // ENHANCED CARDS
  // =============================================================================
  
  /// Standard card with enhanced styling and interaction
  static Widget standardCard({
    required Widget child,
    VoidCallback? onTap,
    bool isSelected = false,
    bool isHoverable = true,
    EdgeInsetsGeometry? padding,
    String? semanticLabel,
    String? tooltip,
  }) {
    return AccessibilityUtils.createFocusableWidget(
      onPressed: onTap,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      child: AnimatedContainer(
        duration: DesignTokens.animationNormal,
        decoration: ComponentStyles.getInteractiveCard(
          isSelected: isSelected,
          isHovered: false, // Will be handled by HoverButton
        ),
        child: onTap != null
            ? HoverButton(
                onPressed: onTap,
                builder: (context, states) {
                  return Container(
                    padding: padding ?? const EdgeInsets.all(DesignTokens.cardPadding),
                    decoration: ComponentStyles.getInteractiveCard(
                      isSelected: isSelected,
                      isHovered: states.contains(WidgetState.hovered),
                    ),
                    child: child,
                  );
                },
              )
            : Container(
                padding: padding ?? const EdgeInsets.all(DesignTokens.cardPadding),
                child: child,
              ),
      ),
    );
  }
  
  /// Glassmorphism card with enhanced visual effects
  static Widget glassmorphismCard({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
    String? semanticLabel,
    String? tooltip,
  }) {
    return AccessibilityUtils.createFocusableWidget(
      onPressed: onTap,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      child: Container(
        decoration: ComponentStyles.glassmorphismCard,
        child: onTap != null
            ? HoverButton(
                onPressed: onTap,
                builder: (context, states) {
                  return Container(
                    padding: padding ?? const EdgeInsets.all(DesignTokens.cardPadding),
                    child: child,
                  );
                },
              )
            : Container(
                padding: padding ?? const EdgeInsets.all(DesignTokens.cardPadding),
                child: child,
              ),
      ),
    );
  }
  
  // =============================================================================
  // STATUS INDICATORS
  // =============================================================================
  
  /// Status badge with semantic colors
  static Widget statusBadge({
    required String text,
    required SemanticColorType type,
    IconData? icon,
    String? semanticLabel,
  }) {
    final color = DesignTokens.getSemanticColor(type);
    
    return Semantics(
      label: semanticLabel ?? AccessibilityUtils.getStatusSemanticLabel(type, text),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space3,
          vertical: DesignTokens.space1,
        ),
        decoration: ComponentStyles.getStatusBadge(type),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: DesignTokens.iconSizeSmall, color: color),
              const SizedBox(width: DesignTokens.space1),
            ],
            Text(
              text,
              style: DesignTextStyles.caption.copyWith(
                color: color,
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Status dot indicator
  static Widget statusDot({
    required SemanticColorType type,
    double size = 8.0,
    String? semanticLabel,
  }) {
    return Semantics(
      label: semanticLabel ?? AccessibilityUtils.getStatusSemanticLabel(type, ''),
      child: Container(
        width: size,
        height: size,
        decoration: ComponentStyles.getStatusDot(type),
      ),
    );
  }
  
  // =============================================================================
  // ENHANCED INPUT FIELDS
  // =============================================================================
  
  /// Enhanced text input with validation and accessibility
  static Widget textInput({
    required TextEditingController controller,
    String? label,
    String? placeholder,
    String? helperText,
    String? errorText,
    IconData? prefixIcon,
    IconData? suffixIcon,
    VoidCallback? onSuffixIconPressed,
    bool obscureText = false,
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    void Function()? onTap,
    FocusNode? focusNode,
    String? semanticLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label,
            style: DesignTextStyles.body.copyWith(
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
          const SizedBox(height: DesignTokens.space1),
        ],
        
        Semantics(
          label: semanticLabel ?? label,
          textField: true,
          child: TextFormBox(
            controller: controller,
            placeholder: placeholder,
            obscureText: obscureText,
            enabled: enabled,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            onChanged: onChanged,
            onTap: onTap,
            focusNode: focusNode,
            prefix: prefixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Icon(prefixIcon, size: DesignTokens.iconSizeSmall),
                )
              : null,
            suffix: suffixIcon != null
              ? IconButton(
                  icon: Icon(suffixIcon, size: DesignTokens.iconSizeSmall),
                  onPressed: onSuffixIconPressed,
                )
              : null,
          ),
        ),
        
        if (helperText != null || errorText != null) ...[
          const SizedBox(height: DesignTokens.space1),
          Text(
            errorText ?? helperText!,
            style: DesignTextStyles.caption.copyWith(
              color: errorText != null
                  ? DesignTokens.semanticError
                  : DesignTokens.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
  
  // =============================================================================
  // NAVIGATION COMPONENTS
  // =============================================================================
  
  /// Enhanced navigation item with accessibility
  static Widget navigationItem({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
    bool hasSubItems = false,
    String? badge,
    String? tooltip,
  }) {
    return AccessibilityUtils.createFocusableWidget(
      onPressed: onPressed,
      semanticLabel: AccessibilityUtils.getNavigationSemanticLabel(
        label: label,
        isActive: isActive,
        hasSubItems: hasSubItems,
      ),
      tooltip: tooltip,
      child: AnimatedContainer(
        duration: DesignTokens.animationNormal,
        margin: const EdgeInsets.symmetric(vertical: DesignTokens.space1),
        decoration: ComponentStyles.getNavigationItem(isActive: isActive),
        child: HoverButton(
          onPressed: onPressed,
          builder: (context, states) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space4,
                vertical: DesignTokens.space3,
              ),
              decoration: ComponentStyles.getNavigationItem(
                isActive: isActive,
                isHovered: states.contains(WidgetState.hovered),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: DesignTokens.iconSizeMedium,
                    color: isActive
                        ? DesignTokens.accentPrimary
                        : DesignTokens.textSecondary,
                  ),
                  const SizedBox(width: DesignTokens.space3),
                  Expanded(
                    child: Text(
                      label,
                      style: DesignTextStyles.body.copyWith(
                        color: isActive
                            ? DesignTokens.accentPrimary
                            : DesignTokens.textPrimary,
                        fontWeight: isActive
                            ? DesignTokens.fontWeightSemiBold
                            : DesignTokens.fontWeightRegular,
                      ),
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: DesignTokens.space2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.space2,
                        vertical: DesignTokens.space1,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.accentPrimary,
                        borderRadius: BorderRadius.circular(DesignTokens.radiusRound),
                      ),
                      child: Text(
                        badge,
                        style: DesignTextStyles.caption.copyWith(
                          color: DesignTokens.textInverse,
                          fontWeight: DesignTokens.fontWeightBold,
                        ),
                      ),
                    ),
                  ],
                  if (hasSubItems) ...[
                    const SizedBox(width: DesignTokens.space2),
                    Icon(
                      FluentIcons.chevron_right,
                      size: DesignTokens.iconSizeSmall,
                      color: DesignTokens.textTertiary,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  // =============================================================================
  // LOADING STATES
  // =============================================================================
  
  /// Enhanced loading indicator with message
  static Widget loadingIndicator({
    String? message,
    double size = 32.0,
    Color? color,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: ProgressRing(
              strokeWidth: size * 0.1,
            ),
          ),
          if (message != null) ...[
            SizedBox(height: DesignTokens.space4),
            Text(
              message,
              style: DesignTextStyles.body.copyWith(
                color: color ?? DesignTokens.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
  
  /// Skeleton loader for content placeholders
  static Widget skeletonLoader({
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height ?? 16,
      decoration: BoxDecoration(
        color: DesignTokens.neutralGray200,
        borderRadius: borderRadius ?? BorderRadius.circular(DesignTokens.radiusSmall),
      ),
      child: const _ShimmerEffect(),
    );
  }
  
  // =============================================================================
  // EMPTY STATES
  // =============================================================================
  
  /// Enhanced empty state with action
  static Widget emptyState({
    required String title,
    required String message,
    required IconData icon,
    String? actionText,
    VoidCallback? onAction,
    Color? iconColor,
  }) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.space8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: (iconColor ?? DesignTokens.textTertiary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusXLarge),
              ),
              child: Icon(
                icon,
                size: 40,
                color: iconColor ?? DesignTokens.textTertiary,
              ),
            ),
            SizedBox(height: DesignTokens.space6),
            Text(
              title,
              style: DesignTextStyles.subtitle.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DesignTokens.space2),
            Text(
              message,
              style: DesignTextStyles.body.copyWith(
                color: DesignTokens.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              SizedBox(height: DesignTokens.space6),
              primaryButton(
                text: actionText,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  // =============================================================================
  // HELPER METHODS
  // =============================================================================
  
  static Future<bool?> _showConfirmationDialog({
    required String title,
    required String message,
  }) async {
    // This would need to be implemented with proper context
    // For now, return true as a placeholder
    return true;
  }
}

/// Shimmer effect for skeleton loaders
class _ShimmerEffect extends StatefulWidget {
  const _ShimmerEffect();

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
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
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
              colors: [
                DesignTokens.neutralGray200,
                DesignTokens.neutralGray100,
                DesignTokens.neutralGray200,
              ],
            ),
          ),
        );
      },
    );
  }
}

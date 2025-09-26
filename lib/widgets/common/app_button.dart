import 'package:flutter/material.dart';
import '../../core/constants.dart';

enum AppButtonType {
  primary,
  secondary,
  outline,
  text,
}

enum AppButtonSize {
  small,
  medium,
  large,
}

/// Reusable button component with consistent styling
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle();
    final padding = _getPadding();
    final textStyle = _getTextStyle();

    Widget buttonChild = _buildButtonContent(textStyle);

    if (isFullWidth) {
      buttonChild = SizedBox(
        width: double.infinity,
        height: _getButtonHeight(),
        child: buttonChild,
      );
    }

    if (icon != null && !isLoading) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: _getIconSize()),
        label: _buildButtonContent(textStyle),
        style: buttonStyle.copyWith(
          padding: WidgetStateProperty.all(padding),
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: onPressed,
        style: buttonStyle.copyWith(
          padding: WidgetStateProperty.all(padding),
        ),
        child: buttonChild,
      );
    }
  }

  Widget _buildButtonContent(TextStyle textStyle) {
    if (isLoading) {
      return SizedBox(
        height: _getIconSize(),
        width: _getIconSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            type == AppButtonType.outline || type == AppButtonType.text
                ? AppConstants.primaryBlue
                : Colors.white,
          ),
        ),
      );
    }

    return Text(text, style: textStyle);
  }

  ButtonStyle _getButtonStyle() {
    switch (type) {
      case AppButtonType.primary:
        return AppTheme.primaryButtonStyle;
      case AppButtonType.secondary:
        return AppTheme.secondaryButtonStyle;
      case AppButtonType.outline:
        return OutlinedButton.styleFrom(
          foregroundColor: AppConstants.primaryBlue,
          side: const BorderSide(color: AppConstants.primaryBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          ),
        );
      case AppButtonType.text:
        return TextButton.styleFrom(
          foregroundColor: AppConstants.primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          ),
        );
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMedium,
          vertical: AppConstants.spacingSmall,
        );
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingLarge,
          vertical: AppConstants.spacingMedium,
        );
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingXLarge,
          vertical: AppConstants.spacingLarge,
        );
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppButtonSize.small:
        return AppTheme.bodySmall.copyWith(fontWeight: FontWeight.bold);
      case AppButtonSize.medium:
        return AppTheme.buttonText;
      case AppButtonSize.large:
        return AppTheme.buttonText.copyWith(
          fontSize: AppConstants.fontSizeLarge,
        );
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return AppConstants.iconSizeSmall;
      case AppButtonSize.medium:
        return AppConstants.iconSizeMedium;
      case AppButtonSize.large:
        return AppConstants.iconSizeLarge;
    }
  }

  double _getButtonHeight() {
    switch (size) {
      case AppButtonSize.small:
        return 36.0;
      case AppButtonSize.medium:
        return AppConstants.buttonHeight;
      case AppButtonSize.large:
        return 56.0;
    }
  }
}

/// Convenience constructors for common button types
class AppPrimaryButton extends AppButton {
  const AppPrimaryButton({
    super.key,
    required super.text,
    required super.onPressed,
    super.size,
    super.icon,
    super.isLoading,
    super.isFullWidth,
  }) : super(type: AppButtonType.primary);
}

class AppSecondaryButton extends AppButton {
  const AppSecondaryButton({
    super.key,
    required super.text,
    required super.onPressed,
    super.size,
    super.icon,
    super.isLoading,
    super.isFullWidth,
  }) : super(type: AppButtonType.secondary);
}

class AppOutlineButton extends AppButton {
  const AppOutlineButton({
    super.key,
    required super.text,
    required super.onPressed,
    super.size,
    super.icon,
    super.isLoading,
    super.isFullWidth,
  }) : super(type: AppButtonType.outline);
}

class AppTextButton extends AppButton {
  const AppTextButton({
    super.key,
    required super.text,
    required super.onPressed,
    super.size,
    super.icon,
    super.isLoading,
    super.isFullWidth,
  }) : super(type: AppButtonType.text);
}


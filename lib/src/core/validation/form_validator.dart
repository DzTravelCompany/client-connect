import 'package:fluent_ui/fluent_ui.dart';
import 'validators.dart';

/// Form field validation state
class FieldValidationState {
  final bool isValid;
  final String? errorMessage;
  final bool hasBeenValidated;

  const FieldValidationState({
    this.isValid = true,
    this.errorMessage,
    this.hasBeenValidated = false,
  });

  FieldValidationState copyWith({
    bool? isValid,
    String? errorMessage,
    bool? hasBeenValidated,
  }) {
    return FieldValidationState(
      isValid: isValid ?? this.isValid,
      errorMessage: errorMessage,
      hasBeenValidated: hasBeenValidated ?? this.hasBeenValidated,
    );
  }
}

/// Form validator that manages multiple field validations
class FormValidator extends ChangeNotifier {
  final Map<String, Validator> _validators = {};
  final Map<String, FieldValidationState> _fieldStates = {};
  final Map<String, dynamic> _values = {};

  /// Add a validator for a field
  void addValidator(String fieldName, Validator validator) {
    _validators[fieldName] = validator;
    _fieldStates[fieldName] = const FieldValidationState();
  }

  /// Set the value for a field and optionally validate
  void setValue(String fieldName, dynamic value, {bool validate = false}) {
    _values[fieldName] = value;
    
    if (validate) {
      validateField(fieldName);
    }
    
    notifyListeners();
  }

  /// Get the current value for a field
  T? getValue<T>(String fieldName) => _values[fieldName] as T?;

  /// Validate a specific field
  bool validateField(String fieldName) {
    final validator = _validators[fieldName];
    if (validator == null) return true;

    final value = _values[fieldName];
    final result = validator.validate(value);

    _fieldStates[fieldName] = FieldValidationState(
      isValid: result.isValid,
      errorMessage: result.errorMessage,
      hasBeenValidated: true,
    );

    notifyListeners();
    return result.isValid;
  }

  /// Validate all fields
  bool validateAll() {
    bool allValid = true;
    
    for (final fieldName in _validators.keys) {
      final isFieldValid = validateField(fieldName);
      if (!isFieldValid) {
        allValid = false;
      }
    }
    
    return allValid;
  }

  /// Get validation state for a field
  FieldValidationState getFieldState(String fieldName) {
    return _fieldStates[fieldName] ?? const FieldValidationState();
  }

  /// Check if the form is valid (all fields that have been validated are valid)
  bool get isValid {
    return _fieldStates.values
        .where((state) => state.hasBeenValidated)
        .every((state) => state.isValid);
  }

  /// Get all validation errors
  Map<String, String> get errors {
    final errors = <String, String>{};
    
    for (final entry in _fieldStates.entries) {
      if (!entry.value.isValid && entry.value.errorMessage != null) {
        errors[entry.key] = entry.value.errorMessage!;
      }
    }
    
    return errors;
  }

  /// Clear validation state for a field
  void clearFieldValidation(String fieldName) {
    _fieldStates[fieldName] = const FieldValidationState();
    notifyListeners();
  }

  /// Clear all validation states
  void clearAllValidation() {
    for (final fieldName in _fieldStates.keys) {
      _fieldStates[fieldName] = const FieldValidationState();
    }
    notifyListeners();
  }

  /// Reset the form (clear values and validation states)
  void reset() {
    _values.clear();
    _fieldStates.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _validators.clear();
    _fieldStates.clear();
    _values.clear();
    super.dispose();
  }
}

/// Validated TextBox widget that integrates with FormValidator
class ValidatedTextBox extends StatelessWidget {
  final String fieldName;
  final FormValidator formValidator;
  final String? placeholder;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefix;
  final Widget? suffix;
  final bool enabled;
  final int? maxLines;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final void Function()? onEditingComplete;

  const ValidatedTextBox({
    super.key,
    required this.fieldName,
    required this.formValidator,
    this.placeholder,
    this.obscureText = false,
    this.keyboardType,
    this.prefix,
    this.suffix,
    this.enabled = true,
    this.maxLines = 1,
    this.controller,
    this.onChanged,
    this.onEditingComplete,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: formValidator,
      builder: (context, child) {
        final fieldState = formValidator.getFieldState(fieldName);
        final currentValue = formValidator.getValue<String>(fieldName) ?? '';
        
        // Update controller if provided and value changed
        if (controller != null && controller!.text != currentValue) {
          controller!.text = currentValue;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextBox(
              controller: controller,
              placeholder: placeholder,
              obscureText: obscureText,
              keyboardType: keyboardType,
              prefix: prefix,
              suffix: suffix,
              enabled: enabled,
              maxLines: maxLines,
              onChanged: (value) {
                formValidator.setValue(fieldName, value);
                onChanged?.call(value);
              },
              onEditingComplete: () {
                formValidator.validateField(fieldName);
                onEditingComplete?.call();
              },
            ),
            if (fieldState.hasBeenValidated && !fieldState.isValid)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  fieldState.errorMessage ?? '',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

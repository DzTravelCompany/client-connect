abstract class Validator<T> {
  ValidationResult validate(T? value);
}

/// Validation result
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult.valid() : isValid = true, errorMessage = null;
  const ValidationResult.invalid(this.errorMessage) : isValid = false;

  @override
  String toString() => isValid ? 'Valid' : 'Invalid: $errorMessage';
}

/// Composite validator that combines multiple validators
class CompositeValidator<T> implements Validator<T> {
  final List<Validator<T>> validators;

  CompositeValidator(this.validators);

  @override
  ValidationResult validate(T? value) {
    for (final validator in validators) {
      final result = validator.validate(value);
      if (!result.isValid) {
        return result;
      }
    }
    return const ValidationResult.valid();
  }
}

/// String validators
class RequiredValidator implements Validator<String> {
  final String fieldName;

  RequiredValidator(this.fieldName);

  @override
  ValidationResult validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.invalid('$fieldName is required');
    }
    return const ValidationResult.valid();
  }
}

class EmailValidator implements Validator<String> {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  ValidationResult validate(String? value) {
    if (value == null || value.isEmpty) {
      return const ValidationResult.valid(); // Optional field
    }
    
    if (!_emailRegex.hasMatch(value)) {
      return const ValidationResult.invalid('Please enter a valid email address');
    }
    return const ValidationResult.valid();
  }
}

class PhoneValidator implements Validator<String> {
  static final RegExp _phoneRegex = RegExp(r'^\+?[\d\s\-$$$$]{10,}$');

  @override
  ValidationResult validate(String? value) {
    if (value == null || value.isEmpty) {
      return const ValidationResult.valid(); // Optional field
    }
    
    if (!_phoneRegex.hasMatch(value)) {
      return const ValidationResult.invalid('Please enter a valid phone number');
    }
    return const ValidationResult.valid();
  }
}

class LengthValidator implements Validator<String> {
  final int? minLength;
  final int? maxLength;
  final String fieldName;

  LengthValidator({
    required this.fieldName,
    this.minLength,
    this.maxLength,
  });

  @override
  ValidationResult validate(String? value) {
    if (value == null) {
      return const ValidationResult.valid();
    }

    if (minLength != null && value.length < minLength!) {
      return ValidationResult.invalid(
        '$fieldName must be at least $minLength characters long',
      );
    }

    if (maxLength != null && value.length > maxLength!) {
      return ValidationResult.invalid(
        '$fieldName must be no more than $maxLength characters long',
      );
    }

    return const ValidationResult.valid();
  }
}

class PatternValidator implements Validator<String> {
  final RegExp pattern;
  final String errorMessage;

  PatternValidator({
    required this.pattern,
    required this.errorMessage,
  });

  @override
  ValidationResult validate(String? value) {
    if (value == null || value.isEmpty) {
      return const ValidationResult.valid(); // Optional field
    }

    if (!pattern.hasMatch(value)) {
      return ValidationResult.invalid(errorMessage);
    }
    return const ValidationResult.valid();
  }
}

/// Numeric validators
class RangeValidator implements Validator<num> {
  final num? min;
  final num? max;
  final String fieldName;

  RangeValidator({
    required this.fieldName,
    this.min,
    this.max,
  });

  @override
  ValidationResult validate(num? value) {
    if (value == null) {
      return const ValidationResult.valid();
    }

    if (min != null && value < min!) {
      return ValidationResult.invalid('$fieldName must be at least $min');
    }

    if (max != null && value > max!) {
      return ValidationResult.invalid('$fieldName must be no more than $max');
    }

    return const ValidationResult.valid();
  }
}

/// Date validators
class DateRangeValidator implements Validator<DateTime> {
  final DateTime? minDate;
  final DateTime? maxDate;
  final String fieldName;

  DateRangeValidator({
    required this.fieldName,
    this.minDate,
    this.maxDate,
  });

  @override
  ValidationResult validate(DateTime? value) {
    if (value == null) {
      return const ValidationResult.valid();
    }

    if (minDate != null && value.isBefore(minDate!)) {
      return ValidationResult.invalid(
        '$fieldName cannot be before ${_formatDate(minDate!)}',
      );
    }

    if (maxDate != null && value.isAfter(maxDate!)) {
      return ValidationResult.invalid(
        '$fieldName cannot be after ${_formatDate(maxDate!)}',
      );
    }

    return const ValidationResult.valid();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Convenience class for common validation scenarios
class Validators {
  /// Email validation (optional)
  static Validator<String> email() => EmailValidator();

  /// Required email validation
  static Validator<String> requiredEmail() => CompositeValidator([
    RequiredValidator('Email'),
    EmailValidator(),
  ]);

  /// Phone validation (optional)
  static Validator<String> phone() => PhoneValidator();

  /// Required field validation
  static Validator<String> required(String fieldName) => RequiredValidator(fieldName);

  /// Name validation (required, 2-50 characters)
  static Validator<String> name(String fieldName) => CompositeValidator([
    RequiredValidator(fieldName),
    LengthValidator(fieldName: fieldName, minLength: 2, maxLength: 50),
  ]);

  /// Company name validation (optional, max 100 characters)
  static Validator<String> companyName() => LengthValidator(
    fieldName: 'Company name',
    maxLength: 100,
  );

  /// Campaign name validation (required, 3-100 characters)
  static Validator<String> campaignName() => CompositeValidator([
    RequiredValidator('Campaign name'),
    LengthValidator(fieldName: 'Campaign name', minLength: 3, maxLength: 100),
  ]);

  /// Template name validation (required, 3-50 characters)
  static Validator<String> templateName() => CompositeValidator([
    RequiredValidator('Template name'),
    LengthValidator(fieldName: 'Template name', minLength: 3, maxLength: 50),
  ]);

  /// Future date validation (must be in the future)
  static Validator<DateTime> futureDate(String fieldName) => DateRangeValidator(
    fieldName: fieldName,
    minDate: DateTime.now(),
  );
}

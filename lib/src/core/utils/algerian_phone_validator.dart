class AlgerianPhoneValidator {
  // Algerian mobile prefixes (without country code)
  static const List<String> _validPrefixes = [
    '55', '56', '57', '58', '59', // Mobilis
    '66', '67', '68', '69',       // Ooredoo
    '77', '78', '79',             // Djezzy
  ];

  static const String _countryCode = '213';
  static const int _expectedLength = 12; // 213 + 9 digits

  /// Validates and formats an Algerian phone number to WhatsApp format (213xxxxxxxxx)
  static PhoneValidationResult validateAndFormat(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      return PhoneValidationResult.invalid('Phone number is required');
    }

    // Clean the phone number (remove spaces, dashes, parentheses)
    String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-$$$$]'), '');

    // Handle different input formats
    String formatted = _formatPhoneNumber(cleaned);
    
    if (formatted.isEmpty) {
      return PhoneValidationResult.invalid('Invalid phone number format');
    }

    // Validate the formatted number
    if (!_isValidAlgerianNumber(formatted)) {
      return PhoneValidationResult.invalid('Invalid Algerian phone number');
    }

    return PhoneValidationResult.valid(formatted);
  }

  /// Formats phone number from various input formats to 213xxxxxxxxx
  static String _formatPhoneNumber(String cleaned) {
    // Remove any leading zeros or plus signs
    cleaned = cleaned.replaceAll(RegExp(r'^[+0]+'), '');

    // Case 1: Already in correct format (213xxxxxxxxx)
    if (cleaned.startsWith(_countryCode) && cleaned.length == _expectedLength) {
      return cleaned;
    }

    // Case 2: Starts with 213 but wrong length
    if (cleaned.startsWith(_countryCode)) {
      String withoutCountryCode = cleaned.substring(3);
      if (withoutCountryCode.length == 9) {
        return _countryCode + withoutCountryCode;
      }
      return ''; // Invalid length
    }

    // Case 3: Local format (xxxxxxxxx) - 9 digits
    if (cleaned.length == 9) {
      return _countryCode + cleaned;
    }

    // Case 4: Local format with leading zero (0xxxxxxxxx) - 10 digits
    if (cleaned.length == 10 && cleaned.startsWith('0')) {
      return _countryCode + cleaned.substring(1);
    }

    // Invalid format
    return '';
  }

  /// Validates if the formatted number is a valid Algerian mobile number
  static bool _isValidAlgerianNumber(String formattedNumber) {
    if (formattedNumber.length != _expectedLength) {
      return false;
    }

    if (!formattedNumber.startsWith(_countryCode)) {
      return false;
    }

    // Extract the mobile number part (without country code)
    String mobileNumber = formattedNumber.substring(3);
    
    // Check if it's 9 digits
    if (mobileNumber.length != 9) {
      return false;
    }

    // Check if all characters are digits
    if (!RegExp(r'^\d+$').hasMatch(mobileNumber)) {
      return false;
    }

    // Check if it starts with a valid prefix
    String prefix = mobileNumber.substring(0, 2);
    return _validPrefixes.contains(prefix);
  }

  /// Gets user-friendly error message for common formatting issues
  static String getFormattingHint(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      return 'Please enter a phone number';
    }

    String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-$$$$]'), '');
    cleaned = cleaned.replaceAll(RegExp(r'^[+0]+'), '');

    if (cleaned.length < 9) {
      return 'Phone number is too short. Expected format: 0554125478 or +213554125478';
    }

    if (cleaned.length > 12) {
      return 'Phone number is too long. Expected format: 0554125478 or +213554125478';
    }

    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'Phone number should contain only digits';
    }

    // Check prefix if we can extract it
    String testNumber = _formatPhoneNumber(cleaned);
    if (testNumber.isNotEmpty) {
      String mobileNumber = testNumber.substring(3);
      String prefix = mobileNumber.substring(0, 2);
      if (!_validPrefixes.contains(prefix)) {
        return 'Invalid Algerian mobile prefix. Valid prefixes: ${_validPrefixes.join(', ')}';
      }
    }

    return 'Invalid phone number format. Expected: 0554125478 or +213554125478';
  }

  /// Checks if a phone number is likely Algerian based on format
  static bool isAlgerianNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      return false;
    }

    String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-$$$$]'), '');
    
    // Check for Algerian country code
    if (cleaned.startsWith('+213') || cleaned.startsWith('213')) {
      return true;
    }

    // Check for local format starting with 0
    if (cleaned.startsWith('0') && cleaned.length == 10) {
      String withoutZero = cleaned.substring(1);
      String prefix = withoutZero.substring(0, 2);
      return _validPrefixes.contains(prefix);
    }

    // Check for local format without 0
    if (cleaned.length == 9) {
      String prefix = cleaned.substring(0, 2);
      return _validPrefixes.contains(prefix);
    }

    return false;
  }
}

class PhoneValidationResult {
  final bool isValid;
  final String? formattedNumber;
  final String? errorMessage;

  const PhoneValidationResult._({
    required this.isValid,
    this.formattedNumber,
    this.errorMessage,
  });

  factory PhoneValidationResult.valid(String formattedNumber) {
    return PhoneValidationResult._(
      isValid: true,
      formattedNumber: formattedNumber,
    );
  }

  factory PhoneValidationResult.invalid(String errorMessage) {
    return PhoneValidationResult._(
      isValid: false,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    return isValid 
        ? 'Valid: $formattedNumber'
        : 'Invalid: $errorMessage';
  }
}
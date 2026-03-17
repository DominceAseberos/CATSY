/// Input validation helpers used across forms.
class Validators {
  Validators._();

  static String? required(String? value, [String fieldName = 'Field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final regex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$');
    if (!regex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final regex = RegExp(r'^\+?[\d\s\-]{10,15}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? minLength(String? value, int min) {
    if (value == null || value.length < min) {
      return 'Must be at least $min characters';
    }
    return null;
  }

  static String? number(String? value) {
    if (value == null || value.trim().isEmpty) return 'Value is required';
    if (double.tryParse(value) == null) return 'Enter a valid number';
    return null;
  }

  static String? positiveNumber(String? value) {
    final numError = number(value);
    if (numError != null) return numError;
    if (double.parse(value!) <= 0) return 'Must be greater than zero';
    return null;
  }

  static String? pin(String? value) {
    if (value == null || value.trim().isEmpty) return 'PIN is required';
    if (value.length != 4) return 'PIN must be 4 digits';
    if (int.tryParse(value) == null) return 'PIN must contain only digits';
    return null;
  }
}

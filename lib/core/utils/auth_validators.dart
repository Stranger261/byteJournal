class AuthValidators {
  AuthValidators._();

  static const int minPasswordLength = 8;
  // for email
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  // for password
  static final RegExp _hasDigit = RegExp(r'\d');
  static final RegExp _hasUpperCaseLetter = RegExp(r'[A-Z]');
  static final RegExp _hasLowerCaseLetter = RegExp(r'[a-z]');
  static final RegExp _hasSpecialCharacter = RegExp(r'[@$!%*?&]');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return 'Email is Required.';
    }
    if (!_emailPattern.hasMatch(v)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static PasswordValidation passwordRequirements(String? value) {
    final v = value ?? '';

    return PasswordValidation(
      minLength: v.length >= minPasswordLength,
      hasNumber: _hasDigit.hasMatch(v),
      hasUppercase: _hasUpperCaseLetter.hasMatch(v),
      hasLowercase: _hasLowerCaseLetter.hasMatch(v),
      hasSpecialCharacter: _hasSpecialCharacter.hasMatch(v),
    );
  }

  static String? password(String? value, {required bool isLogin}) {
    final v = value ?? '';

    if (v.isEmpty) {
      return 'Password is required.';
    }

    if (isLogin) {
      return null;
    }

    final validation = passwordRequirements(v);

    return validation.isValid
        ? null
        : 'Password does not meet the requirements.';
  }
}

class PasswordValidation {
  final bool minLength;
  final bool hasNumber;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasSpecialCharacter;

  const PasswordValidation({
    required this.minLength,
    required this.hasNumber,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasSpecialCharacter,
  });

  bool get isValid =>
      minLength &&
      hasNumber &&
      hasUppercase &&
      hasLowercase &&
      hasSpecialCharacter;
}

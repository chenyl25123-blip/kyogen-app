class PhoneNumberFormatException implements Exception {
  final String code;
  final String message;

  const PhoneNumberFormatException(this.code, this.message);

  @override
  String toString() => 'PhoneNumberFormatException($code): $message';
}

String normalizeJapanMobileNumber(String? input) {
  final value = input?.trim() ?? '';
  if (value.isEmpty) {
    throw const PhoneNumberFormatException(
      'phone/empty',
      'Phone number is empty.',
    );
  }

  final normalized = value
      .replaceAll(RegExp(r'[\s\-()]+'), '')
      .replaceAll('ー', '')
      .replaceAll('−', '')
      .replaceAll('－', '');

  if (!RegExp(r'^\+?\d+$').hasMatch(normalized)) {
    throw const PhoneNumberFormatException(
      'phone/invalid-characters',
      'Phone number contains unsupported characters.',
    );
  }

  if (normalized.startsWith('+81')) {
    final local = '0${normalized.substring(3)}';
    _validateJapanMobileDigits(local);
    return local;
  }

  _validateJapanMobileDigits(normalized);
  return normalized;
}

String toE164JapanPhoneNumber(String input) {
  final local = normalizeJapanMobileNumber(input);
  return '+81${local.substring(1)}';
}

bool isValidJapanMobileNumber(String? input) {
  try {
    normalizeJapanMobileNumber(input);
    return true;
  } on PhoneNumberFormatException {
    return false;
  }
}

void _validateJapanMobileDigits(String value) {
  if (value.length != 11) {
    throw const PhoneNumberFormatException(
      'phone/invalid-length',
      'Japan mobile number must be 11 digits in local format.',
    );
  }

  if (!RegExp(r'^(070|080|090)\d{8}$').hasMatch(value)) {
    throw const PhoneNumberFormatException(
      'phone/invalid-prefix',
      'Japan mobile number must start with 070, 080, or 090.',
    );
  }
}

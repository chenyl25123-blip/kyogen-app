import 'package:flutter_test/flutter_test.dart';
import 'package:kyogen/utils/email_validator.dart';

void main() {
  group('isValidEmailAddress', () {
    test('accepts common email addresses', () {
      expect(isValidEmailAddress('user@gmail.com'), isTrue);
      expect(isValidEmailAddress('hanako@example.co.jp'), isTrue);
      expect(isValidEmailAddress('first.last+tag@sub.example.com'), isTrue);
    });

    test('accepts surrounding whitespace after trimming', () {
      expect(isValidEmailAddress('  user@gmail.com  '), isTrue);
    });

    test('rejects incomplete or whitespace-containing addresses', () {
      expect(isValidEmailAddress(''), isFalse);
      expect(isValidEmailAddress('user'), isFalse);
      expect(isValidEmailAddress('user@'), isFalse);
      expect(isValidEmailAddress('@example.com'), isFalse);
      expect(isValidEmailAddress('user@example'), isFalse);
      expect(isValidEmailAddress('user name@example.com'), isFalse);
      expect(isValidEmailAddress('user@example .com'), isFalse);
    });
  });
}

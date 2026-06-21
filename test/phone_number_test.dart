import 'package:flutter_test/flutter_test.dart';
import 'package:kyogen/utils/phone_number.dart';

void main() {
  group('normalizeJapanMobileNumber', () {
    test('accepts Japan mobile numbers with separators', () {
      expect(normalizeJapanMobileNumber('090-1234-5678'), '09012345678');
      expect(normalizeJapanMobileNumber('080 1234 5678'), '08012345678');
      expect(normalizeJapanMobileNumber('(070)1234-5678'), '07012345678');
    });

    test('accepts E.164 Japan mobile numbers', () {
      expect(normalizeJapanMobileNumber('+819012345678'), '09012345678');
    });

    test('throws precise exceptions for invalid numbers', () {
      expect(
        () => normalizeJapanMobileNumber(null),
        throwsA(
          isA<PhoneNumberFormatException>()
              .having((e) => e.code, 'code', 'phone/empty'),
        ),
      );
      expect(
        () => normalizeJapanMobileNumber('090-1234'),
        throwsA(
          isA<PhoneNumberFormatException>()
              .having((e) => e.code, 'code', 'phone/invalid-length'),
        ),
      );
      expect(
        () => normalizeJapanMobileNumber('050-1234-5678'),
        throwsA(
          isA<PhoneNumberFormatException>()
              .having((e) => e.code, 'code', 'phone/invalid-prefix'),
        ),
      );
      expect(
        () => normalizeJapanMobileNumber('090-abc-5678'),
        throwsA(
          isA<PhoneNumberFormatException>()
              .having((e) => e.code, 'code', 'phone/invalid-characters'),
        ),
      );
    });
  });

  group('toE164JapanPhoneNumber', () {
    test('converts local mobile number to E.164', () {
      expect(toE164JapanPhoneNumber('090-1234-5678'), '+819012345678');
    });
  });

  group('isValidJapanMobileNumber', () {
    test('returns true only for supported Japan mobile numbers', () {
      expect(isValidJapanMobileNumber('09012345678'), isTrue);
      expect(isValidJapanMobileNumber('05012345678'), isFalse);
      expect(isValidJapanMobileNumber('0901234'), isFalse);
    });
  });
}

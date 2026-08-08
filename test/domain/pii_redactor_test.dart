import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/services/pii_redactor.dart';

import '../support/meeting_fixtures.dart';

/// S03-UT-01 — PII redaction (BR patterns).
///
/// The two halves matter equally. Missing a CPF sends personal data to a third
/// party; eating `PROJ-123` returns a summary of a meeting that never
/// mentioned the ticket it was about.
void main() {
  const PiiRedactor redactor = PiiRedactor();

  group('S03-UT-01: PII redaction', () {
    test('S03-UT-01: every documented pattern is removed', () {
      final String redacted = redactor.redact(transcriptWithPii);

      // Nothing that was personal survives, in any of its written forms.
      expect(redacted, isNot(contains('123.456.789-09')));
      expect(redacted, isNot(contains('12345678909')));
      expect(redacted, isNot(contains('+55 11 98765-4321')));
      expect(redacted, isNot(contains('(11) 3555-0100')));
      expect(redacted, isNot(contains('11987654321')));
      expect(redacted, isNot(contains('bruno@example.com')));
      expect(redacted, isNot(contains('bruno.silva+jira@sub.example.org')));

      // And the pass says so itself.
      expect(redactor.containsPii(redacted), isFalse);
    });

    test('S03-UT-01: each pattern leaves its own placeholder', () {
      final String redacted = redactor.redact(transcriptWithPii);

      // Two CPFs: the punctuated one and the bare eleven digits whose third
      // digit is not 9.
      expect(PiiRedactor.cpfMask.allMatches(redacted).length, 2);
      // Three phone numbers: +55 mobile, parenthesised landline, bare mobile.
      expect(PiiRedactor.phoneMask.allMatches(redacted).length, 3);
      expect(PiiRedactor.emailMask.allMatches(redacted).length, 2);
    });

    test('S03-UT-01: dates, issue keys and versions survive untouched', () {
      final String redacted = redactor.redact(transcriptWithPii);

      expect(redacted, contains('PROJ-123'));
      expect(redacted, contains('NORTE-4567'));
      expect(redacted, contains('2026-08-08'));
      expect(redacted, contains('08/08/2026'));
      expect(redacted, contains('1.2.3'));
    });

    test('S03-UT-01: everything that is not PII is returned byte for byte', () {
      final String redacted = redactor.redact(transcriptWithPii);

      // The structure of the conversation is intact: same number of lines,
      // same speakers, same words around the placeholders.
      expect(redacted.split('\n').length, transcriptWithPii.split('\n').length);
      expect(redacted, contains('Ana: my CPF is '));
      expect(redacted, contains(' is blocked until '));
      expect(redacted, contains('and we are on version '));
    });

    test('S03-UT-01: a transcript with no PII is unchanged', () {
      expect(redactor.redact(retroTranscript), retroTranscript);
      expect(redactor.containsPii(retroTranscript), isFalse);
    });

    test('S03-UT-01: an empty transcript is not a special case', () {
      expect(redactor.redact(''), '');
      expect(redactor.containsPii(''), isFalse);
    });

    // The ambiguity the class documents, asserted rather than left implicit:
    // eleven bare digits are a CPF or a mobile, the mandatory 9 decides, and
    // a CPF whose third digit is 9 gets the wrong label. What matters is that
    // it is still removed.
    test('S03-UT-01: an ambiguous eleven-digit run is still redacted', () {
      final String redacted = redactor.redact('the number is 12945678909 ok');

      expect(redacted, isNot(contains('12945678909')));
      expect(redacted, contains(PiiRedactor.phoneMask));
      expect(redactor.containsPii(redacted), isFalse);
    });

    test('S03-UT-01: a ten-digit run with no punctuation is left alone', () {
      // An order number, a row count, an epoch-ish figure — redacting these
      // would eat ordinary numbers out of ordinary meetings.
      expect(
        redactor.redact('we processed 1234567890 rows'),
        'we processed 1234567890 rows',
      );
    });

    test('S03-UT-01: an address is redacted whole, not in pieces', () {
      // Redacting the digits first would leave `[CPF]@example.com` behind,
      // which is worse than either outcome.
      final String redacted = redactor.redact(
        'write to 12345678909@example.com',
      );

      expect(redacted, 'write to ${PiiRedactor.emailMask}');
    });
  });
}

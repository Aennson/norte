import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/entities/transcript.dart';
import 'package:norte/domain/ports/audio_recorder.dart';

/// Value semantics of the types Sprint 04 added to the domain.
///
/// Not a documented sprint case — added under `docs/project-rules.md` §5.4.
/// It earns its place: `RecordingProgress` is compared on every tick of the
/// recording indicator, and a type whose `==` was wrong would either redraw
/// the screen twenty times a second or stop redrawing it at all. Neither
/// failure looks like a failure in any other test.
void main() {
  group('Transcript', () {
    test('equal text and language are the same transcript', () {
      const Transcript a = Transcript(text: 'bom dia', language: 'pt');
      const Transcript b = Transcript(text: 'bom dia', language: 'pt');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('the language is part of the identity, not decoration', () {
      const Transcript pt = Transcript(text: 'bom dia', language: 'pt');
      const Transcript en = Transcript(text: 'bom dia', language: 'en');

      // The same words detected as a different language is a different
      // answer, and the summarizer will treat it as one.
      expect(pt, isNot(en));
    });

    test('toString reports the size, never the contents', () {
      const Transcript transcript = Transcript(
        text: 'Ana: my CPF is 123.456.789-09',
        language: 'pt',
      );

      // A transcript is exactly the kind of thing that must not turn up in a
      // log line (BR-03, `docs/architecture.md` §10).
      expect(transcript.toString(), 'Transcript(pt, 29 chars)');
      expect(transcript.toString(), isNot(contains('123.456.789-09')));
    });
  });

  group('RecordingProgress', () {
    test('identical ticks are equal', () {
      const RecordingProgress a = RecordingProgress(
        state: RecordingState.recording,
        elapsed: Duration(minutes: 1),
        level: 0.5,
      );
      const RecordingProgress b = RecordingProgress(
        state: RecordingState.recording,
        elapsed: Duration(minutes: 1),
        level: 0.5,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('each field alone is enough to make a different tick', () {
      const RecordingProgress base = RecordingProgress(
        state: RecordingState.recording,
        elapsed: Duration(minutes: 1),
        level: 0.5,
      );

      expect(
        base,
        isNot(
          const RecordingProgress(
            state: RecordingState.paused,
            elapsed: Duration(minutes: 1),
            level: 0.5,
          ),
        ),
      );
      expect(
        base,
        isNot(
          const RecordingProgress(
            state: RecordingState.recording,
            elapsed: Duration(minutes: 2),
            level: 0.5,
          ),
        ),
      );
      expect(
        base,
        isNot(
          const RecordingProgress(
            state: RecordingState.recording,
            elapsed: Duration(minutes: 1),
            level: 0.9,
          ),
        ),
      );
    });
  });

  group('AudioRecording', () {
    test('same path and duration are the same recording', () {
      const AudioRecording a = AudioRecording(
        path: '/tmp/norte_recordings/meeting_1.m4a',
        duration: Duration(minutes: 41),
      );
      const AudioRecording b = AudioRecording(
        path: '/tmp/norte_recordings/meeting_1.m4a',
        duration: Duration(minutes: 41),
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('two takes at the same length are still two takes', () {
      const AudioRecording first = AudioRecording(
        path: '/tmp/norte_recordings/meeting_1.m4a',
        duration: Duration(minutes: 41),
      );
      const AudioRecording second = AudioRecording(
        path: '/tmp/norte_recordings/meeting_2.m4a',
        duration: Duration(minutes: 41),
      );

      // The path is the identity: deleting the wrong one of these would
      // destroy a meeting the user still has.
      expect(first, isNot(second));
    });
  });
}

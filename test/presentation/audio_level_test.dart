import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:norte/presentation/voice/audio_level.dart';

/// The meter reads the audio (`sprint-05`, reported by the Developer).
///
/// Not a documented sprint case — added under `docs/project-rules.md` §5.4.
/// It exists because the first version of the overlay had **no** level at all:
/// it said "Listening…" from the moment the button was pressed and looked
/// identical whether the microphone was feeding the pipeline or mute. The
/// value of the replacement rests entirely on the number being real, so the
/// number is what this pins.
void main() {
  /// [seconds] of a sine at [amplitude] of full scale, as PCM 16-bit LE.
  Uint8List tone(double amplitude, {double seconds = 0.1}) {
    const int rate = 16000;
    final int samples = (rate * seconds).round();
    final Uint8List bytes = Uint8List(samples * 2);
    final ByteData view = ByteData.view(bytes.buffer);
    for (var i = 0; i < samples; i++) {
      final int v = (math.sin(2 * math.pi * 440 * i / rate) * 32767 * amplitude)
          .round();
      view.setInt16(i * 2, v, Endian.little);
    }
    return bytes;
  }

  group('level', () {
    test('digital silence is zero', () {
      expect(AudioLevel.of(Uint8List(3200)), 0);
    });

    test('an empty frame is zero rather than a crash', () {
      expect(AudioLevel.of(Uint8List(0)), 0);
    });

    test('an odd-length frame ignores its trailing byte', () {
      // Half a sample is not a sample. Reading it would put a spike on the
      // meter that no one made.
      expect(() => AudioLevel.of(Uint8List(3201)), returnsNormally);
    });

    test('a frame at an odd offset into its buffer is read, not thrown at', () {
      // The regression, reported from a real run. `record` hands out
      // `Uint8List`s that are *views* into a larger buffer, and nothing
      // promises the view begins on an even byte. The first version used
      // `Int16List.view`, which requires two-byte alignment and throws
      // otherwise — and because the level is computed inside a `map` on the
      // microphone stream, that throw propagated as a stream error and killed
      // the session. The console said it plainly: one frame captured, then
      // `session failed after 0 audio frames`, then 426 more frames captured
      // by a microphone nobody was listening to any more.
      final Uint8List backing = Uint8List(3202);
      final ByteData writer = ByteData.view(backing.buffer);
      for (var i = 0; i < 1600; i++) {
        writer.setInt16(1 + i * 2, 12000, Endian.little);
      }
      final Uint8List odd = Uint8List.view(backing.buffer, 1, 3200);

      expect(odd.offsetInBytes.isOdd, isTrue, reason: 'the point of the test');
      expect(() => AudioLevel.of(odd), returnsNormally);
      expect(AudioLevel.of(odd), greaterThan(0));
    });

    test('a 1538-byte frame is read — the size the platform actually sent', () {
      expect(() => AudioLevel.of(Uint8List(1538)), returnsNormally);
    });

    test('room tone stays near the floor, speech does not', () {
      // Roughly -60 dB: below the floor, and the reason the floor exists.
      final double quiet = AudioLevel.of(tone(0.001));
      // Roughly -12 dB: someone talking.
      final double speech = AudioLevel.of(tone(0.25));

      expect(quiet, 0, reason: 'a meter that swings on room tone lies');
      expect(speech, greaterThan(0.5));
      expect(speech, lessThanOrEqualTo(1.0));
    });

    test('louder input reads higher, monotonically', () {
      final List<double> levels = <double>[
        for (final double a in <double>[0.01, 0.05, 0.2, 0.5, 1.0])
          AudioLevel.of(tone(a)),
      ];

      for (var i = 1; i < levels.length; i++) {
        expect(levels[i], greaterThan(levels[i - 1]), reason: 'step $i');
      }
      // A full-scale *sine* tops out near 0.94, not 1.0: its RMS is 1/√2, so
      // about -3 dBFS. Only a square wave reaches the ceiling. Asserting 1.0
      // here would be asserting a signal no microphone produces.
      expect(levels.last, greaterThan(0.9));
      expect(levels.last, lessThanOrEqualTo(1.0));
    });
  });

  group('smoothing', () {
    test('rises immediately', () {
      // A meter that lagged the start of a word would make the user think the
      // microphone missed it.
      expect(AudioLevel.smooth(0.1, 0.9), 0.9);
    });

    test('falls gradually', () {
      final double next = AudioLevel.smooth(0.8, 0.0);

      // Between syllables the level drops to nothing; a meter that followed it
      // exactly would read as a microphone cutting in and out.
      expect(next, lessThan(0.8));
      expect(next, greaterThan(0.0));
    });

    test('settles at zero once the speaking stops', () {
      var level = 0.9;
      for (var i = 0; i < 40; i++) {
        level = AudioLevel.smooth(level, 0);
      }

      expect(level, lessThan(0.01));
    });
  });
}

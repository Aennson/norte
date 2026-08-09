import 'dart:math' as math;
import 'dart:typed_data';

/// Turns a frame of PCM into a level the meter can render.
///
/// **It measures the audio, it does not decorate it.** A pulsing circle that
/// animates on a timer looks the same whether the microphone is working or
/// dead, which makes it worse than no indicator: it is an assurance the app is
/// in no position to give. This reads the samples.
///
/// Nothing is retained. A frame goes in, a number comes out, and the bytes are
/// the caller's to forget (BR-06).
abstract final class AudioLevel {
  /// Quietest input the meter distinguishes, in dBFS.
  ///
  /// Below roughly -50 dB everything is room tone and electrical noise. A
  /// meter that swung on that would tell the user their microphone is hearing
  /// them when it is hearing the fan — the same reasoning, and the same floor
  /// give or take, as the recording screen's meter.
  static const double floorDb = -50;

  /// RMS level of [frame] as `0.0..1.0`, where 0 is at or below [floorDb].
  ///
  /// [frame] is signed 16-bit little-endian, the format the realtime engine
  /// requires. An odd-length frame has its trailing byte ignored rather than
  /// being read as half a sample.
  /// **Read through [ByteData], not [Int16List.view].** The typed-list view
  /// requires its offset to be a multiple of two and throws otherwise, and
  /// `record` hands out frames that are views into a larger buffer at whatever
  /// offset the platform chose. The first version used it, threw on the very
  /// first frame, and — because the level is computed inside a `map` on the
  /// microphone stream — took the whole session down with it. `getInt16` reads
  /// at any offset.
  static double of(Uint8List frame) {
    final int samples = frame.lengthInBytes ~/ 2;
    if (samples == 0) return 0;

    final ByteData pcm = ByteData.view(
      frame.buffer,
      frame.offsetInBytes,
      samples * 2,
    );

    var sum = 0.0;
    for (var i = 0; i < samples; i++) {
      final double normalized = pcm.getInt16(i * 2, Endian.little) / 32768.0;
      sum += normalized * normalized;
    }
    final double rms = math.sqrt(sum / samples);
    if (rms <= 0) return 0;

    final double db = 20 * (math.log(rms) / math.ln10);
    return ((db - floorDb) / -floorDb).clamp(0.0, 1.0);
  }

  /// [next] smoothed against [previous], so the meter follows speech rather
  /// than flickering on every 100 ms frame.
  ///
  /// It rises fast and falls slow — the asymmetry matters. A meter that fell
  /// as quickly as it rose would sit at zero between syllables and read as a
  /// microphone cutting in and out.
  static double smooth(double previous, double next) =>
      next > previous ? next : previous * 0.75 + next * 0.25;
}

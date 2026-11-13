import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Plays an animated image asset (GIF/WebP) on the wall clock.
///
/// `Image.asset` shows each frame for at least its duration and then waits
/// for the next vsync, so short frames (~20-30 ms) stretch and a long
/// animation drifts behind anything it should stay in time with. This widget
/// instead picks the frame for the time elapsed since it was mounted and
/// skips frames when it falls behind, so the animation keeps pace with a
/// song started at the same moment. Give it a new key to restart it.
class ClockedAnimation extends StatefulWidget {
  const ClockedAnimation({super.key, required this.asset, this.fit});

  final String asset;
  final BoxFit? fit;

  @override
  State<ClockedAnimation> createState() => _ClockedAnimationState();
}

class _ClockedAnimationState extends State<ClockedAnimation>
    with SingleTickerProviderStateMixin {
  final _clock = Stopwatch()..start();
  late final Ticker _ticker = createTicker((_) => _catchUp());
  ui.Codec? _codec;
  ui.Image? _image;

  /// Clock time at which the frame on screen ends.
  var _frameEnd = Duration.zero;
  var _decoding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await rootBundle.load(widget.asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    if (!mounted) {
      codec.dispose();
      return;
    }
    _codec = codec;
    await _catchUp();
    if (mounted && codec.frameCount > 1) _ticker.start();
  }

  /// Decodes forward to the frame for the current clock time.
  Future<void> _catchUp() async {
    final codec = _codec;
    if (codec == null || _decoding || _clock.elapsed < _frameEnd) return;
    _decoding = true;
    ui.Image? next;
    try {
      while (_clock.elapsed >= _frameEnd) {
        final frame = await codec.getNextFrame();
        if (!mounted) {
          frame.image.dispose();
          next?.dispose();
          return;
        }
        next?.dispose();
        next = frame.image;
        // A zero-length frame would never advance the clock target.
        final length = frame.duration > Duration.zero
            ? frame.duration
            : const Duration(milliseconds: 100);
        _frameEnd += length;
      }
    } finally {
      _decoding = false;
    }
    final old = _image;
    setState(() => _image = next);
    old?.dispose();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _codec?.dispose();
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      RawImage(image: _image, fit: widget.fit);
}

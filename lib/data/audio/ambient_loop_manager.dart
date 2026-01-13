import 'dart:async';
import 'package:pixel_adventure/data/audio/audio_center.dart';

class AmbientLoopManager {
  // constructor parameters
  final AudioCenter _audioCenter;

  AmbientLoopManager({required AudioCenter audioCenter}) : _audioCenter = audioCenter {
    _audioCenter.addAmbientResetListener(_onAmbientReset);
  }

  // active sources for each loop sound
  final Map<LoopSfx, Set<Object>> _activeSources = {};

  // pending stops for each loop sound to avoid hysteresis against flickering at the edge of the screen
  final Map<LoopSfx, Timer?> _pendingStop = {};

  // default stop delay and fade out
  static const Duration _defaultStopDelay = Duration(milliseconds: 250);

  void dispose() {
    _audioCenter.removeAmbientResetListener(_onAmbientReset);
    _clearUp();
  }

  Future<void> registerSource(LoopSfx loop, Object source) async {
    if (_audioCenter.effectiveSfxVolume == 0 || _audioCenter.gameSfxMuted) return;

    // cancel timer
    _pendingStop[loop]?.cancel();
    _pendingStop[loop] = null;

    // create the set if it does not already exist and add the source to the set
    final set = _activeSources.putIfAbsent(loop, () => <Object>{});
    final wasEmpty = set.isEmpty;
    set.add(source);

    // if it is currently the only source for the specific loop sound, the loop will be started
    if (wasEmpty) await _audioCenter.startLoop(loop, fadeIn: true);
  }

  Future<void> unregisterSource(LoopSfx loop, Object source) async {
    if (_audioCenter.effectiveSfxVolume == 0 || _audioCenter.gameSfxMuted) return;

    // check whether a set exists for this loop sound
    final set = _activeSources[loop];
    if (set == null) return;

    // remove source from set
    set.remove(source);

    // if there is no longer a source, stop loop with delay
    if (set.isNotEmpty) return;
    _pendingStop[loop]?.cancel();
    _pendingStop[loop] = Timer(_defaultStopDelay, () async {
      final stillEmpty = (_activeSources[loop]?.isEmpty ?? true);
      if (stillEmpty) await _audioCenter.stopLoop(loop, fadeOut: true);
    });
  }

  void _onAmbientReset() => _clearUp();

  void _clearUp() {
    // kill all timer
    for (final timer in _pendingStop.values) {
      timer?.cancel();
    }
    _pendingStop.clear();

    // clear active sources and stop active loops
    _activeSources.clear();
  }
}

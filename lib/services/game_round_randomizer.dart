// lib/services/game_round_randomizer.dart
//
// Provides a shuffled, no-repeat round order for every game + difficulty.
//
// How it works
// ─────────────
// Each game+difficulty combination has its own "deck" — a shuffled list of
// all available indices.  When a session starts, it consumes the next batch
// of indices from the front of that deck.
//
// When the deck is exhausted (or too small for the next session), it is
// refilled by re-shuffling the full pool.  The re-shuffle guarantees the
// new first index differs from the previous session's first index, so
// replaying the same difficulty never starts on the same round twice in a row.
//
// Usage (inside a game screen initState / _restart):
//   final indices = GameRoundRandomizer()
//       .nextSession('rhyming', widget.difficulty, _allRounds.length);
//   _activeRounds = indices.map((i) => _allRounds[i]).toList();

import 'dart:math';
import '../models/difficulty.dart';

class GameRoundRandomizer {
  // ── Singleton ─────────────────────────────────────────────────────────
  static final GameRoundRandomizer _instance = GameRoundRandomizer._internal();
  factory GameRoundRandomizer() => _instance;
  GameRoundRandomizer._internal();

  final _rng = Random();

  // deck per "gameId|difficulty" key
  final Map<String, List<int>> _decks = {};
  // first index of the previous session, per key — used to avoid same start
  final Map<String, int> _prevFirst = {};

  // ── Public API ─────────────────────────────────────────────────────────

  /// Returns a list of [poolSize] indices in a randomised order.
  /// The order is guaranteed to differ from the last session for this key.
  ///
  /// [gameId]   – short string identifying the game, e.g. 'rhyming'
  /// [diff]     – the active Difficulty
  /// [poolSize] – total number of rounds available for this difficulty
  List<int> nextSession(String gameId, Difficulty diff, int poolSize) {
    if (poolSize <= 0) return [];
    final key = '$gameId|${diff.name}';

    var deck = _decks[key] ?? [];

    // Refill whenever the deck can't cover a full session
    if (deck.length < poolSize) {
      deck = _refill(key, poolSize);
    }

    // Take poolSize indices from the front
    final session = deck.take(poolSize).toList();
    _decks[key] = deck.skip(poolSize).toList();
    _prevFirst[key] = session.first;
    return session;
  }

  // ── Internal ───────────────────────────────────────────────────────────

  List<int> _refill(String key, int poolSize) {
    final prev = _prevFirst[key]; // null on first call
    List<int> attempt;
    var tries = 0;

    do {
      attempt = List.generate(poolSize, (i) => i)..shuffle(_rng);
      tries++;
      // Accept immediately if pool is 1 (nothing to vary) or after 10 tries
    } while (tries < 10 && poolSize > 1 && attempt.first == prev);

    return attempt;
  }

  /// Call this to fully reset a single game (e.g. when difficulty changes).
  void resetGame(String gameId, Difficulty diff) {
    final key = '$gameId|${diff.name}';
    _decks.remove(key);
    _prevFirst.remove(key);
  }

  /// Reset everything (e.g. on progress wipe).
  void resetAll() {
    _decks.clear();
    _prevFirst.clear();
  }
}

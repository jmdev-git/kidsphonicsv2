// lib/services/word_image_service.dart
//
// Maps every word to its PNG asset path.
// Keys are lowercase word names. Values are full Flutter asset paths.
// Only real image files are listed — no substitutes or placeholders.
// Words with no image return null and show the icon placeholder in GameImageCard.

import 'dart:math';

class WordImageService {
  static WordImageService _instance = WordImageService._internal();
  factory WordImageService() => _instance;
  WordImageService._internal();

  final _rng = Random();
  final Map<String, List<String>> _used = {};

  static const Map<String, List<String>> _images = {

    // ── A-Z_Letter ────────────────────────────────────────────────────────
    'apple':     ['assets/images/A-Z_Letter/Apple.png'],
    'banana':    ['assets/images/A-Z_Letter/Banana.png'],
    'cat':       ['assets/images/A-Z_Letter/Cat.png'],
    'dog':       ['assets/images/A-Z_Letter/Dog.png'],
    'egg':       ['assets/images/A-Z_Letter/Egg.png'],
    'fish':      ['assets/images/A-Z_Letter/Fish.png'],
    'grapes':    ['assets/images/A-Z_Letter/Grapes.png'],
    'house':     ['assets/images/A-Z_Letter/House.png'],
    'ice cream': ['assets/images/A-Z_Letter/IceCream.png'],
    'juice':     ['assets/images/A-Z_Letter/Juice.png'],
    'kite':      ['assets/images/A-Z_Letter/Kite.png'],
    'lion':      ['assets/images/A-Z_Letter/Lion.png'],
    'moon':      ['assets/images/A-Z_Letter/Moon.png'],
    'nut':       ['assets/images/A-Z_Letter/Nut.png'],
    'octopus':   ['assets/images/A-Z_Letter/Octopus.png'],
    'pig':       ['assets/images/A-Z_Letter/Pig.png'],
    'queen':     ['assets/images/A-Z_Letter/Queen.png'],
    'rainbow':   ['assets/images/A-Z_Letter/Rainbow.png'],
    'sun':       ['assets/images/A-Z_Letter/Sun.png'],
    'turtle':    ['assets/images/A-Z_Letter/Turtle.png'],
    'umbrella':  ['assets/images/A-Z_Letter/Umbrella.png'],
    'violin':    ['assets/images/A-Z_Letter/Violin.png'],
    'whale':     ['assets/images/A-Z_Letter/Whale.png'],
    'xylophone': ['assets/images/A-Z_Letter/Xylophone.png'],
    'yarn':      ['assets/images/A-Z_Letter/Yarn.png'],
    'zebra':     ['assets/images/A-Z_Letter/Zebra.png'],

    // ── Memory_Sound_Match_Quiz ───────────────────────────────────────────
    // hog has two real images — randomised between sessions
    'hog': [
      'assets/images/Memory_Sound_Match_Quiz/Hog.png',
      'assets/images/Rhyming_Words/Hog.png',
    ],
    'rain': ['assets/images/Memory_Sound_Match_Quiz/Rain.png'],

    // ── Rhyming_Words ─────────────────────────────────────────────────────
    'ball':    ['assets/images/Rhyming_Words/Ball.png'],
    'balloon': ['assets/images/Rhyming_Words/Balloon.png'],
    'bat':     ['assets/images/Rhyming_Words/Bat.png'],
    'bee':     ['assets/images/Rhyming_Words/Bee.png'],
    'box':     ['assets/images/Rhyming_Words/Box.png'],
    'bug':     ['assets/images/Rhyming_Words/Bug.png'],
    'cake':    ['assets/images/Rhyming_Words/Cake.png'],
    'car':     ['assets/images/Rhyming_Words/Car.png'],
    'fox':     ['assets/images/Rhyming_Words/Fox.png'],
    'frog':    ['assets/images/Rhyming_Words/Frog.png'],
    'hat':     ['assets/images/Rhyming_Words/Hat.png'],
    'lake':    ['assets/images/Rhyming_Words/Lake.png'],
    'log':     ['assets/images/Rhyming_Words/Log.png'],
    'mat':     ['assets/images/Rhyming_Words/Mat.png'],
    'mouse':   ['assets/images/Rhyming_Words/Mouse.png'],
    'mug':     ['assets/images/Rhyming_Words/Mug.png'],
    'snake':   ['assets/images/Rhyming_Words/Snake.png'],
    'spoon':   ['assets/images/Rhyming_Words/Spoon.png'],
    'star':    ['assets/images/Rhyming_Words/Star.png'],
    'tree':    ['assets/images/Rhyming_Words/Tree.png'],

    // ── Word_Builder ──────────────────────────────────────────────────────
    'ape': ['assets/images/Word_Builder/Ape.png'],
    'lip': ['assets/images/Word_Builder/Lip.png'],
    'mop': ['assets/images/Word_Builder/Mop.png'],
    'rat': ['assets/images/Word_Builder/Rat.png'],
  };

  /// Returns the asset path for [word], or null if no image exists.
  /// Cycles through multiple variants without repeating.
  String? imageFor(String word) {
    final key = word.trim().toLowerCase();
    final all = _images[key];
    if (all == null || all.isEmpty) return null;
    if (all.length == 1) return all.first;

    final used = _used.putIfAbsent(key, () => []);
    var available = all.where((p) => !used.contains(p)).toList();
    if (available.isEmpty) {
      _used[key] = [];
      available = List.from(all);
    }
    available.shuffle(_rng);
    final picked = available.first;
    used.add(picked);
    return picked;
  }

  void resetSession() => _used.clear();

  static void resetInstance() {
    _instance = WordImageService._internal();
  }
}

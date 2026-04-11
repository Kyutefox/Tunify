import 'dart:math';

/// Generates fun, creative random usernames for guest users.
/// Combines various word categories to create unique and memorable names.
class UsernameGenerator {
  UsernameGenerator._();

  static final _random = Random();

  static const _adjectives = [
    // Colors & Visual
    'Neon', 'Cosmic', 'Solar', 'Lunar', 'Crystal', 'Golden', 'Silver',
    'Crimson',
    'Azure', 'Violet', 'Emerald', 'Obsidian', 'Prismatic', 'Radiant', 'Glowing',
    // Personality
    'Epic', 'Mystic', 'Swift', 'Brave', 'Chill', 'Wild', 'Lucky', 'Clever',
    'Sneaky', 'Mighty', 'Noble', 'Fierce', 'Gentle', 'Witty', 'Jolly',
    // Weather & Nature
    'Frost', 'Storm', 'Thunder', 'Misty', 'Sunny', 'Snowy', 'Windy', 'Rainy',
    // Tech & Cyber
    'Cyber', 'Digital', 'Pixel', 'Quantum', 'Turbo', 'Hyper', 'Ultra', 'Mega',
    // Mystical
    'Shadow', 'Phantom', 'Ghost', 'Spirit', 'Astral', 'Ethereal', 'Arcane',
    'Mythic',
    // Fun
    'Funky', 'Groovy', 'Jazzy', 'Snazzy', 'Zippy', 'Zesty', 'Spicy', 'Sassy',
    'Fluffy', 'Sparkly', 'Bouncy', 'Wobbly', 'Giggly', 'Bubbly', 'Dizzy',
    'Fizzy',
  ];

  static const _nouns = [
    // Animals
    'Wolf', 'Dragon', 'Fox', 'Bear', 'Tiger', 'Panda', 'Hawk', 'Lynx', 'Raven',
    'Phoenix', 'Falcon', 'Panther', 'Otter', 'Badger', 'Owl', 'Koala',
    'Penguin',
    'Dolphin', 'Shark', 'Octopus', 'Raccoon', 'Sloth', 'Llama', 'Alpaca',
    'Moose',
    // Mythical
    'Unicorn', 'Griffin', 'Sphinx', 'Hydra', 'Kraken', 'Yeti', 'Goblin',
    'Wizard',
    'Knight', 'Ninja', 'Samurai', 'Viking', 'Pirate', 'Mage', 'Druid', 'Bard',
    // Space & Nature
    'Comet', 'Meteor', 'Nebula', 'Nova', 'Pulsar', 'Quasar', 'Star', 'Moon',
    'Ember', 'Blaze', 'Flame', 'Spark', 'Thunder', 'Storm', 'Breeze', 'Tide',
    // Objects & Concepts
    'Echo', 'Sage', 'Cipher', 'Glitch', 'Byte', 'Pixel', 'Vortex', 'Prism',
    'Ripple', 'Whisper', 'Shadow', 'Specter', 'Phantom', 'Wraith', 'Spirit',
    // Food & Fun
    'Waffle', 'Pickle', 'Muffin', 'Cookie', 'Noodle', 'Taco', 'Pretzel',
    'Donut',
    'Cupcake', 'Pancake', 'Nugget', 'Biscuit', 'Dumpling', 'Burrito', 'Nacho',
  ];

  static const _prefixes = [
    'The',
    'Sir',
    'Captain',
    'Lord',
    'Lady',
    'Dr',
    'Agent',
    'Chief',
    'Master',
    'Grand',
    'Super',
    'Ultra',
    'Mega',
    'Pro',
    'Elite',
    'Prime',
  ];

  static const _suffixes = [
    'Master',
    'Lord',
    'King',
    'Queen',
    'Boss',
    'Chief',
    'Pro',
    'Star',
    'Hero',
    'Legend',
    'Ace',
    'Champion',
    'Guru',
    'Wizard',
    'Ninja',
    'Sage',
  ];

  /// Generates a random username using various patterns.
  static String generate() {
    final pattern = _random.nextInt(6);

    switch (pattern) {
      case 0:
        // AdjectiveNoun123 (classic)
        return '${_pick(_adjectives)}${_pick(_nouns)}${_randomNumber(100, 999)}';
      case 1:
        // NounAdjective (reversed)
        return '${_pick(_nouns)}${_pick(_adjectives)}${_randomNumber(10, 99)}';
      case 2:
        // PrefixNoun
        return '${_pick(_prefixes)}${_pick(_nouns)}${_randomNumber(1, 99)}';
      case 3:
        // NounSuffix
        return '${_pick(_nouns)}${_pick(_suffixes)}${_randomNumber(1, 99)}';
      case 4:
        // DoubleNoun
        return '${_pick(_nouns)}${_pick(_nouns)}${_randomNumber(1, 99)}';
      case 5:
      default:
        // AdjectiveAdjectiveNoun (extra descriptive)
        return '${_pick(_adjectives)}${_pick(_nouns)}';
    }
  }

  static String _pick(List<String> list) => list[_random.nextInt(list.length)];

  static int _randomNumber(int min, int max) =>
      min + _random.nextInt(max - min + 1);
}

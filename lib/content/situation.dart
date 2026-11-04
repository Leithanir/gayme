/// A single gameplay card: a quoted stereotype or a quoted respectful line.
class Situation {
  const Situation({
    required this.id,
    required this.kind,
    required this.target,
    required this.category,
    required this.difficulty,
    required this.active,
    required this.text,
    required this.explanation,
  });

  static const Set<String> languages = {'en', 'fil'};

  static const Set<String> targets = {'women', 'men', 'lgbtqia+'};

  static const Set<String> categories = {
    'workplace',
    'home',
    'school',
    'media',
    'public',
  };

  static final RegExp _idPattern = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

  final String id;
  final SituationKind kind;
  final String target;
  final String category;
  final int difficulty;
  final bool active;

  /// Localized card text keyed by language code (`en`, `fil`).
  final Map<String, String> text;

  /// Localized explanation keyed by language code (`en`, `fil`).
  final Map<String, String> explanation;

  String textFor(String languageCode) {
    return text[languageCode] ?? text['en'] ?? '';
  }

  String explanationFor(String languageCode) {
    return explanation[languageCode] ?? explanation['en'] ?? '';
  }

  factory Situation.fromJson(Map<String, dynamic> json) {
    final id = _readString(json, 'id');

    if (!_idPattern.hasMatch(id)) {
      throw FormatException(
        '"id" must use lowercase letters, numbers, and dashes (got "$id")',
      );
    }

    final kind = SituationKind.fromJson(_readString(json, 'kind'));
    final target = _readString(json, 'target');

    if (!targets.contains(target)) {
      throw FormatException(
        'Card "$id": unknown target "$target"',
      );
    }

    final category = _readString(json, 'category');

    if (!categories.contains(category)) {
      throw FormatException(
        'Card "$id": unknown category "$category"',
      );
    }

    final difficulty = json['difficulty'];

    if (difficulty is! int || difficulty < 1 || difficulty > 3) {
      throw FormatException(
        'Card "$id": "difficulty" must be 1, 2, or 3',
      );
    }

    final active = json['active'];

    if (active is! bool) {
      throw FormatException(
        'Card "$id": "active" must be a boolean',
      );
    }

    return Situation(
      id: id,
      kind: kind,
      target: target,
      category: category,
      difficulty: difficulty,
      active: active,
      text: _readLocalized(json, 'text'),
      explanation: _readLocalized(json, 'explanation'),
    );
  }

  static String _readString(Map<String, dynamic> json, String field) {
    final value = json[field];

    if (value is! String || value.trim().isEmpty) {
      throw FormatException('"$field" must be a non-empty string');
    }

    return value.trim();
  }

  static Map<String, String> _readLocalized(
    Map<String, dynamic> json,
    String field,
  ) {
    final value = json[field];

    if (value is! Map) {
      throw FormatException('"$field" must be a JSON object');
    }

    final localized = <String, String>{};

    for (final language in languages) {
      final entry = value[language];

      if (entry is! String || entry.trim().isEmpty) {
        throw FormatException(
          '"$field.$language" must be a non-empty string',
        );
      }

      localized[language] = entry.trim();
    }

    return Map.unmodifiable(localized);
  }
}

/// Whether a card is a stereotype or a respectful line.
enum SituationKind {
  stereotype('stereotype'),
  respectful('respectful');

  const SituationKind(this.jsonValue);

  final String jsonValue;

  static SituationKind fromJson(String value) {
    for (final kind in values) {
      if (kind.jsonValue == value) return kind;
    }

    throw FormatException('unknown "kind" "$value"');
  }
}

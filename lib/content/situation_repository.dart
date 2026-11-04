import 'dart:convert';

import 'package:flutter/services.dart';

import 'situation.dart';

/// Loads and validates the bundled situation decks.
class SituationRepository {
  const SituationRepository({this.bundle});

  final AssetBundle? bundle;

  static const int supportedSchemaVersion = 1;

  static const List<String> assetPaths = [
    'assets/data/stereotypes.json',
    'assets/data/respectful.json',
  ];

  Future<List<Situation>> loadCards() async {
    final bundle = this.bundle ?? rootBundle;
    final cards = <Situation>[];
    final ids = <String>{};

    for (final path in assetPaths) {
      final raw = await bundle.loadString(path);
      final contents = raw.startsWith('\uFEFF') ? raw.substring(1) : raw;

      Map<String, dynamic> document;

      try {
        final decoded = jsonDecode(contents);

        if (decoded is! Map<String, dynamic>) {
          throw const FormatException(
            'expected a JSON object at the top level',
          );
        }

        document = decoded;
      } on FormatException catch (error) {
        throw SituationLoadException(
          '$path: invalid JSON (${error.message})',
        );
      }

      final version = document['schemaVersion'];

      if (version != supportedSchemaVersion) {
        throw SituationLoadException(
          '$path: unsupported schemaVersion "$version" '
          '(expected $supportedSchemaVersion)',
        );
      }

      final rawCards = document['cards'];

      if (rawCards is! List) {
        throw SituationLoadException('$path: "cards" must be a list');
      }

      for (final rawCard in rawCards) {
        if (rawCard is! Map<String, dynamic>) {
          throw SituationLoadException(
            '$path: every card must be a JSON object',
          );
        }

        final Situation card;

        try {
          card = Situation.fromJson(rawCard);
        } on FormatException catch (error) {
          throw SituationLoadException('$path: ${error.message}');
        }

        if (!ids.add(card.id)) {
          throw SituationLoadException(
            '$path: duplicate card id "${card.id}"',
          );
        }

        if (card.active) {
          cards.add(card);
        }
      }
    }

    if (cards.length < 2) {
      throw const SituationLoadException(
        'Not enough active cards to play.',
      );
    }

    final hasStereotype = cards.any(
      (card) => card.kind == SituationKind.stereotype,
    );
    final hasRespectful = cards.any(
      (card) => card.kind == SituationKind.respectful,
    );

    if (!hasStereotype || !hasRespectful) {
      throw const SituationLoadException(
        'The deck needs both stereotype and respectful cards.',
      );
    }

    return List.unmodifiable(cards);
  }
}

class SituationLoadException implements Exception {
  const SituationLoadException(this.message);

  final String message;

  @override
  String toString() => message;
}

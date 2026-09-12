import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/features/exam_attempt/domain/listening_payload.dart';

const int expectedContractVersion = 1;

const _taskTypes = <String>{
  'SUMMARIZE_SPOKEN_TEXT',
  'WRITE_FROM_DICTATION',
  'MC_LISTENING_MULTIPLE',
  'HIGHLIGHT_CORRECT_SUMMARY',
  'SELECT_MISSING_WORD',
  'FILL_BLANKS_LISTENING',
  'HIGHLIGHT_INCORRECT_WORDS',
  'MC_LISTENING_SINGLE',
};

Map<String, dynamic> _loadFixture() {
  final file = File('test/fixtures/listening-payload-contract.json');
  if (!file.existsSync()) {
    fail(
      'Listening payload fixture is missing at ${file.path}; sync it from '
      'pte-doc/projects/fixtures/listening-payload-contract.json.',
    );
  }
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, dynamic>) {
    fail('Listening payload fixture root must be a JSON object.');
  }
  return decoded;
}

List<Map<String, dynamic>> _fixtureEntries(Map<String, dynamic> fixture) {
  final rawEntries = fixture['fixtures'];
  if (rawEntries is! List) {
    fail('Listening payload fixture must contain a fixtures array.');
  }
  return [
    for (final rawEntry in rawEntries)
      if (rawEntry is Map<String, dynamic>)
        rawEntry
      else
        fail('Every Listening payload fixture entry must be a JSON object.'),
  ];
}

void main() {
  late Map<String, dynamic> fixture;
  late List<Map<String, dynamic>> entries;

  setUpAll(() {
    fixture = _loadFixture();
    entries = _fixtureEntries(fixture);
  });

  test('fixture schema and contract version are explicit', () {
    expect(
      fixture['contractVersion'],
      expectedContractVersion,
      reason:
          'Fixture contractVersion changed; sync the fixture and update '
          'expectedContractVersion intentionally.',
    );
    expect(entries, hasLength(_taskTypes.length));

    final taskTypes = <String>[];
    for (final entry in entries) {
      expect(entry, contains('taskType'));
      expect(entry, contains('optionsJson'));
      expect(entry, contains('payload'));
      expect(entry, contains('description'));
      expect(entry['taskType'], isA<String>());
      expect(entry['payload'], isA<String>());
      expect(entry['description'], isA<String>());
      expect(entry['optionsJson'], anyOf(isNull, isA<String>()));
      taskTypes.add(entry['taskType'] as String);
    }

    expect(taskTypes.toSet(), _taskTypes);
    expect(taskTypes, hasLength(_taskTypes.length));
  });

  test('actual Listening serializers reproduce every canonical payload', () {
    final serializers = <String, String Function()>{
      'SUMMARIZE_SPOKEN_TEXT': () =>
          listeningFreeTextPayload('The student\'s summary text'),
      'WRITE_FROM_DICTATION': () =>
          listeningFreeTextPayload('The dictated text'),
      'MC_LISTENING_MULTIPLE': () =>
          listeningMultipleSelectionPayload(const ['3', '0', '2']),
      'HIGHLIGHT_CORRECT_SUMMARY': () => listeningSingleSelectionPayload('1'),
      'SELECT_MISSING_WORD': () => listeningSingleSelectionPayload('2'),
      'FILL_BLANKS_LISTENING': () =>
          listeningPositionalTextPayload(const ['rapid', null, 'forest', null]),
      'HIGHLIGHT_INCORRECT_WORDS': () =>
          listeningTranscriptWordIndicesPayload(const [11, 3, 7]),
      'MC_LISTENING_SINGLE': () => listeningSingleSelectionPayload('2'),
    };

    expect(serializers.keys.toSet(), _taskTypes);
    for (final entry in entries) {
      final taskType = entry['taskType'] as String;
      final serializer = serializers[taskType];
      expect(serializer, isNotNull, reason: 'No serializer for $taskType');
      expect(
        serializer!(),
        entry['payload'],
        reason: entry['description'] as String,
      );
    }
  });

  test('positional typed text rejects an ambiguous comma in one gap value', () {
    expect(
      () => listeningPositionalTextPayload(const ['good, bad']),
      throwsArgumentError,
    );
  });
}

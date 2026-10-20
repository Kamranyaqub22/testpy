import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the Horizon design system: screens and widgets take colours from
/// tokens (`context.hz`), icons from `HzIcons`, and contain no emoji.
/// See CLAUDE.md and design/README.md.
void main() {
  final files = [
    ...Directory('lib/screens').listSync(),
    ...Directory('lib/widgets').listSync(),
  ].whereType<File>().where((f) => f.path.endsWith('.dart')).toList();

  List<String> offences(
    RegExp pattern, {
    bool Function(String, String)? allow,
  }) {
    final found = <String>[];
    for (final f in files) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        for (final m in pattern.allMatches(line)) {
          if (allow?.call(f.path, m.group(0)!) ?? false) continue;
          found.add('${f.path}:${i + 1}: ${line.trim()}');
        }
      }
    }
    return found;
  }

  test('no colour literals outside the tokens', () {
    expect(offences(RegExp(r'\bColor\(0x[0-9A-Fa-f]+\)')), isEmpty);
    expect(
      offences(
        RegExp(r'\bColors\.\w+'),
        allow: (path, match) =>
            match == 'Colors.transparent' ||
            (path.endsWith('widgets/common.dart') &&
                (match == 'Colors.white' || match == 'Colors.white70')),
      ),
      isEmpty,
    );
  });

  test('icons come from HzIcons, not Material', () {
    expect(offences(RegExp(r'(?<![A-Za-z])Icons\.\w+')), isEmpty);
  });

  test('no emoji in the interface', () {
    expect(
      offences(
        RegExp('[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B50}]', unicode: true),
      ),
      isEmpty,
    );
  });

  test('generated tokens are up to date with design/tokens.json', () {
    final tokens = File('design/tokens.json').readAsStringSync();
    final generated = File('lib/design/tokens.g.dart').readAsStringSync();
    for (final m in RegExp(r'"name": "([a-z][a-z0-9-]*)"').allMatches(tokens)) {
      final kebab = m.group(1)!;
      if (kebab.startsWith('space-') ||
          kebab.startsWith('radius-') ||
          kebab.startsWith('size-')) {
        continue;
      }
      final camel = kebab.replaceAllMapped(
        RegExp(r'-([a-z0-9])'),
        (x) => x.group(1)!.toUpperCase(),
      );
      expect(
        generated.contains(camel),
        isTrue,
        reason: '$kebab is missing: run python3 tool/gen_tokens.py',
      );
    }
  });
}

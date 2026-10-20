#!/usr/bin/env python3
"""Generates lib/design/tokens.g.dart from design/tokens.json.

design/tokens.json is the single source of truth for Horizon's colours, type,
spacing, radii, shadows and sizes. Edit it, then run:

    python3 tool/gen_tokens.py && dart format lib/design
"""
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
tokens = json.loads((ROOT / 'design' / 'tokens.json').read_text())
out = ROOT / 'lib' / 'design' / 'tokens.g.dart'


def camel(name):
    head, *rest = re.split(r'[-.]', name)
    return head + ''.join(p[:1].upper() + p[1:] for p in rest)


def dart_color(v):
    v = v.lstrip('#')
    if len(v) == 6:
        v = 'ff' + v
    elif len(v) == 8:
        v = v[6:] + v[:6]
    return f'Color(0x{v.upper()})'


def px(v):
    return float(str(v).replace('px', ''))


def num(v):
    s = f'{v:g}'
    return s if '.' in s else s + '.0' if False else s


def shadow(v):
    m = re.match(r'0 (\d+)px (\d+)px rgba\((\d+), (\d+), (\d+), ([\d.]+)\)', v)
    y, blur, r, g, b, a = m.groups()
    alpha = round(float(a) * 255)
    return (f'BoxShadow(color: Color(0x{alpha:02X}{int(r):02X}{int(g):02X}{int(b):02X}), '
            f'offset: Offset(0, {y}), blurRadius: {blur})')


themes = [t['id'] for t in tokens['color']['themes']]
colors = tokens['color']['tokens']
shadows = tokens['shadow']['tokens']

lines = [
    '// GENERATED from design/tokens.json by tool/gen_tokens.py. Do not edit.',
    '// ignore_for_file: lines_longer_than_80_chars',
    '',
    "import 'package:flutter/material.dart';",
    '',
    '/// Horizon colour and shadow tokens for one theme. Read it with',
    '/// `context.hz` (see hz.dart); never hard-code a colour in a widget.',
    'class HzPalette extends ThemeExtension<HzPalette> {',
    '  const HzPalette({',
]
lines += [f'    required this.{camel(c["name"])},' for c in colors]
lines += [f'    required this.{camel(s["name"])},' for s in shadows]
lines += ['  });', '']
for c in colors:
    lines.append(f'  /// {c["usage"]}')
    lines.append(f'  final Color {camel(c["name"])};')
for s in shadows:
    lines.append(f'  /// {s["usage"]}')
    lines.append(f'  final List<BoxShadow> {camel(s["name"])};')
lines.append('')
for th in themes:
    lines.append(f'  static const {th} = HzPalette(')
    for c in colors:
        v = c['value'] if isinstance(c['value'], str) else c['value'].get(th, c['value'][themes[0]])
        lines.append(f'    {camel(c["name"])}: {dart_color(v)},')
    for s in shadows:
        v = s['value'] if isinstance(s['value'], str) else s['value'].get(th, s['value'][themes[0]])
        lines.append(f'    {camel(s["name"])}: [{shadow(v)}],')
    lines.append('  );')
    lines.append('')
lines.append('  @override')
lines.append('  HzPalette copyWith() => this;')
lines.append('')
lines.append('  @override')
lines.append('  HzPalette lerp(HzPalette? other, double t) {')
lines.append('    if (other == null) return this;')
lines.append('    return HzPalette(')
for c in colors:
    n = camel(c['name'])
    lines.append(f'      {n}: Color.lerp({n}, other.{n}, t)!,')
for s in shadows:
    n = camel(s['name'])
    lines.append(f'      {n}: t < .5 ? {n} : other.{n},')
lines += ['    );', '  }', '}', '']


def const_class(name, doc, family, prefix_strip):
    out = [f'/// {doc}', f'abstract final class {name} {{']
    for t in tokens[family]['tokens']:
        n = camel(t['name'].removeprefix(prefix_strip))
        if n[0].isdigit():
            n = 's' + n
        out.append(f'  /// {t["usage"]}')
        out.append(f'  static const double {n} = {px(t["value"]):g};')
    out += ['}', '']
    return out


lines += const_class('HzSpace', 'Spacing scale (logical pixels).', 'spacing', 'space-')
lines += const_class('HzRadius', 'Corner radii (logical pixels).', 'radius', 'radius-')
lines += const_class('HzSize', 'Component sizes (logical pixels).', 'size', 'size-')

lines += ['/// Type styles. Colour comes from the theme; apply with `.copyWith(color:)`.',
          'abstract final class HzType {',
          "  static const family = 'Manrope';"]
for g in tokens['type']['groups']:
    tabular = g['name'] == 'Money'
    for s in g['styles']:
        size = px(s['fontSize'])
        height = px(s['lineHeight']) / size
        args = [f"fontFamily: family", f"fontSize: {size:g}", f"height: {height:.4g}",
                f"fontWeight: FontWeight.w{s['fontWeight']}"]
        if 'letterSpacing' in s:
            args.append(f"letterSpacing: {px(s['letterSpacing']):g}")
        if tabular:
            args.append('fontFeatures: [FontFeature.tabularFigures()]')
        lines.append(f'  /// {s.get("usage", "")}')
        lines.append(f'  static const {camel(s["name"])} = TextStyle({", ".join(args)});')
lines += ['}', '']

out.write_text('\n'.join(lines))
print(f'wrote {out.relative_to(ROOT)}')

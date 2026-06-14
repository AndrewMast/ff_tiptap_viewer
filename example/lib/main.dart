import 'package:flutter/material.dart';
import 'package:ff_tiptap_viewer/ff_tiptap_viewer.dart';

import 'fake_flutter_flow_theme.dart';

void main() => runApp(const ExampleApp());

/// Builds a paragraph node from a flat list of inline children.
Map<String, dynamic> _p(List<Map<String, dynamic>> inline) =>
    <String, dynamic>{'type': 'paragraph', 'content': inline};

/// Builds a plain text inline node.
Map<String, dynamic> _t(String text) =>
    <String, dynamic>{'type': 'text', 'text': text};

/// Builds a list item wrapping a single line of plain text, plus any nested
/// block content (e.g. a sub-list) so indentation levels are easy to see.
Map<String, dynamic> _li(String text,
        [List<Map<String, dynamic>> nested = const <Map<String, dynamic>>[]]) =>
    <String, dynamic>{
      'type': 'listItem',
      'content': <Map<String, dynamic>>[
        _p(<Map<String, dynamic>>[_t(text)]),
        ...nested,
      ],
    };

/// A document laid out to make vertical rhythm and indentation obvious:
/// several stacked paragraphs, a blank-line spacer, a multi-paragraph
/// blockquote, body text, and bullet + ordered lists nested two levels deep.
final Map<String, dynamic> kSampleDoc = <String, dynamic>{
  'type': 'doc',
  'content': <Map<String, dynamic>>[
    <String, dynamic>{
      'type': 'paragraph',
      'content': <Map<String, dynamic>>[
        <String, dynamic>{'type': 'text', 'text': 'This viewer renders '},
        <String, dynamic>{
          'type': 'text',
          'marks': <Map<String, dynamic>>[
            <String, dynamic>{'type': 'bold'},
          ],
          'text': 'bold',
        },
        <String, dynamic>{'type': 'text', 'text': ', '},
        <String, dynamic>{
          'type': 'text',
          'marks': <Map<String, dynamic>>[
            <String, dynamic>{'type': 'italic'},
          ],
          'text': 'italic',
        },
        <String, dynamic>{'type': 'text', 'text': ', '},
        <String, dynamic>{
          'type': 'text',
          'marks': <Map<String, dynamic>>[
            <String, dynamic>{'type': 'underline'},
          ],
          'text': 'underline',
        },
        <String, dynamic>{'type': 'text', 'text': ', '},
        <String, dynamic>{
          'type': 'text',
          'marks': <Map<String, dynamic>>[
            <String, dynamic>{'type': 'strike'},
          ],
          'text': 'strike',
        },
        <String, dynamic>{'type': 'text', 'text': ', and '},
        <String, dynamic>{
          'type': 'text',
          'marks': <Map<String, dynamic>>[
            <String, dynamic>{'type': 'bold'},
            <String, dynamic>{'type': 'italic'},
            <String, dynamic>{'type': 'underline'},
          ],
          'text': 'all at once',
        },
        <String, dynamic>{'type': 'text', 'text': '. Mention: '},
        <String, dynamic>{
          'type': 'mention',
          'attrs': <String, dynamic>{'id': 'course@123', 'label': 'Intro Course'},
        },
        <String, dynamic>{'type': 'text', 'text': '.'},
      ],
    },
    _p(<Map<String, dynamic>>[
      _t('A second paragraph sits directly below the first. The gap between '
          'them is the theme\'s paragraphSpacing — block siblings, not a blank '
          'line.'),
    ]),
    _p(<Map<String, dynamic>>[
      _t('A third paragraph follows. Below it is a deliberately empty '
          'paragraph, the kind the editor leaves behind when you press Enter '
          'twice:'),
    ]),
    <String, dynamic>{'type': 'paragraph'},
    _p(<Map<String, dynamic>>[
      _t('Text resumes after that blank line. Toggle "Render empty '
          'paragraphs" below to see the spacer collapse.'),
    ]),
    <String, dynamic>{
      'type': 'blockquote',
      'content': <Map<String, dynamic>>[
        _p(<Map<String, dynamic>>[
          _t('A blockquote can hold more than one paragraph behind its left '
              'border bar.'),
        ]),
        _p(<Map<String, dynamic>>[
          _t('This is its second paragraph — note the spacing carries inside '
              'the quote too.'),
        ]),
      ],
    },
    _p(<Map<String, dynamic>>[
      _t('Body text returns to the full width after the blockquote.'),
    ]),
    <String, dynamic>{
      'type': 'bulletList',
      'content': <Map<String, dynamic>>[
        _li('Bullet one', <Map<String, dynamic>>[
          <String, dynamic>{
            'type': 'bulletList',
            'content': <Map<String, dynamic>>[
              _li('Nested bullet (one level in)'),
              _li('Another nested bullet'),
            ],
          },
        ]),
        _li('Bullet two', <Map<String, dynamic>>[
          <String, dynamic>{
            'type': 'orderedList',
            'attrs': <String, dynamic>{'start': 3},
            'content': <Map<String, dynamic>>[
              _li('Nested ordered item (starts at 3)'),
              _li('And the next one'),
            ],
          },
        ]),
        _li('Bullet three'),
      ],
    },
    <String, dynamic>{
      'type': 'orderedList',
      'content': <Map<String, dynamic>>[
        _li('First ordered item'),
        _li('Second ordered item', <Map<String, dynamic>>[
          <String, dynamic>{
            'type': 'bulletList',
            'content': <Map<String, dynamic>>[
              _li('A bullet nested under an ordered item'),
              _li('One more for good measure'),
            ],
          },
        ]),
        _li('Third ordered item'),
      ],
    },
  ],
};

/// A raw JSON string fed to the String input path via [TiptapViewer.fromJson].
/// It does not need to mirror [kSampleDoc] — a short standalone document keeps
/// the parsed-string preview easy to read.
const String kSampleJson =
    '{"type":"doc","content":['
    '{"type":"paragraph","content":[{"type":"text","text":"Parsed straight '
    'from a JSON "},{"type":"text","marks":[{"type":"bold"}],"text":"string"},'
    '{"type":"text","text":" — the exact shape the API serves."}]},'
    '{"type":"paragraph","content":[{"type":"text","text":"A second '
    'paragraph, so the spacing shows here too."}]},'
    '{"type":"blockquote","content":[{"type":"paragraph","content":[{"type":'
    '"text","text":"Even a blockquote survives the round-trip."}]}]}'
    ']}';

enum ThemeChoice { light, dark, flutterFlow, custom }

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  // Toggle state for each node/mark type.
  final Map<String, bool> _enabled = <String, bool>{
    'bold': true,
    'italic': true,
    'underline': true,
    'strike': true,
    'blockquote': true,
    'bulletList': true,
    'orderedList': true,
    'mention': true,
  };

  ThemeChoice _themeChoice = ThemeChoice.light;
  MentionDisplay _mentionDisplay = MentionDisplay.highlight;
  bool _useRawJson = false;
  bool _renderEmptyParagraphs = false;

  // Compact-preview (TiptapText) controls.
  bool _previewIncludeStyle = false;
  int _previewMaxLines = 2;
  bool _previewCapChars = false;

  // When mentions are toggled off: render their label as plain text (true) or
  // strip them entirely (false).
  bool _disabledMentionAsText = true;

  bool get _isDark => _themeChoice == ThemeChoice.dark;

  List<TiptapExtension> _buildExtensions() {
    return <TiptapExtension>[
      const Doc(),
      const Paragraph(),
      const TextNode(),
      const ListItem(),
      if (_enabled['bold']!) const Bold(),
      if (_enabled['italic']!) const Italic(),
      if (_enabled['underline']!) const Underline(),
      if (_enabled['strike']!) const Strike(),
      if (_enabled['blockquote']!) const Blockquote(),
      if (_enabled['bulletList']!) const BulletList(),
      if (_enabled['orderedList']!) const OrderedList(),
      if (_enabled['mention']!)
        Mention(
          display: _mentionDisplay,
          onTap: (id, label) =>
              _showSnack('Tapped mention: id="$id", label="$label"'),
        )
      // Mention off + "as text": still register it, but render the bare label.
      // Off + "strip": omit it so the renderer drops mentions entirely.
      else if (_disabledMentionAsText)
        const Mention(display: MentionDisplay.plain),
    ];
  }

  TiptapViewerTheme _buildTheme(BuildContext context) {
    final TiptapViewerTheme base;
    switch (_themeChoice) {
      case ThemeChoice.light:
      case ThemeChoice.dark:
        base = TiptapViewerTheme.fromContext(context);
      case ThemeChoice.flutterFlow:
        base = tiptapThemeFromFlutterFlow(FakeFlutterFlowTheme.of(context));
      case ThemeChoice.custom:
        base = const TiptapViewerTheme(
          baseTextStyle:
              TextStyle(fontSize: 17, height: 1.5, color: Color(0xFF0F766E)),
          mentionColor: Color(0xFFDB2777),
          bulletGlyph: '—',
          blockquoteBorderColor: Color(0xFF0F766E),
        );
    }
    return base.copyWith(renderEmptyParagraphs: _renderEmptyParagraphs);
  }

  void _showSnack(String message) {
    _messengerKey.currentState
      ?..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ff_tiptap_viewer example',
      scaffoldMessengerKey: _messengerKey,
      theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
      darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('ff_tiptap_viewer')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _sectionTitle('Rendered document (select & copy me)'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _useRawJson
                    ? TiptapViewer.fromJson(
                        kSampleJson,
                        extensions: _buildExtensions(),
                        theme: _buildTheme(context),
                      )
                    : TiptapViewer(
                        document: kSampleDoc,
                        extensions: _buildExtensions(),
                        theme: _buildTheme(context),
                      ),
              ),
              const SizedBox(height: 24),
              _sectionTitle('Compact preview (TiptapText)'),
              Text(
                'The same document flattened onto one truncatable run — the '
                'shape a list/card preview wants.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TiptapText(
                  document: _useRawJson ? kSampleJson : kSampleDoc,
                  extensions: _buildExtensions(),
                  theme: _buildTheme(context),
                  includeStyle: _previewIncludeStyle,
                  maxLines: _previewMaxLines,
                  overflow: TextOverflow.ellipsis,
                  maxChars: _previewCapChars ? 80 : null,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Include style'),
                subtitle: const Text(
                  'On: keep bold/italic/underline/strike. Off: flat text.',
                ),
                value: _previewIncludeStyle,
                onChanged: (v) => setState(() => _previewIncludeStyle = v),
              ),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Cap at 80 characters'),
                subtitle: const Text(
                  'On: hard maxChars cut with a trailing ellipsis.',
                ),
                value: _previewCapChars,
                onChanged: (v) => setState(() => _previewCapChars = v),
              ),
              Row(
                children: <Widget>[
                  const Text('Max lines'),
                  const SizedBox(width: 12),
                  SegmentedButton<int>(
                    segments: const <ButtonSegment<int>>[
                      ButtonSegment(value: 1, label: Text('1')),
                      ButtonSegment(value: 2, label: Text('2')),
                      ButtonSegment(value: 3, label: Text('3')),
                    ],
                    selected: <int>{_previewMaxLines},
                    onSelectionChanged: (s) =>
                        setState(() => _previewMaxLines = s.first),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _sectionTitle('Input source'),
              SegmentedButton<bool>(
                segments: const <ButtonSegment<bool>>[
                  ButtonSegment(value: false, label: Text('Decoded Map')),
                  ButtonSegment(value: true, label: Text('Raw JSON string')),
                ],
                selected: <bool>{_useRawJson},
                onSelectionChanged: (s) => setState(() => _useRawJson = s.first),
              ),
              if (_useRawJson)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('View raw JSON string being parsed'),
                    children: <Widget>[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: SelectableText(
                          kSampleJson,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              _sectionTitle('Theme'),
              SegmentedButton<ThemeChoice>(
                segments: const <ButtonSegment<ThemeChoice>>[
                  ButtonSegment(value: ThemeChoice.light, label: Text('Light')),
                  ButtonSegment(value: ThemeChoice.dark, label: Text('Dark')),
                  ButtonSegment(
                      value: ThemeChoice.flutterFlow, label: Text('FF')),
                  ButtonSegment(
                      value: ThemeChoice.custom, label: Text('Custom')),
                ],
                selected: <ThemeChoice>{_themeChoice},
                onSelectionChanged: (s) =>
                    setState(() => _themeChoice = s.first),
              ),
              const SizedBox(height: 24),
              if (_enabled['mention']!) ...<Widget>[
                _sectionTitle('Mention display'),
                SegmentedButton<MentionDisplay>(
                  segments: const <ButtonSegment<MentionDisplay>>[
                    ButtonSegment(
                        value: MentionDisplay.highlight,
                        label: Text('Highlight')),
                    ButtonSegment(
                        value: MentionDisplay.chip, label: Text('Chip')),
                  ],
                  selected: <MentionDisplay>{_mentionDisplay},
                  onSelectionChanged: (s) =>
                      setState(() => _mentionDisplay = s.first),
                ),
              ] else ...<Widget>[
                _sectionTitle('Disabled mention'),
                SegmentedButton<bool>(
                  segments: const <ButtonSegment<bool>>[
                    ButtonSegment(value: true, label: Text('Label as text')),
                    ButtonSegment(value: false, label: Text('Strip')),
                  ],
                  selected: <bool>{_disabledMentionAsText},
                  onSelectionChanged: (s) =>
                      setState(() => _disabledMentionAsText = s.first),
                ),
              ],
              const SizedBox(height: 24),
              _sectionTitle('Display options'),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Render empty paragraphs'),
                subtitle: const Text(
                  'On: empty paragraphs show as a blank line. '
                  'Off: they are stripped and the gap collapses.',
                ),
                value: _renderEmptyParagraphs,
                onChanged: (v) => setState(() => _renderEmptyParagraphs = v),
              ),
              const SizedBox(height: 24),
              _sectionTitle('Enable / disable nodes & marks'),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _enabled.keys
                    .map(
                      (key) => FilterChip(
                        label: Text(key),
                        selected: _enabled[key]!,
                        onSelected: (v) => setState(() => _enabled[key] = v),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      );
}

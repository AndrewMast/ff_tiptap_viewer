import 'package:flutter/material.dart';
import 'package:ff_tiptap_viewer/ff_tiptap_viewer.dart';

import 'fake_flutter_flow_theme.dart';

void main() => runApp(const ExampleApp());

/// A document exercising every node/mark, stacked marks, an empty paragraph,
/// a nested ordered list, a blockquote, and a mention.
const Map<String, dynamic> kSampleDoc = <String, dynamic>{
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
    <String, dynamic>{'type': 'paragraph'},
    <String, dynamic>{
      'type': 'blockquote',
      'content': <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'paragraph',
          'content': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'text',
              'text': 'A blockquote with a left border bar.',
            },
          ],
        },
      ],
    },
    <String, dynamic>{
      'type': 'bulletList',
      'content': <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'listItem',
          'content': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'paragraph',
              'content': <Map<String, dynamic>>[
                <String, dynamic>{'type': 'text', 'text': 'Bullet one'},
              ],
            },
            <String, dynamic>{
              'type': 'orderedList',
              'attrs': <String, dynamic>{'start': 3},
              'content': <Map<String, dynamic>>[
                <String, dynamic>{
                  'type': 'listItem',
                  'content': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'type': 'paragraph',
                      'content': <Map<String, dynamic>>[
                        <String, dynamic>{
                          'type': 'text',
                          'text': 'Nested item (starts at 3)',
                        },
                      ],
                    },
                  ],
                },
              ],
            },
          ],
        },
        <String, dynamic>{
          'type': 'listItem',
          'content': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'paragraph',
              'content': <Map<String, dynamic>>[
                <String, dynamic>{'type': 'text', 'text': 'Bullet two'},
              ],
            },
          ],
        },
      ],
    },
  ],
};

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
        ),
    ];
  }

  TiptapViewerTheme? _buildTheme(BuildContext context) {
    switch (_themeChoice) {
      case ThemeChoice.light:
      case ThemeChoice.dark:
        return null; // fromContext
      case ThemeChoice.flutterFlow:
        return tiptapThemeFromFlutterFlow(FakeFlutterFlowTheme.of(context));
      case ThemeChoice.custom:
        return const TiptapViewerTheme(
          baseTextStyle:
              TextStyle(fontSize: 17, height: 1.5, color: Color(0xFF0F766E)),
          mentionColor: Color(0xFFDB2777),
          bulletGlyph: '—',
          blockquoteBorderColor: Color(0xFF0F766E),
        );
    }
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
                child: TiptapViewer(
                  document: kSampleDoc,
                  extensions: _buildExtensions(),
                  theme: _buildTheme(context),
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
              const SizedBox(height: 24),
              _sectionTitle('Enable / disable nodes & marks'),
              ..._enabled.keys.map(
                (key) => SwitchListTile(
                  dense: true,
                  title: Text(key),
                  value: _enabled[key]!,
                  onChanged: (v) => setState(() => _enabled[key] = v),
                ),
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

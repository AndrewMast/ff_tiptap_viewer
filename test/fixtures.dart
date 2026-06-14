/// Test fixtures.
///
/// [kRealWorldFixture] is a verbatim real-world API output string, used as a
/// "parses what the server actually sends" smoke test.
///
/// [kKitchenSinkDoc] is a synthetic document that exercises every node and mark,
/// stacked marks, an empty paragraph, nested lists (with an ordered `start`),
/// a blockquote, and a mention — the primary coverage fixture.
library;

/// Verbatim real-world fixture (paragraph + bold + italic only).
const String kRealWorldFixture =
    '{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Example "},{"type":"text","marks":[{"type":"bold"}],"text":"bold"},{"type":"text","text":" ("},{"type":"text","marks":[{"type":"italic"}],"text":"italic"},{"type":"text","text":")."}]}]}';

/// Synthetic kitchen-sink document as a decoded map.
const Map<String, dynamic> kKitchenSinkDoc = <String, dynamic>{
  'type': 'doc',
  'content': <Map<String, dynamic>>[
    <String, dynamic>{
      'type': 'paragraph',
      'content': <Map<String, dynamic>>[
        <String, dynamic>{'type': 'text', 'text': 'Plain, '},
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
            <String, dynamic>{'type': 'bold'},
            <String, dynamic>{'type': 'italic'},
            <String, dynamic>{'type': 'underline'},
            <String, dynamic>{'type': 'strike'},
          ],
          'text': 'stacked',
        },
        <String, dynamic>{'type': 'text', 'text': ', and a '},
        <String, dynamic>{
          'type': 'mention',
          'attrs': <String, dynamic>{'id': 'course@123', 'label': 'My Course'},
        },
        <String, dynamic>{'type': 'text', 'text': '.'},
      ],
    },
    // Intentionally empty paragraph (spacer).
    <String, dynamic>{'type': 'paragraph'},
    <String, dynamic>{
      'type': 'blockquote',
      'content': <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'paragraph',
          'content': <Map<String, dynamic>>[
            <String, dynamic>{'type': 'text', 'text': 'Quoted line.'},
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
                <String, dynamic>{'type': 'text', 'text': 'First bullet'},
              ],
            },
            // Nested ordered list starting at 3.
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
                        <String, dynamic>{'type': 'text', 'text': 'Nested three'},
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
                <String, dynamic>{'type': 'text', 'text': 'Second bullet'},
              ],
            },
          ],
        },
      ],
    },
  ],
};

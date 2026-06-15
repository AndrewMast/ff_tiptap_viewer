import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../model/tiptap_mark.dart';
import '../render/tiptap_renderer.dart';
import 'tiptap_extension.dart';

/// Signature for a link tap. [href] is the raw stored `href` attribute; the
/// package never opens URLs itself (it is dependency-free) — your app decides
/// what to do (e.g. `url_launcher`).
typedef LinkTapCallback = void Function(String href);

/// `link` mark → colored, optionally-underlined text, tappable when [onTap] is
/// supplied.
///
/// `Link` ships **inside** `StarterKit`, but the kit's instance has no [onTap],
/// so links render as styled-but-non-interactive text by default (a link with
/// no handler is still perfectly readable). To make links tappable, list your
/// own wired instance *after* the kit — last-wins replaces the default:
///
/// ```dart
/// extensions: const [StarterKit()] + [Link(onTap: (href) => launchUrl(href))],
/// ```
class Link extends TiptapMarkExtension {
  /// Called when the link is tapped, with the raw `href`. When null, the link
  /// renders styled but is not interactive.
  final LinkTapCallback? onTap;

  const Link({this.onTap});

  @override
  String get type => 'link';

  @override
  TextStyle apply(TiptapRenderer r, TiptapMark mark, TextStyle style) {
    final t = r.theme;
    var result = style.copyWith(color: t.linkColor);
    if (t.linkUnderline) {
      final existing = result.decoration;
      final combined = (existing == null || existing == TextDecoration.none)
          ? TextDecoration.underline
          : TextDecoration.combine(
              <TextDecoration>[existing, TextDecoration.underline]);
      result = result.copyWith(decoration: combined);
    }
    return result;
  }

  @override
  GestureRecognizer? buildRecognizer(TiptapRenderer r, TiptapMark mark) {
    final tap = onTap;
    if (tap == null) {
      return null;
    }
    final href = (mark.attrs['href'] ?? '').toString();
    return TapGestureRecognizer()..onTap = () => tap(href);
  }
}

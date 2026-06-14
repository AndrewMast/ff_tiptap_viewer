import 'package:flutter/material.dart';
import 'package:ff_tiptap_viewer/ff_tiptap_viewer.dart';

/// A tiny stand-in shaped like the real FlutterFlow `FlutterFlowTheme` — same
/// getter names (`bodyMedium`, `primary`, `alternate`, …), returning plain
/// `Color`/`TextStyle`. The real one lives in the FlutterFlow app and drags in
/// `google_fonts`/`shared_preferences`, so a package can't import it — but the
/// mapping into a [TiptapViewerTheme] is identical regardless of the source.
///
/// Copy [tiptapThemeFromFlutterFlow] into the FlutterFlow app, swap this stand-in
/// for `FlutterFlowTheme.of(context)`, and you have a branded viewer.
class FakeFlutterFlowTheme {
  final Color primary;
  final Color alternate;
  final Color primaryText;
  final TextStyle bodyMedium;

  const FakeFlutterFlowTheme({
    required this.primary,
    required this.alternate,
    required this.primaryText,
    required this.bodyMedium,
  });

  static FakeFlutterFlowTheme of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return FakeFlutterFlowTheme(
      primary: const Color(0xFF7C3AED),
      alternate: dark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0),
      primaryText: dark ? const Color(0xFFF2F2F2) : const Color(0xFF14181B),
      bodyMedium: TextStyle(
        fontSize: 16,
        height: 1.4,
        color: dark ? const Color(0xFFF2F2F2) : const Color(0xFF14181B),
      ),
    );
  }
}

/// The one mapping you lift into the host app: FlutterFlow tokens → viewer theme.
TiptapViewerTheme tiptapThemeFromFlutterFlow(FakeFlutterFlowTheme ff) {
  return TiptapViewerTheme(
    baseTextStyle: ff.bodyMedium.copyWith(color: ff.primaryText),
    blockquoteBorderColor: ff.alternate,
    mentionColor: ff.primary,
    orderedNumberStyle: ff.bodyMedium.copyWith(color: ff.primaryText),
  );
}

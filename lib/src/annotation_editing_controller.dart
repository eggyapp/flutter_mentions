part of flutter_mentions;

/// A custom implementation of [TextEditingController] to support @ mention or other
/// trigger based mentions.
class AnnotationEditingController extends TextEditingController {
  Map<String, Annotation> _mapping;
  String? _pattern;

  // Generate the Regex pattern for matching all the suggestions in one.
  AnnotationEditingController(this._mapping)
      : _pattern = _mapping.keys.isNotEmpty
            ? "(?<!\\w)(${_mapping.keys.map((key) => RegExp.escape(key)).join('|')})\\b"
            : null;

  /// Can be used to get the markup from the controller directly.
  String get markupText {
    final someVal = _mapping.isEmpty
        ? text
        : text.splitMapJoin(
            RegExp('$_pattern', caseSensitive: false),
            onMatch: (Match match) {
              final matchedWord = match[0]!;
              final mappingEntries = _mapping.entries;

              final matchedEntry = mappingEntries.firstWhere((entry) {
                return entry.key.toLowerCase() == matchedWord.toLowerCase();
              });

              final mention = matchedEntry.value;

              // Default markup format for mentions
              if (!mention.disableMarkup) {
                return mention.markupBuilder != null
                    ? mention.markupBuilder!(mention.trigger, mention.id!, mention.display!)
                    : '${mention.trigger}[__${mention.id}__](__${mention.display}__)';
              } else {
                return matchedWord;
              }
            },
            onNonMatch: (String text) {
              return text;
            },
          );

    return someVal;
  }

  Map<String, Annotation> get mapping {
    return _mapping;
  }

  set mapping(Map<String, Annotation> _mapping) {
    this._mapping = _mapping;

    _pattern = "(?<!\\w)(${_mapping.keys.map((key) => RegExp.escape(key)).join('|')})\\b";
  }

  @override
  TextSpan buildTextSpan({BuildContext? context, TextStyle? style, bool? withComposing}) {
    var children = <InlineSpan>[];

    if (_pattern == null || _pattern == '()') {
      children.add(TextSpan(text: text, style: style));
    } else {
      text.splitMapJoin(
        RegExp('$_pattern', caseSensitive: false),
        onMatch: (Match match) {
          final matchedWord = match[0]!;

          if (_mapping.isNotEmpty) {
            final mappingEntries = _mapping.entries;

            final matchedEntry = mappingEntries.firstWhere((entry) {
              return entry.key.toLowerCase() == matchedWord.toLowerCase();
            });

            children.add(
              TextSpan(
                text: matchedEntry.key,
                style: style!.merge(matchedEntry.value.style),
              ),
            );
          }

          return '';
        },
        onNonMatch: (String text) {
          children.add(TextSpan(text: text, style: style));
          return '';
        },
      );
    }

    return TextSpan(style: style, children: children);
  }
}

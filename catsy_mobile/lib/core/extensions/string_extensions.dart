/// String extensions for common transformations.
extension StringExt on String {
  /// "hello world" → "Hello World"
  String get titleCase => split(' ')
      .map(
        (w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
      )
      .join(' ');

  /// "HELLO" → "hello"
  String get lower => toLowerCase();

  /// Truncate to [maxLength] and append "…".
  String truncate(int maxLength) =>
      length <= maxLength ? this : '${substring(0, maxLength)}…';

  /// Check if the string is a valid UUID v4.
  bool get isUuid => RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  ).hasMatch(this);
}

/// Splits [command] into the arguments a POSIX shell would pass to `curl`.
///
/// Supports what `CurlCommandGenerator` emits: single quotes, double quotes
/// (with `\` escapes) and backslashes. Unescaped `$` or backtick inside double
/// quotes would be expanded by the shell, so they are reported as errors.
List<String> shellWords(String command) {
  final words = <String>[];
  final current = StringBuffer();
  var inWord = false;
  var i = 0;

  while (i < command.length) {
    final char = command[i];
    if (char == "'") {
      final end = command.indexOf("'", i + 1);
      if (end == -1) {
        throw FormatException('Unterminated single quote', command, i);
      }
      current.write(command.substring(i + 1, end));
      inWord = true;
      i = end + 1;
    } else if (char == '"') {
      final start = i;
      i++;
      while (true) {
        if (i >= command.length) {
          throw FormatException('Unterminated double quote', command, start);
        }
        final quoted = command[i];
        if (quoted == '"') {
          i++;
          break;
        }
        if (quoted == r'\' &&
            i + 1 < command.length &&
            r'$`"\'.contains(command[i + 1])) {
          current.write(command[i + 1]);
          i += 2;
          continue;
        }
        if (quoted == r'$' || quoted == '`') {
          throw FormatException('Unescaped shell expansion', command, i);
        }
        current.write(quoted);
        i++;
      }
      inWord = true;
    } else if (char == r'\' && i + 1 < command.length) {
      current.write(command[i + 1]);
      inWord = true;
      i += 2;
    } else if (char == ' ' || char == '\n' || char == '\t') {
      if (inWord) {
        words.add(current.toString());
        current.clear();
        inWord = false;
      }
      i++;
    } else {
      current.write(char);
      inWord = true;
      i++;
    }
  }
  if (inWord) words.add(current.toString());
  return words;
}

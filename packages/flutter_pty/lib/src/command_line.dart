/// [argument] as one word of a Windows command line, the way the C
/// runtime splits it back: unchanged without spaces, tabs or quotes, else
/// in double quotes with quotes and the backslashes before them escaped.
String windowsQuote(String argument) {
  if (argument.isNotEmpty && !argument.contains(RegExp(r'[\s"]'))) {
    return argument;
  }
  final escaped = argument
      .replaceAllMapped(RegExp(r'(\\*)"'), (m) => '${m[1]}${m[1]}\\"')
      .replaceAllMapped(RegExp(r'(\\+)$'), (m) => '${m[1]}${m[1]}');
  return '"$escaped"';
}

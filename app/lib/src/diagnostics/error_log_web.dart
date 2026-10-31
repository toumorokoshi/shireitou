/// The web app keeps no error log file (AV-145): the browser's console
/// has every error.
library;

/// Where the log is and how to add an entry to it.
typedef ErrorLogFile = ({String path, void Function(String entry) write});

/// None on the web.
Future<ErrorLogFile?> openErrorLog() async => null;

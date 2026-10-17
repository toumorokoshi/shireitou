/// Opens SSH shells (AV-014) where the platform has TCP sockets, and
/// says so with [sshSupported]: browsers cannot open raw TCP sockets, so
/// the web build has no SSH terminal.
library;

export 'ssh_connect_web.dart' if (dart.library.io) 'ssh_connect_io.dart';

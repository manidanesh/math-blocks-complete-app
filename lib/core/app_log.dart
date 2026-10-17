import 'dart:developer' as developer;

/// Send diagnostics to the debugger without logging child data in release builds.
void debugLog(String message) {
  if (!const bool.fromEnvironment('dart.vm.product')) {
    developer.log(message, name: 'NumberBond');
  }
}

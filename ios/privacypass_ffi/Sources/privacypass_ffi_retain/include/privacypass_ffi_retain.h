#ifndef PRIVACYPASS_FFI_RETAIN_H
#define PRIVACYPASS_FFI_RETAIN_H

// Touches every Rust FFI symbol that Dart looks up at runtime so that the
// linker keeps them in the final binary. Call this from a live code path
// (the Flutter plugin registration) to defeat `-dead_strip`.
void privacypass_ffi_retain_symbols(void);

#endif /* PRIVACYPASS_FFI_RETAIN_H */

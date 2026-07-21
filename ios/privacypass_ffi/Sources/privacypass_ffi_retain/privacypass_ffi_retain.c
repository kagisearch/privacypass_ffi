#include "privacypass_ffi_retain.h"

// Declarations of the Rust FFI entry points. Only their addresses are used
// here; the real implementations live in the vendored static library
// (KagiPrivacyPassFFI.xcframework).
extern char *privacy_pass_token_request(const char *header, unsigned short count);
extern char *privacy_pass_token_finalization(const char *tokens, const char *responses);
extern char *privacy_pass_version(void);
extern void privacy_pass_free_string(char *ptr);

// A file-scope, externally-visible table holding the address of every FFI
// entry point Dart resolves at runtime.
//
// `__attribute__((used))` marks the symbol N_NO_DEAD_STRIP for the Mach-O
// linker, so neither the optimizer nor `ld -dead_strip` can remove it — even
// in release builds. Because the table's initializer references the Rust
// symbols, keeping the table forces those symbols to be linked into the final
// binary, where `dlsym(RTLD_DEFAULT, ...)` (Dart's DynamicLibrary.process())
// can find them.
//
// NOTE: this must be a file-scope global, not a function-local array. A local
// (even `static volatile`) that is never read gets eliminated under release
// optimization, which is why an earlier version worked in debug but not in
// release.
__attribute__((used, visibility("default")))
const void *const privacypass_ffi_retained_symbols[] = {
    (const void *)&privacy_pass_token_request,
    (const void *)&privacy_pass_token_finalization,
    (const void *)&privacy_pass_version,
    (const void *)&privacy_pass_free_string,
};

// Kept as the call site invoked from the plugin registration so the object
// file carrying the table above is pulled into the link. The real anchor is
// the `used` table.
void privacypass_ffi_retain_symbols(void) {}

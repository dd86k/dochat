/**
 * Compile-time configuration
 */

//
// Compile settings
//

enum SERVER_VERSION = "0.0.0";	/// Server platform version
enum API_VERSION = "0.0.0";	/// API version

enum DEFAULT_PORT = 3311;	/// Default listening port

/// Initial number of memory user sessions to reserves in memory.
enum USERSESSION_RESERVE = 100;

//
// Compile messages and constants
//

version (D_SIMD)
	pragma(msg, "* compiler: SIMD available");

debug {
	pragma(msg, "* compiler: debug build");
	enum BUILD_TYPE = "debug";	/// For printing purposes
} else {
	enum BUILD_TYPE = "release";	/// For printing purposes
}

version (CRuntime_Bionic) {
	enum C_RUNTIME = "Bionic";	/// Printable C runtime string
} else version (CRuntime_DigitalMars) {
	enum C_RUNTIME = "DigitalMars";	/// Printable C runtime string
} else version (CRuntime_Glibc) {
	enum C_RUNTIME = "Glibc";	/// Printable C runtime string
} else version (CRuntime_Microsoft) {
	enum C_RUNTIME = "Microsoft";	/// Printable C runtime string
} else version(CRuntime_Musl) {
	enum C_RUNTIME = "musl";	/// Printable C runtime string
} else version (CRuntime_UClibc) {
	enum C_RUNTIME = "uClibc";	/// Printable C runtime string
} else {
	enum C_RUNTIME = "UNKNOWN";	/// Printable C runtime string
}

pragma(msg, "* compiler: ", C_RUNTIME, " runtime");

version (X86) {
	enum PLATFORM = "x86";	/// Platform string
} else version (X86_64) {
	enum PLATFORM = "amd64";	/// Platform string
} else version (ARM) {
	version (LittleEndian) enum PLATFORM = "aarch32le";	/// Platform string
	version (BigEndian) enum PLATFORM = "aarch32be";	/// Platform string
} else version (AArch64) {
	version (LittleEndian) enum PLATFORM = "aarch64le";	/// Platform string
	version (BigEndian) enum PLATFORM = "aarch64be";	/// Platform string
} else {
	static assert(0, "Unknown or untested hardware platform.");
}